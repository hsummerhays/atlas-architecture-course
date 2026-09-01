# Field Guide 07 — Observability: Understanding a Running System

> **Chapter Reference:** [Chapter 7 — Observability](../course/chapter-07-observability-understanding-a-running-system.md)  
> **ADR:** [ADR-0007 — OpenTelemetry Instrumentation Boundary](../adr-examples/ADR-0007-opentelemetry-instrumentation-boundary.md)  
> **Exercise:** [Exercise 7 — Diagnose the Incident](../exercises/exercise-07-diagnose-the-incident.md)

---

## 1. Core Principle
> **A production system must be designed not only to perform its work, but to explain its behavior. Telemetry without context produces data; telemetry with context produces evidence.**

---

## 2. 30-Second Elevator Pitch
"In Atlas, observability enables evidence-based incident triage by correlating synchronous HTTP calls with asynchronous message flows. We propagate W3C `traceparent` headers, `correlation_id`, `causation_id`, and `tenant_id` across API gateways, transactional outboxes, SNS topics, SQS consumers, and carrier adapters. We monitor golden signals (Latency, Traffic, Errors, Saturation), track **oldest-message age** to instantly detect poison messages and head-of-line blocking in queues, and define customer-centric **SLOs** that measure business workflow completion rather than mere container uptime."

---

## 3. The Whiteboard Sketch

```text
[ Inbound HTTP POST ] ──► (W3C traceparent: trace_id=abc, span_id=001, tenant=T1)
          │
          ▼
┌─────────────────────────┐
│ Shipping API Service    │ ──► Structured Log: {event: "booking_started", trace_id: "abc"}
└─────────┬───────────────┘
          │ (Commit DB + Outbox with trace context)
          ▼
┌─────────────────────────┐
│ Outbox Message Record   │ ──► Outbox Metadata: {trace_id: "abc", causation_id: "cmd_123"}
└─────────┬───────────────┘
          │ (Publisher extracts trace context)
          ▼
┌─────────────────────────┐
│ SNS Topic ➔ SQS Queue   │ ──► Message Attribute: "traceparent"="00-abc-002-01"
└─────────┬───────────────┘
          │
          ▼
┌─────────────────────────┐
│ Accounting Consumer     │ ──► Span: "accounting_intake" (Child of span 002)
└─────────────────────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** An on-call engineer receives an alert: *"Booking error budget burn rate > 5x."*
- **The Telemetry Landscape:**
  - *Public API:* Throughput normal (1,450 req/s), p50 latency 110ms, but p99 latency spikes to 3,850ms.
  - *Carrier Signals:* FedEx/UPS healthy (p95 < 300ms); Carrier-X degraded (p95 = 8.4s, 18% timeouts, circuit breaker tripped 17 times).
  - *Async Queue Signals:* Accounting queue depth 1,240 messages, but **oldest-message age is 46 minutes** with 100% error rate on a specific item (poison message causing head-of-line blocking).

---

## 5. Diagram & Boundary Map
- **Diagram:** [Observability Context & Trace Propagation](../diagrams/observability-correlation.svg)
- **Trace Context Boundary:** W3C Trace Context propagated across HTTP headers and SQS message attributes.
- **Business Identity Boundary:** `ShipmentId` and `TenantId` preserved across logs, traces, and metrics for auditability after trace expiration.
- **Operational Metrics:** RED (Rate, Errors, Duration) for APIs; USE (Utilization, Saturation, Errors) for workers; Queue Depth + Message Age for queues.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Sub-Minute Root Cause Triage:** End-to-end trace correlation immediately pinpoints whether latency is in carrier adapters, database locks, or queue lag. | **Instrumentation & Storage Overhead:** Injecting trace headers, emitting spans, and storing structured logs incurs CPU, memory, and telemetry ingest costs. |
| **High Cardinality Dimension Slicing:** Ability to isolate performance regressions to a single tenant, carrier, or release version. | **Cardinality Explosion Risk:** Unchecked metrics tags (e.g., putting `shipment_id` in Prometheus labels) can crash metrics backends. |
| **Actionable Alerting:** SLO error budget alerts prevent alert fatigue by alerting only on customer-impacting degradation. | **SRE Governance:** Requires defining SLIs/SLOs, monitoring error budgets, and maintaining runbooks for each capability. |

---

## 7. 2-Minute Architectural Defense

### Context
"When incidents occur across distributed services and message queues, teams waste hours guessing root causes because logs lack correlation IDs and metrics only report aggregate averages."

### Decision
"Atlas implements explicit **OpenTelemetry Context Propagation** across both HTTP and message brokers (ADR-0007). We mandate structured JSON logging with bounded dimensions (`tenant_id`, `carrier`, `version`, `trace_id`), monitor queue health via oldest-message age, and alert on capability SLOs."

### Tradeoffs Accepted
"We accept the development discipline of propagating context and the telemetry storage cost in exchange for moving from intuition-based debugging to evidence-based incident resolution."

### Alternatives Rejected
1. *Unstructured Console Logs (`System.out.println`):* Rejected because logs without structured JSON and trace IDs cannot be parsed or correlated across distributed containers.
2. *Alerting on Raw Infrastructure Thresholds (CPU > 80%):* Rejected because high CPU does not mean customers are failing, while 100% business failures can happen at 5% CPU (alert fatigue).
3. *High-Cardinality Metric Labels:* Rejected; `shipment_id` and raw UUIDs belong in traces and logs, never in metrics label keys.

### Revisit Trigger
"Revisit sampling rates (e.g., move from 100% trace capture to head/tail-based probabilistic sampling) when platform throughput exceeds 50,000 req/sec to control telemetry storage bills."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "Why is queue depth alone a misleading signal for asynchronous consumer health? What metric must accompany it?"
- **Strong Answer:** "Queue depth tells you volume, not latency. A queue with 10,000 messages processing at 2,000 msg/sec is completely healthy (backlog empties in 5 seconds). Conversely, a queue with only 100 messages where the **oldest-message age is 45 minutes** indicates a severe incident: a **poison message** is repeatedly failing, blocking the worker thread (head-of-line blocking), and delaying customer reactions. Oldest-message age is the vital SLI."

### Q2: "What is the difference between an SLI, an SLO, and an SLA?"
- **Strong Answer:** 
  - **SLI (Indicator):** The quantifiable metric (e.g., `% of shipment requests completing < 500ms with HTTP 2xx`).
  - **SLO (Objective):** The internal target and error budget set by engineering and product (e.g., `99.5% success over 30 rolling days`).
  - **SLA (Agreement):** The legal/business contract with customers with financial penalties for breach (e.g., `99.0% availability or 10% credit refund`).

### 🚩 Common Interview Pitfalls
- ❌ **Putting High-Cardinality IDs in Metrics Tags:** Emitting `metric.increment("requests", tags: ["shipment_id", id])`, blowing up time-series databases.
- ❌ **Losing Trace Context at the Broker:** Failing to inject `traceparent` into SQS/Kafka message attributes, severing traces into disconnected islands.
- ❌ **Relying on Average Latency (Mean):** Looking at average response time (e.g., 180ms) and missing the fact that the p99 tail latency is 8.4s for Carrier-X customers.

---

**Deep dive:** [Chapter 7 — Observability](../course/chapter-07-observability-understanding-a-running-system.md) · [ADR-0007](../adr-examples/ADR-0007-opentelemetry-instrumentation-boundary.md) · [Exercise 7](../exercises/exercise-07-diagnose-the-incident.md)
