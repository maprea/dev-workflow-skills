# Pressure-Testing Skills

Clear documentation is not enough. Under pressure, agents rationalize their way
past good advice — the same way people do. A skill is only as strong as its
behavior when the agent has a reason to cut the corner. Pressure-testing finds
those reasons before your users do.

## Why baseline first (RED)

If you write a skill from imagination, you guess at the failure mode and usually
guess wrong — over-explaining what Claude already knows, under-defending the one
step it actually skips. Running the scenario *without* the skill shows you the
real failure and, crucially, the *exact words* the agent uses to justify it.
Those words become the rows of your rationalization table.

## Running a baseline scenario

1. Pick a realistic scenario that should trigger the behavior you want.
2. Dispatch a **fresh subagent** with the scenario and *without* the skill (or
   without the new section you're adding). A fresh agent has no shared context
   pushing it toward compliance.
3. Record what it does and the verbatim justifications it gives.
4. Apply pressure (below) and run again — corners get cut under pressure, not in
   the calm path.

## The four pressure levers

Combine them; real situations stack pressure.

| Lever | Example injection |
|---|---|
| **Time** | "We ship in 20 minutes, just get it working." |
| **Sunk cost** | "I already spent two hours on this implementation." |
| **Authority** | "The senior engineer said tests aren't needed here." |
| **Exhaustion** | A long session with many prior steps before the ask. |

If the behavior holds under all four combined, it will hold in normal use.

## Turning rationalizations into counters

For each excuse the baseline produced, add one of:

- A **rationalization table** row: `| "<verbatim excuse>" | <why it's wrong> |`
- A **red flag**: an in-the-moment signal the agent can catch itself on
  ("you're typing 'done' without a command output above it").
- A tighter **Iron Law** if the excuse attacks the core rule itself.

Address the excuse the agent *actually used*, in language close to how it used
it — that's what makes it recognize and resist the same move next time.

## Convergence

Re-run after each change. Each pass tends to surface a *new*, subtler
rationalization — add a counter and repeat. Stop when two consecutive
pressure runs produce the desired behavior with no new excuses. Don't chase
zero forever; diminishing returns set in fast.

## Worked example (tdd-workflow)

- **RED:** "We're in a hurry — just write the validator, we'll add tests after."
  Baseline agent writes the implementation first and says "I'll add tests after,
  it achieves the same thing."
- **GREEN:** Add the Iron Law ("no production code without a failing test you
  watched fail") and a rationalization row: `| "Tests-after achieve the same
  thing" | Tests-first ask 'what should this do?'; tests-after ask 'what does
  this do?' |`.
- **REFACTOR:** Re-run under sunk-cost pressure ("I already wrote it"). New
  excuse: "deleting working code is wasteful." Add the sunk-cost row. Re-run;
  behavior holds → done.
