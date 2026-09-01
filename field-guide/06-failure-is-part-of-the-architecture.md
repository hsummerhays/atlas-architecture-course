# Field Guide 06 — Failure Is Part of the Architecture

> **Chapter Reference:** [Chapter 6 — Failure Is Part of the Architecture](../course/chapter-06-failure-is-part-of-the-architecture.md)  
> **ADR:** [ADR-0006 — Explicit Distributed Resilience Policies](../adr-examples/ADR-0006-explicit-resilience-policies.md)  
> **Exercise:** [Exercise 6 — Design for Failure](../exercises/exercise-06-design-for-failure.md)

---

## 1. Core Principle
> **Resilience is not preventing failure; it is controlling the consequences of failure. A dependency is not fully designed until its failure behavior is understood, bounded, and contained.**

---

## 2. 30-Second Elevator Pitch
"In distributed systems, networks will drop packets and external providers will stall. Atlas treats failure as normal by establishing bounded **Timeouts** to avoid thread exhaustion, **Retries with Exponential Backoff and Full Jitter** to prevent synchronized retry storms, and **Retry Budgets** to eliminate cross-layer amplification. When an external carrier degrades, a **Circuit Breaker** fails fast within 1ms rather than holding resources, while **Bulkheads** isolate thread and connection pools per carrier so that an outage in FedEx or Carrier-X can never exhaust capacity for UPS or internal APIs."

---

## 3. The Whiteboard Sketch

```text
[ Inbound Request ]
         │
         ▼
┌────────────────────────────────┐
│ Dedicated Carrier Bulkhead     │ (Max 30 threads for Carrier X; 170 free for others)
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│ Circuit Breaker (CLOSED/OPEN)  │ ──► [ OPEN ] ──► Fast-Fail HTTP 503 (< 1ms)
└────────┬───────────────────────┘
         │ [ CLOSED / HALF-OPEN ]
         ▼
┌────────────────────────────────┐
│ Bounded HTTP Timeout (2.5s)    │ (Read/Connect ceiling; avoids indefinite wait)
└────────┬───────────────────────┘
         │ (On transient 503/Timeout)
         ▼
┌────────────────────────────────┐
│ Bounded Retry + Full Jitter    │ (Max 2 retries; sleep = random(0, 100ms * 2^attempt))
└────────┬───────────────────────┘
         │ (Exhausted retries)
         ▼
┌────────────────────────────────┐
│ Graceful Degradation / DLQ     │ (Carrier isolated; prompt user to pick alternate)
└────────────────────────────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** On peak shopping days, Carrier-X experiences severe infrastructure latency (p95 jumps to 8.4s with 18% HTTP 504 timeouts).
- **The Cascading Collapse Hazard:** With default 60s timeouts and unbounded retries, Atlas worker threads get blocked waiting on Carrier-X. Database connections stay open. Thread pools exhaust, and requests for healthy carriers (FedEx, UPS) fail with HTTP 500.
- **Atlas Resolution:** Strict 2.5s timeouts, Resilience4j circuit breakers, dedicated per-carrier connection bulkheads, and exponential backoff with full jitter.

---

## 5. Diagram & Boundary Map
- **Diagram:** [Distributed Resilience & Fault Containment Flow](../diagrams/resilience-flow.svg)
- **Timeout Boundary:** Connect 500ms; Read 2,500ms max.
- **Circuit Breaker Boundary:** Sliding window of 50 calls; trips `OPEN` if failure rate > 50%; wait duration 30s before `HALF-OPEN`.
- **Bulkhead Boundary:** Carrier-X pool max 30 connections; FedEx pool max 50; UPS pool max 50; Atlas general pool 100.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Blast Radius Containment:** A catastrophic outage at one carrier never takes down Atlas or other healthy carriers. | **Fast-Fail Errors for Degraded Path:** When a circuit trips `OPEN`, requests for that carrier are rejected immediately. |
| **Protected Downstream Capacity:** Exponential backoff with full randomized jitter prevents thundering herd retry waves. | **Tail Latency on Transient Errors:** Retries with backoff add bounded latency before succeeding or giving up. |
| **Deterministic Resource Limits:** Bulkheads guarantee thread pool availability for core services. | **Resource Partitioning Overhead:** Managing distinct connection pools per external integration. |

---

## 7. 2-Minute Architectural Defense

### Context
"When external third-party logistics APIs degrade, distributed systems face cascading thread pool exhaustion and catastrophic retry storms."

### Decision
"Atlas implements explicit distributed resilience policies (ADR-0006): strict bounded timeouts (2.5s), a centralized retry owner with exponential backoff and full jitter (max 2 retries), circuit breakers that trip to `OPEN` under 50% failure rate, and isolated per-carrier bulkheads."

### Tradeoffs Accepted
"We accept that when a carrier is degraded, clients selecting that carrier will receive fast HTTP 503/424 errors once the circuit opens, in exchange for guaranteeing that the rest of Atlas and all other healthy carrier workflows remain 100% available."

### Alternatives Rejected
1. *Unbounded Aggressive Retries:* Rejected because retrying a failing service without backoff or jitter creates a self-inflicted Distributed Denial of Service (DDoS) storm.
2. *Infinite/Default Timeouts:* Rejected because holding threads open for 30–60s saturates web servers and connection pools within seconds.
3. *Shared Global Connection Pool:* Rejected because one slow provider exhausts all threads, starving every other service in the platform.

### Revisit Trigger
"Revisit timeout and circuit breaker thresholds if a high-volume freight carrier's SLA contract guarantees sub-second responses or requires asynchronous batch polling instead of synchronous HTTP calls."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "Why is exponential backoff alone insufficient to prevent retry storms? Why is jitter mandatory?"
- **Strong Answer:** "Exponential backoff increases delay (e.g., 100ms, 200ms, 400ms), but if 1,000 clients fail at the exact same instant, backoff alone means all 1,000 clients will retry together in synchronized pulses. Full jitter randomizes the delay (`sleep = random(0, backoff)`), scattering retries smoothly across time and allowing the downstream service to recover without experiencing recurring traffic spikes."

### Q2: "What is retry amplification, and who should own the retry policy?"
- **Strong Answer:** "Retry amplification occurs when multiple layers in a stack retry independently. If the HTTP client retries 3 times, the application service retries 3 times, and an SQS queue redelivers 3 times, a single failed call produces $3 \times 3 \times 3 = 27$ downstream requests. Architecture must establish **one clear retry owner** for every operation (typically the edge adapter or queue consumer, never both)."

### 🚩 Common Interview Pitfalls
- ❌ **Assuming Timeouts Cancel Remote Work:** Forgetting that timing out on an HTTP call only stops the client from waiting; the server may still execute the request (requiring idempotency).
- ❌ **Retrying Non-Idempotent Operations Blindly:** Retrying payment or booking calls without idempotency keys.
- ❌ **Treating Circuit Breakers as Healing Tools:** Believing a circuit breaker fixes a broken provider; it only prevents your system from futilely wasting resources on it.

---

**Deep dive:** [Chapter 6 — Failure Is Part of the Architecture](../course/chapter-06-failure-is-part-of-the-architecture.md) · [ADR-0006](../adr-examples/ADR-0006-explicit-resilience-policies.md) · [Exercise 6](../exercises/exercise-06-design-for-failure.md)
