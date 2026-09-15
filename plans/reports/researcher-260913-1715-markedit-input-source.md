# MarkEdit and keyboard input source / IME handling

## Finding

MarkEdit (github.com/MarkEdit-app/MarkEdit) contains no code that reads, selects, or reacts to
the keyboard input source itself. A `gh search code` sweep of the repo for
`TISCopyCurrentKeyboardInputSource`, `TISSelectInputSource`, `inputSource`, `keyboardLayout`,
`"ABC"`, `kTISNotifySelectedKeyboardInputSourceChanged`, `allowedInputSourceLocales`,
`becomeFirstResponder`, `inputContext`, `setMarkedText`, and `hasMarkedText` returned zero hits.
MarkEdit never touches Carbon TIS/TSM APIs and never customizes `NSTextInputContext`.

`EditorWebView` (`MarkEditMac/Sources/Editor/Views/EditorWebView.swift`) is a thin `WKWebView`
subclass. It overrides `performKeyEquivalent` (only to silence a spurious beep on
Ctrl+Cmd+arrow), `mouseDown`, `willOpenMenu`, `performDragOperation`, and `resignFirstResponder`.
`resignFirstResponder` only fires a delegate callback used to update search-selection state, and
the delegate (`EditorViewController+Delegate.swift`) explicitly no-ops unless
`webView.isHidden` is true:

```swift
override func resignFirstResponder() -> Bool {
  actionDelegate?.editorWebViewResignFirstResponder(self)
  return super.resignFirstResponder()
}
```
```swift
func editorWebViewResignFirstResponder(_ webView: EditorWebView) {
  // resignFirstResponder is called when webView.isHidden = true
  guard hasFinishedLoading && !webView.isHidden else { return }
  bridge.search.updateHasSelection()
}
```

There is no `makeFirstResponder` call anywhere tied to typing, and no code that blurs/refocuses
the editor after `insertText`. All of `NSTextInputClient`/marked-text handling is inside WebKit's
own `WKContentView`, which MarkEdit does not subclass or intercept — MarkEdit's app layer never
sees `setMarkedText:`/`hasMarkedText`/`insertText:replacementRange:` calls directly; those are
consumed by WebKit before anything reaches MarkEdit's Swift code.

## IME-adjacent code that does exist

All of MarkEdit's IME awareness lives in the CodeMirror/TypeScript layer
(`CoreEditor/src/modules/events/index.ts` and `CoreEditor/src/modules/input/index.ts`), and it is
scoped entirely to the DOM `compositionstart`/`compositionend` events, i.e., **marked-text**
composition (Pinyin-style). There is nothing for an IME that commits text via `insertText`
without ever entering marked-text/composition state:

- `compositionstart` records `editingState.compositionEnded = false` and a `compositionPosition`
  anchor, to guard against a WebKit bug that over-deletes text before the caret when a
  composition commits.
- `compositionend` sets `compositionEnded = true` and calls
  `notifyCompositionEnded` back to native, because "input methods like Pinyin may not trigger
  `inputHandler` on `compositionend`."
- `filterTransaction` clamps composition-commit transactions to never touch text before the
  composition anchor ("Work around a WebKit IME bug where committing a composition
  over-deletes text before the caret").
- Related merged PRs, all WebKit-composition-specific: #958 "Ignore incorrect updates in
  composition mode", #1473 "Fix WebKit composition mode issues", #1485 "Prevent unwanted
  scrolling due to IME", #1640 "Harden IME issue fixes", #1641 "Respect
  editorView.compositionStarted".

## Issues found

- Issue #358 ["Unable to input characters with Chinese IME on macOS
  14"](https://github.com/MarkEdit-app/MarkEdit/issues/358) — reproducible in bare Safari
  loading MarkEdit's own `index.html`, fixed via PR #353 (one-line change in
  `CoreEditor/src/modules/input/index.ts`). Confirmed by the maintainer as a WebKit regression,
  not app-specific.
- Issue #956 ["\[Bug\] IME error"](https://github.com/MarkEdit-app/MarkEdit/issues/956) — typing
  `"#ceshi"` with the Chinese IME interrupts composition after `"e"`, IME then stops accepting
  input. Maintainer: "common composition mode bug that occurs specifically in Safari," fixed by
  PR #958. Symptom shape (input silently breaks mid-word, only in WebKit/Safari-family engines,
  not Chrome/Firefox) is the closest analog to the VTX report, but #956/#358 are both about
  **marked-text composition** (Pinyin candidate window), whereas VTX's secondary mode commits
  plain characters via `insertText:replacementRange:` with no marked text at all.

## Relevance to the VTX symptom

Nothing in MarkEdit distinguishes or reacts to `tsInputModePrimaryInScriptKey`, `TISIntendedLanguage`,
or any other IMKit/TSM-level mode property — MarkEdit has no visibility into which registered
input mode is active, only into whether WebKit's DOM reports a composition in progress. Since
VTX's secondary mode apparently never enters marked-text composition (it commits the first
letter directly via `insertText:replacementRange:`), none of MarkEdit's composition workarounds
apply, and MarkEdit has no code path that would itself deactivate/reactivate the input method or
call `setTextCursorIsActive:NO`. That log line is emitted by AppKit/WebKit's `TextInputUI` layer
(inside `WKContentView`'s internal `NSTextInputClient` plumbing), which is opaque to and
unmodified by MarkEdit. The mode-specific divergence (primary-in-script vs not) is therefore most
likely being decided inside WebKit/TSM's own input-context bookkeeping for that flag, not by
anything in MarkEdit's source — MarkEdit is a passive bystander here, same as it is a bystander
in #358/#956 where the maintainer attributed the bug directly to WebKit.

## Limitations

- GitHub code search hit a rate limit partway through (`beep`, `NSBeep`, `IME`,
  `makeFirstResponder` as literal searches returned HTTP 403); those terms were still covered
  indirectly via targeted searches and issue/PR titles, but a literal "NSBeep" string search was
  not completed. Given `EditorWebView` has no AppKit beep-related code besides the one
  `performKeyEquivalent` comment already quoted, this is unlikely to change the conclusion, but a
  fresh `gh search code "NSBeep" repo:MarkEdit-app/MarkEdit` after the rate-limit window would
  close the gap.
- Did not check MarkEdit's Sparkle/updater or unrelated modules; scope was limited to
  editor/input-related files as requested.

Status: DONE
Summary: MarkEdit has no TIS/TSM/input-source code and no first-responder cycling tied to typing; its only IME-aware code handles WebKit's marked-text composition bugs (issues #358, #956; PRs #353, #958, #1473, #1485, #1640, #1641), none of which apply to a non-composing `insertText` commit, so the mode-specific VTX behavior is not explained by anything in MarkEdit's source and points to WebKit/TSM's internal handling of the `tsInputModePrimaryInScriptKey` distinction instead.
