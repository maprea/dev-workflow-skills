# SessionStart hook — the activation baseline writer

This hook drives the **name-only baseline** (see [ROLES.md](../docs/ROLES.md)). On every
session boundary (`startup|resume|clear|compact`) it writes the activation
`skillOverrides` into `settings.local.json` — all skills `name-only` except the
pinned set (and the active role's set, if one is set) — and emits
`reloadSkills: true` so it applies to the current session. It also injects a short
pointer telling Claude to route through `skill-router`.

It runs on every boundary because the skill listing is **not re-injected after
`/compact`**, so the baseline must be re-asserted.

The installer **applies the baseline once at install time** (so the install is
crop-safe immediately, and stays so even with `--no-hook`, since `skillOverrides`
persists in `settings.local.json`). This hook's job is to **re-assert** that baseline
each session — covering `/compact` and any skills added later — and to inject the
router nudge. It's installed **by default**; pass `--no-hook` to skip it. It calls
`resolve.mjs` and reads the `.roles.json` marker next to the skills.

The hook is **pure Node** and is registered as `node "…/session-start.mjs"`, so it
runs identically on Linux, macOS, and Windows — the one runtime Claude Code already
guarantees.

## What's here

- `session-start.mjs` — writes the baseline + emits the SessionStart JSON.
- `hooks.json` — a reference snippet to merge into your Claude Code settings.

## Enable it

It's on by default — any full install includes it:

```bash
node install.mjs             # project-local (.claude/), hook included
node install.mjs --global    # user config dir, hook included
node install.mjs --no-hook   # skip the hook (baseline still applied at install)
```

The installer copies `session-start.mjs` (and `resolve.mjs`) into your config's
`hooks/` and prints the exact `settings.json` snippet to paste, with the absolute
`HOOK_PATH` filled in. It does **not** modify your `settings.json` automatically —
merging is left to you so your existing config is never clobbered. (The hook then
re-asserts the `skillOverrides` baseline in `settings.local.json` at runtime.)

## Manual setup

1. Copy `session-start.mjs` (and `resolve.mjs`) somewhere stable — e.g. your config's
   `hooks/` directory, so the hook can find `resolve.mjs` beside it.
2. Add the `hooks` block from `hooks.json` to `.claude/settings.json` (project)
   or `~/.claude/settings.json` (global), replacing `HOOK_PATH` with the absolute
   path to your copy of `session-start.mjs` (the command runs it as
   `node "HOOK_PATH"`).
3. Start a new session. Run `/doctor` to confirm the hook is registered.

## Disable it

Remove the `SessionStart` block from your `settings.json`. That's it.

To remove the whole library (skills + machinery + this hook script), run
[`node uninstall.mjs`](../uninstall.mjs) (`--global` / `--dir` mirror the installer).
It deletes the hook script and prunes the library's `skillOverrides` from
`settings.local.json`, then prints this same `SessionStart` block for you to delete
from `settings.json` by hand — it never edits `settings.json`.

## Requirements

Just **Node** — the runtime Claude Code already requires, present on every OS.
`session-start.mjs` imports `resolve.mjs` (its sibling) to compute/merge the baseline
and encodes its JSON with `JSON.stringify`. If `resolve.mjs` or the markers aren't
found it still emits the nudge but skips writing the baseline (best-effort). No bash,
Python, or `sed` is involved, so the hook behaves the same on Linux, macOS, and
Windows.
