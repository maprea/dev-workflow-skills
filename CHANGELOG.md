# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) as defined in
[docs/RELEASING.md](docs/RELEASING.md).

## [Unreleased]

### Changed
- Deployment layer rewritten in pure Node (`install.mjs`, `uninstall.mjs`,
  `scripts/resolve.mjs`, `hooks/session-start.mjs`, `scripts/verify.mjs`), replacing the
  bash + Python + `sed` scripts. Installs identically on Linux, macOS, and Windows.
- README slimmed to a conventional structure; deep reference moved to
  `docs/SKILLS.md` (catalog) and `docs/AUTHORING.md` (skill-authoring guide).

### Added
- Mermaid routing diagram and a worked "what routing looks like" walkthrough in
  `docs/ROLES.md`; reproducible terminal-demo GIF source under `docs/demo/`.
- Versioning policy (`docs/RELEASING.md`), a single-source `VERSION` file, and this
  changelog.

### Removed
- `install.sh`, `uninstall.sh`, `scripts/resolve.py`, `hooks/session-start.sh`,
  `scripts/verify.sh` (superseded by the Node equivalents above).

## [0.1.0] — unreleased

Initial library: 42 SDLC skills + the `skill-router` orchestrator and `writing-skills`
meta skills, the name-only activation baseline, per-role plugins, the `/role` command,
the SessionStart hook, and the eval harness.

[Unreleased]: https://github.com/SWEStash/swe-workflow-skills/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/SWEStash/swe-workflow-skills/releases/tag/v0.1.0
