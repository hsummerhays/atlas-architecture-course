# ADR-0003: Guaranteed Event Publication via Transactional Outbox

## Status
Accepted

## Context
When a shipment is successfully booked, downstream services (analytics, tracking, email notifications, accounting) must be notified asynchronously via domain events (e.g., `ShipmentBooked`). Performing a database write and publishing directly to a remote message broker as two separate operations lacks atomicity; if the application crashes or the network fails after the DB commit, the event is permanently lost, causing downstream state divergence.

## Decision
We adopt the **Transactional Outbox Pattern**. In the same local database transaction that records the shipment state, the application writes a serialized event record into an `outbox` table. An asynchronous background process polls or streams from the outbox table and guarantees durable dispatch to the message broker.

## Alternatives Considered
1. **Dual Writes (DB write followed by direct broker publish):** Rejected because failure between the two writes causes silent data loss and eventual consistency breakdown.
2. **Two-Phase Commit (2PC / XA Transactions):** Distributed transaction across DB and broker. Rejected due to poor latency, protocol incompatibility, and high operational fragility.

## Consequences
- **Positive:** Guarantees at-least-once event publication without distributed locks; preserves local transaction boundaries.
- **Negative:** Downstream subscribers experience slight asynchronous latency; outbox tables require periodic pruning/compaction.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in `atlas-shipping-app` persistence and outbox publisher module.
