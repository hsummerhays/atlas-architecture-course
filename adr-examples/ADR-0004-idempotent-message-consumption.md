# ADR-0004: Idempotent Message Consumption with Dedicated Consumer Queues

## Status
Accepted

## Context
Message delivery over distributed networks guarantees **at-least-once delivery**, which means duplicate events will inevitably be delivered to downstream consumers. If consumer handlers are non-idempotent, duplicates will cause duplicate billing charges, duplicate email notifications, or corrupted read models. Furthermore, sharing a single queue among multiple distinct consumer types couples independent processing speeds.

## Decision
1. We use **Topic Fan-Out with dedicated SQS queues** for each independent consumer group (e.g., tracking, accounting, notifications).
2. Each consumer implements an **Idempotent Consumer Pattern** using an `inbox` deduplication table or natural idempotency key checked within its local transaction before applying side effects.
3. Terminal consumer failures are routed to a consumer-specific **Dead-Letter Queue (DLQ)** after bounded retries.

## Alternatives Considered
1. **Single Shared Queue for All Consumers:** Multiple consumers pull from the same queue and filter. Rejected because it couples consumer processing rates and complicates retry/DLQ ownership.
2. **Assuming Exactly-Once Transport Delivery:** Relying on broker exactly-once guarantees across end-to-end distributed boundaries. Rejected because network timeouts and consumer retries still generate duplicate application processing.

## Consequences
- **Positive:** Isolates consumer failure blast radius; guarantees idempotent business effects; gives each team ownership of its queue and retry policy.
- **Negative:** Requires inbox table maintenance and storage for message tracking.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in downstream event subscribers.
