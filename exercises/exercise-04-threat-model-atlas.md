# Exercise 4 — Threat-Model Atlas

## Scenario
Atlas is preparing for SOC2 and ISO 27001 certification. The platform handles multi-tenant customer shipping data, sensitive carrier OAuth client secrets, and developer agent automation (`atlas-agent-platform`).

A security auditor examines the architecture and presents three potential attack vectors:
1. **Tenant Cross-Contamination (IDOR):** An authenticated user belonging to Tenant A guesses the UUID of a shipment belonging to Tenant B and issues an HTTP `GET /api/v1/shipments/{tenantB_uuid}`.
2. **Secret Exfiltration via Compromised Container:** A vulnerable open-source logging library allows remote code execution (RCE) inside a shipping runtime container. The attacker attempts to read carrier API credentials, GitHub deployment tokens, and raw database passwords from environment variables.
3. **Agent Privilege Escalation:** An automated AI coding agent running on the developer platform becomes compromised by prompt injection from an external GitHub issue and generates a malicious PR containing a backdoor, attempting to self-approve and merge the PR to `main` for automatic deployment.

## Your Task
Perform a STRIDE / Trust-Boundary Threat Model on Atlas. Detail the architectural controls that mitigate each attack vector.

## Constraints
1. Multi-tenant isolation must be enforced at the resource level, never relying on UI secrecy.
2. The runtime shipping application must not possess permissions or credentials belonging to CI/CD or agent automation planes.
3. No automated agent may possess authority to approve or deploy its own code changes.

## Architecture Questions
1. How does resource-scoped authorization prevent Insecure Direct Object References (IDOR)?
2. How do cloud managed identities and secret vaults limit the blast radius if an individual application container is compromised?
3. What architectural separation of duty exists between `atlas-shipping-app` and `atlas-agent-platform`?

## Deliverable
A Threat Mitigation Matrix:
- **Threat Vector & Plane**
- **Trust Boundary Crossed**
- **Enforced Architectural Control**
- **Residual Blast Radius**

## Run-Through Checklist
- [ ] Explicit distinction between authentication (who you are) and authorization (what tenant resource you own).
- [ ] Elimination of static credentials in code, `.env`, and deployment manifests.
- [ ] Strict branch protection and non-self-approving guardrails for autonomous agents.

## Discussion / Reflection
Why is "Least Privilege" considered a structural architecture pattern rather than just a security ops checklist?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### Threat Mitigation Matrix

| Threat Vector | Trust Boundary | Enforced Architectural Control | Residual Blast Radius |
|---|---|---|---|
| **1. Tenant IDOR Attack** | Public Internet ➔ API Resource Boundary | `ShipmentRepository` queries always include `WHERE id = :id AND tenant_id = :authenticated_tenant_id`. Authorization check fails with HTTP 404 (or 403), preventing data leak. | Zero data leakage outside authenticated tenant boundary. |
| **2. Container RCE & Secret Theft** | Internal Container Runtime ➔ Secret Store / Cloud Plane | Containers use short-lived AWS IAM Roles for Service Accounts (IRSA). No static secrets stored in environment variables; secrets fetched dynamically from Secrets Manager scoped only to shipping carrier keys. Container has zero IAM access to GitHub, CI/CD, or agent platforms. | Attacker gains access only to runtime memory of that single container pod; cannot access CI/CD, GitHub, or cross-plane secrets. |
| **3. Agent Prompt Injection / Backdoor** | Developer Control Plane ➔ Production Release Plane | Hard separation of duty (ADR-0005, ADR-0009). Agent identity has `repo:write` to branches only. GitHub branch protection requires mandatory human code review + passing automated CI fitness functions. Agent identity is explicitly prohibited from approving PRs or triggering production deployment tags. | Malicious code remains in an unmerged branch; cannot reach `main` or production. |

*(Reference: [Diagram: Security Architecture & Trust Boundaries](../diagrams/security-trust-boundaries.svg), [ADR-0005](../adr-examples/ADR-0005-managed-identity-and-secret-handling.md))*
</details>
