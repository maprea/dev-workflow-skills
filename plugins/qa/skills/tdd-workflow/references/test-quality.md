# Test Quality Checklist

## Contents
- FIRST principles for tests
- Test naming patterns
- Common test smells
- Coverage guidance
- Test doubles guidance

## FIRST Principles

Good tests are:

- **Fast**: Unit tests run in milliseconds. If a test needs a database, it's an integration test.
- **Independent**: Each test sets up its own state and cleans up after itself. No test depends on another test's side effects or execution order.
- **Repeatable**: Same result every time. No reliance on system clock, random values, or external services without deterministic control.
- **Self-validating**: Tests have a boolean outcome (pass/fail). No manual inspection of output needed.
- **Timely**: Written before or alongside the code they test, not as an afterthought.

## Test Naming

Tests are specifications. Their names should be readable by someone who hasn't seen the code.

Pattern: `test_{unit}_{scenario}_{expected_result}`

Examples:
- `test_password_validator_rejects_passwords_shorter_than_8_chars`
- `test_order_total_includes_tax_when_region_is_taxable`
- `test_login_returns_401_when_credentials_are_invalid`

Avoid:
- `test_password_1`, `test_password_2` (meaningless)
- `test_it_works` (what works?)
- `test_function_name` (tests behavior, not functions)

## Common Test Smells

**Test knows too much about implementation**: If changing internal structure (without changing behavior) breaks tests, the tests are coupled to implementation. Assert on outputs and observable side effects, not internal state.

**Fragile tests**: Tests that break when unrelated code changes. Usually caused by over-mocking or testing through too many layers.

**Slow tests**: A single test taking >100ms is suspicious for a unit test. Check for hidden I/O (file system, network, database).

**Test duplication**: Multiple tests asserting the same thing in slightly different ways. Consolidate or parameterize.

**Missing assertion**: A test that does work but never asserts anything. Passes vacuously.

**Logic in tests**: Tests with if/else, loops, or complex setup. Keep tests linear (arrange-act-assert) with no branching.

## Coverage Guidance

- Aim for high **behavior coverage**, not line coverage percentages
- 100% line coverage with shallow assertions is worse than 80% with meaningful tests
- Focus coverage on: business logic, validation, state transitions, error handling
- Acceptable to skip: boilerplate, framework glue, trivial delegation
- Track coverage trends, not absolute numbers — declining coverage is a signal

## Test Doubles

| Type | Purpose | When to Use |
|------|---------|-------------|
| **Stub** | Returns canned answers | When you need to control indirect inputs |
| **Mock** | Verifies interactions | When the side effect IS the behavior (sending email) |
| **Fake** | Working but simplified implementation | In-memory database, fake file system |
| **Spy** | Records calls for later assertion | When you need to verify call patterns |

Rules of thumb:
- Prefer stubs over mocks (test state, not interactions)
- If you need more than 3 mocks in a test, the code under test has too many dependencies
- Never mock what you don't own (wrap third-party code and mock the wrapper)
- Fakes are underused — an in-memory repository is often better than 20 mocked queries
