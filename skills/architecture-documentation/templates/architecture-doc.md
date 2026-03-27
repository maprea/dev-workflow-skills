# Architecture Documentation — Repository Structure Template

## Recommended Directory Layout

```
docs/
  architecture/
    README.md                              # Index: what's here, how to navigate, conventions used
    glossary.md                            # Shared vocabulary — authoritative names for all systems

    canonical/                             # Source-of-truth structural diagrams (C4 model)
      system-context.{puml|dsl|mmd}        # Level 1: system + users + external dependencies
      container-{system-name}.{ext}        # Level 2: services, data stores, message brokers
      component-{service-name}.{ext}       # Level 3: internal structure (only if needed)

    runtime/                               # Operational behavior diagrams
      flows/                               # Data and request flows
        {flow-name}.{d2|mmd|puml}          # e.g., checkout-flow.d2, rag-pipeline.d2
      infra/                               # Deployment and infrastructure topology
        {environment}-topology.{d2|mmd}    # e.g., production-topology.d2
      sequences/                           # Sequence diagrams for key interactions
        {interaction-name}.{ext}           # e.g., auth-handshake.puml

    conceptual/                            # Communication and onboarding diagrams
      overview-{audience}.md               # e.g., overview-new-hires.md (with Mermaid)
      {topic}.md                           # e.g., data-flow-simplified.md

  decisions/                               # ADRs (managed by architecture-design skill)
    ADR-001-{title}.md
    ADR-002-{title}.md
```

### Multi-Repo Variant

For systems spanning multiple repositories, either:

**A) Central docs repo** — One repo holds all architecture docs. Services reference it.
```
architecture-docs/           # Dedicated repo
  canonical/                 # Cross-system C4 diagrams
  runtime/                   # Cross-service flows
  decisions/                 # Cross-cutting ADRs
```

**B) Co-located per service** — Each repo has its own `docs/architecture/` with service-scoped diagrams. A top-level repo or wiki holds the system context and cross-service views.

Choose A when: a single team owns architecture docs, or the system context is the primary audience.
Choose B when: teams own their services end-to-end and update docs alongside code.

---

## Glossary Template

The glossary is the single source of truth for system element names. Every diagram must use these names exactly.

```yaml
# docs/architecture/glossary.md (or glossary.yaml)

systems:
  payments-platform:
    description: Processes payments and manages billing
    owner: team-payments
    repo: github.com/org/payments

services:
  payments-api:
    system: payments-platform
    description: REST API for payment operations
    tech: Node.js / Express

  payment-worker:
    system: payments-platform
    description: Async payment processing
    tech: Node.js

data-stores:
  payments-db:
    system: payments-platform
    description: Transaction and billing storage
    tech: PostgreSQL

  payment-queue:
    system: payments-platform
    description: Job queue for async payment processing
    tech: Redis

external-systems:
  stripe:
    description: Payment gateway provider
    integration: REST API

  bank-api:
    description: Account verification service
    integration: REST API
```

**Rules:**
- Same names used in C4, runtime, and conceptual diagrams — no aliasing
- New services must be added to the glossary before appearing in any diagram
- The glossary is the authority — if a name isn't here, it shouldn't be in a diagram

---

## Architecture README Template

```markdown
# Architecture Documentation

## How to Read These Docs

This directory contains architecture documentation at three abstraction levels:

- **`canonical/`** — Source of truth for system structure (C4 model). Start here.
- **`runtime/`** — How the system behaves: data flows, deployment topology, key interactions.
- **`conceptual/`** — Simplified overviews for onboarding and communication. Not authoritative.
- **`../decisions/`** — Architecture Decision Records (ADRs) explaining why the architecture looks this way.

## Conventions

- **Naming**: All diagrams use names from `glossary.md`. No aliases or renames.
- **Tools**: [List your chosen tools, e.g., "C4-PlantUML for canonical, D2 for runtime, Mermaid for conceptual"]
- **Rendering**: [How to render diagrams, e.g., "Mermaid renders in GitHub. Run `make diagrams` for PlantUML/D2."]

## Diagram Index

| Diagram | Level | Description | Last Updated |
|---------|-------|-------------|--------------|
| [System Context](canonical/system-context.puml) | Canonical | Top-level system view | YYYY-MM-DD |
| [Containers](canonical/container-payments.puml) | Canonical | Services and data stores | YYYY-MM-DD |
| [Checkout Flow](runtime/flows/checkout-flow.d2) | Runtime | End-to-end checkout sequence | YYYY-MM-DD |
| [Production Topology](runtime/infra/production-topology.d2) | Runtime | K8s cluster layout | YYYY-MM-DD |
| [New Hire Overview](conceptual/overview-new-hires.md) | Conceptual | Simplified system map | YYYY-MM-DD |
```

---

## Validation Checklist

Use this checklist when reviewing architecture documentation for completeness:

### Structure
- [ ] `docs/architecture/` directory exists with canonical/, runtime/, and conceptual/ subdirectories (as needed)
- [ ] `glossary.md` exists with all system element names
- [ ] `README.md` exists with navigation guide and diagram index

### Canonical Diagrams
- [ ] System context diagram exists showing users and external dependencies
- [ ] Container diagram exists for each system with multiple services
- [ ] All services and data stores in the codebase appear in canonical diagrams
- [ ] Each canonical diagram has a title and last-updated date

### Runtime Diagrams (if applicable)
- [ ] Runtime diagrams reference only elements from canonical diagrams (infrastructure-only components excepted)
- [ ] Key data flows and interactions are documented
- [ ] Deployment topology matches actual infrastructure

### Naming Consistency
- [ ] All element names match the glossary exactly
- [ ] No diagram introduces new system names not in the glossary
- [ ] File names follow the established convention

### Traceability
- [ ] ADRs that changed architecture reference affected diagrams
- [ ] Canonical diagrams link to relevant ADRs in annotations or comments
- [ ] Runtime diagrams are traceable to canonical elements

### Maintenance
- [ ] Diagrams are version-controlled as text files
- [ ] Diagrams render correctly (manually verified or CI-checked)
- [ ] Conceptual diagrams are labeled as non-canonical
- [ ] Review cadence is documented (e.g., quarterly for canonical)
