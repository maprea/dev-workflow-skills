# Version Compatibility in Polyrepo Architectures

## Semantic Versioning as the Compatibility Contract

Each app repo must follow semver strictly — it's the language the deployment repo uses to reason about compatibility:

- **MAJOR** (v2.0.0): Breaking changes to the service's external interface (API contracts, event schemas, shared database schemas). Consumers MUST update.
- **MINOR** (v1.3.0): New functionality, backward-compatible. Consumers MAY update to use new features.
- **PATCH** (v1.2.4): Bug fixes, no interface changes. Consumers SHOULD update.

**What counts as the "external interface":**
- REST/gRPC API request and response shapes
- Published event schemas (message payloads)
- Shared database tables that other services read
- Configuration contracts (expected environment variables, feature flags)
- CLI interfaces consumed by other tools

**Versioning enforcement in app repos:**
- Tag releases with `vMAJOR.MINOR.PATCH` in git
- CI publishes Docker images tagged with the git tag
- Breaking change detection should be automated where possible (OpenAPI diff, schema registry compatibility checks)

## The Compatibility Lock

The deployment repo's `versions.yaml` is a compatibility lock — it records version combinations that have been validated together.

### Structure

```yaml
# versions.yaml
services:
  api-gateway:
    image: registry.example.com/api-gateway
    version: v2.3.1
    min_compatible:
      user-service: ">=v1.5.0"
      billing-service: ">=v3.0.0"
  user-service:
    image: registry.example.com/user-service
    version: v1.7.0
  billing-service:
    image: registry.example.com/billing-service
    version: v3.1.2
  notification-service:
    image: registry.example.com/notification-service
    version: v1.0.4
  frontend:
    image: registry.example.com/frontend
    version: v4.2.0
    min_compatible:
      api-gateway: ">=v2.0.0"

validated:
  timestamp: "2025-01-15T14:30:00Z"
  contract_tests: pass
  e2e_tests: pass
  validated_by: "ci-pipeline-run-1234"
```

### How the lock works

1. Developer bumps `user-service` to `v1.8.0` in the deployment repo (via PR)
2. CI reads `versions.yaml`, checks `min_compatible` constraints
3. CI runs contract tests between all services at their pinned versions
4. CI runs E2E tests against the composed system
5. If all pass: PR is mergeable, `validated` block is updated
6. If any fail: PR is blocked, developer must fix compatibility or coordinate a multi-service bump

### Lightweight alternative (small teams)

For the lightweight tier, a `.env` file serves the same purpose:

```env
# .versions.env — the compatibility lock (lightweight)
API_GATEWAY_VERSION=v2.3.1
USER_SERVICE_VERSION=v1.7.0
BILLING_SERVICE_VERSION=v3.1.2
FRONTEND_VERSION=v4.2.0
```

Referenced by `docker-compose.yml`:

```yaml
services:
  api-gateway:
    image: registry.example.com/api-gateway:${API_GATEWAY_VERSION}
```

## Consumer-Driven Contract Testing

Contract tests are the mechanism that makes version pinning trustworthy. Without them, the compatibility lock records what was *assumed* compatible, not what was *verified*.

### How Pact-style contracts work

1. **Consumer defines expectations**: The frontend team writes a Pact test that says "when I call GET /users/123, I expect a response with `id`, `name`, and `email` fields"
2. **Contract is published**: The contract is stored in a Pact Broker or the deployment repo's `contracts/` directory
3. **Provider verifies**: The user-service CI runs the contract against its actual API — does it satisfy the frontend's expectations?
4. **`can-i-deploy` check**: Before updating the deployment repo's version pins, query the Pact Broker: "is user-service v1.8.0 compatible with frontend v4.2.0?"

### Contract testing in the deployment repo CI

```yaml
# .github/workflows/validate-versions.yml (simplified)
name: Validate Version Compatibility
on:
  pull_request:
    paths: ['versions.yaml']

jobs:
  contract-check:
    steps:
      - name: Read pinned versions
        run: |
          # Parse versions.yaml for all service versions
      - name: Check Pact compatibility
        run: |
          pact-broker can-i-deploy \
            --pacticipant api-gateway --version $API_GW_VERSION \
            --pacticipant user-service --version $USER_SVC_VERSION \
            --to-environment staging
      - name: Run E2E smoke tests
        run: |
          docker compose up -d
          npm run test:e2e
```

### Event schema compatibility

For event-driven services, use a schema registry (Confluent, AWS Glue, or a simple Git-based registry in the deployment repo):

- **Backward compatible**: New consumer can read old producer messages (add optional fields, don't remove fields)
- **Forward compatible**: Old consumer can read new producer messages (ignore unknown fields)
- **Full compatible**: Both directions work — this is the gold standard for event schemas

Store schemas in the deployment repo:

```
contracts/
├── events/
│   ├── user-created.v1.avsc
│   ├── user-created.v2.avsc    # Must be backward-compatible with v1
│   └── order-placed.v1.json
└── apis/
    ├── api-gateway.openapi.yaml
    └── user-service.openapi.yaml
```

CI validates schema evolution on every PR.

## Breaking Change Coordination

When a breaking change is unavoidable (major version bump), the deployment repo coordinates the migration:

### Pattern: Coordinated multi-service bump

```
1. Provider deploys v2 alongside v1 (both endpoints active)
2. Deployment repo PR: bump provider to v2, update consumers to use v2
3. Contract tests verify all consumers work with provider v2
4. E2E tests pass with the new version set
5. Merge and promote through environments
6. After all environments stable: provider removes v1 support
7. Deployment repo PR: bump provider to v2.1 (v1 removed)
```

### Pattern: Expand-contract for shared data

```
1. Expand: Add new column/field alongside old (backward compatible)
2. Deployment repo PR: bump service with migration, all other versions unchanged
3. Migrate: Update consumers one by one to use new field
4. Deployment repo PRs: bump each consumer as it's updated
5. Contract: Remove old field once all consumers migrated
6. Deployment repo PR: bump service with cleanup migration
```

### Version compatibility matrix

For complex systems, maintain an explicit compatibility matrix:

```yaml
# compatibility-matrix.yaml
api-gateway:
  v2.x:
    user-service: ">=v1.5.0, <v3.0.0"
    billing-service: ">=v3.0.0"
  v1.x:
    user-service: ">=v1.0.0, <v2.0.0"
    billing-service: ">=v2.0.0, <v3.0.0"
```

CI uses this matrix to validate that the pinned versions in `versions.yaml` are within the declared compatibility ranges.

## Environment Promotion Workflows

### Git-based promotion (recommended)

Each environment has its own `versions.yaml` (or the deployment repo uses branches/directories per environment):

```
environments/
├── dev/
│   └── versions.yaml       # Latest validated versions
├── staging/
│   └── versions.yaml       # Promoted from dev after E2E pass
└── production/
    └── versions.yaml       # Promoted from staging after approval
```

**Promotion = copying versions.yaml from one environment to the next:**

```bash
# Promote dev to staging
cp environments/dev/versions.yaml environments/staging/versions.yaml
git commit -m "promote: dev version set -> staging"
# PR triggers staging E2E tests
```

### Automated promotion pipeline

```
dev:      Auto-deploy on merge. E2E tests run post-deploy.
staging:  Triggered by "promote to staging" PR. Full E2E + performance tests.
prod:     Triggered by "promote to production" PR. Requires 2 approvals. Canary optional.
```

Rollback at any stage = revert the promotion commit. The previous version set is restored.
