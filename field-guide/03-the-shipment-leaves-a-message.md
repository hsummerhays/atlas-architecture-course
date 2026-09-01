# Field Guide 03 — The Shipment Leaves a Message

> **Chapter Reference:** [Chapter 3 — The Shipment Leaves a Message](../course/chapter-03-events-and-reliability.md)  
> **ADRs:** [ADR-0003 — Transactional Outbox](../adr-examples/ADR-0003-transactional-outbox.md) · [ADR-0004 — Idempotent Message Consumption](../adr-examples/ADR-0004-idempotent-message-consumption.md)  
> **Exercise:** [Exercise 3 — Break the Message Flow](../exercises/exercise-03-break-the-message-flow.md)

---

## 1. Core Principle
> **Preserve the authoritative business fact first, then distribute independent reactions through durable, asynchronous messaging. In distributed systems, rely on at-least-once delivery combined with idempotent consumer processing—never assume exactly-once network transport.**

---

## 2. 30-Second Elevator Pitch
"Atlas separates synchronous shipment booking from downstream reactions (notifications, tracking, accounting intake) to ensure booking availability is never coupled to secondary systems. We prevent dual-write inconsistencies by writing the shipment state and event publication intent to a **Transactional Outbox** within the same local database transaction. A separate publisher relays events to an **SNS topic**, which fans out to dedicated **SQS queues** per consumer. Because distributed brokers provide at-least-once delivery, each consumer maintains an **Idempotent Inbox** to guarantee that duplicate messages never duplicate business effects."

---

## 3. The Whiteboard Sketch

```text
┌──────────────────────────────────────────────┐
│ Local Database Transaction (Atomicity)       │
│  ├── 1. INSERT INTO shipments (...)          │
│  └── 2. INSERT INTO outbox_messages (...)    │
└──────────────────────┬───────────────────────┘
                       │ 3. Polls unpublished rows (pessimistic lock)
                       ▼
             ┌───────────────────┐
             │ Outbox Publisher  │
             └─────────┬─────────┘
                       │ 4. Publish Event (ShipmentBooked)
                       ▼
             ┌───────────────────┐
             │ SNS Fan-Out Topic │
             └────┬─────────┬────┘
                  │         │ 5. Fan-Out to Dedicated Queues
         ┌────────┘         └────────┐
         ▼                           ▼
  ┌──────────────┐            ┌──────────────┐
  │ Tracking SQS │            │Accounting SQS│
  └──────┬───────┘            └──────┬───────┘
         │                           │
         ▼                           ▼
  ┌──────────────┐            ┌──────────────┐
  │Tracking Inbox│            │Acct Inbox    │ (Checks message_id before ledger write)
  └──────────────┘            └──────────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** Booking a shipment creates downstream work: customer emails, tracking webhook registrations, and accounting intake records.
- **The Architectural Hazard (Dual-Write Bug):** If the application updates PostgreSQL and then immediately calls the message broker via HTTP/SDK, a process crash or broker network glitch between steps 1 and 2 results in a booked shipment whose event was never published.
- **Atlas Resolution:** Atomic transactional outbox insertion, asynchronous background publishing, per-consumer queue isolation, and deduplication tables (inbox pattern).

---

## 5. Diagram & Boundary Map
- **Diagram:** [Transactional Outbox & Message Flow](../diagrams/outbox-message-flow.svg)
- **Synchronous Booking Boundary:** Commits `Shipment` aggregate + `OutboxMessageEntity` in PostgreSQL.
- **Publisher Boundary:** Reads unpublished rows, publishes to SNS, marks outbox row as `published = TRUE`.
- **Consumer Boundary:** Consumes SQS message, validates idempotency in `inbox_consumed_events`, executes business reaction, and ACKs message.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Zero Lost Events:** Business state and event intent are 100% atomic in local DB. | **Eventual Consistency:** Downstream systems (accounting/tracking) reflect state with milliseconds-to-seconds of latency. |
| **Booking Availability Decoupling:** SQS/SNS outages or slow email servers never fail the customer booking request. | **Operational Complexity:** Requires running outbox publisher workers, monitoring outbox lag, and managing Dead-Letter Queues (DLQs). |
| **Consumer Fault Isolation:** A poison message crashing notifications does not impact accounting or tracking queues. | **Duplicate Delivery Handling:** Every consumer must implement idempotency stores and deduplication keys. |

---

## 7. 2-Minute Architectural Defense

### Context
"In event-driven architectures, developers often attempt to publish to message brokers directly inside HTTP use-case controllers."

### Decision
"Atlas implements the **Transactional Outbox** pattern (ADR-0003) for publication and **Dedicated SQS Consumer Queues with Idempotent Inboxes** (ADR-0004) for consumption. Booking commits the outbox row locally. A background worker polls with `SKIP LOCKED` and publishes to SNS."

### Tradeoffs Accepted
"We accept eventual consistency and the operational cost of managing outbox publishers and consumer inboxes in exchange for guaranteed event durability and complete isolation of the synchronous booking path from downstream outages."

### Alternatives Rejected
1. *Direct Inline Broker Publishing (Dual-Write):* Rejected because network or process failure between DB commit and broker publish causes silent, unrecoverable data loss.
2. *Two-Phase Commit (2PC / XA Transactions):* Rejected due to severe latency, lock contention, and lack of cloud-native broker support.
3. *Shared Queue for All Consumers:* Rejected because slow or crashing accounting workers would block tracking and notification events.

### Revisit Trigger
"Revisit if native database Change Data Capture (CDC via Debezium/Kafka Connect) is introduced to replace the polling outbox publisher worker without modifying domain code."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "How do you explain: 'The broker delivers a message more than once, yet the business operation is effectively once'?"
- **Strong Answer:** "The broker provides at-least-once transport. If a consumer processes a message and crashes before sending the ACK, SQS redelivers it. The consumer achieves effectively-once semantics by recording the unique `event_id` in an `inbox` table within the same transaction as the business effect. When redelivered, the unique constraint detects the duplicate and ACKs without re-applying the effect."

### Q2: "What happens if the message broker is completely down for 30 minutes?"
- **Strong Answer:** "Shipment bookings proceed normally with zero downtime. Outbox rows accumulate durably in PostgreSQL. The outbox publisher logs connection errors and backs off. When the broker recovers, the publisher drains the backlog in order. Downstream consumers catch up asynchronously."

### 🚩 Common Interview Pitfalls
- ❌ **Claiming Exactly-Once Transport:** Saying "we configured our broker for exactly-once delivery" without explaining consumer idempotency and edge-case failure boundaries.
- ❌ **Dual-Write Vulnerability:** Proposing `db.save(); broker.send();` without transactional outbox or CDC.
- ❌ **Shared Consumer Queues:** Directing multiple distinct business capabilities to read from the same physical queue, causing head-of-line blocking and shared failure domains.

---

**Deep dive:** [Chapter 3 — The Shipment Leaves a Message](../course/chapter-03-events-and-reliability.md) · [ADR-0003](../adr-examples/ADR-0003-transactional-outbox.md) · [ADR-0004](../adr-examples/ADR-0004-idempotent-message-consumption.md) · [Exercise 3](../exercises/exercise-03-break-the-message-flow.md)
