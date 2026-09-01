# Exercise 9 — Architect a New Capability (Capstone)

## Scenario (Architecture Interview Simulation)
You are the Lead Architect for the Atlas Enterprise Platform. The Chief Product Officer and VP of Engineering come to you with a major strategic initiative:

> *"Our enterprise shippers want real-time event integration with their internal ERPs (SAP, Oracle NetSuite) and warehouse management systems. We need Atlas to provide **Outbound Webhook Subscriptions**.*
>
> *Shippers should be able to register webhook URLs in their Atlas settings and receive instantaneous HTTP `POST` notifications whenever their shipments change state (`ShipmentBooked`, `InTransit`, `OutForDelivery`, `Delivered`, `Exception`).*
>
> *We expect 10,000 active webhooks delivering over 2,000,000 webhook dispatches per day."*

The requirement is intentionally open-ended. You are responsible for leading the architectural design from problem definition to blueprint and operational readiness.

## Your Task
Apply the complete **Architect's Method** learned throughout this course to design the **Atlas Webhook Dispatching Capability**.

## Constraints & Challenges to Address
1. **Hostile / Slow Customer Endpoints:** Customer webhook servers may respond in 50ms, hang for 60 seconds, return 500 Internal Server Errors, or suffer day-long outages. A customer's failing webhook server must NEVER degrade Atlas's core shipping performance or block webhooks destined for other customers.
2. **Security & Payload Verification:** Customers must be able to cryptographically verify that webhook payloads originated from Atlas and were not tampered with or forged by attackers.
3. **Delivery Guarantees & Ordering:** Webhooks must provide at-least-once delivery with exponential retry policies, signature validation, and disablement of permanently failing endpoints (circuit breaking dead endpoints).
4. **Multi-Tenant Isolation:** High-volume tenants sending 100,000 webhooks/hour must not starve low-volume tenants.

## The Architect's Method Deliverables
Structure your comprehensive architecture proposal into six core sections:

### 1. Problem Framing & Actors
- State the business problem, key actors, and quality-attribute scenarios (Latency, Availability, Security, Multi-Tenant Fairness).

### 2. Domain & Boundary Modeling
- Define domain models: `WebhookSubscription`, `WebhookDeliveryAttempt`, `WebhookEvent`.
- Identify transaction boundaries, command/event flows, and ports/adapters.

### 3. Asynchronous Architecture & Fault Isolation
- Design the dispatch pipeline: Message Broker topic subscription ➔ Dedicated Webhook Dispatcher ➔ Bounded Retries ➔ Dead-Letter Queue / Auto-Disablement.
- Detail how slow/failing customer endpoints are isolated using Bulkheads, Timeouts, and Circuit Breakers.

### 4. Security & Cryptographic Verification
- Design HMAC-SHA256 payload signing with shared secrets and timestamp headers to prevent replay attacks and payload tampering.

### 5. Observability, Telemetry & SLOs
- Define SLIs/SLOs (e.g., 99% of webhooks delivered within 5 seconds of domain event occurrence).
- Detail structured log dimensions (`tenant_id`, `subscription_id`, `http_status`, `duration_ms`, `attempt_number`).

### 6. Architectural Decision Record (ADR)
- Draft a new **ADR-0009: Webhook Delivery Architecture & Security** summarizing Context, Decision, Alternatives Considered (e.g., synchronous HTTP calls vs. dedicated serverless/worker dispatch queue), and Consequences.

## Run-Through Checklist
- [ ] Uses asynchronous decoupled workers (never dispatching webhooks inside the synchronous shipment transaction).
- [ ] Enforces HMAC-SHA256 signing and timestamp replay defense.
- [ ] Provides multi-tenant queue fairness and auto-disabling for dead endpoints after 24 hours of 100% failure.
- [ ] Formulates a complete, interview-grade ADR.

## Discussion / Reflection
In an architecture review, the VP of Product asks: *"Why can't we just write a simple `HttpClient.post(webhookUrl, json)` directly in the shipment event listener?"* How do you explain the catastrophic risks of thread starvation, unmanaged retries, and coupling to customer uptime?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### Architectural Blueprint Summary for Webhook Subscriptions

#### 1. Architecture Flow
```text
Shipment Transaction Commits
         ↓
Outbox Publisher emits ShipmentBooked
         ↓
SNS Topic Fan-Out
         ↓
Dedicated Webhook SQS Queue
         ↓
Webhook Dispatch Service (Worker Pool)
         ↓
Query Tenant Subscriptions for Event Type
         ↓
Generate HMAC-SHA256 Signature Header
         ↓
Outbound HTTP POST (Strict 3.0s Timeout)
 ├── Success (2xx) ➔ Record WebhookDelivery Log
 └── Failure (5xx / Timeout) ➔ Retry with Exponential Backoff + Jitter
         ↓
After 5 Failures ➔ Move to Webhook DLQ & Increment Tenant Endpoint Failure Counter
(If 100% failure for 24h ➔ Auto-suspend subscription & notify tenant admin)
```

#### 2. Security: HMAC-SHA256 Payload Signing
Headers sent to customer webhook endpoints:
- `X-Atlas-Signature: sha256=52f92f48...` (HMAC-SHA256 of `timestamp + "." + payload` using tenant's webhook signing secret).
- `X-Atlas-Timestamp: 1725178920` (Customer rejects requests older than 5 minutes to eliminate replay attacks).
- `X-Atlas-Event-Id: evt-891024` (Customer deduplication key).

#### 3. Fault Isolation & Fairness
- **Bulkheads:** Each worker pod handles maximum 50 concurrent outbound HTTP requests.
- **Strict Timeouts:** 3.0s read timeout.
- **Fairness:** High-volume tenants dispatch to partitioned SQS FIFO queues with `MessageGroupId = tenant_id` to prevent single-tenant queue hoarding.

#### 4. Architecture Decision Record (ADR-0009 Summary)
- **Decision:** Asynchronous worker queue dispatch with HMAC signing and auto-suspension circuit breaking.
- **Alternatives Rejected:** Synchronous inline dispatch (destroys platform availability); customer-facing serverless functions (high cost and complex tenant key management).
- **Consequences:** Near-zero impact on core shipping availability; robust, verifiable event delivery for enterprise shippers.

*(Reference: [Diagram: The Architect's Method Process Flow](../diagrams/architects-method.svg), [Chapter 9](../course/chapter-09-the-architects-method.md))*
</details>
