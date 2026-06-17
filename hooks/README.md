# Optional SessionStart hook

This hook is **opt-in**. It injects a short pointer at the start of each session
reminding Claude that the skills library is installed and to consult the
`skill-router` skill before substantial SDLC work. It is deliberately
lightweight — a nudge, not a mandatory per-turn skill check.

You do not need the hook for skills to work; skills still trigger from their
descriptions. The hook just raises activation reliability (under-triggering is
the library's most common failure mode).

## What's here

- `session-start.sh` — emits the SessionStart pointer as JSON on stdout.
- `hooks.json` — a reference snippet to merge into your Claude Code settings.

## Enable it

The easiest path:

```bash
./install.sh --hook          # project-local (.claude/)
./install.sh --hook --global # global (~/.claude/)
```

`--hook` copies `session-start.sh` next to your installed skills and prints the
exact `settings.json` snippet to paste, with the absolute `HOOK_PATH` filled in.
It does **not** modify your `settings.json` automatically — merging is left to
you so your existing config is never clobbered.

## Manual setup

1. Copy `session-start.sh` somewhere stable and make it executable
   (`chmod +x session-start.sh`).
2. Add the `hooks` block from `hooks.json` to `.claude/settings.json` (project)
   or `~/.claude/settings.json` (global), replacing `HOOK_PATH` with the
   absolute path to your copy of `session-start.sh`.
3. Start a new session. Run `/doctor` to confirm the hook is registered.

## Disable it

Remove the `SessionStart` block from your `settings.json`. That's it.

## Requirements

`session-start.sh` uses `python3` for safe JSON encoding and falls back to a
`sed`-based encoder if `python3` is unavailable, so it works on a bare shell.
