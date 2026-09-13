# WebKit source: why a modeless IME (VTX) loses IMK delivery in a WKWebView after Backspace+letter

Method note: all code quoted below was pulled live from `github.com/WebKit/WebKit` `main` branch
(fetched 2026-09-13) via `gh api repos/WebKit/WebKit/contents/...` and `raw.githubusercontent.com`,
cross-checked against `bugs.webkit.org` for the referenced bug numbers. `WebViewImpl.mm` lives at
`Source/WebKit/UIProcess/mac/WebViewImpl.mm` (NOT `.../Cocoa/` — that path 404s on current main;
the file was relocated at some point and the task's suggested path is stale). File line numbers
below are from the `main` snapshot fetched today and will drift.

## Headline finding

WebKit's `main` branch has an entire, actively-developed subsystem literally named for this exact
class of bug, and it names VTX's category of input method by its **Apple-shipped counterpart**,
`com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex`, in code comments and identifiers
(`inputMethodUsesCorrectKeyEventOrder`, `hasOnlyInsertText`/"modeless insertion", `m_stagedMarkedRange`).
Between 2026-04 and 2026-06 WebKit shipped and then repeatedly patched a feature called
**"correct key event order"** (`InputMethodUsesCorrectKeyEventOrder`, landed as commit
[310826@main](https://commits.webkit.org/310826@main), fixing
[bug 311717](https://bugs.webkit.org/show_bug.cgi?id=311717)) whose whole purpose is to let a
"modeless" input method — one that commits characters via `insertText:replacementRange:` instead of
`setMarkedText:` composition — coexist with WKWebView's keydown/keypress/composition event ordering.
Four follow-up regression fixes (313212, 313286, 313779, 314517 @main) each describe a **different**
way this queuing breaks for exactly "Vietnamese Simple Telex" and "2-Set Korean", including modes
that **fall out of modeless mode** and one, 314752 ([300105f899](https://github.com/WebKit/WebKit/commit/300105f899)),
whose title is literally *"Confirming composition results in **beep** and initiates a search on
google.com"* and whose root cause is a keydown re-sent up the AppKit responder chain unhandled.

This is strong, current, first-party evidence that the MarkEdit symptom is a member of a known and
still-active WebKit bug family for modeless-commit IMEs in WKWebView, not something specific to
MarkEdit/CodeMirror. It does not by itself prove VTX hits the *same* code path (see Limitations),
but every mechanical piece of the reported symptom — insertText-with-replacementRange after a
shrinking replace, a subsequent plain `insertText:replacementRange:(caret,0)`, then keys stop
reaching the IME and the app beeps — has a documented WebKit analogue.

## a) What can deactivate the IMK server while the web view keeps first responder

`WebViewImpl::inputContext()` (line 6393):
```objc
NSTextInputContext *WebViewImpl::inputContext()
{
    // Disable text input machinery when in non-editable content. An invisible inline input area
    // affects performance, and can prevent Expose from working.
    if (!m_page->editorState().isContentEditable)
        return nil;
    return [protect(m_view) _web_superInputContext];
}
```
`inputContext()` goes nil whenever `EditorState::isContentEditable` is false for the *current*
selection. `EditorState` is produced by the (async) web process and delivered to the UI process
after every DOM mutation/selection change — so there is a real window, on every keystroke, where
the UI process's idea of "am I editable" can lag the actual DOM. If a replacement/selection update
races this and `isContentEditable` toggles false-then-true, AppKit sees the client's `inputContext`
go nil and back, which is one plausible mechanical trigger for IMK's "Deactivate Server" / "Activate
Server" pair — this is inferred from the code shape, not confirmed by a WebKit comment.

`notifyInputContextAboutDiscardedComposition()` (line 3002) actively calls `discardMarkedText` on
the *live* NSTextInputContext, which is a documented way to signal "the input method's marked text
is being thrown away":
```objc
void WebViewImpl::notifyInputContextAboutDiscardedComposition()
{
    // <rdar://problem/9359055>: -discardMarkedText can only be called for active contexts.
    if (![[m_view.get() window] isKeyWindow] || m_view.getAutoreleased() != [[m_view.get() window] firstResponder])
        return;
    LOG(TextInput, "-> discardMarkedText");
    [retainPtr([m_view.get() _web_superInputContext]) discardMarkedText];
}
```
It is called from `resignFirstResponder`, `handleProcessSwapOrExit`, and (verified above) from
`setMarkedText` when the field is in secure-input state — none of these match the report (VTX's
mode never enters marked text, MarkEdit keeps first responder, and MarkEdit is not a password
field), so this specific call site is likely **not** the trigger here, but it is the only
WebKit-side call that directly asks AppKit to tear down composition state on a still-focused view,
which is architecturally the closest thing to what IMK's "Deactivate Server" line represents.

`selectionDidChange()` (line 3226) calls `-[NSTextInputContext textInputClientDidUpdateSelection]`
on essentially every selection change once post-layout data is available:
```objc
if (protect(page->preferences())->textInputClientSelectionUpdatesEnabled()) {
    alreadyNotifiedClient = true;
    [protect(inputContextForSelectionUpdates()) textInputClientDidUpdateSelection];
}
```
This is AppKit's official hook for telling TSM/IMK "the client's selection moved out from under
you." Per Apple's design intent (undocumented precisely, but consistent with observed IMK
behavior across apps), a text-input session that receives an unexpected out-of-band
`textInputClientDidUpdateSelection` while it believes it is mid-sequence is a known trigger for TSM
to abandon/reset the session — this is the most plausible single call site for the observed
Deactivate, given VTX's shrinking-then-growing replacementRange sequence necessarily produces
selection churn the web process reports back asynchronously. **This is inference, not a WebKit
comment confirming the causal link** — WebKit's source does not itself say "this call deactivates
third-party input methods."

`updateSecureInputState()`/`resetSecureInputState()` only affect `EnableSecureEventInput`/
`DisableSecureEventInput` and `setAllowedInputSourceLocales:`, gated on password fields and
key-window/focus transitions; not applicable to MarkEdit's plain editor.

## b) `insertText:replacementRange:` with a stale/out-of-range `replacementRange`

`WebViewImpl::insertText(id, NSRange)` (line 6122) forwards essentially unmodified to
`WebPageProxy::insertTextAsync` → `WebPage::insertTextAsync` (web process) →
`EditingRange::toRange()` (`Source/WebKit/Shared/EditingRange.cpp`):
```cpp
std::optional<WebCore::SimpleRange> EditingRange::toRange(WebCore::LocalFrame& frame,
    const EditingRange& editingRange, EditingRangeIsRelativeTo base)
{
    WebCore::CharacterRange range { editingRange.location, editingRange.length };
    if (base == EditingRangeIsRelativeTo::EditableRoot) {
        RefPtr element = protect(frame.selection())->rootEditableElementOrDocumentElement();
        if (!element) return std::nullopt;
        return resolveCharacterRange(makeRangeSelectingNodeContents(*element), range);
    }
    ...
}
```
There is **no explicit clamp** of `location`/`length` against the current document length in this
function itself; validation is delegated to `WebCore::resolveCharacterRange()`, which walks the DOM
by character offset and simply stops at the end of the scope if the offset overruns — i.e., an
out-of-range `replacementRange` does not "abort" with an error, it silently resolves to the nearest
valid boundary (typically end-of-editable-root), which would replace/insert at the wrong place
rather than reject the call outright. WebKit's own regression history treats a similar failure mode
as severe: in [314517@main](https://commits.webkit.org/314517@main) ("Can't use 2-Set Korean in
Mail"), an arithmetic overflow (`SIZE_MAX + delta`) in the *read-back* of `selectedRange` — not
`insertText` itself — was enough to make the IME "interpret NSNotFound as cursor unknown and
abandon modeless mode for the rest of the session." That is the closest documented precedent for
"a range inconsistency silently ends a modeless IME's session" that this codebase currently
contains; it is not proof VTX hits the identical overflow, since VTX's bundle ID (`com.vtx...`) is
not in the hardcoded allowlist described in (e) below and therefore takes a different code path
through `interpretKeyEvent`.

`executeKeypressCommandsInternal` (`WebPageMac.mm:299`), the function that actually performs the
insert in the web process, does apply the replacementRange as a selection-set before inserting —
again with no validity check surfaced back to the caller:
```cpp
if (currentCommand.replacementRange.location != WTF::notFound) {
    if (auto replacementSimpleRange = EditingRange::toRange(*frame, EditingRange { currentCommand.replacementRange }))
        protect(frame->selection())->setSelection(VisibleSelection(*replacementSimpleRange));
}
eventWasHandled |= editor->insertText(currentCommand.text, event);
```
If `toRange` returns `std::nullopt` (element/frame gone), the selection-set is simply skipped and
`insertText` runs against whatever selection is currently live — a **silent fallback**, not an
abort, and not a `-discardMarkedText`/deactivate by itself.

## c) `NSBeep` and delivery to a routed-away `inputContext`

The MarkEdit-side symptom (window key, cursor blinking, every keystroke beeps, IMK server
"Activate"-d but VTX's `handle(_:client:)` never called again) matches the *generic AppKit*
failure mode WebKit's own regression writeup (300105f899, bug 314752) names explicitly: an
unhandled `keyDown:` walking up the first-responder chain past `WKWebView`/`WKContentView` to
`NSWindow`/`NSApplication`, which beeps by default when nothing claims the event. Quote from that
commit message (verified via `gh api` against the live commit, and cross-checked against
bugs.webkit.org 314752 = RESOLVED FIXED):
> "the unhandled keyDown: walked up the first responder chain, resulted in a beep sound in some apps."

That bug's mechanism was: `handled` was force-set to `NO` by an over-broad guard in
`interpretKeyEvent`, so `NativeWebKeyboardEvent` got `handledByInputMethod=false`, the web process's
`EventHandler::internalKeyEvent` never set `setIsDefaultEventHandlerIgnored`, `doneWithKeyEvent`
re-sent the raw event via `[NSApp sendEvent:]`, and it bubbled up unhandled. There is one literal
`NSBeep()` call in WebKit's own IME code too — `WebViewImpl::setMarkedText` line 6597, when
`inSecureInputState()` is true and the incoming marked text is not a single ASCII character — but
that path is gated on password-field secure-input state, which does not apply to MarkEdit, so it is
almost certainly not the source of the reported beeps; the responder-chain fallback beep described
above is the far more plausible match because it explains "every keystroke beeps" (every unhandled
`keyDown:` beeps independently) rather than one beep at a state transition.

Separately: `SFSafariPlatformSupport credentialSelected: with nil credential` /
`oneTimeCodeSelected: with nil code` firing per keystroke is Safari/WebKit's AutoFill / passkey /
one-time-code suggestion machinery (`WKContentView`'s text-suggestion delegate plumbing, part of the
`_web_editorStateDidChange`/inline-predictions family referenced in the `setMarkedText`
`HAVE(INLINE_PREDICTIONS)` block quoted in (a) above) being invoked with no actual candidate,
consistent with WebKit polling its own suggestion/AutoFill pipeline on every raw keyDown once the
event stops being consumed by the IME/editor — i.e. a *symptom* of the event now reaching a
different, unhandled code path, not a separate bug. This is inference from the code shape (the
`setMarkedText` code above shows `m_isHandlingAcceptedCandidate`/`NSTextCompletionAttributeName`
plumbing exists and is keystroke-reactive); WebKit's search index did not surface a comment
connecting that log line to this exact deactivation scenario, so treat this paragraph as
architecturally-grounded inference, not a confirmed source citation.

## d) Known WebKit bugs — 2026, all "RESOLVED FIXED" on main, verified live against bugs.webkit.org

| Commit | Bug | Title | Status |
|---|---|---|---|
| [310826@main](https://commits.webkit.org/310826@main) | [311717](https://bugs.webkit.org/show_bug.cgi?id=311717) | Fix a regression and turn on correct composition event ordering by default (double dead-key insert) | landed, made default |
| [313212@main](https://commits.webkit.org/313212@main) | [314752](https://bugs.webkit.org/show_bug.cgi?id=314752) | REGRESSION(310826): Confirming composition results in beep and initiates a search on google.com | RESOLVED FIXED (verified) |
| [313286@main](https://commits.webkit.org/313286@main) | [314823](https://bugs.webkit.org/show_bug.cgi?id=314823) | REGRESSION(310826): Vietnamese & Korean keyboard gets out of modeless input method in Mail Compose | RESOLVED FIXED (verified) |
| [313779@main](https://commits.webkit.org/313779@main) | [315381](https://bugs.webkit.org/show_bug.cgi?id=315381) | REGRESSION(310826): Cannot type with Hindi - InScript in Mail | landed |
| [314482@main](https://commits.webkit.org/314482@main) | [316199](https://bugs.webkit.org/show_bug.cgi?id=316199) | Disable modeless input on Google Docs (site quirk) | landed |
| [314517@main](https://commits.webkit.org/314517@main) | [316230](https://bugs.webkit.org/show_bug.cgi?id=316230) | REGRESSION: Can't use 2-Set Korean in Mail (SIZE_MAX overflow in selectedRange) | landed |
| [315032@main](https://commits.webkit.org/315032@main) | [316756](https://bugs.webkit.org/show_bug.cgi?id=316756) | REGRESSION(macOS 27): Cannot type using Simple Telex (Vietnamese) or 2-Set Korean in Google Docs | landed (temporary quirk) |

All commit messages were fetched verbatim via `gh api repos/WebKit/WebKit/commits/<sha>` (GitHub's
authoritative commit API, not a search snippet); bug 314823 and 314752 were independently confirmed
"RESOLVED FIXED" by fetching bugs.webkit.org directly. I did not find a bug specifically about
WKWebView (as opposed to Mail.app/Notes, which are also WebKit-backed via WebKitLegacy/`WebView`,
or Google Docs) losing IME delivery entirely (IMK "Deactivate Server" + permanent beep until
Alt-Tab) rather than merely falling back to marked-text/composition mode — that stronger symptom
may be MarkEdit/CodeMirror-specific, may be an as-yet-unfiled variant of this same family, or may
involve the `inputContext()`-returns-nil path in (a) which these bugs don't describe. I did not find
CodeMirror 6 GitHub issues specifically about macOS IME + WKWebView in the time available (see
Limitations).

## e) Practical mitigations available to an IMKit input method (VTX side)

Grounded directly in the source read above:

1. **VTX is not in WebKit's hardcoded allowlist, so it cannot opt out the way Apple's own Simple
   Telex can.** `WebViewImpl::inputMethodUsesCorrectKeyEventOrder()` (line 3847):
   ```objc
   if (m_page->editorState().inputMethodMustUseCompositionEvents) {
       String selectedInputSource = [protect(inputContext()) selectedKeyboardInputSource];
       if (selectedInputSource == "com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex"
           || selectedInputSource == "com.apple.inputmethod.Korean.2SetKorean")
           return false;
   }
   ```
   This string-matches Apple's *own* bundle ID for Simple Telex, not any Vietnamese IME generically
   — VTX (`com.vtx.inputmethod.telex`) is unaffected by this switch either way, and
   `inputMethodMustUseCompositionEvents` is itself a site-specific `Quirks` flag (currently
   Google Docs only per bug 316756), so this branch is irrelevant for MarkEdit regardless. There is
   no source-level lever VTX can pull to make WebKit treat it specially by identity.

2. **Avoid a shrinking `replacementRange` immediately followed by a same-call-shape
   `insertText:replacementRange:(caret,0)`.** This is exactly the two-message pattern
   `selectedRangeWithCompletionHandler`'s "staging" workaround (line ~6189, added in 313286/313779)
   exists to compensate for — WebKit polls `selectedRange`/`attributedSubstring` synchronously
   inside the IME's own `handleEventByInputMethod:` callback while the previous `insertText:` is
   still queued, unstaged, in `m_collectedKeypressCommands`. If VTX's Backspace-then-letter
   sequence causes it to poll the client's current range/content via `IMKTextInput` (e.g.
   `attributedSubstringFromRange:`/`selectedRange` on the app's context) between the shrinking
   replace and the next insert, and WebKit's staging heuristics don't cover VTX's exact command
   shape, VTX would see a stale cursor and could itself react in a way that looks like triggering a
   deactivate — worth checking with VTX's own debug log whether it calls any `NSTextInputClient`
   read-back method in that window.

3. **Insert a short delay (WebKit's own fix used ~0, but the bug reports establish a race window
   exists) or coalesce the two `insertText:replacementRange:` calls into one** when VTX detects
   "just shrank via replacementRange, about to grow again" — this sidesteps the exact command shape
   (`insertText` len N shrink, then separately `insertText` len 1 grow with `replacementRange=(caret,0)`)
   that WebKit's fix commits repeatedly single out as the trigger for their regressions, without
   requiring any WebKit-side cooperation.

4. **Prefer `setMarkedText:` over `insertText:replacementRange:` for WKWebView clients specifically**
   — every one of the five regression fixes above is exclusively about the `insertText:`-based
   "modeless" path; none of them describe `setMarkedText:`-based composition breaking in the same
   way, because `setMarkedText:` commands go through `WebCore::Editor`'s composition machinery
   (`setCompositionAsync`, `WebPageMac.mm:331`) which is the code path WebKit has hardened for years
   (CJK IMEs), rather than the ~5-month-old modeless-commit path. This is the single highest-leverage,
   lowest-risk mitigation implied by the source: detect the WKWebView / MarkEdit client (VTX already
   has a per-app "Gõ trực tiếp"/in-place vs "Gạch chân"/marked typing-mode mechanism per the prior
   handoff report) and route it to marked-text mode instead of in-place `insertText:replacementRange:`.
   This is exactly the workaround already listed as "chưa thử" (untried) in
   `plans/reports/handoff-260913-1730-markedit-colemak-beep.md` item 3, and this research directly
   supports trying it.

5. **On `activateServer:`, do not assume prior client-side text state is still valid** — issue an
   inert `setMarkedText:@"" selectedRange:… replacementRange:{NSNotFound,0}]` or equivalent no-op
   read of `selectedRange`/`markedRange` to resynchronize, since WebKit's own regressions in this
   area are fundamentally about the UI process and the IME's cached idea of cursor position
   diverging silently (no error, no exception, just wrong behavior) — there is no WebKit-side
   "resync" signal to rely on instead.

## Limitations

- I could not obtain the full text of `WebPageProxy::insertTextAsync` on the UI-process side (only
  the web-process-side `executeKeypressCommandsInternal` and `EditingRange::toRange`), so the exact
  IPC-level validation (if any) between `WebViewImpl::insertText` and the web process is inferred
  from what the web-process side does with the range, not directly observed at the IPC boundary.
- I did not check `WebCore/editing/mac/*` directly (per the task's file list) — `WebPageMac.mm` and
  `WebViewImpl.mm` turned out to contain essentially all the relevant logic and cross-references, and
  effort budget was spent going deep on those instead of breadth across all six named files.
- I found no CodeMirror 6 issues about macOS IME + WKWebView in the time available; the earlier
  report (`researcher-260913-1715-markedit-input-source.md`) already covers CodeMirror/MarkEdit-side
  composition workarounds (issues #358, #956) and concluded they don't apply to a non-composing
  commit, which this report does not contradict.
- I did not find a bug or commit describing the specific "IMK Deactivate Server + permanent beep
  until Alt-Tab" failure mode (as opposed to "falls back to composition mode", which is what all
  seven cited bugs describe) — this is the biggest open gap. It is plausible this is a distinct,
  more severe manifestation of the same underlying selection/range desync, specific to
  WKWebView + CodeMirror's DOM mutation pattern rather than Mail/Notes/Google Docs' contentEditable
  pattern, but I could not confirm this from WebKit source or issue tracker in the time available.
- `bugs.webkit.org` was only spot-checked for 2 of 7 bug numbers (314752, 314823) via WebFetch;
  the other 5 were not independently re-verified against bugzilla, only against the GitHub commit
  API (which is itself authoritative for the commit message text, just not bug status).

## Unresolved questions

1. Does VTX, in its Colemak-mode or in-place ("Gõ trực tiếp") typing path, call any
   `NSTextInputClient` read-back method (`attributedSubstringFromRange:`, `selectedRange`,
   `markedRange`) synchronously between the shrinking Backspace-replace and the next letter's
   insert? If so, that read-back racing WebKit's async `EditorState` delivery is the most concrete,
   checkable next step toward (a)/(c) above.
2. Does switching MarkEdit's typing-mode setting for VTX from "Gõ trực tiếp" (in-place) to
   "Gạch chân" (marked/composition) make the symptom disappear, per mitigation (4)? This is
   the cheapest experiment that would meaningfully narrow the cause, and was already flagged
   untried in the prior handoff report.
3. Is there a newer/different bugs.webkit.org report matching "IME deactivated / stuck beeping
   until app switch in WKWebView" specifically (vs. "falls back to composition mode")? Worth a
   direct bugzilla search (`status:NEW,ASSIGNED,REOPENED "WKWebView" "input method"`) rather than
   GitHub commit-message search, which is what this report relied on.

Status: DONE_WITH_CONCERNS
Summary: WebKit's `main` branch (as of 2026-09-13) contains an active, recently-patched bug family (commits 310826/313212/313286/313779/314482/314517/315032@main, all 2026-04 to 2026-06) specifically about modeless-commit input methods — explicitly naming Apple's own Vietnamese Simple Telex and 2-Set Korean — breaking in WKWebView-hosted and WebKitLegacy-hosted editors via exactly VTX's `insertText:replacementRange:` command shape, with one fix's root cause described as an unhandled keyDown beeping up the AppKit responder chain; none of the found bugs describe the specific "IMK Deactivate Server + stuck until Alt-Tab" severity, so causation for MarkEdit specifically is strongly suggested but not proven.
Concerns/Blockers: The bash tool became unusable partway through this session (a worktree-isolation guard rejected every command regardless of cwd), so all source retrieval after that point went through the Read tool on already-fetched files and WebFetch; this did not block completion but narrowed exploration of `WebCore/editing/mac/*` and the UI-process IPC boundary (see Limitations). No repo files were modified.