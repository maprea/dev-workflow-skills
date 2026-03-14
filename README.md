# Dev Workflow Skills for Claude Code

A curated collection of Claude Code Agent Skills designed for senior software engineers who want to enforce best practices, maintain high code quality, and accelerate their development workflow.

## Philosophy

These skills encode the methodology of a disciplined engineer: DRY, YAGNI, KISS, functional independence, TDD, clean architecture, and thoughtful design decisions. Each skill guides Claude Code through a specific phase of the SDLC, ensuring consistent quality without sacrificing speed.

## Skills Overview

### Software Engineering (15 skills)

| Skill | Phase | Purpose |
|-------|-------|---------|
| `feature-planning` | Planning | Break features into well-scoped tasks with acceptance criteria |
| `architecture-design` | Design | Make and document architectural decisions with ADRs |
| `api-design` | Design | Design REST/GraphQL endpoints, contracts, errors, and pagination |
| `data-modeling` | Design | Design schemas, relationships, and migration strategies |
| `tdd-workflow` | Implementation | Red-green-refactor cycle with test-first development |
| `test-suite-design` | Quality | Add comprehensive test suites to existing code, plan test strategy |
| `code-reviewing` | Quality | Structured reviews enforcing principles and best practices |
| `security-audit` | Quality | OWASP Top 10 assessment, auth review, vulnerability scanning |
| `performance-optimization` | Quality | Bottleneck detection, query optimization, caching strategy |
| `refactoring` | Improvement | Systematic code improvement guided by design principles |
| `dependency-management` | Maintenance | Evaluate, audit, and upgrade project dependencies |
| `bug-investigating` | Maintenance | Root cause analysis with structured debugging methodology |
| `git-workflow` | All Phases | Commit messages, PR descriptions, and branching strategy |
| `project-documentation` | All Phases | README, API docs, contributing guides, and changelogs |
| `deployment-checklist` | Release | Pre-deploy verification and release safety checks |

### Design (3 skills)

| Skill | Purpose |
|-------|---------|
| `ui-ux-design` | User flows, screen specs, interaction patterns, loading/error/empty states, responsive strategy |
| `frontend-architecture` | React component hierarchy, state management, design tokens, data fetching, code organization |
| `accessibility-design` | WCAG compliance, semantic HTML, ARIA patterns, keyboard navigation, focus management, screen readers |

### DevOps (3 skills)

| Skill | Purpose |
|-------|---------|
| `containerization` | Dockerfiles, docker-compose, Kubernetes manifests with security and efficiency best practices |
| `cicd-pipeline` | CI/CD pipeline design for GitHub Actions, GitLab CI with quality gates and safe deploys |
| `infrastructure-as-code` | Terraform/IaC modules with state management, security, and environment separation |

### MLOps (3 skills)

| Skill | Purpose |
|-------|---------|
| `ml-experiment-tracking` | Experiment design, reproducibility, tracking with MLflow/W&B, model registry |
| `ml-pipeline-design` | Training pipelines, data validation, feature engineering, continuous training |
| `ml-model-deployment` | Model serving, drift detection, monitoring, safe rollout strategies |

### Evaluation & Monitoring (2 skills)

| Skill | Purpose |
|-------|---------|
| `observability-design` | SLI/SLO/SLA design, error budgets, OpenTelemetry, structured logging, alerting, dashboards |
| `test-data-strategy` | Test data factories, synthetic data, property-based testing, boundary analysis, contract testing, GDPR-safe data |

### Project Management — Agile (5 skills)

| Skill | Purpose |
|-------|---------|
| `project-proposal` | Business case, scope, budget estimate, risk assessment, go/no-go decision documents |
| `prd-writing` | Lightweight agile PRDs and technical RFCs for stakeholder alignment |
| `effort-estimation` | Story points, t-shirt sizing, three-point estimation, capacity planning, budget forecasting |
| `metrics-and-okrs` | OKR design, KPI definition, DORA metrics, success measurement |
| `retrospective` | Sprint retros, project post-mortems, incident post-mortems with blameless culture |

## Installation

### Per-project (recommended for teams)
```bash
cp -r skills/* your-project/.claude/skills/
git add .claude/skills/
git commit -m "feat: add dev workflow skills for Claude Code"
```

### Global (personal use across all projects)
```bash
cp -r skills/* ~/.claude/skills/
```

## Skill Architecture

Each skill follows the progressive disclosure pattern:

```
skill-name/
├── SKILL.md              # Entry point: metadata + core workflow (< 500 lines)
├── references/            # Deep-dive docs loaded on demand
│   └── principles.md     # Domain-specific guidelines
├── templates/             # Output templates
│   └── template.md       # Structured output formats
└── scripts/               # Utility scripts (optional)
    └── validate.sh        # Validation helpers
```

## Design Principles

1. **Concise over verbose** — Claude is smart; only add what it doesn't already know
2. **Progressive disclosure** — SKILL.md is the map; reference files are the territory
3. **Appropriate freedom** — Strict where fragile, flexible where creative
4. **Feedback loops** — Validate-fix-repeat for quality-critical operations
5. **Composable** — Skills can be used independently or combined in workflows

## Evaluation Strategy

Each skill includes an `evals/` directory with test scenarios:

```json
{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 1,
      "prompt": "Realistic user prompt",
      "expected_output": "Description of what good looks like",
      "assertions": ["Specific verifiable criteria"]
    }
  ]
}
```

## License

MIT
