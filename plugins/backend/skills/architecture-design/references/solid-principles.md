# SOLID Principles Reference

## Contents
- Open/Closed Principle (OCP)
- Liskov Substitution Principle (LSP)
- Interface Segregation Principle (ISP)
- Dependency Inversion Principle (DIP)

SRP is already covered extensively in the review checklist and refactoring skill. This reference focuses on the four principles that are less intuitive and more often misapplied.

## Open/Closed Principle (OCP)

**Software entities should be open for extension but closed for modification.**

When a new requirement arrives, you should be able to add new behavior without changing existing, tested code. Changing existing code risks breaking things that already work.

How to achieve it:
- **Polymorphism**: Define a base type with a contract. New behaviors become new implementations, not if/else branches in existing code.
- **Strategy pattern**: Pass behavior as a parameter instead of hard-coding it.
- **Plugin architecture**: Define extension points where new functionality can be registered.

When OCP matters most:
- Code that is stable and widely depended upon — changing it has high blast radius
- Frameworks and libraries consumed by others
- Business rule engines where rules are added frequently

When to relax OCP:
- Early in a feature's life when the abstraction isn't clear yet — premature abstraction violates KISS
- Internal code with few consumers — just change it
- When the "extension" mechanism would be more complex than the modification it avoids

**The smell**: A growing switch/if-else chain where each new case modifies the same function. This is the classic OCP violation — each addition risks breaking existing cases.

## Liskov Substitution Principle (LSP)

**Subtypes must be substitutable for their base types without altering the correctness of the program.**

If code works with a base type, it must also work with any subtype. Violations create bugs that surface far from the offending code — a subtype behaves unexpectedly in a context that expects the base type's contract.

The contract includes:
- **Preconditions**: A subtype cannot strengthen preconditions (require more from callers)
- **Postconditions**: A subtype cannot weaken postconditions (promise less to callers)
- **Invariants**: A subtype must maintain all invariants of the base type
- **History constraint**: A subtype cannot change state in ways the base type cannot

Classic violations:
- `Square extends Rectangle` where setting width also sets height — breaks `Rectangle`'s contract that width and height are independent
- A `ReadOnlyList` that throws on `add()` — callers of `List` expect `add()` to work
- A cache implementation that silently drops entries — callers expect `get()` after `put()` to return the value

How to detect LSP violations:
- Look for `instanceof` / type checks in code consuming the base type — these indicate the base type's contract is insufficient
- Look for overridden methods that throw `UnsupportedOperationException` — the subtype can't fulfill the contract
- Look for subtypes that ignore or no-op base type methods

How to fix:
- Redesign the hierarchy — often the inheritance relationship is wrong
- Use composition instead of inheritance
- Split the base type into smaller interfaces (leads naturally to ISP)

## Interface Segregation Principle (ISP)

**Clients should not be forced to depend on interfaces they do not use.**

Fat interfaces create unnecessary coupling. When a client depends on methods it never calls, changes to those methods can still force recompilation, redeployment, or unexpected breakage.

Signs of ISP violation:
- An interface with 10+ methods where most implementors only use a subset
- Classes that implement interface methods with empty bodies or `throw new NotImplementedException()`
- A "god interface" that every module depends on but each uses a different slice

How to apply ISP:
- Split large interfaces into smaller, role-specific ones: `Readable`, `Writable`, `Closeable` instead of `FileHandler`
- Define interfaces from the client's perspective — what does the consumer need? — not from the implementor's perspective
- A class can implement multiple small interfaces, so splitting costs nothing

Relationship to other principles:
- ISP violations often cause LSP violations (implementors that can't fulfill the full contract)
- ISP supports DIP (small, focused abstractions are easier to depend on)
- ISP aligns with CRP at the component level (don't depend on what you don't use)

## Dependency Inversion Principle (DIP)

**High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details. Details should depend on abstractions.**

This is the architectural principle behind Clean Architecture's Dependency Rule. Without DIP, high-level business logic becomes coupled to infrastructure — changing a database or API client forces changes to business rules.

How it works:
1. High-level module defines an interface for what it needs (e.g., `OrderRepository`)
2. Low-level module implements that interface (e.g., `PostgresOrderRepository`)
3. Both depend on the abstraction — the high-level module owns the interface definition
4. A composition root (main, DI container) wires implementations to interfaces

Key insight: **the interface belongs to the consumer, not the provider**. `OrderService` defines `OrderRepository`; the database layer implements it. This means the database layer depends on the business layer, not the other way around.

When DIP matters:
- Business logic that should survive infrastructure changes (database, API, messaging)
- Code that needs to be testable in isolation (inject test doubles through the interface)
- Boundaries between teams — interface ownership defines the dependency direction

When to skip DIP:
- Internal code where the "low-level" module will never change (e.g., wrapping a string utility)
- When there's only one possible implementation and no testing benefit — the abstraction adds noise
- Early prototyping where speed matters more than structure

**The test**: Can you test your business logic without a database, network, or file system? If not, DIP is likely missing at a critical boundary.
