# Field Guide 08 — Evolutionary Architecture

> **Chapter Reference:** [Chapter 8 — Evolutionary Architecture](../course/chapter-08-evolutionary-architecture.md)  
> **ADR:** [ADR-0008 — Automated Architectural Fitness Functions in CI/CD](../adr-examples/ADR-0008-architectural-fitness-functions.md)  
> **Exercise:** [Exercise 8 — Evolve Atlas Safely](../exercises/exercise-08-evolve-atlas-safely.md)

---

## 1. Core Principle
> **Evolutionary architecture is not architecture without a plan; it is architecture designed to change safely over time, guided by evidence and protected by automated fitness functions.**

---

## 2. 30-Second Elevator Pitch
"In live enterprise systems, software cannot stop running for major architectural changes. Atlas evolves safely without maintenance windows by using the **Expand-and-Contract (Parallel Run) Pattern** for database schemas and API contracts: we expand capabilities additively, deploy **Tolerant Readers**, migrate data/traffic asynchronously with shadow verification, and contract the old path only after evidence proves it is dead. To prevent architectural decay and dependency drift over time, we enforce automated **ArchUnit Fitness Functions** in CI/CD that fail builds if code violates package boundaries, security rules, or dependency directions."

---

## 3. The Whiteboard Sketch

```text
Phase 1: EXPAND (Additive Change)
┌──────────────────────────────────────────────┐
│ Schema/Code: Add new column `secret_arn`     │
│ Tolerant Reader: Reads `secret_arn` ?? `token`│
└──────────────────────┬───────────────────────┘
                       │ Rolling deploy v1.1 (Zero downtime)
                       ▼
Phase 2: MIGRATE (Dual-Run / Backfill)
┌──────────────────────────────────────────────┐
│ Background Job: Backfills secrets to Vault   │
│ Shadow Reads: Telemetry verifies 100% parity │
│ Switch Authority: Code writes/reads new path │
└──────────────────────┬───────────────────────┘
                       │ Verify zero traffic on old path
                       ▼
Phase 3: CONTRACT (Cleanup & Guardrails)
┌──────────────────────────────────────────────┐
│ Schema/Code: DROP COLUMN `auth_token`        │
│ Fitness Function: CI test fails if old field │
│                   is ever referenced again   │
└──────────────────────────────────────────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** Atlas must migrate 450 enterprise tenants storing plaintext carrier credentials in `carrier_configs.auth_token` to dynamic AWS Secrets Manager references `carrier_configs.secret_arn` with zero downtime.
- **The Big-Bang Anti-Pattern:** Shutting the platform down for a 4-hour Saturday maintenance window to drop columns and deploy new code simultaneously.
- **Atlas Resolution:** Three-phase Expand-and-Contract migration with automated ArchUnit fitness test enforcement.

---

## 5. Diagram & Boundary Map
- **Diagram:** [Evolutionary Architecture Feedback Loop](../diagrams/evolutionary-architecture-loop.svg)
- **Fitness Function Boundary:** Automated CI test suite (`AtlasArchitectureTests`) enforcing architectural rules.
- **Compatibility Budget Boundary:** Old schema and API routes are maintained across rolling deployments with explicit deprecation windows.
- **Ownership Boundary:** Clear team accountability for domain contracts, fitness functions, and decommissioning legacy paths.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Zero-Downtime Releases:** Continuous deployments proceed 24/7 without scheduled maintenance windows. | **Temporary Dual-Path Complexity:** Application code must act as a tolerant reader supporting both old and new representations during migration. |
| **Drift Prevention:** Automated fitness functions catch layer violations and forbidden coupling in pull requests before merge. | **CI Test Maintenance:** ArchUnit rules must be updated deliberately when architecture changes. |
| **Controlled Rollback:** If a migration phase exhibits regressions, traffic switches back instantly without data corruption. | **Migration Lifecycle Overhead:** Requires tracking compatibility budgets and executing dedicated cleanup phases. |

---

## 7. 2-Minute Architectural Defense

### Context
"When evolving core database schemas or third-party provider interfaces, teams often attempt big-bang cutovers during maintenance windows, risking catastrophic deployment failures."

### Decision
"Atlas mandates the **Expand-and-Contract Pattern** and automated **Architectural Fitness Functions** in CI/CD (ADR-0008). We make additive schema changes, release tolerant readers, backfill data asynchronously, switch authority, and drop legacy columns only after verified contract phases."

### Tradeoffs Accepted
"We accept the temporary code complexity of maintaining parallel paths during migrations in exchange for zero downtime, zero customer disruption, and automated protection against architectural erosion."

### Alternatives Rejected
1. *Big-Bang Maintenance Window Cutover:* Rejected because scheduled downtime breaks enterprise SLAs and rolling back a failed big-bang database migration is extremely high risk.
2. *Relying on Wiki Pages and Architecture Review Boards:* Rejected because manual guidelines erode within months; only automated, executable CI guardrails prevent dependency drift.

### Revisit Trigger
"Revisit when introducing database-per-tenant architectures where tenant schemas can be migrated independently in isolated batches."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "What is an architectural fitness function, and how does it differ from a unit or integration test?"
- **Strong Answer:** 
  - **Unit Test:** Verifies that a specific method or class logic works correctly (`Shipment.calculateWeight() == 500`).
  - **Integration Test:** Verifies that two physical components interact correctly (`PostgresRepository` saves and queries a row).
  - **Fitness Function:** Verifies that the system continues to exhibit an **intended architectural property** across the entire codebase (e.g., an ArchUnit test asserting that *'No classes in `domain` may import classes from `adapters` or `infrastructure`'*, or verifying that *'Shipping manifests do not contain agent secrets'*).

### Q2: "Why is a migration plan without a deletion plan incomplete?"
- **Strong Answer:** "Compatibility mechanisms (temporary adapters, fallback flags, dual-read logic) represent architectural debt. If an exit condition and deletion phase are not scheduled, temporary code becomes permanent legacy baggage, increasing cognitive load and slowing down all future development. Every expand phase must have an explicit contract phase."

### 🚩 Common Interview Pitfalls
- ❌ **Proposing Big-Bang Database Migrations:** Recommending scheduled maintenance windows to alter live production tables.
- ❌ **Ignoring Application-Level Dual-Write Hazards:** Writing to both old and new databases without transactional atomicity or reconciliation, causing data divergence.
- ❌ **Treating Architecture as a Finished Destination:** Assuming the initial system diagram is permanent and failing to plan for schema/contract evolution.

---

**Deep dive:** [Chapter 8 — Evolutionary Architecture](../course/chapter-08-evolutionary-architecture.md) · [ADR-0008](../adr-examples/ADR-0008-architectural-fitness-functions.md) · [Exercise 8](../exercises/exercise-08-evolve-atlas-safely.md)
