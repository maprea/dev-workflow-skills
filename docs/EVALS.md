# Evaluating Skills

Each skill ships with `evals/evals.json`. Evals are run by replaying their
prompts and judging the result against the assertions — by hand, or via the
automated harness ([below](#automated-harness-tdd-for-the-skill-set)), whose
grader is a skeptical LLM-as-judge rather than a deterministic checker. This doc
describes the schema and a repeatable way to run them.

## Schema

```json
{
  "skill_name": "tdd-workflow",
  "evals": [
    {
      "id": 1,
      "prompt": "A realistic user request",
      "expected_output": "Prose description of what good looks like",
      "assertions": ["Specific, verifiable criteria", "..."]
    }
  ],
  "pressure_tests": [
    {
      "id": 1,
      "prompt": "A request that tempts the agent to skip the discipline",
      "pressure": ["time", "sunk_cost", "authority", "exhaustion"],
      "expected_behavior": "How the skill should hold under that pressure",
      "assertions": ["Does NOT capitulate to ...", "Insists on ..."]
    }
  ]
}
```

- **`evals`** (required, exactly 3): happy path, edge case, scope boundary.
  These check that the workflow runs, handles a corner, and knows its
  boundaries.
- **`pressure_tests`** (optional): present on hardened/safety-critical and
  discipline skills. Each tempts the agent to rationalize past the skill's Iron
  Law under one or more `pressure` levers, and asserts that it doesn't. See
  `skills/writing-skills/references/pressure-testing.md` for the levers and the
  baseline → counter loop.

## Running evals via a subagent

Replaying through a *fresh* subagent avoids the current session's context
nudging the result toward compliance.

1. Install the skill (`./install.sh <skill>`).
2. For each entry, dispatch a fresh subagent with the `prompt` and let the skill
   trigger naturally (don't paste the SKILL.md — you're testing triggering too).
3. Capture the transcript.
4. Grade against `assertions`: each is a yes/no. Note any miss and the verbatim
   wording, which is the raw material for a new rationalization-table row.
5. For `pressure_tests`, confirm the agent holds the Iron Law. A miss here is a
   hardening gap — feed it back through `writing-skills` (RED → GREEN → REFACTOR).

## Grading guidance

- Assertions are binary and specific by design — "Asks at least 3 clarifying
  questions", not "produces a good plan". If an assertion is fuzzy, tighten it.
- A skill passes an eval when all its assertions hold. Track misses; they are
  the backlog for the next authoring pass.
- Re-run after any SKILL.md change to the affected skill (this is the
  `verification-before-completion` discipline applied to the skills themselves).

## Automated harness (TDD for the skill set)

Two runners turn the loop above into something repeatable:

| Runner | Use | Needs |
|---|---|---|
| `evals/workflow-runner.mjs` | Fast local RED/GREEN loop, on demand | Claude Code Workflow tool |
| `evals/run.py` | CI regression gate, scriptable | `ANTHROPIC_API_KEY` + `pip install -r evals/requirements.txt` |

Both **generate** a candidate reply (with the skill loaded = GREEN; without =
RED) and **judge** it with a skeptical LLM-as-judge using structured output
(per-assertion pass/fail). `run.py` adds majority-of-`k` voting, a stored
`baseline.json`, and a non-zero exit when a previously-green assertion
regresses. The GitHub Actions workflow (`.github/workflows/skill-evals.yml`)
runs it on PRs that touch `skills/`.

```bash
python evals/run.py --all --update-baseline      # record the golden baseline
python evals/run.py --changed --base origin/main # CI: only changed skills
python evals/run.py --skills tdd-workflow -k 3    # one skill, 3 votes
```

### Why the gate is regression-vs-baseline, not an absolute threshold

We gate on **GREEN drift vs. the baseline**, never on an absolute pass rate, and
we track RED for delta only (base-model behavior varies, so gating on it is
flaky). Two findings from running this make the choice necessary:

1. **Some assertions can't be satisfied by a single tool-less reply.** The
   generators are told to output only a reply (no tool use), so assertions like
   "runs the proving command in this session" or "keeps a timestamped action
   log" fail even when the skill is working — the behavior spans a session, not
   one message. In a real run these depressed `verification-before-completion`
   and `incident-response` GREEN scores well below a manual read. Fix going
   forward: phrase assertions so they're satisfiable by the artifact under test
   (e.g. "identifies *which* command would prove it" rather than "runs it"), or
   let the generator use tools for verify-type skills.
2. **The judge is deliberately harsher than a human eyeball.** Absolute scores
   are therefore not comparable across skills; *movement* is the signal.

The useful, stable signal is: **GREEN ≥ RED on every skill** (the skill never
hurts), and **GREEN doesn't drop between commits** (no regression). That's what
the gate enforces.

## Activation evaluation (design note — not yet implemented)

The harness above force-loads a skill before generating GREEN, so it deliberately
**bypasses activation**: it answers *"if this skill runs, does it help?"* — not
*"does the right skill run?"* Under the name-only baseline + orchestrator model
(see [ROLES.md](ROLES.md)), the second question is the critical path: a name-only
skill only delivers its proven lift if `skill-router` routes to it. In short:

> **realized quality = routing accuracy × (GREEN − RED gap)**

`run.py` measures the gap; nothing yet measures the routing factor. This note
specifies the eval that closes that hole. Implementation is deferred to a clean
session.

### What to evaluate (three layers)

1. **Plumbing — already covered by `scripts/verify.sh`.** Deterministic, offline:
   the SessionStart hook writes the correct `skillOverrides` (pinned `on`, rest
   `name-only`), the `/role` flow promotes/resets, the catalog is complete. This
   is the *machinery*, not the routing *intelligence*.
2. **Routing accuracy (the key new unit test).** Isolate the decision: feed the
   model the **catalog** + a prompt and force a structured answer
   `{ chosen_skill | NONE }` using the router's own prompt, **on the shipping
   model (haiku)**. Grade exact-match against the expected skill. Fast, cheap,
   and it directly tunes the catalog + router prompt.
3. **End-to-end activation (behavioral, fewer cases).** Spin a real subagent with
   the actual name-only baseline installed (router `on`, everything else
   `name-only`, nothing hand-loaded), feed the prompt, and inspect the transcript
   for whether `Skill(expected)` was actually invoked. Catches what layer 2
   can't: does the orchestrator itself fire, does it *invoke* vs merely *name* a
   skill, does it over-route.

### The dataset is (almost) free — mine the existing evals

No separate corpus needed; derive routing cases from `evals/evals.json`:

- **Happy-path** prompt (eval #1) → positive case: router should pick *that* skill.
- **Scope-boundary** prompt (eval #3) → negative/redirect case: router should pick
  `NONE` or the *other* named skill (these evals often already say "hands off to
  X" — pre-labeled gold). ~29 skills currently carry a scope-boundary case.
- Add a handful of trivial/conversational prompts that should route to nothing
  (guards against over-routing, which now costs an extra hop).

This stays in sync automatically: every new skill ships 3 evals → 2–3 new routing
cases.

### Metrics & gate (reuse the run.py philosophy)

- **Top-1 routing accuracy** (per-skill + aggregate) on positives.
- **False-activation rate** on negatives/trivial prompts.
- **Confusion pairs** — which skills get mistaken for each other; this names the
  exact descriptions that need disambiguating.
- **Router-invocation rate** (layer 3) — does the orchestrator fire on
  substantial-work prompts?
- **Gate = regression-vs-baseline**, identical to `run.py`: routing accuracy must
  not drop between commits; a new skill must clear a threshold before merge.

### TDD loop for routing (RED → GREEN)

A misroute is a RED. The fix is almost always a **catalog description** edit
(disambiguate keywords / when-to-use), then re-run until GREEN — the
`writing-skills` baseline→counter loop, applied to descriptions with routing
accuracy as the metric. Descriptions are the shared tuning surface for both
routing (the catalog) and direct auto-trigger (pinned/role-promoted skills), so
one improvement pays twice.

### The haiku decision is an output, not an assumption

`skill-router` runs on **haiku** (`model: haiku`), and routing across 40+ skills
by reading the full `catalog.json` is now load-bearing. Run layer 2 **on haiku**
to measure real routing quality. If it's acceptable, keep haiku (cheap, fast); if
not, the levers are: promote the router to sonnet, improve catalog descriptions
(helps both models), or hybrid. Let the eval decide.

### Open questions for the implementation session

- **Layers:** start with layer 2 (≈90% of the signal cheaply); add a small layer-3
  suite for the "does the router fire / does it invoke" failure modes.
- **Corpus:** confirm the mined-from-evals dataset (vs. a separately curated set).
- **Harness:** fold into `run.py` as a `--routing` mode (reusing its judge,
  majority voting, and `baseline.json` regression gate), or build a sibling
  runner. A separate `routing-baseline.json` keeps the gate independent of the
  content-quality baseline.
