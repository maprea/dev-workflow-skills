# Clean Architecture Reference

## Contents
- The Dependency Rule
- The four layers
- Screaming Architecture
- Plugin Architecture
- The Main Component
- Humble Object Pattern
- Policy and Level
- Entities vs Use Cases
- Crossing boundaries

## The Dependency Rule

**Source code dependencies must point inward only.** Nothing in an inner circle can know anything about something in an outer circle — not a name, a type, a function, or even that an outer layer exists.

This is the foundational rule. Every other concept in Clean Architecture exists to enforce or support it. When dependencies point inward, the core business logic is protected from changes to UI, databases, frameworks, and delivery mechanisms.

Data can flow outward (a use case returns a result to a controller), but the source code dependency still points inward — the outer layer calls into the inner layer, not the reverse. When inner layers need to communicate outward, they define an interface that the outer layer implements (Dependency Inversion Principle).

## The Four Layers

From innermost to outermost:

### Layer 1: Entities
Enterprise-wide business rules — the most general, highest-level policies. Entities encapsulate the critical business logic that would exist even if there were no software system.

- Pure domain objects with behavior and validation
- No dependency on any framework, database, or delivery mechanism
- Reusable across applications (if the enterprise has multiple apps)
- Example: `Order` that enforces "cannot add items after checkout", `Money` that handles currency arithmetic

### Layer 2: Use Cases (Application Business Rules)
Application-specific business rules that orchestrate entities to achieve a goal. Each use case represents one thing the system does for a user or external system.

- Orchestrate the flow of data to and from entities
- Contain application logic: "when user places order, validate stock, calculate total, reserve inventory, send confirmation"
- Define input/output port interfaces (what data comes in, what goes out)
- Independent of UI, database, or external services
- Example: `PlaceOrderUseCase` that coordinates `Order`, `Inventory`, and `PaymentGateway` interfaces

### Layer 3: Interface Adapters
Convert data between the format used by use cases/entities and the format used by external agencies.

- **Controllers**: Receive external input (HTTP, CLI, events), convert to use case input format, invoke the use case
- **Presenters**: Take use case output, format it for the delivery mechanism (JSON, HTML, CLI output)
- **Gateways**: Implement repository/service interfaces defined by use cases, translate to database queries or API calls
- **DTOs**: Data transfer objects that cross the boundary — simple data structures, no business logic

### Layer 4: Frameworks & Drivers
The outermost layer — databases, web frameworks, UI frameworks, external APIs, file systems.

- Contains no business logic — only glue code
- Frameworks are kept at arm's length — they are tools, not the architecture
- This layer is where the "details" live: which database, which web framework, which messaging system
- Easiest to replace because nothing depends on it

## Screaming Architecture

**Your architecture should tell you what the system does, not what framework it uses.**

When you look at a project's top-level directory structure, it should scream "healthcare system" or "accounting application" — not "Rails app" or "Spring Boot project."

Signs of screaming architecture:
- Top-level directories named after domain concepts: `orders/`, `inventory/`, `payments/`
- Use cases are visible as first-class code artifacts, not buried inside controllers
- You can understand the system's purpose without knowing the technology stack

Signs of framework-dominated architecture:
- Top-level directories named `controllers/`, `models/`, `views/`, `services/`
- Business logic scattered across framework-specific classes
- Switching frameworks would require rewriting business logic

This doesn't mean you can't have a `controllers/` directory — but it should live inside a feature module, not the other way around.

## Plugin Architecture

**Frameworks, databases, and UI are plugins to the business rules — not the other way around.**

The business rules are the core. Everything else plugs into them. This means:
- The database is a plugin — you should be able to swap PostgreSQL for MongoDB without touching business logic
- The web framework is a plugin — you should be able to swap Express for Fastify without touching use cases
- The UI is a plugin — you should be able to add a CLI interface alongside the web UI without duplicating logic

This is achieved through interfaces defined by the inner layers and implemented by the outer layers (DIP).

## The Main Component

Every application has an entry point — `main()`, `app.ts`, `settings.py`. This is the "dirtiest" component in the system:

- It knows about everything: frameworks, databases, use cases, entities
- It wires all the dependencies together (composition root)
- It is a plugin to the application — the outermost detail
- It should contain no business logic — only wiring

The Main component is where dependency injection configuration lives. It creates concrete implementations and passes them to the layers that depend on abstractions.

## Humble Object Pattern

**Separate behaviors that are hard to test from behaviors that are easy to test.**

At every architectural boundary, you'll find code that's hard to test (UI rendering, database I/O, network calls) adjacent to code that's easy to test (data formatting, validation, business decisions). The Humble Object pattern splits them:

- **Humble part**: Kept as simple as possible. Does the hard-to-test thing (renders HTML, executes SQL) but contains no logic worth testing.
- **Testable part**: Contains all the decisions and logic. Receives and returns simple data structures.

Common applications:
- **Presenter / View**: The presenter formats data and makes decisions (testable). The view just renders what the presenter provides (humble).
- **Gateway / Database**: The gateway implementation executes queries (humble). The use case that calls the gateway interface contains the logic (testable).
- **Controller / Framework**: The framework routing is humble. The controller logic that processes input is testable.

## Policy and Level

Software is composed of policies at different levels. High-level policies (business rules) change rarely and for important reasons. Low-level policies (formatting, I/O, protocols) change frequently and for trivial reasons.

The architecture should protect high-level policies from changes to low-level details:
- Business rules should not change when you switch databases
- Domain logic should not change when you change the API response format
- Core calculations should not change when you add a new delivery channel

**Level** is determined by distance from inputs and outputs. The farther a policy is from I/O, the higher its level. Entities are the highest level; UI rendering and database queries are the lowest.

## Entities vs Use Cases

This distinction is often confused. The key difference:

**Entities** embody enterprise-wide business rules that exist independently of any application:
- "An order must have at least one line item"
- "Discount cannot exceed 50% of the item price"
- "A user's email must be unique"

**Use Cases** embody application-specific rules that orchestrate entities:
- "When a user places an order: validate stock, apply discount rules, calculate shipping, charge payment, send confirmation"
- "When an admin cancels an order: refund payment, restore stock, notify user"

Entities don't know about use cases. Use cases know about entities and direct them to enforce their rules.

## Crossing Boundaries

When data crosses an architectural boundary:
- Use simple data structures (DTOs, value objects) — not entity objects or framework objects
- The inner layer defines what it needs (input port) and what it returns (output port)
- The outer layer maps its own data structures to/from the boundary's format
- Never pass database rows or HTTP request objects into business logic

This keeps each layer independent and testable. The mapping code lives in the Interface Adapters layer.
