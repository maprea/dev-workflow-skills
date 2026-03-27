# Abstraction Levels for Architecture Documentation

Architecture documentation must operate at different abstraction levels to serve different audiences and purposes. Mixing levels in a single diagram creates confusion — a system context diagram cluttered with Kubernetes pods, or a deployment diagram that also tries to show business boundaries.

## The Three Levels

### Canonical (Structural Truth)

The authoritative representation of what exists in the system. Uses the C4 model hierarchy:

1. **System Context**: The system as a whole, its users, and external systems it depends on or integrates with. Every architecture should have this diagram.
2. **Container**: The major deployable units inside the system — services, databases, message brokers, frontends, batch jobs. This is the most commonly useful C4 level.
3. **Component**: Internal structure of a single container — modules, major classes, or subsystems. Only create when a service is complex enough that its internals are architecturally significant.
4. **Code**: Class diagrams or module diagrams. Almost never worth maintaining manually — IDEs generate these on demand.

**Rules:**
- Canonical diagrams define system structure. If a service, data store, or external dependency exists, it should appear here.
- Changes to canonical diagrams represent actual architectural changes — these should be infrequent and deliberate.
- Canonical diagrams should be minimal and stable. Resist adding runtime or deployment details.

### Runtime (Operational Behavior)

How the system behaves when running. These diagrams show movement, flow, and infrastructure:

- **Data flow diagrams**: How data moves through the system (e.g., RAG pipeline, ETL flow, event streaming)
- **Sequence diagrams**: Step-by-step interaction for key scenarios (e.g., checkout flow, authentication handshake)
- **Deployment/infrastructure topology**: Where code runs — Kubernetes clusters, cloud regions, CDNs, load balancers
- **Integration diagrams**: How external systems connect at runtime (webhooks, polling, file drops)

**Rules:**
- Runtime diagrams must reference elements defined in canonical diagrams. Don't introduce new system names here.
- Infrastructure-only components (load balancers, ingress controllers, service meshes, CI runners) are exceptions — they may appear only at the runtime level since they're not architecturally significant at the canonical level.
- Focus on relationships and flows, not ownership or boundaries (those belong in canonical diagrams).

### Conceptual (Communication)

Lightweight diagrams for human understanding. These serve communication, not governance:

- **Onboarding overviews**: Simplified system maps for new team members
- **RFC/ADR illustrations**: Quick visuals to support a written proposal
- **Presentation diagrams**: Architecture slides for stakeholders
- **PR explanations**: "Here's what this change does" diagrams

**Rules:**
- Conceptual diagrams are non-canonical. They may simplify, omit, or group elements for clarity.
- They should never be treated as the source of truth.
- Label them clearly (e.g., "Simplified overview — see canonical diagrams for authoritative structure").
- They are disposable by default. If one proves valuable and gets referenced repeatedly, promote it.

## Traceability

Elements should be traceable across levels:

```
Decision (ADR)
   ↓  justifies why the architecture looks this way
Canonical (C4)
   ↓  defines what exists structurally
Runtime (D2/sequence/deployment)
   ↓  shows how it behaves operationally
Code / Deployment
   ↓  implements the architecture
```

**Practical traceability rules:**
- Every container in a canonical diagram should correspond to a deployable unit in the codebase
- Every element in a runtime diagram should trace to a container or external system in the canonical diagram (with the infrastructure-only exception noted above)
- ADRs that change architecture should reference the canonical diagrams they affect
- Conceptual diagrams are exempt from strict traceability — they serve communication, not governance

## The Promotion Model

Diagrams have a maturity lifecycle. Not every sketch needs to become a canonical diagram.

```
Conceptual (sketch / idea / RFC)
   ↓  proves valuable — referenced repeatedly, used for onboarding
Runtime (structured, uses proper tooling, follows naming conventions)
   ↓  represents a stable structural change to the system
Canonical (source of truth, reviewed, maintained)
```

**When to promote:**
- A conceptual diagram gets referenced in 3+ documents or conversations → consider promoting to runtime level with proper tooling
- A runtime diagram reveals a structural boundary that isn't captured canonically → update the canonical diagrams
- An ADR introduces a new service or changes boundaries → update canonical diagrams directly (skip promotion)

**When NOT to promote:**
- A conceptual diagram was useful for one presentation but isn't referenced again → let it age naturally
- A runtime diagram shows a temporary deployment configuration → keep at runtime level
- The system is simple enough that canonical diagrams capture everything needed → don't create runtime diagrams just to have them
