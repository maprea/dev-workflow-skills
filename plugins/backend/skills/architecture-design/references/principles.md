# Architecture Principles Reference

## Contents
- KISS in architecture
- YAGNI in architecture
- Functional independence and coupling
- Separation of concerns
- DRY at the system level
- Common anti-patterns

## KISS in Architecture

Simplicity in architecture means fewer moving parts, fewer failure modes, and faster onboarding. When evaluating options:

- Prefer a monolith over microservices unless you have a concrete scaling or deployment bottleneck that a monolith cannot solve
- Prefer synchronous communication unless you need resilience to downstream failures
- Prefer a single database unless you have conflicting access patterns that provably degrade each other
- Prefer server-side rendering unless you need offline capability or real-time interactivity

The burden of proof is on complexity — if you can't articulate why the simpler approach fails, choose simple.

## YAGNI in Architecture

Build for today's known requirements plus 6 months of projected growth. Do not:

- Design for "millions of users" when you have hundreds
- Add a message queue because "we might need it"
- Create microservices because "we might scale the team"
- Abstract every boundary because "we might swap implementations"

Instead, identify the minimum viable architecture that meets current quality attributes. Document what triggers a redesign (e.g., "if request latency exceeds 200ms at P95, revisit the caching strategy").

## Functional Independence and Coupling

Measure coupling by asking: "If I change module A, how many other modules must also change?"

Coupling types (ordered from worst to best):
1. **Content coupling**: Module A directly modifies the internals of module B
2. **Common coupling**: Modules share global mutable state
3. **Control coupling**: Module A passes flags that dictate module B's behavior
4. **Stamp coupling**: Modules share composite data structures but only use parts
5. **Data coupling**: Modules share only the data they each need (best achievable)

At the architecture level, aim for data coupling between services/modules. Each component should have a well-defined interface and no knowledge of other components' internals.

## Separation of Concerns

Good boundaries emerge from asking "what changes together?":

- **Business rules** change when business requirements change
- **Data access** changes when storage technology changes
- **Presentation** changes when UX requirements change
- **Infrastructure** changes when deployment targets change

If a single change requires touching all four layers, your separation is leaking. Common signs:
- Business logic inside API controllers
- SQL queries inside domain models
- Formatting logic inside data access layers
- Environment-specific code outside configuration

## DRY at the System Level

DRY in architecture is about eliminating **knowledge duplication**, not code duplication. Two services can have similar code if they represent different business concepts that happen to look alike today.

Dangerous false DRY:
- Sharing a "common" library between services that evolve at different rates
- Creating a "generic" service that handles too many concerns
- Forcing different domains into a shared data model

Legitimate DRY:
- Centralizing authentication/authorization logic
- Shared API contracts (OpenAPI specs, protobuf definitions)
- Common infrastructure configuration (Terraform modules, Helm charts)

## Common Anti-patterns

- **Premature abstraction**: Creating interfaces and abstractions before you have two concrete implementations
- **Distributed monolith**: Microservices that must be deployed together and share a database
- **God service**: One service that everything depends on and that handles too many concerns
- **Speculative generality**: Building for flexibility nobody has asked for
- **Golden hammer**: Using the same pattern/technology for every problem
