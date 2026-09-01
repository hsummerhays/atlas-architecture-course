# Exercise 3 — Break the Message Flow

## Scenario
Atlas processes 50,000 shipments per day. When a shipment is booked, downstream systems must react:
- **Tracking Service:** Registers carrier tracking webhooks.
- **Accounting Service:** Posts financial charges to the general ledger.
- **Notification Service:** Dispatches email and SMS receipts to the end customer.

You are conducting a failure-injection drill on the messaging pipeline. You simulate the following four catastrophic points of failure:
1. **Crash during Booking:** The database commits the shipment row, but the server loses power before publishing to the message broker.
2. **Broker Outage:** The AWS SNS/SQS broker is completely unreachable for 25 minutes.
3. **Consumer Duplicate Wave:** The SQS queue redelivers the exact same `ShipmentBooked` message 5 times in 10 seconds to the Accounting consumer.
4. **Poison Message:** A notification payload contains an invalid Unicode character that causes the Notification consumer to throw an unhandled `NullPointerException` on every attempt.

## Your Task
Walk through each failure scenario. Explain how Atlas's messaging architecture guarantees data integrity, prevents duplicate billing, and isolates poison messages without blocking other customers.

## Constraints
1. No dual writes without transactional atomicity.
2. At-least-once delivery must be assumed; exactly-once transport cannot be relied upon.
3. A poison message in notifications must never prevent accounting or tracking events from processing.

## Architecture Questions
1. How does the Transactional Outbox pattern resolve Failure Scenarios 1 and 2?
2. How does an Idempotent Consumer Inbox prevent Scenario 3 from double-charging a customer?
3. How do Dead-Letter Queues (DLQs) and retry thresholds resolve Scenario 4?

## Deliverable
A Failure-Mode Analysis Matrix table:
| Failure Scenario | Immediate System Behavior | Recovery Mechanism | Resulting Business State |
|---|---|---|---|
| 1. Crash after DB commit | ... | ... | ... |
| 2. Broker 25-min outage | ... | ... | ... |
| 3. SQS 5x duplicate redelivery | ... | ... | ... |
| 4. Unhandled Consumer NPE | ... | ... | ... |

## Run-Through Checklist
- [ ] Atomic local transactions protect outbox intent and shipment state together.
- [ ] Deduplication occurs within the consumer's local transaction.
- [ ] Bounded retries ensure poison messages land in DLQs within defined SLAs.

## Discussion / Reflection
Why does separating topic fan-out into dedicated consumer queues prevent a slow accounting consumer from starving high-priority tracking events?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### Failure-Mode Analysis Matrix

| Failure Scenario | Immediate System Behavior | Recovery Mechanism | Resulting Business State |
|---|---|---|---|
| **1. Crash after DB commit** | Application process terminates immediately. | Outbox row exists in DB with `published = FALSE`. Background publisher process restarts and reads unpublished rows. | Event published successfully upon recovery; zero data loss. |
| **2. Broker Outage (25 min)** | Synchronous bookings succeed; outbox publisher logs connection errors and backs off. | Events accumulate durably in PostgreSQL `outbox` table. When broker recovers, publisher drains queue in order. | Booking availability unaffected; downstream reactions converge with ~25 min eventual consistency delay. |
| **3. Duplicate Delivery (5x)** | SQS delivers message 5 times across worker threads. | 1st thread inserts `message_id` into `inbox` table and commits accounting ledger. Threads 2–5 detect unique constraint violation on `message_id` and acknowledge (ACK) without executing financial charge. | Exactly one financial ledger entry created; zero duplicate billing. |
| **4. Poison Message in Notifications** | Notification worker throws NPE on message processing. | SQS redrive policy retries with exponential backoff up to max receive count (e.g., 3). After 3 failures, message moves to `Notification_DLQ`. Worker continues processing subsequent queue messages. | Dedicated DLQ alerts on-call engineer; other notifications and tracking/accounting queues continue uninterrupted. |

*(Reference: [Diagram: Outbox & Message Flow](../diagrams/outbox-message-flow.svg), [ADR-0003](../adr-examples/ADR-0003-transactional-outbox.md), [ADR-0004](../adr-examples/ADR-0004-idempotent-message-consumption.md))*
</details>
