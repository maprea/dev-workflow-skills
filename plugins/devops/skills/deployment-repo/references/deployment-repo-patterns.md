# Deployment Repo Patterns by Scale Tier

## Lightweight Tier (1 team, 2-5 services)

Best for small teams that need coordinated local dev and basic version tracking without Kubernetes complexity.

### Structure

```
deployment-repo/
├── docker-compose.yml           # Full system for local dev
├── docker-compose.override.yml  # Developer-specific overrides (gitignored)
├── .versions.env                # Pinned service versions
├── .env.example                 # Environment template (copy to .env)
├── Makefile                     # Developer commands
├── tests/
│   └── e2e/
│       ├── package.json         # E2E test dependencies
│       └── specs/               # E2E test files
├── docs/
│   ├── architecture.md          # System overview
│   └── local-setup.md           # Getting started guide
└── scripts/
    ├── setup.sh                 # First-time setup (clone repos, build images)
    ├── seed.sh                  # Seed dev database
    └── health-check.sh          # Verify all services are running
```

### Example docker-compose.yml

```yaml
services:
  api:
    image: ${REGISTRY}/api:${API_VERSION}
    build:
      context: ../api-repo          # For local dev with source
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/app
      REDIS_URL: redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      retries: 3

  frontend:
    image: ${REGISTRY}/frontend:${FRONTEND_VERSION}
    build:
      context: ../frontend-repo
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      API_URL: http://api:8000
    depends_on:
      api:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      retries: 3

volumes:
  pgdata:
```

### Example Makefile

```makefile
.PHONY: up down test logs setup

up:                        ## Start all services
	docker compose up -d

down:                      ## Stop all services
	docker compose down

test:                      ## Run E2E tests
	docker compose up -d
	cd tests/e2e && npm test

logs:                      ## Tail all service logs
	docker compose logs -f

setup:                     ## First-time setup
	cp .env.example .env
	docker compose build
	docker compose up -d
	./scripts/seed.sh

bump-%:                    ## Bump a service version: make bump-api VERSION=v1.2.3
	sed -i 's/^$*_VERSION=.*/$*_VERSION=$(VERSION)/' .versions.env
	@echo "Updated $* to $(VERSION). Run 'make test' to validate."
```

### Example .versions.env

```env
API_VERSION=v1.3.2
FRONTEND_VERSION=v2.1.0
REGISTRY=ghcr.io/myorg
```

## Standard Tier (2-3 teams, 5-15 services)

Adds Helm/Kustomize for multi-environment K8s deployments, structured CI, and contract testing.

### Structure

```
deployment-repo/
├── versions.yaml                # System-wide version pins
├── docker-compose.yml           # Local dev orchestration
├── Makefile
├── helm/
│   ├── Chart.yaml               # Umbrella chart
│   ├── values.yaml              # Shared defaults
│   └── values/
│       ├── dev.yaml             # Dev overrides
│       ├── staging.yaml         # Staging overrides
│       └── production.yaml      # Production overrides
├── contracts/
│   ├── apis/                    # OpenAPI specs per service
│   │   ├── user-service.v1.yaml
│   │   └── api-gateway.v2.yaml
│   └── events/                  # Event schemas
│       └── user-created.v1.avsc
├── tests/
│   ├── e2e/
│   └── contract/                # Contract verification tests
├── ci/
│   ├── validate-versions.yml    # Contract + E2E on version bump PRs
│   └── promote.yml              # Environment promotion pipeline
├── environments/
│   ├── dev/
│   │   └── versions.yaml
│   ├── staging/
│   │   └── versions.yaml
│   └── production/
│       └── versions.yaml
├── infrastructure/
│   └── terraform/               # Shared infra (databases, queues, networking)
├── docs/
│   ├── architecture/
│   │   └── adr/                 # Architecture Decision Records
│   ├── runbooks/
│   └── onboarding.md
└── scripts/
```

### Kustomize alternative to Helm

```
deployment-repo/
├── base/
│   ├── api-gateway/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── user-service/
│   └── ...
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml   # Patches: replicas, resource limits, image tags
│   │   └── patches/
│   ├── staging/
│   └── production/
```

## Enterprise Tier (many teams, 15+ services)

Adds ArgoCD/Flux integration, ApplicationSets, automated promotion, and audit infrastructure.

### Structure

```
deployment-repo/
├── versions.yaml
├── argocd/                      # ArgoCD Application definitions
│   ├── app-of-apps.yaml         # Root Application
│   ├── dev/
│   │   └── applications.yaml    # Per-service ArgoCD Applications for dev
│   ├── staging/
│   └── production/
├── helm/
│   ├── charts/                  # Per-service Helm charts (or references to external charts)
│   └── values/                  # Per-environment values
├── contracts/
├── tests/
├── ci/
│   ├── validate-versions.yml
│   ├── promote.yml
│   └── drift-report.yml         # Detect config drift
├── environments/
├── infrastructure/
├── policies/                    # OPA/Gatekeeper policies
├── docs/
└── scripts/
```

### App of Apps pattern (ArgoCD)

```yaml
# argocd/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: system-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/deployment-repo
    targetRevision: main
    path: argocd/production
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Anti-Patterns

**Mixing app source with deployment config**: Leads to infinite CI loops (deploy triggers build triggers deploy). Keep them separate.

**Using `latest` tags instead of pinned versions**: Destroys reproducibility. You can't answer "what was running in production last Tuesday?"

**Per-service deployment repos**: Defeats the purpose. The value is seeing the whole system in one place.

**Manual version tracking** (Slack messages, wiki pages): Will drift from reality within days. The deployment repo IS the tracking system.

**Promoting services independently without testing the set**: Version A of service X might work with version B of service Y in staging but fail with version C that was deployed separately. Always validate the full version set.
