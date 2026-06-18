# Dockerfile Patterns

## Contents
- Node.js patterns
- Python patterns
- Go patterns
- Docker Compose patterns
- Common anti-patterns

## Node.js Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM node:20.11-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20.11-alpine AS production
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["node", "dist/main.js"]
```

## Python Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir poetry
COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt -o requirements.txt --without-hashes
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
COPY . .

# Stage 2: Production
FROM python:3.12-slim AS production
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY --from=builder /app .
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["gunicorn", "app:create_app()", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

## Go (Distroless)

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

FROM gcr.io/distroless/static-debian12
COPY --from=builder /server /server
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```

Go produces a static binary — the final image can be distroless (no shell, no package manager) for a minimal attack surface. Image size: ~10-20 MB.

## Docker Compose for Local Development

```yaml
services:
  app:
    build:
      context: .
      target: builder  # Use the build stage for development
    volumes:
      - .:/app
      - /app/node_modules  # Prevent overwriting container's node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/appdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: npm run dev  # Override CMD for hot-reload

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  pgdata:
```

## .dockerignore Template

```
.git
.github
node_modules
dist
*.log
.env
.env.*
!.env.example
docker-compose*.yml
Dockerfile*
.dockerignore
README.md
docs/
tests/
__pycache__
*.pyc
.pytest_cache
.coverage
```

## Common Anti-patterns

**Running as root**: Every container should run as a non-root user. If the base image runs as root by default, create a user.

**Using `latest` tag**: Tags can be overwritten. Pin to a specific version or SHA digest for reproducibility.

**Installing dev dependencies in production**: Use multi-stage builds. Keep test frameworks, linters, and build tools out of the final image.

**Copying everything before installing deps**: This busts the Docker layer cache on every code change. Copy dependency manifests first, install, then copy application code.

**Large images**: A Node.js app shouldn't be 1.5 GB. Use Alpine bases, multi-stage builds, and .dockerignore. Target: <200 MB for most apps.

**Secrets in build args**: Build args are visible in `docker history`. Use runtime env vars or mounted secrets for sensitive data. Never `ARG DB_PASSWORD`.
