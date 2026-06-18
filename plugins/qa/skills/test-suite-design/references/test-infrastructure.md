# Test Infrastructure Setup

## Contents
- JavaScript/TypeScript (Jest, Vitest)
- Python (pytest)
- Go (testing)
- General CI patterns

## JavaScript/TypeScript

### Jest (mature, feature-rich)

```bash
npm install --save-dev jest @types/jest ts-jest
```

Directory structure (co-located):
```
src/
  services/
    order.service.ts
    order.service.test.ts
  utils/
    format.ts
    format.test.ts
tests/
  integration/
    api.test.ts
  helpers/
    factories.ts
    setup.ts
```

Key config (`jest.config.ts`):
```typescript
export default {
  testMatch: ['**/*.test.ts'],
  setupFilesAfterSetup: ['./tests/helpers/setup.ts'],
  coverageThreshold: {
    global: { branches: 70, functions: 80, lines: 80 }
  }
};
```

### Vitest (fast, ESM-native, Vite-compatible)

```bash
npm install --save-dev vitest
```

Same directory structure and API as Jest, but faster and ESM-first. Prefer Vitest for new projects using Vite, Nuxt, or SvelteKit.

### Mocking

- **jest.mock / vi.mock**: Module-level mocks. Use for replacing imports.
- **jest.spyOn / vi.spyOn**: Spy on existing methods without replacing.
- **MSW (Mock Service Worker)**: Mock HTTP requests at the network level. Better than mocking fetch/axios directly because it tests your actual HTTP client code.

## Python

### pytest (recommended)

```bash
pip install pytest pytest-cov pytest-mock
```

Directory structure:
```
src/
  services/
    order_service.py
tests/
  unit/
    test_order_service.py
  integration/
    test_order_api.py
  conftest.py          # shared fixtures
  factories.py         # test data factories
```

Key config (`pyproject.toml`):
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing"

[tool.coverage.run]
branch = true
```

### Fixtures (conftest.py)

pytest fixtures are powerful — use them for setup/teardown:

```python
@pytest.fixture
def db_session():
    session = create_test_session()
    yield session
    session.rollback()
    session.close()

@pytest.fixture
def authenticated_client(db_session):
    user = create_user(db_session, role="admin")
    client = TestClient(app)
    client.headers["Authorization"] = f"Bearer {create_token(user)}"
    return client
```

Fixtures compose naturally — `authenticated_client` depends on `db_session` and pytest handles the dependency chain.

## Go

### Built-in testing package

```
pkg/
  order/
    service.go
    service_test.go       # co-located, same package
    service_integ_test.go  # integration tests with build tag
```

Key patterns:
- **Table-driven tests**: Go's idiomatic pattern for parameterized tests
- **testify**: Popular assertion and mock library
- **Build tags**: Separate integration tests with `//go:build integration`

```go
func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []Item
        expected float64
    }{
        {"empty cart", []Item{}, 0},
        {"single item", []Item{{Price: 10, Qty: 2}}, 20},
        {"with discount", []Item{{Price: 100, Qty: 1, Discount: 0.1}}, 90},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := CalculateTotal(tt.items)
            assert.Equal(t, tt.expected, got)
        })
    }
}
```

## General CI Patterns

### Minimum viable test pipeline

```yaml
# Run on every PR
test:
  steps:
    - install dependencies
    - run linter
    - run unit tests
    - run integration tests (with test database)
    - report coverage
```

### Test database in CI

- Use a Docker service container (PostgreSQL, MySQL, Redis)
- Apply migrations fresh for each run
- Never share a test database between parallel jobs

### Coverage gates

- Set a coverage floor (e.g., 80%) that fails the build if not met
- More importantly: require new code to have tests (diff-coverage)
- Tools: `diff-cover` (Python), `jest --changedSince` (JS)
