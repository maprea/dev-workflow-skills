# Authoring Skills

What you need to know to write a new skill or modify an existing one. This guide is
also packaged as the installable `writing-skills` skill, which adds the Skill
Discovery Optimization (SDO) description rule and pressure-testing (TDD-for-docs) on
top of these rules.

## Skill Architecture

Each skill follows the progressive disclosure pattern:

```
skill-name/
├── SKILL.md              # Entry point: metadata + core workflow (< 500 lines)
├── references/           # Deep-dive docs loaded on demand
│   └── principles.md     # Domain-specific guidelines
├── templates/            # Output templates
│   └── template.md       # Structured output formats
└── scripts/              # Utility scripts (optional)
    └── validate.sh       # Validation helpers
```

## Design Principles

1. **Concise over verbose** — Claude is smart; only add what it doesn't already know.
2. **Progressive disclosure** — SKILL.md is the map; reference files are the territory.
3. **Appropriate freedom** — Strict where fragile, flexible where creative.
4. **Feedback loops** — Validate-fix-repeat for quality-critical operations.
5. **Composable** — Skills can be used independently or combined in workflows.

## Description Is Everything

The `description` field in SKILL.md's YAML frontmatter is the primary mechanism Claude
uses to decide whether to load a skill. If the description doesn't match the user's
prompt, the skill never runs — no matter how good the workflow is.

**Rules for writing descriptions:**
- **Keyword-rich**: Include all the phrases a user might say ("plan this feature",
  "scope this out", "break this down", "sprint planning"). Cast a wide net.
- **Third-person, present tense**: "Use when the user needs to..." not "I help with..."
- **~350 characters, hard cap 1024**: The 1024-char per-skill limit is enforced, but
  it is not the binding constraint at scale. Claude Code only injects skill listings up
  to `skillListingBudgetFraction` of the context (default 1% ≈ 2k tokens). With 30+
  skills installed, ~350 chars per description is a realistic target — anything longer
  and `/doctor` will report descriptions being dropped.
- **Slightly assertive**: "Use when the user reports a bug" triggers more reliably than
  "May be used for bug reports." Under-triggering is the most common failure mode.
- **Include related vocabulary**: If your skill is about deployments, also mention "go
  live", "ship it", "push to production", "release".

**Recommended pattern:** `<one-line purpose>. Triggers: <comma-separated keywords>. <one-line boundary or delegation note>.`

**Skill Discovery Optimization (SDO):** describe *when to use* the skill, not *what it
does internally*. Agents follow the description over the body, so a description that
summarizes the workflow ("reviews code in two passes") triggers worse than one that
lists situations. The `Triggers:` keyword list is the when-to-use expressed as the
phrases a user actually types — that's what makes this format SDO-compliant.

## Listing Budget

Every installed skill contributes its `name` + `description` to a single listing that
Claude Code injects on every prompt, capped by `skillListingBudgetFraction` in
`settings.json` (default `0.01`, i.e. 1% of context). When the cap is exceeded, the
least-recently-used descriptions are dropped arbitrarily, and dropped skills will not
trigger. Check with `/doctor` — it reports dropped descriptions.

**This repo sidesteps the cap with a name-only baseline** rather than by raising the
budget: only a pinned set keeps full descriptions; the rest are listed name-only
(invoked on demand by `skill-router`). So the listing stays tiny on any window — see
[ROLES.md](ROLES.md). A good `description` still matters for every skill: it's what the
orchestrator routes on (from `catalog.json`) and what auto-triggers when a role
promotes the skill to `on`.

(If you instead run a flat install of many skills with descriptions on, you can raise
the budget — e.g. `{ "skillListingBudgetFraction": 0.02 }` — but the baseline approach
is preferred.)

## Frontmatter Fields

Beyond `name` and `description`, two optional fields are recommended:

| Field | Purpose | Used in this repo |
|---|---|---|
| `model` | Pin a default model when the skill activates | `haiku` for cheap formatting/lookup skills, `sonnet` for most design/review work, `opus` for deep multi-step reasoning (architecture, security audit, debt review, RCA) |
| `allowed-tools` | Restrict tools the skill can call | Most skills use `Read, Grep, Glob, Write, Edit`. Implementation- or infra-adjacent skills add `Bash`. Research-oriented skills (dependency-management, security-audit) add `WebFetch, WebSearch`. |

Neither field counts toward the listing budget — only `name` + `description` do.

## Token Economy and Progressive Disclosure

Every token in SKILL.md costs budget when the skill is loaded. Reference files cost
zero tokens until Claude explicitly loads them. This creates three loading tiers:

1. **Metadata** (~100 tokens): Skill name + description. Always loaded when matched.
2. **SKILL.md** (< 500 lines): Core workflow, principles, cross-references. Loaded when
   the skill activates.
3. **references/ and templates/**: Deep-dive docs, loaded on demand within a conversation.

A skill with 10,000 lines of reference material costs zero extra tokens until Claude
needs that material. **Put everything Claude already knows in references; put only
what's unique to your workflow in SKILL.md.**

## When to Use Scripts, References, and Templates

| Resource type | Use when | Example |
|---|---|---|
| `references/*.md` | Deep technical detail that's only needed sometimes (patterns, checklists, domain knowledge) | `owasp-top-10.md`, `debugging-patterns.md` |
| `templates/*.md` | Output format matters for consistency (documents, specs, reports) | `adr.md`, `pull-request.md` |
| `scripts/` | A step should always happen identically — pixel-perfect output, file generation, validation | A script that generates a migration file in the project's exact format |

These workflow skills guide *thinking*, not deterministic file operations. When in
doubt, use a reference file over a script.

## Eval Design

Each skill must have exactly 3 evals:

1. **Happy path**: The canonical use case. Good input, skill produces the expected artifact.
2. **Edge case**: Unusual but valid input that tests a corner of the workflow (empty
   state, very large scope, ambiguous requirements).
3. **Scope boundary**: A prompt that seems related but should NOT trigger this skill, or
   that triggers it and correctly hands off to a different skill.

The `assertions` array should contain specific, verifiable criteria — not vague goals
like "produces a good plan."

For safety-critical and discipline skills, add a **`pressure_tests`** block on top of
the three evals: a scenario that tempts the agent to skip the skill's Iron Law under
combined pressure (time, sunk cost, authority, exhaustion), with assertions that it
doesn't capitulate. Bulletproof skills by capturing the exact rationalizations a fresh
agent uses *without* the skill (RED), then writing the minimum that counters them
(GREEN) — see [EVALS.md](EVALS.md) and the `writing-skills` skill.

## Common Mistakes

1. **Over-stuffing SKILL.md**: If your skill is over 300 lines, move domain knowledge to
   `references/`. Claude doesn't need to be taught what a REST API is.
2. **Vague descriptions**: "Helps with development tasks" will never trigger. Be specific.
3. **Time-sensitive content**: Don't include specific version numbers, dates, or tool
   versions in SKILL.md. They go stale. Put them in references/ with a note to check the
   latest docs.
4. **Windows-style paths**: Use forward slashes in all paths — users may be on any OS.
5. **Imperative commands in ALL CAPS**: "ALWAYS use parameterized queries." Modern LLMs
   respond better to reasoning: "Use parameterized queries — string interpolation enables
   SQL injection."
6. **Missing feedback loops**: If a step produces output that could be wrong, add a
   verification step. "Run the tests. If they fail, fix the issue before proceeding."
7. **Not testing the skill**: Write the evals before publishing. A skill that looks good
   but doesn't trigger is useless.

## Model Variance

Skills are tested against Claude Sonnet as the baseline. What works on Sonnet will
typically work on Opus; Haiku may need more explicit guidance in SKILL.md. If you plan
cross-model deployment, test on the lowest-capability model you'll target and add detail
accordingly.

## Explain the Why

Skills that explain *why* a practice matters produce better outcomes than skills that
issue commands. Compare:

- **Command**: "Always write a regression test before fixing a bug."
- **Why**: "Write a regression test before fixing the bug — without it, the same bug
  will silently reappear in a future refactor."

The second version helps Claude make good judgment calls in edge cases. Apply this
throughout your workflow steps.
