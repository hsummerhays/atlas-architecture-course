# Atlas Architecture Field Guide / Interview Edition

Quick-reference discussion sheets for senior/staff system design reviews and technical interviews, distilled directly from the [Atlas Enterprise Platform Architecture Course v1.0](../course/).

## Purpose & How to Use This Field Guide

The **Atlas Architecture Course** teaches in-depth architectural reasoning across 37,000 words. This **Field Guide** compresses that knowledge into rapid-retrieval 1–2 page discussion sheets designed for:
- **System Design Interviews:** Quick recall of principles, whiteboard flows, 30-second pitches, and 2-minute structured defenses.
- **Architecture Reviews:** Framing tradeoffs, boundary decisions, failure models, and non-negotiables under stakeholder pressure.
- **On-Call & Engineering Leadership:** High-density summaries of invariants, error budgets, and boundary rules.

## Standard Discussion Sheet Format

Every guide follows an identical 8-part quick-retrieval layout:
1. **Core Principle:** The fundamental architectural insight (1–2 sentences).
2. **30-Second Elevator Pitch:** High-impact, concise verbal summary.
3. **The Whiteboard:** The 4–7 essential boxes/arrows to sketch on a board or digital canvas.
4. **The Atlas Scenario:** Concrete business and technical context from the reference platform.
5. **Diagram & Boundary Map:** Visual link and explicit ownership boundaries.
6. **The Central Tradeoff:** Explicit *"What We Buy vs. What We Pay"* balance.
7. **2-Minute Architectural Defense:** Structured walkthrough (Context ➔ Decision ➔ Tradeoffs ➔ Alternatives Rejected ➔ Revisit Trigger).
8. **Interview Questions, Follow-ups & Red Flags:** Staff-level probing questions, model answers, and fatal interview pitfalls.

## Field Guide Directory

| Chapter | Field Guide Sheet | Core Topic | Whiteboard Anchor |
|---|---|---|---|
| **1** | [01 — The Business Problem](01-business-problem.md) | Domain before framework; canonical model vs. provider schemas | Application ➔ Canonical Domain ➔ Adapters ➔ Carriers |
| **2** | [02 — Following a Shipment](02-following-a-shipment.md) | Request path; thin controllers; dependency inversion | Security ➔ Controller ➔ Use Case ➔ Registry ➔ Adapter ➔ DB |
| **3** | [03 — The Shipment Leaves a Message](03-the-shipment-leaves-a-message.md) | Outbox atomicity; at-least-once delivery; consumer idempotency | Local DB+Outbox ➔ Publisher ➔ SNS ➔ SQS Queues ➔ Inboxes |
| **4** | [04 — Security](04-security.md) | AuthN vs. AuthZ; tenant resource boundaries; agent governance | JWT Claims ➔ Resource AuthZ ➔ Workload IAM ➔ Plane Isolation |
| **5** | [05 — Architectural Tradeoffs](05-architectural-tradeoffs.md) | Buying vs. paying; YAGNI; sync vs. async; reversibility | Tradeoff Map: Simplicity vs. Flexibility vs. Resilience |
| **6** | [06 — Failure Is Part of the Architecture](06-failure-is-part-of-the-architecture.md) | Fault containment; retry budgets + jitter; circuit breakers; bulkheads | Timeout ➔ Retry+Jitter ➔ Circuit Breaker ➔ Bulkhead Isolation |
| **7** | [07 — Observability: Understanding a Running System](07-observability.md) | Trace context propagation; golden signals; oldest-message age; SLOs | Request Context ➔ Async Propagation ➔ Golden Signals ➔ SLOs |
| **8** | [08 — Evolutionary Architecture](08-evolutionary-architecture.md) | ArchUnit fitness functions; expand-and-contract migrations; tolerant readers | Fitness Guardrails ➔ Expand ➔ Dual-Read ➔ Contract/Cleanup |
| **9** | [09 — The Architect's Method](09-the-architects-method.md) | The 5-stage loop: Frame ➔ Model ➔ Prove ➔ Observe ➔ Communicate | Problem Framing ➔ Model ➔ Walking Skeleton ➔ Evidence ➔ Views |
