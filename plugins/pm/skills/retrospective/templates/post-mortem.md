# Post-Mortem Templates

## Incident Post-Mortem

```markdown
# Incident Post-Mortem: [Incident Title]

**Date**: [YYYY-MM-DD]
**Severity**: SEV-1 / SEV-2 / SEV-3
**Duration**: [X hours Y minutes]
**Author**: [Name]
**Status**: Draft | In Review | Final

## Summary

[2-3 sentences: What happened, what was the user impact, how long it lasted.]

## Impact

- **Users affected**: [Number or percentage]
- **Revenue impact**: [If applicable]
- **Data impact**: [Any data loss or corruption]
- **Duration**: [Start time → Detection time → Resolution time]

## Timeline (all times UTC)

| Time | Event |
|------|-------|
| HH:MM | [First signs of the problem] |
| HH:MM | [Alert fired / User report received] |
| HH:MM | [On-call engineer paged] |
| HH:MM | [Root cause identified] |
| HH:MM | [Fix deployed] |
| HH:MM | [Service fully recovered] |

**Time to detect**: [How long from start to detection]
**Time to resolve**: [How long from detection to resolution]

## Root Cause

[Detailed explanation of what caused the incident. Use 5 Whys if helpful.
Be specific and technical. This section should help someone prevent the same issue.]

## What Went Well

- [Effective response actions]
- [Monitoring that helped]
- [Team coordination that worked]

## What Went Poorly

- [Detection gaps]
- [Response delays]
- [Missing runbooks or documentation]

## Action Items

| Action | Type | Owner | Deadline | Status |
|--------|------|-------|----------|--------|
| [Specific action] | Prevention | [Name] | [Date] | ⬜ |
| [Specific action] | Detection | [Name] | [Date] | ⬜ |
| [Specific action] | Process | [Name] | [Date] | ⬜ |

## Lessons Learned

[Key takeaways that apply beyond this specific incident.]
```

## Project Post-Mortem

```markdown
# Project Post-Mortem: [Project Name]

**Date**: [YYYY-MM-DD]
**Author**: [Name]
**Project duration**: [Start → End]
**Team**: [Names/roles]

## Project Summary

[What the project set out to do and what it actually delivered.]

## Results vs Goals

| Goal | Target | Actual | Met? |
|------|--------|--------|------|
| [Goal 1] | [Target] | [Result] | ✅/❌ |
| [Goal 2] | [Target] | [Result] | ✅/❌ |

## Estimates vs Actuals

| | Estimated | Actual | Delta |
|---|----------|--------|-------|
| Duration | [X weeks] | [Y weeks] | [+/- N weeks] |
| Effort | [X person-weeks] | [Y person-weeks] | [+/- N] |
| Scope | [N features] | [M features] | [Added/cut] |

## What Went Well

- [Process, decision, or practice that helped]
- [Technical approach that paid off]
- [Team dynamic that worked]

## What Could Be Improved

- [Process gap or friction point]
- [Decision that didn't work out and why]
- [Estimation miss and what caused it]

## Key Decisions and Their Outcomes

| Decision | Why We Made It | Outcome | Would We Do It Again? |
|----------|---------------|---------|----------------------|
| [Decision] | [Rationale] | [Result] | Yes/No/Modified |

## Recommendations

1. [Specific recommendation for future projects]
2. [Specific recommendation]
3. [Specific recommendation]
```
