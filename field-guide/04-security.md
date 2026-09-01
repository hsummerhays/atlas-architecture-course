# Field Guide 04 — Security

> **Chapter Reference:** [Chapter 4 — Security](../course/chapter-04-security.md)  
> **ADR:** [ADR-0005 — Managed Identity, Resource Scoping, and Automation Governance](../adr-examples/ADR-0005-managed-identity-and-secret-handling.md)  
> **Exercise:** [Exercise 4 — Threat-Model Atlas](../exercises/exercise-04-threat-model-atlas.md)

---

## 1. Core Principle
> **Security is architecture, not an authentication add-on. Establish identity, derive trusted context, enforce authorization at the resource boundary, grant least-privilege workload identities, and strictly separate business-runtime and automation-control planes.**

---

## 2. 30-Second Elevator Pitch
"Atlas enforces security across four fundamental questions: *Who are you?* (JWT Authentication), *What may you do?* (Role-scoped Authorization), *What may you access?* (Resource-level Tenant Scoping), and *How are credentials handled?* (Cloud Managed Identities & Vaults). We treat tenant isolation as an architectural invariant that survives controllers, repositories, messages, and logs. We maintain strict separation of duty between the shipping runtime data plane and the engineering agent automation plane—ensuring autonomous AI agents can propose pull requests but can never approve, merge, or deploy their own code."

---

## 3. The Whiteboard Sketch

```text
[ External Request ] ──(JWT Token)──► [ Edge Security Gateway ]
                                                │ 1. Validate Sig, Issuer, Expiry
                                                ▼
┌─────────────────────────────────────────────────────────────┐
│ Application Boundary: TenantContext (Immutable Authority)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ 2. Scoped Query (WHERE tenant_id = :ctx)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Shipping Data Plane (Runtime Pod)                           │
│  ├── IAM Role: IRSA (Only access to S3/SQS shipping assets) │
│  └── Dynamic Secret Resolution (carrier_configs.secret_arn) │
└─────────────────────────────────────────────────────────────┘
                               ▲
                 [ HARD TRUST BOUNDARY ]
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Engineering Agent Control Plane (CI / Automation)           │
│  ├── IAM Role: Scoped to GitHub Branch Creation Only        │
│  └── Guardrail: Explicitly Forbidden to Approve/Merge PRs   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** Atlas operates as a multi-tenant platform managing sensitive shipment manifests, payment tokens, and carrier OAuth secrets.
- **The Threat Landscape:**
  1. *Tenant IDOR Attack:* An attacker attempts to guess another customer's UUID via `GET /api/v1/shipments/{uuid}`.
  2. *Secret Exfiltration:* A compromised container tries to dump static API keys and database credentials from environment variables.
  3. *Agent Supply-Chain Escalation:* An autonomous AI agent gets compromised via prompt injection and tries to push a backdoor to production.

---

## 5. Diagram & Boundary Map
- **Diagram:** [Security Architecture & Trust Boundaries](../diagrams/security-trust-boundaries.svg)
- **Edge Boundary:** Validates JWT signature, maps claims to `TenantContext`.
- **Resource Boundary:** Repositories enforce `WHERE id = :id AND tenant_id = :tenant_id`.
- **Secret Boundary:** Cloud Managed Identities (AWS IRSA / Azure Workload Identity) resolve dynamic vault ARNs; no static secrets in `.env` or manifests.
- **Governance Boundary:** Separation of duties between developer agents and release pipelines.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Zero Tenant Data Leaks:** Multi-tenant boundaries are enforced at the database query and repository layer, preventing IDOR. | **Developer Friction & Query Discipline:** Every database query, cache key, and event payload must include and validate `tenant_id`. |
| **Drastically Reduced Blast Radius:** A compromised shipping pod cannot access agent keys, CI pipelines, or cloud root credentials. | **Infrastructure Complexity:** Requires configuring cloud IAM roles for service accounts (IRSA), secret vault policies, and OIDC federation. |
| **Supply-Chain & Agent Integrity:** Mandatory human review and automated fitness gates prevent rogue autonomous deployments. | **Release Latency:** Eliminates fully autonomous continuous deployment for agent-generated code. |

---

## 7. 2-Minute Architectural Defense

### Context
"In multi-tenant SaaS systems, teams often rely on UI filtering or a single shared superuser database connection string, leading to catastrophic tenant data leaks."

### Decision
"Atlas enforces resource-level tenant authorization in all repositories, short-lived cloud managed identities (IRSA), dynamic secret resolution via ARNs, and hard plane separation between shipping runtime and agent automation (ADR-0005)."

### Tradeoffs Accepted
"We accept the operational overhead of managing fine-grained cloud IAM roles, vault policies, and mandatory multi-tenant query structures to guarantee zero cross-tenant contamination and eliminate static secret storage."

### Alternatives Rejected
1. *Global Tenant-Blind Queries with Filter in Memory:* Rejected because any unhandled code exception or missed filter exposes private tenant data.
2. *Shared Atlas Service Account / Secret Bundle:* Rejected because compromising the runtime container immediately grants access to GitHub, CI/CD, and all cloud resources.
3. *Autonomous Agent Self-Deployment:* Rejected because separating code proposal from code approval is a non-negotiable security invariant.

### Revisit Trigger
"Revisit if Atlas introduces dedicated per-tenant physical database instances (database-per-tenant isolation) for enterprise healthcare/defense clients."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "Why is `SELECT * FROM shipments WHERE id = :id` an architectural security failure in a multi-tenant system?"
- **Strong Answer:** "Because it relies on identifier secrecy rather than authorization. If an attacker discovers or guesses a valid UUID (Insecure Direct Object Reference - IDOR), the system returns another tenant's private data. Every query must enforce ownership: `WHERE id = :id AND tenant_id = :authenticated_tenant_id`, returning HTTP 404/403 if ownership fails."

### Q2: "Why can't our AI coding agent have permissions to auto-merge pull requests if all CI tests pass?"
- **Strong Answer:** "Separation of duties. An entity that generates a code change cannot be the entity that approves it. If an agent is targeted by prompt injection or model hallucination, automated tests might not catch a subtle logical backdoor. Independent verification (human review + static architecture fitness functions) is an essential security control."

### 🚩 Common Interview Pitfalls
- ❌ **Confusing Authentication with Authorization:** Assuming a user with a valid JWT is allowed to view any resource in the system.
- ❌ **Storing Static Secrets in Code or Manifests:** Hardcoding carrier API keys or GitHub tokens in `application.yml` or Kubernetes deployment specs.
- ❌ **Relying on Perimeter-Only Security:** Assuming that because a service is inside a private VPC, input validation and tenant authorization checks are unnecessary.

---

**Deep dive:** [Chapter 4 — Security](../course/chapter-04-security.md) · [ADR-0005](../adr-examples/ADR-0005-managed-identity-and-secret-handling.md) · [Exercise 4](../exercises/exercise-04-threat-model-atlas.md)
