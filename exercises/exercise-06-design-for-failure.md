# Exercise 6 — Design for Failure

## Scenario
On Cyber Monday, Atlas experiences a 10x traffic surge (5,000 requests/minute). During peak hours, an external partner, Carrier-Global, experiences severe infrastructure degradation:
- 40% of their API requests hang until timing out after 30 seconds.
- 30% of their requests return HTTP 503 Service Unavailable immediately.
- 30% of their requests succeed normally in 300ms.

Because Atlas originally had a default 60-second HTTP timeout and unlimited automatic retries, the following cascade occurred:
1. Atlas Tomcat worker threads were quickly exhausted (all 200 threads blocked waiting on Carrier-Global).
2. Inbound requests for other healthy carriers (FedEx, UPS) began failing with HTTP 500 because no application threads were free to process them.
3. The database connection pool became saturated by idle transactions holding locks while waiting for HTTP responses.
4. The entire Atlas shipping platform crashed.

## Your Task
Redesign Atlas's outbound integration architecture to make it resilient against this exact scenario. Define specific timeout, retry, backoff, circuit-breaker, and bulkhead parameters.

## Constraints
1. A slow or failing carrier must NEVER consume more than 25% of Atlas's available worker threads or connections.
2. Inbound requests for healthy carriers must continue processing normally with SLA < 500ms.
3. Fast-fail errors must be returned to the client when a carrier is degraded, rather than locking up the user interface.

## Architecture Questions
1. What should the outbound HTTP timeout be for carrier requests?
2. What retry policy (attempts, backoff curve, jitter, status code filters) should be applied?
3. What threshold and reset timeout should trigger the Circuit Breaker from `CLOSED` to `OPEN` and `HALF-OPEN`?
4. How do Bulkheads (thread pool / connection pool isolation) prevent cross-carrier starvation?

## Deliverable
A Resilience Specification Document containing:
- Specific numeric thresholds for Timeouts, Retries, Jitter, Circuit Breaker, and Bulkheads.
- A state transition diagram or flowchart showing how a degraded carrier is isolated.
- The exact error response returned to the client when the circuit is `OPEN`.

## Run-Through Checklist
- [ ] Explicit maximum timeout (bounded work).
- [ ] Full randomized jitter applied to exponential backoff.
- [ ] Strict isolation of connection pools per carrier (Bulkhead).
- [ ] Clear fail-fast behavior with circuit breaker metrics emitted.

## Discussion / Reflection
Why is a fast HTTP 503 / 424 "Carrier Temporarily Unavailable" error infinitely better for user experience and system survivability than an HTTP request that hangs for 30 seconds and then fails?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### 1. Concrete Resilience Parameter Specification

#### A. Strict Bounded Timeouts
- **Connect Timeout:** 500ms
- **Read Timeout:** 2,500ms (Hard ceiling)
- *Rationale:* If Carrier-Global hasn't responded in 2.5s, holding the thread longer causes severe resource exhaustion.

#### B. Retry Policy with Exponential Backoff & Full Jitter
- **Max Retries:** 2 attempts (Total calls: 3)
- **Retryable Errors:** Only HTTP 502, 503, 504, and connect timeouts. (Never retry HTTP 4xx business errors).
- **Backoff Formula:** `sleep = min(1000ms, random(0, 100ms * 2^attempt))`
- *Rationale:* Full jitter prevents synchronized thundering herd waves against the recovering carrier.

#### C. Circuit Breaker Configuration (e.g., Resilience4j)
- **Sliding Window:** 50 requests
- **Failure Rate Threshold:** 50% (slow calls > 2s or 5xx errors)
- **State Transition to OPEN:** Immediately fails subsequent calls with `CarrierCircuitOpenException` (< 1ms).
- **Wait Duration in OPEN:** 30 seconds
- **State Transition to HALF-OPEN:** Allows 5 probe requests to evaluate carrier health.

#### D. Dedicated Thread & Connection Bulkheads
- **Carrier-Global Pool:** Max 30 concurrent connections / threads.
- **FedEx Pool:** Max 50 connections.
- **UPS Pool:** Max 50 connections.
- **General Atlas Pool:** 100 connections.
- *Rationale:* Even if Carrier-Global hangs, it can at most occupy 30 threads. 170 threads remain 100% available for FedEx, UPS, and internal use cases.

### 2. Client Response when Circuit is OPEN
- **HTTP Status:** `503 Service Unavailable` (or `424 Failed Dependency`)
- **JSON Body:**
```json
{
  "error": "CARRIER_UNAVAILABLE",
  "carrier": "CARRIER_GLOBAL",
  "message": "Carrier service is currently experiencing high latency and has been temporarily isolated. Please select an alternate carrier or retry in 30 seconds.",
  "retry_after_seconds": 30
}
```

*(Reference: [Diagram: Resilience & Fault Containment Flow](../diagrams/resilience-flow.svg), [ADR-0006](../adr-examples/ADR-0006-explicit-resilience-policies.md))*
</details>
