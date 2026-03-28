# Component Principles Reference

## Contents
- Component cohesion (REP, CCP, CRP)
- Component coupling (ADP, SDP, SAP)
- The tension triangle
- Stability and abstractness metrics

Components are the units of deployment — JARs, gems, npm packages, Go modules, Python packages. These principles guide what goes into a component and how components relate to each other.

## Component Cohesion Principles

These three principles govern which classes belong together in a component. They pull in different directions — balancing them is a design judgment.

### Reuse/Release Equivalence Principle (REP)

**The granule of reuse is the granule of release.**

Classes and modules that are reused together should be released together, with a shared version number and release process. If you release a component, everything in it should make sense to a consumer who depends on it.

Violation signals:
- A package where consumers only use 20% of the classes and are forced to take the other 80%
- A "utils" package with unrelated utilities — date formatting, string helpers, HTTP clients, and logging all in one
- Version bumps that break consumers who don't use the changed code

### Common Closure Principle (CCP)

**Gather together classes that change for the same reasons and at the same time.**

This is SRP at the component level. A change in requirements should affect one component, not scatter across many. When classes change together, they belong together.

This minimizes the number of components that need to be redeployed when a requirement changes.

Violation signals:
- A single feature change requires modifying 5+ components
- Related classes are scattered across packages by technical layer rather than grouped by business capability
- Every PR touches the same set of "shared" packages

### Common Reuse Principle (CRP)

**Don't force users of a component to depend on things they don't need.**

If a consumer uses one class from a component, it implicitly depends on the entire component. If another class in that component changes, the consumer must revalidate and potentially redeploy — even though it doesn't use the changed class.

This is ISP at the component level.

Violation signals:
- Consumers frequently pinpoint specific files to import rather than using the component as a whole
- A change to an unused class in a dependency forces downstream rebuilds or version bumps
- "I only need the `parseDate` function but I have to install a 2MB package"

## The Tension Triangle

REP, CCP, and CRP pull in different directions:

```
        REP
       /    \
     CCP --- CRP
```

- **REP + CCP** (group for reusers + group for changers): Tends toward large components — easy to release and change together, but consumers depend on more than they need (violates CRP)
- **CCP + CRP** (group for changers + split for consumers): Tends toward many small components — changes are localized and consumers only get what they need, but hard to manage releases (violates REP)
- **REP + CRP** (group for reusers + split for consumers): Tends toward well-packaged components, but changes scatter across many of them (violates CCP)

**Early in a project**, favor CCP — you want changes localized because requirements shift fast. **As the project matures and gains consumers**, shift toward REP and CRP — reusability and minimal dependency surface matter more.

## Component Coupling Principles

These three principles govern the dependency relationships between components.

### Acyclic Dependencies Principle (ADP)

**The dependency graph of components must have no cycles.**

Cycles create a "morning after" problem: you arrive to find your code broken because something you depend on changed, which depended on something you changed, creating an unresolvable build order.

With cycles:
- You cannot build or test components in isolation
- A change anywhere in the cycle potentially affects everything in the cycle
- Release order becomes ambiguous or impossible

How to break cycles:
1. **Apply DIP**: If A depends on B and B depends on A, have B depend on an interface defined by A (or introduce a new component for the shared abstraction)
2. **Extract a new component**: Move the shared dependency into its own component that both A and B depend on
3. **Merge the components**: If two components are so intertwined they form a cycle, they may actually be one component

### Stable Dependencies Principle (SDP)

**Depend in the direction of stability.**

A component's stability is measured by how hard it is to change. Components that many others depend on are stable (changing them has high cost). Components with few dependents are volatile (easy to change).

**Stability metric (I)**: `I = Fan-out / (Fan-in + Fan-out)`
- Fan-in: number of incoming dependencies (other components that depend on this one)
- Fan-out: number of outgoing dependencies (components this one depends on)
- I = 0: maximally stable (everyone depends on it, it depends on nothing)
- I = 1: maximally unstable (it depends on others, nobody depends on it)

The rule: a component should only depend on components with a lower I (more stable). Depending on something less stable than yourself means your component can be destabilized by volatile changes.

### Stable Abstractions Principle (SAP)

**A component should be as abstract as it is stable.**

Stable components (hard to change because many depend on them) should consist of abstractions — interfaces and abstract classes — so they can be extended without modification (OCP).

Volatile components (easy to change) should be concrete — they contain the implementation details that change frequently.

**Abstractness metric (A)**: `A = abstract classes and interfaces / total classes`
- A = 0: fully concrete (no abstractions)
- A = 1: fully abstract (only interfaces)

Plotting I against A gives the **Main Sequence** — the ideal diagonal where `I + A ≈ 1`:
- Components near (0,1): stable and abstract — good (e.g., interface packages)
- Components near (1,0): volatile and concrete — good (e.g., implementations, UI)
- Components near (0,0): stable and concrete — **Zone of Pain** (hard to change but contains implementation details)
- Components near (1,1): volatile and abstract — **Zone of Uselessness** (abstract but nobody depends on it)

## Applying These Principles

When designing component boundaries:

1. **Start with CCP** — group by business capability so changes are localized
2. **Check for cycles (ADP)** — if you find one, restructure using DIP or extraction
3. **Verify stability direction (SDP)** — volatile components should not be depended upon by stable ones
4. **Balance abstraction with stability (SAP)** — if a component is heavily depended upon, make it abstract
5. **As consumers appear, apply CRP** — split components so consumers only depend on what they use
6. **Version and release cohesive units (REP)** — everything in a release should make sense together
