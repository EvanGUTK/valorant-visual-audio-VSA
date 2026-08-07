# Engineering Role Subagents

Fifteen specialized Cursor [custom subagents](https://cursor.com/docs/subagents.md) you can spawn in parallel.

| # | Slash name | Role |
|---|---|---|
| 1 | `/principal-systems-architect` | System design, ADRs, cross-cutting architecture |
| 2 | `/senior-backend-engineer` | APIs, microservices, workers, backend performance |
| 3 | `/senior-frontend-architect` | React/Next/TS, design systems, a11y, CWV |
| 4 | `/senior-ai-llm-engineer` | RAG, agents, vector DBs, LLM evals, MCP |
| 5 | `/senior-devops-engineer` | Terraform, K8s, CI/CD, cloud IaC |
| 6 | `/senior-security-engineer` | OWASP, authn/z, secrets, compliance |
| 7 | `/senior-database-engineer` | Schemas, indexes, migrations, caching |
| 8 | `/senior-sre` | Observability, SLOs, runbooks, resilience |
| 9 | `/senior-qa-engineer` | Unit/integration/E2E, fuzzing, anti-flake |
| 10 | `/senior-technical-product-manager` | Stories, Given-When-Then AC, edge cases |
| 11 | `/senior-mobile-engineer` | iOS/Android / RN/Flutter, offline, push |
| 12 | `/senior-dx-engineer` | Monorepos, linters, Devcontainers, CLIs |
| 13 | `/senior-data-pipeline-engineer` | ETL/ELT, Kafka, warehouses, dbt |
| 14 | `/senior-refactoring-engineer` | Legacy cleanup, patterns, debt reduction |
| 15 | `/senior-integrations-engineer` | Stripe/Twilio/OAuth, webhooks, gateways |

## How multi-agent works in Cursor

- **Custom subagents** are markdown files with a prompt + YAML frontmatter.
- The parent Agent can **auto-delegate** based on each file's `description`, or you can invoke explicitly with `/name`.
- Each subagent gets its **own context window** and can run in **parallel**.
- They are **not** tied to one git fork — scope depends on where the files live (see below).

## Install for EVERY project (recommended)

### Option A — User-level agents (simplest)

Copy the agent files into your user agents directory (applies to all projects on that machine):

```bash
mkdir -p ~/.cursor/agents
cp agents/*.md ~/.cursor/agents/
```

Or, from this repo root:

```bash
mkdir -p ~/.cursor/agents
cp .cursor/agents/*.md ~/.cursor/agents/
# same files live in cursor-roles-plugin/agents/
```

Restart Cursor (or reload the window). Invoke with `/senior-backend-engineer …` etc.

### Option B — Local Cursor Plugin (user scope)

```bash
mkdir -p ~/.cursor/plugins/local
cp -R cursor-roles-plugin ~/.cursor/plugins/local/engineering-role-subagents
```

Then in Cursor: **Customize → Plugins** and confirm it is enabled for your user.

### Option C — Team Marketplace

Publish this folder as a Cursor Plugin and install it from **Dashboard → Plugins → Team Marketplace** at **user** or **required** scope so every teammate gets the roles.

## Install for THIS repo only

The same agents are checked in at `.cursor/agents/`. Anyone cloning this repo gets them automatically for this project. Project agents override user agents when names collide.

## Usage examples

```text
/principal-systems-architect Draft an ADR for UDP audio streaming reliability

Have senior-backend-engineer and senior-security-engineer review this PR in parallel

/multitask Run senior-qa-engineer and senior-sre on the new webhook ingestion path
```

Natural language also works: *"Use the senior-database-engineer subagent to design the clip metadata schema."*
