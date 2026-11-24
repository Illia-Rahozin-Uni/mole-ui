# Architecture

Mole UI is a thin SwiftUI shell around the `mo` command-line tool. One core holds all the logic. Three themes only draw what the core exposes.

```
            ┌──────────────── Core.swift ────────────────┐
mo CLI ───▶ │ Mole (runner)  StatusModel  CleanFlow       │ ───▶ @EnvironmentObject
            └─────────────────────────────────────────────┘
                                 │
            ┌──────────────── App.swift ─────────────────┐
            │ MoleUIApp → ThemedRoot → (AppleRoot|NeonRoot|CyberRoot)
            │ SectionContent: "Clean" is per theme,       │
            │                 the other sections are shared
            └─────────────────────────────────────────────┘
```

## `Mole` — running the CLI

- `binary` looks for `mo` in `~/.homebrew/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin`, `/usr/bin` and `/bin`, then falls back to `zsh -lc 'command -v mo'`. The result is cached.
- Every process gets an extended `PATH`, `NO_COLOR=1`, `TERM=dumb` and **stdin = /dev/null**, so Mole's scripts take their non-interactive code paths.
- Anything that needs a password or live input (uninstall, full clean, Touch ID, update) opens in Terminal through a temporary `.command` file. That doesn't need Automation permission.

## `StatusModel` — live metrics

A long-running `mo status --watch --interval 2s` streams NDJSON. Each line is decoded into `StatusSnapshot`: snake_case keys, every field optional. The model keeps the last 40 CPU and memory points for sparklines and restarts the process 3 s after it exits.

## `CleanFlow` — the cleanup scenario

Phases: `idle → scanning → review → cleaning → done`.

**Scan.** Runs `mo clean --dry-run` and streams its output into `logLines`.

- `➤ <Section>` headers create category cards as they appear.
- Lines starting with `○` add a provisional size to the current card. `⊙` (manual review) and `◎` (skipped) lines are ignored.
- Progress is the larger of a time curve and the section index, capped at 97%.

When the process exits, the exact data is read from `~/.config/mole/clean-list.txt`:

```
=== App caches ===
/Users/me/Library/Caches/com.spotify.client  # 1.23GB
/Users/me/Library/Caches/foo/bar  # 10.0MB, counted under /Users/me/Library/Caches/foo
```

- `counted under` lines are skipped, because their bytes are already in the parent.
- If `mo` failed, or the file wasn't rewritten by this scan, the result is discarded rather than trusting a stale list.

**Categories.**

- Paths outside `$HOME` are dropped from a category and from its size.
- A category with no safe paths at all is shown **locked**. Mole cleans those itself in Terminal.
- Large files, device backups, Time Machine, system caches and external volumes start unchecked.

**Clean.** Each selected path goes through `NSWorkspace.recycle` (to the Trash). `isSafeToTrash` accepts only paths inside `$HOME` that are at least two levels deep, are not a whole `~/Library/<X>`, and contain no `..`, `.` or `*` components.

> Trade-off: `mo clean` can't clean individual sections, so the app trashes files itself. That means these runs don't appear in `mo history`, and the space comes back only after the Trash is emptied.

## Themes

`AppTheme` is stored in `@AppStorage("theme")`. Neon and Cyber force dark mode. Apple follows the system appearance.

| Theme | Navigation | Clean screen |
|---|---|---|
| Apple | `NavigationSplitView` sidebar over a floating, blurred wallpaper | Glass cards, spring ring, sparklines |
| Neon | Top tabs with `matchedGeometryEffect` | Big orb: pulse waves → radar → counter → check mark |
| Cyber | Slanted tabs, chamfered frame, glitch logo | Core matrix, reactor rings, targets, log |

### Motion budget

`ThemedRoot` publishes `liveMotion` in the environment:

```
liveMotion = !reduceMotion && windowVisible && (appActive || flow.isBusy)
```

Every infinite animation is a `TimelineView` paused by this flag, with a capped frame rate:

- wallpaper: 15 fps;
- scan ring and radar: 60 fps, only while scanning;
- CRT flicker and glitch: custom schedules that tick only at the moments they're visible.

`repeatForever` isn't used, because it runs at display refresh rate and can't be paused.

## Localization

`Localization.swift` maps English keys to Ukrainian and Russian (`L("Scan")`, `L("Clean %@", size)`). The language comes from `@AppStorage("language")`, or the system language when set to *System*. Changing it rebuilds the view tree, so the switch is instant. Sizes use the language's decimal separator and units (`1.23 GB` / `1,23 ГБ`).

## Mole commands used

- `mo status --watch --interval 2s`
- `mo clean --dry-run` and `~/.config/mole/clean-list.txt`
- `mo analyze --json <path>`
- `mo uninstall --list` (JSON when stdout isn't a TTY)
- `mo history --json`
- `mo --version`

The source of truth for formats is Mole's own code: `cmd/status/metrics.go`, `cmd/analyze/json.go`, `bin/clean.sh`, `bin/uninstall.sh` and `lib/core/history.sh`.
