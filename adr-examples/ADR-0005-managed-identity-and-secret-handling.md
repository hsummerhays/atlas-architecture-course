# ADR-0005: Managed Identity, Resource Scoping, and Automation Governance

## Status
Accepted

## Context
Atlas operates in a multi-tenant cloud environment handling sensitive carrier API credentials, shipment records, and developer automation agents. Hardcoding API secrets or sharing database superuser credentials introduces extreme blast radius and supply-chain risk. Furthermore, granting AI or automation agents unrestrained permissions could allow unverified self-approval and deployment of vulnerable code.

## Decision
1. **Workload Managed Identities:** Atlas runtime containers authenticate to cloud services (databases, queues, secret managers) using short-lived managed identities (e.g., AWS IAM Roles / Azure Managed Identity) instead of static long-lived credentials.
2. **Resource-Scoped Multi-Tenancy:** Tenant authorization is verified at the resource boundary on every request, never inferred from unvalidated client parameters.
3. **Separation of Duty for Automation:** Autonomous engineering agents (`atlas-agent-platform`) run under distinct identities with write permissions limited to creating branches and proposing PRs; agents are strictly prohibited from self-approving, merging, or deploying changes to production.

## Alternatives Considered
1. **Static Shared Secret Files:** Storing credentials in `.env` or deployment manifests. Rejected due to high leakage risk and complex manual rotation.
2. **Single Universal Service Account:** Sharing one IAM role across shipping runtime and CI/CD agents. Rejected because compromise of the agent environment would expose production databases.

## Consequences
- **Positive:** Eliminates static credential leaks; limits lateral movement in security incidents; enforces automated governance over agentic tooling.
- **Negative:** Requires cloud IAM infrastructure configuration and token refresh handling in SDKs.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in CI/CD pipeline policies and runtime deployment manifests; planned direction for dedicated agent container deployment.
