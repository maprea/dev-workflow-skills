# Deployment Repo Structure Template

Use this template to scaffold a deployment repo. Choose the tier that matches your scale and adjust to fit.

## Lightweight Tier Scaffold

```bash
#!/bin/bash
# scaffold-lightweight.sh — Create a lightweight deployment repo

REPO_NAME="${1:-deployment-repo}"
mkdir -p "$REPO_NAME"/{tests/e2e,docs,scripts}

# Version pins
cat > "$REPO_NAME/.versions.env" << 'EOF'
# Service versions — the compatibility lock
# Update via: make bump-<service> VERSION=vX.Y.Z
API_VERSION=v0.1.0
FRONTEND_VERSION=v0.1.0
REGISTRY=ghcr.io/your-org
EOF

# Environment template
cat > "$REPO_NAME/.env.example" << 'EOF'
# Copy to .env and customize for local dev
POSTGRES_USER=devuser
POSTGRES_PASSWORD=devpass
POSTGRES_DB=app_dev
EOF

# Docker Compose
cat > "$REPO_NAME/docker-compose.yml" << 'EOF'
# Load service versions from .versions.env
# Usage: docker compose --env-file .versions.env up

services:
  api:
    image: ${REGISTRY}/api:${API_VERSION}
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      retries: 3

  frontend:
    image: ${REGISTRY}/frontend:${FRONTEND_VERSION}
    ports:
      - "3000:3000"
    environment:
      API_URL: http://api:8000
    depends_on:
      api:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    env_file: .env
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 5s
      retries: 5

volumes:
  pgdata:
EOF

# Makefile
cat > "$REPO_NAME/Makefile" << 'MAKEOF'
.PHONY: up down test logs setup health

up:                          ## Start all services
	docker compose --env-file .versions.env up -d

down:                        ## Stop all services
	docker compose down

test:                        ## Run E2E tests against running services
	cd tests/e2e && npm test

logs:                        ## Tail all logs
	docker compose logs -f

setup:                       ## First-time setup
	cp .env.example .env
	docker compose --env-file .versions.env build
	$(MAKE) up
	@echo "System is starting. Run 'make health' to check status."

health:                      ## Check all services are healthy
	docker compose ps

bump-%:                      ## Bump a service version: make bump-api VERSION=v1.2.3
	@if [ -z "$(VERSION)" ]; then echo "Usage: make bump-$* VERSION=vX.Y.Z"; exit 1; fi
	sed -i 's/^$(shell echo $* | tr a-z A-Z)_VERSION=.*/$(shell echo $* | tr a-z A-Z)_VERSION=$(VERSION)/' .versions.env
	@echo "Updated $* to $(VERSION) in .versions.env"
	@echo "Run 'make up && make test' to validate."
MAKEOF

# Gitignore
cat > "$REPO_NAME/.gitignore" << 'EOF'
.env
docker-compose.override.yml
node_modules/
EOF

# README
cat > "$REPO_NAME/README.md" << 'EOF'
# Deployment Repo

Single source of truth for the system's deployment configuration.

## Quick Start

```bash
make setup    # First-time: copies .env, builds, starts services
make up       # Start all services
make test     # Run E2E tests
make down     # Stop all services
```

## Updating Service Versions

```bash
make bump-api VERSION=v1.2.3
make up && make test
git add .versions.env && git commit -m "bump api to v1.2.3"
```

## Adding a New Service

1. Add the service to `docker-compose.yml`
2. Add its version to `.versions.env`
3. Update E2E tests in `tests/e2e/`
4. Document in this README
EOF

echo "Scaffolded $REPO_NAME (lightweight tier)"
```

## Standard Tier Scaffold

Extends lightweight with Helm, contract testing, and environment promotion:

```bash
#!/bin/bash
# scaffold-standard.sh — Extend lightweight with Helm and contracts

REPO_NAME="${1:-deployment-repo}"

# Run lightweight scaffold first, then add:
mkdir -p "$REPO_NAME"/{helm/values,contracts/{apis,events},tests/{e2e,contract}}
mkdir -p "$REPO_NAME"/environments/{dev,staging,production}
mkdir -p "$REPO_NAME"/{ci,infrastructure/terraform,docs/{architecture/adr,runbooks}}

# versions.yaml (replaces .versions.env for standard tier)
cat > "$REPO_NAME/versions.yaml" << 'EOF'
# The compatibility lock — pinned service versions validated together
services:
  api-gateway:
    image: registry.example.com/api-gateway
    version: v1.0.0
  user-service:
    image: registry.example.com/user-service
    version: v1.0.0
  frontend:
    image: registry.example.com/frontend
    version: v1.0.0

validated:
  timestamp: null
  contract_tests: pending
  e2e_tests: pending
EOF

# Per-environment versions
for env in dev staging production; do
  cp "$REPO_NAME/versions.yaml" "$REPO_NAME/environments/$env/versions.yaml"
done

# Helm umbrella chart
cat > "$REPO_NAME/helm/Chart.yaml" << 'EOF'
apiVersion: v2
name: system
description: Umbrella chart for the full system
version: 1.0.0
dependencies:
  - name: api-gateway
    version: "1.0.0"
    repository: "oci://registry.example.com/charts"
  - name: user-service
    version: "1.0.0"
    repository: "oci://registry.example.com/charts"
EOF

echo "Scaffolded $REPO_NAME (standard tier)"
```

## Promotion Template

PR template for environment promotion:

```markdown
## Promotion: [source] -> [target]

### Version changes
<!-- Diff of versions.yaml between environments -->

### Validation
- [ ] Contract tests pass in source environment
- [ ] E2E tests pass in source environment
- [ ] No open incidents related to these versions
- [ ] Rollback plan reviewed (revert this commit)

### Services affected
| Service | Previous | New | Change type |
|---------|----------|-----|-------------|
| api-gateway | v2.3.0 | v2.3.1 | Patch (bug fix) |
| user-service | v1.7.0 | v1.7.0 | No change |
```
