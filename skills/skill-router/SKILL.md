---
name: skill-router
description: "Entry point and dispatcher for the dev-workflow skills library. Use when starting substantial software work or unsure which skill fits — planning, architecture, design, implementation, testing, debugging, review, refactoring, security, deployment, incidents, or PM docs. Routes to the right skill and shows the Golden Path workflow chains."
model: haiku
allowed-tools: Read, Grep, Glob
---

# Skill Router

This project installs the **dev-workflow skills library** — a set of structured
SDLC workflows. This skill is the map. Use it to pick the right skill quickly,
then hand off and get out of the way.

## The soft rule

Before substantial software work — planning a feature, making a structural
decision, implementing, debugging, reviewing, or shipping — **check whether a
dedicated skill applies**, and invoke it. The skills encode the *how* and *why*
of doing each activity well, so you don't have to re-derive them.

This is a nudge, not a gate. Skip the router for trivial, conversational, or
one-off requests where no workflow adds value. **The user's explicit
instructions always take precedence** over any skill — if they say "don't use a
skill" or "just do X", do that.

## How to use this router

1. Match the user's intent to a skill below.
2. If one clearly fits, invoke it directly (don't narrate the routing).
3. If the work spans several phases, follow the relevant **Golden Path** chain.
4. If nothing fits, proceed normally — not everything needs a skill.

## Catalog by SDLC phase

### Plan & Define
- **feature-planning** — break a feature into scoped tasks, acceptance criteria, dependencies
- **prd-writing** — write a PRD / RFC / tech spec to align on the WHAT and WHY
- **project-proposal** — business case / budget / go-no-go before a project starts
- **effort-estimation** — story points, t-shirt sizing, three-point estimates, capacity
- **metrics-and-okrs** — define OKRs, KPIs, success metrics, DORA / engineering health

### Design & Architecture
- **architecture-design** — costly-to-reverse structural decisions, pattern choice, ADRs
- **architecture-documentation** — C4 diagrams, docs-as-code, runtime/infra views
- **api-design** — REST/GraphQL contracts, endpoints, errors, pagination, versioning
- **data-modeling** — schema, relationships, indexes, migration strategy
- **ui-ux-design** — user flows, wireframes, loading/error/empty states, responsive
- **frontend-architecture** — component hierarchy, state management, design tokens
- **accessibility-design** — WCAG, ARIA, keyboard nav, focus, screen readers
- **configuration-strategy** — env config, secrets management, feature-flag hierarchy
- **dependency-impact-analysis** — blast radius of a change *before* implementing
- **dependency-management** — evaluate, audit (CVEs), and upgrade libraries

### Build & Test
- **tdd-workflow** — NEW code, test-first, red-green-refactor
- **test-suite-design** — add tests to EXISTING code, coverage strategy
- **test-data-strategy** — factories, synthetic data, property-based, contract testing
- **git-workflow** — commit messages, PR descriptions, branching strategy
- **project-documentation** — README, contributing guide, changelog, docstrings

### Review & Improve
- **code-reviewing** — structured review enforcing DRY/KISS/YAGNI/SRP & conventions
- **security-audit** — OWASP Top 10, auth/authz, injection, secrets, dependency CVEs
- **performance-optimization** — N+1, algorithmic complexity, caching, bundle size
- **refactoring** — systematic, test-protected code improvement
- **technical-debt-review** — codebase health, hotspots, remediation roadmap

### Diagnose & Fix
- **bug-investigating** — systematic debugging, reproduce → isolate → hypothesize → verify

### Ship & Operate
- **deployment-checklist** — pre-deploy verification and release safety
- **rollback-strategy** — safe rollback plans, irreversible-change detection
- **containerization** — Dockerfiles, docker-compose, Kubernetes manifests
- **cicd-pipeline** — CI/CD pipelines, quality gates (GitHub Actions, GitLab CI)
- **infrastructure-as-code** — Terraform, CloudFormation, Pulumi, CDK
- **deployment-repo** — GitOps polyrepo orchestration, version pinning, promotion
- **gitops-delivery** — ArgoCD / Flux declarative delivery, drift detection
- **observability-design** — SLI/SLO/SLA, OpenTelemetry, structured logging, alerting
- **incident-response** — ACTIVE production incident: triage, mitigate, communicate

### Reflect
- **retrospective** — sprint retros, project / incident post-mortems, action items

### MLOps
- **ml-pipeline-design** — training & data pipelines, feature engineering, orchestration
- **ml-experiment-tracking** — MLflow / W&B / DVC, run comparison, reproducibility
- **ml-model-deployment** — serving, monitoring, drift detection, safe rollouts

## Golden Path workflow chains

When work spans phases, chain skills rather than improvising:

**New feature**
`feature-planning` → `architecture-design` (if structural) → `data-modeling`
(if schema) → `tdd-workflow` → `code-reviewing` → `deployment-checklist`

**Bug / incident**
`incident-response` (if prod is down) → `bug-investigating` → `tdd-workflow`
(regression test) → `deployment-checklist`

**Continuous improvement**
`technical-debt-review` → `refactoring` → `dependency-impact-analysis`
(blast radius) → `test-suite-design` (if coverage is thin)

## When NOT to route

- Pure questions, explanations, or conversation with no workflow component.
- The user named a specific skill or explicitly opted out — follow them.
- Tiny mechanical edits (typo, rename) where a workflow is overhead.
