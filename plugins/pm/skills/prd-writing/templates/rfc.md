# Technical RFC Template

```markdown
# RFC: [Title]

**Author**: [Name]
**Date**: [YYYY-MM-DD]
**Status**: Draft | In Review | Accepted | Rejected | Superseded
**Review deadline**: [Date — give reviewers a clear deadline]
**Reviewers**: [Names/teams]

## Context

[What triggered this RFC? What's the current state? What constraints exist?
Provide enough context for a reviewer who isn't working on this daily.]

## Problem

[Specific technical problem to solve. Reference the PRD if one exists.]

## Proposed Solution

[Describe the technical approach. Include diagrams where helpful.
This should be detailed enough that an engineer can implement from it,
but not so detailed that it prescribes every function signature.]

### Architecture / Design

[High-level design, component diagram, data flow]

### Data Model Changes

[New tables, modified columns, migrations needed.
Link to data-modeling skill output if applicable.]

### API Changes

[New or modified endpoints.
Link to api-design skill output if applicable.]

### Migration Plan

[How to get from current state to proposed state safely.
Especially important for production changes.]

## Alternatives Considered

### [Alternative A]
[Description]
**Why not**: [Specific reason this approach was rejected]

### [Alternative B]
[Description]
**Why not**: [Specific reason]

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| [Risk] | [Strategy] |

## Open Questions

- [ ] [Question for reviewers]
- [ ] [Decision that needs input]

## Implementation Plan

[Rough phases. Link to feature-planning output for detailed task breakdown.]

1. [Phase 1]: [What and rough timing]
2. [Phase 2]: [What and rough timing]

## References

- [PRD link]
- [Related ADRs]
- [External documentation]
```
