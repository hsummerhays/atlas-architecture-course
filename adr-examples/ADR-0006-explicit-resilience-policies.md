# ADR-0006: Explicit Distributed Resilience Policies

## Status
Accepted

## Context
External carrier networks exhibit variable latency, intermittent packet loss, rate limiting, and unexpected outages. In distributed systems, naive retry loops without backoff or global limits cause **retry amplification storms** that exhaust thread pools, flood recovering downstream dependencies, and bring down the entire calling application.

## Decision
Atlas enforces explicit, mandatory resilience policies across all outbound integration boundaries:
1. **Strict Bounded Timeouts:** Every outbound HTTP call has an explicit deadline (e.g., 2500ms).
2. **Exponential Backoff with Full Jitter:** Retries back off exponentially with randomized jitter to prevent synchronized retry waves.
3. **Bounded Retry Budgets:** A maximum of 2–3 retries for transient HTTP status codes (502, 503, 504, 429), with no retries for business or contract errors (400, 401, 403, 422).
4. **Circuit Breakers & Bulkheads:** When failure rates exceed 50%, the circuit trips to `OPEN`, immediately failing fast without sending traffic to the struggling dependency. Dedicated thread/connection bulkheads isolate each carrier adapter.

## Alternatives Considered
1. **Infinite or Aggressive Retries:** Retrying continuously until success. Rejected because it causes catastrophic cascading failures across upstream caller thread pools.
2. **Global Shared Thread Pools for All Carriers:** Running all external outbound calls on one general thread pool. Rejected because one slow carrier would starve requests destined for healthy carriers.

## Consequences
- **Positive:** Protects shared system resources; prevents thundering herds; fails fast when dependencies are unhealthy.
- **Negative:** Callers receive fast failures when a dependency is down rather than waiting indefinitely.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in `atlas-shipping-app` HTTP client resilience configurations.
