# Code Review Checklist

## Contents
- Design principles checklist
- Security checklist
- Testing checklist
- Common patterns to flag
- Language-specific patterns

## Design Principles Checklist

### DRY (Don't Repeat Yourself)
Flag when you see:
- Same logic in multiple places (even if slightly different — the variations often indicate a missing abstraction)
- Copy-pasted code blocks with minor modifications
- Same validation rules implemented in multiple layers without a shared source

Don't flag:
- Similar code that represents genuinely different concepts (false DRY is worse than repetition)
- Test code that repeats setup (test readability trumps DRY)

### KISS (Keep It Simple, Stupid)
Flag when you see:
- Abstraction without a second consumer (premature abstraction)
- Design patterns used where a simple function would suffice
- Complex type gymnastics when a straightforward type would work
- Nested ternaries or complex boolean expressions that need a comment to understand
- Over-engineered configuration when values could be constants

### YAGNI (You Aren't Gonna Need It)
Flag when you see:
- Unused parameters, methods, classes, or exports
- Configuration for hypothetical future features
- Abstraction layers "in case we swap implementations"
- Generic solutions for a problem that currently has one case
- Comments like "we might need this later"

### SRP (Single Responsibility Principle)
Flag when you see:
- Functions longer than ~30 lines (not a hard rule, but a signal)
- Functions that do AND/THEN logic: "validate AND save AND notify"
- Classes with methods that use disjoint subsets of the class's fields
- Files that are the go-to place for "anything related to X"
- Mix of business logic and I/O in the same function

### Functional Independence
Flag when you see:
- Modules reaching into other modules' internals
- Shared mutable state between components
- Functions that require knowledge of the caller's context
- Temporal coupling (function A must be called before function B with nothing enforcing this)

## Security Checklist

- [ ] User input is validated/sanitized before use
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] Auth checks are present on protected endpoints
- [ ] Sensitive data is not logged or exposed in error messages
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] File paths are validated (no path traversal)
- [ ] Rate limiting considered for public endpoints
- [ ] CORS configuration is explicit, not wildcard

## Testing Checklist

- [ ] New behavior has corresponding tests
- [ ] Tests cover the happy path
- [ ] Tests cover at least one error/edge case
- [ ] Tests are independent (no shared mutable state)
- [ ] Test names describe the behavior being tested
- [ ] No logic in tests (no if/else, no loops)
- [ ] Mocks/stubs are used appropriately (not over-mocked)
- [ ] Integration tests exist for cross-boundary interactions

## Common Patterns to Flag

**Boolean blindness**: A function taking multiple boolean parameters. Prefer named options or enum types.

**Stringly typed**: Using strings where enums, constants, or types would prevent errors at compile time.

**Train wreck**: Long method chains like `user.getProfile().getAddress().getCity().toLowerCase()`. Each dot is a coupling point.

**Primitive obsession**: Passing raw strings/numbers when a domain type (EmailAddress, Money, UserId) would add safety and clarity.

**Feature envy**: A method that uses more data from another class than from its own. The method probably belongs in the other class.

**Shotgun surgery**: One logical change requires modifications across many files. Indicates poor encapsulation.

## Language-Specific Patterns

These are loaded contextually based on the codebase language. If reviewing:

- **JavaScript/TypeScript**: Watch for `any` types, missing null checks, callback hell, missing async error handling, loose equality (== vs ===)
- **Python**: Watch for mutable default arguments, bare except clauses, circular imports, missing type hints on public APIs
- **Go**: Watch for ignored errors, goroutine leaks, missing context propagation, sync issues
- **Rust**: Watch for unnecessary clones, unwrap in non-test code, missing error context
- **Java**: Watch for null returns without Optional, checked exception abuse, mutable shared state
