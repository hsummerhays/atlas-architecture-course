# Exercise 7 — Diagnose the Incident

## Scenario
It is 14:15 UTC. The on-call engineer receives an automated P1 alert: *"Shipment Booking Error Budget Exhaustion Rate > 5x"*.

The production telemetry dashboard displays the following live signals:

```text
=== Production Telemetry Snapshot (14:10–14:25 UTC) ===

Shipment Booking Success Rate:   97.2% (SLO Target: 99.9%)
Public API Throughput:           1,450 req/sec (Normal)
Public API Latency (p50):        110 ms
Public API Latency (p95):        410 ms
Public API Latency (p99):        3,850 ms (Severe tail spike!)

Carrier-FedEx Latency (p95):     240 ms (Normal)
Carrier-UPS Latency (p95):       310 ms (Normal)
Carrier-X Latency (p95):         8,400 ms (Degraded!)
Carrier-X Error Rate:            18.4% (HTTP 504 / Timeouts)
Carrier-X Circuit Breaker State: OPEN (Tripped 17 times in last 10m)

Outbox Publisher Lag:            12 events (Healthy)
SNS Topic Throughput:            1,410 events/sec (Normal)

Tracking Consumer Queue Depth:   42 messages (Healthy)
Accounting Consumer Queue Depth: 1,240 messages (Backlog accumulating!)
Accounting Oldest Message Age:   46 minutes (SLO Violation: > 5m)
Accounting Consumer Error Rate:  100% on specific messages (Thread retrying continuously)
```

## Your Task
Analyze this production telemetry snapshot. Formulate a structured diagnostic assessment identifying what is failing, why the tail latency is spiking, what the downstream accounting backlog indicates, and what immediate and structural actions you must take.

## Constraints
1. You must base your diagnosis strictly on the telemetry evidence provided.
2. Distinguish the synchronous API degradation from the asynchronous consumer backlog (two distinct failure modes occurring simultaneously).

## Architecture Questions
1. Why is public API p95 healthy (410ms) while p99 is severely degraded (3,850ms)? Which carrier is responsible?
2. What is happening inside the Accounting Consumer queue? Why is the oldest message 46 minutes old with a 100% error rate on specific messages?
3. What additional log or trace dimensions would you query immediately to confirm your hypotheses?
4. What immediate mitigation steps should the on-call engineer execute?

## Deliverable
An Incident Triage & Root Cause Analysis (RCA) Report:
- **Incident Summary & Impact Assessment**
- **Root Cause Hypothesis 1 (Synchronous Path):** Explanation of p99 tail latency and Carrier-X circuit breaker trips.
- **Root Cause Hypothesis 2 (Asynchronous Path):** Explanation of Accounting Consumer queue backlog and 46-minute age.
- **Immediate Mitigation Actions (Next 15 minutes)**
- **Long-term Architectural Remediations**

## Run-Through Checklist
- [ ] Connects telemetry evidence (p99, queue depth, error rates) to concrete architectural mechanisms.
- [ ] Identifies poison message dynamics causing head-of-line blocking in the accounting queue.
- [ ] Prescribes actionable runbook steps rather than guessing.

## Discussion / Reflection
Why do aggregate averages (e.g., mean latency 150ms) dangerously conceal severe localized outages that p99 percentiles and multi-tenant trace dimensions immediately reveal?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### Incident Triage Assessment

#### 1. Synchronous API Degradation Analysis
- **Symptom:** API p99 latency spiked to 3,850ms, causing the 97.2% success rate drop.
- **Root Cause:** Carrier-X is experiencing massive degradation (p95 = 8.4s, 18.4% timeouts). Because Carrier-X calls take up to the timeout threshold before failing or tripping the circuit breaker, 2.8% of customers selecting Carrier-X experience slow timeouts, while FedEx and UPS customers remain unaffected.
- **Immediate Mitigation:** Force the Carrier-X Circuit Breaker to `FORCED_OPEN` in feature flags to immediately fail-fast and prompt users to choose FedEx/UPS, bringing API p99 back under 450ms.

#### 2. Asynchronous Accounting Queue Backlog Analysis
- **Symptom:** 1,240 messages queued, oldest message age = 46 minutes, 100% error rate on specific items.
- **Root Cause:** A **Poison Message** is causing **Head-of-Line Blocking**. A malformed event payload (or unhandled business edge case) causes the accounting worker thread to fail, retry, fail, retry, without moving to a Dead-Letter Queue (DLQ maxReceiveCount configuration missing or misconfigured). Other valid messages behind it are delayed by 46 minutes.
- **Immediate Mitigation:**
  1. Inspect the top message in the accounting queue using OpenTelemetry `trace_id` and `event_id`.
  2. Manually redrive or isolate the poison message into `accounting-dlq` to unblock the remaining 1,239 messages.
  3. Increase accounting consumer concurrency worker pods temporarily to drain the 46-minute lag.

#### 3. Long-term Architectural Remediations
1. **Enforce DLQ Redrive Policy:** Ensure all SQS consumers have a strict `maxReceiveCount = 3` redrive policy pointing to a monitored DLQ (ADR-0004).
2. **Carrier-X Bulkhead Tuning:** Reduce Carrier-X read timeout from 3.5s to 2.0s and lower circuit breaker trip threshold to isolate outages faster (ADR-0006).

*(Reference: [Diagram: Observability Context & Tracing](../diagrams/observability-correlation.svg), [ADR-0007](../adr-examples/ADR-0007-opentelemetry-instrumentation-boundary.md))*
</details>
