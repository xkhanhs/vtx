# CLAUDE.md

Orientation for an agent session in this repo. Read `docs/MACOS_IME_NOTES.md` before
changing anything that touches macOS itself — it is a log of things that were tried and
did not work, with the measurements that proved it, and it exists so the same dead ends
are not walked twice.

## What this is

A personal fork of [ptrinh/viettelex](https://github.com/ptrinh/viettelex) (MIT), a
Vietnamese Telex input method for macOS built on IMKit. The fork is a **separate input
source**, not a replacement build: bundle id `com.vtx.inputmethod.telex`, product `VTX`,
menu badge "VX". Both can be installed side by side.

Upstream's `VietTelex` name is kept for the Swift module (`PRODUCT_MODULE_NAME`) — it is
internal, and renaming it would churn every test plus the `InputMethodServerControllerClass`
keys in `Info.plist` for nothing.

| | |
|---|---|
| Engine | `TelexCore/` — pure Swift package, no dependencies, ~0.15 µs/key, zero-alloc |
| App | `App/Sources/` — IMKit controller, CGEventTap, SwiftUI settings |
| Signing | Developer ID `CT94G6J3TH`; notary keychain profile `VTXNotary` |

## Two input paths — a change usually needs both

Keys reach the engine through **either** path, per app:

- `TelexInputController` — the IMKit path.
- `TerminalTap` — a CGEventTap, for apps that ignore `replacementRange` (terminals,
  Electron, Lark). DebugLog shows `tap-defer (tap=true …)` when a key took this route.

Fixing only the IMK path and testing in an Electron app produces a "fixed" build that
still reproduces the bug. This has happened.

`TerminalTap` runs on its own thread. Anything it reads that main also writes must be
lock-guarded — see `AppState`'s hot-path caches and `KeyboardLayoutOverride.translator`.

## Build, test, install

```bash
cd TelexCore && swift test          # engine only — no install, no logout
xcodegen generate                   # after adding/removing any source file
./Scripts/dev-install.sh            # fast loop: build → sign → install (NOT notarized)
./Scripts/notarize-install.sh       # release: → notarize → staple → install (~3 min)
```

**macOS 26 requires input methods to be notarized to REGISTER.** An unnotarized
`dev-install` build still runs once the input source is registered, which makes it fine
for a debugging loop — but always finish on `notarize-install.sh`, and never hand the
user a `dev-install` build as the result.

Changing bundle id or input-mode metadata in `Info.plist` needs a logout/login once.

## Traps that have cost real time

- **`log` is a zsh builtin.** `log show …` fails silently; with `2>/dev/null` it looks
  like the app logs nothing. Use `/usr/bin/log`.
- **`dev-install.sh` needs `xcodegen`** to see a new source file. It runs it now; if a
  build fails with "cannot find type in scope", that is why.
- **Carbon returning `noErr` is not evidence.** `TISSetInputMethodKeyboardLayoutOverride`
  returns `noErr` and does nothing. Read the value back before believing a TIS call.
- **Display names are cached in two separate agents.** `TextInputMenuAgent` (menu bar)
  and `TextInputSwitcher` (⌃Space HUD). `dev-install.sh` bounces both.
- **Two installed copies fight over one `InputMethodConnectionName`** — the menu shows
  the IME as selected while keys go somewhere else. Check `pgrep -lf VTX` finds exactly
  one process, from `~/Library/Input Methods/`.
- **`gh` resolves to `ptrinh/viettelex`, not this fork.** With two remotes it picks
  upstream, so a bare `gh release create` publishes to SOMEONE ELSE'S repo. On the
  1.6.10 sync it only missed because upstream already had that tag. `gh repo
  set-default xkhanhs/vtx` is set now; still pass `--repo xkhanhs/vtx` on anything
  that writes (release, issue, PR) — a fresh clone has no default.
- **`git fetch upstream --tags` hijacks the tag namespace.** Both projects tag `vX.Y.Z`,
  so `v1.6.10` locally became upstream's commit while origin's pointed at the fork's.
  Trust `git ls-remote --tags origin`; fix a stale local tag with
  `git fetch origin 'refs/tags/vX.Y.Z:refs/tags/vX.Y.Z' --force`.
- **`make-pkg.sh` emits an UNSIGNED pkg** unless a *Developer ID Installer* cert exists
  — it warns and exits 0, so `make-release.sh` still "succeeds". Never attach that pkg
  to a release; the `.app.zip` is what the updater fetches anyway.

## Working on this repo

- Upstream is `upstream`; the fork is `origin`. Cherry-pick upstream PRs rather than
  merging its branches. Pick in upstream's chronological order and expect dependencies
  between commits: on the 1.5.7 → 1.6.10 sync the perf commit needed `bracketVowels`
  from a feature three releases earlier, and the secure-input monitor needed
  `OwnBundle` from a commit that had looked skippable. A pick that fails to build is
  usually a missing ancestor, not a bad pick.
- An upstream commit that adds user-facing strings ships upstream's NAME in them. After
  a sync, grep both `Localizable.strings` for `VietTelex` on the VALUE side and add a
  fork override — keys stay verbatim so later cherry-picks keep applying. Same hazard
  in resources: the menu-icon picker's `MenuIcon1.pdf` is upstream's Vᴛ mark, and
  selecting "default" would have overwritten the VX badge with it.
- The updater's designated requirement pins this fork's identifier and team, so an
  upstream artifact can never install over VTX. Keep it that way.
- Settings live in the `com.viettelex.settings` defaults suite, deliberately: it carries
  the user's existing shortcuts and preferences over from upstream.
- When something OS-level is learned the hard way — especially a dead end — append it to
  `docs/MACOS_IME_NOTES.md` with the measurement, not just the conclusion.
