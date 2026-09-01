# Exercise 5 — Make the Tradeoff

## Scenario
The business team wants to add real-time carrier rating comparisons at checkout. When a customer inputs a package weight, Atlas must compare live rates from FedEx, UPS, DHL, and USPS and return the cheapest and fastest options within 800 milliseconds.

The engineering team proposes two competing architectures:

### Option A: Fully Synchronous Parallel Aggregator
- When the request arrives, an aggregator spins up 4 parallel HTTP threads.
- It calls FedEx, UPS, DHL, and USPS simultaneously with a strict 700ms timeout.
- It aggregates whichever responses return in time, computes the lowest rate, and returns the response.

### Option B: Asynchronous Rate Cache with Background Refresh
- Atlas pre-fetches and maintains rate tables in a Redis cache for common origin-destination zip code pairs and weight tiers.
- The checkout API queries Redis synchronously (< 10ms).
- When a quote is selected, the final booking step verifies the rate with the carrier before charging.
- A background worker pool continuously refreshes expiring cache entries using rate-limited carrier calls.

## Your Task
Evaluate Option A and Option B using the core architectural question:
> **"What are we buying, and what are we paying for it?"**

## Constraints
1. Checkout response time p95 must be under 800ms.
2. Carrier rate limits must not be exceeded (some carriers enforce maximum 50 calls/second).
3. If a carrier returns an outdated or changed rate, customer booking must handle the discrepancy gracefully without financial loss.

## Architecture Questions
1. What quality attributes does Option A optimize for? What does it sacrifice?
2. What quality attributes does Option B optimize for? What does it sacrifice?
3. Which architecture is more resilient to a third-party carrier outage or slow network conditions?
4. How does each option scale as Atlas adds 10 more regional carriers?

## Deliverable
A Structured Tradeoff Comparison Matrix & Recommendation:
- Quality Attributes Evaluated (Latency, Accuracy, Availability, Carrier API Cost/Limits, Complexity).
- Analysis of "What We Buy" vs. "What We Pay".
- Final Architect's Recommendation with conditions under which the decision should be revisited.

## Run-Through Checklist
- [ ] Explicitly identifies the costs of both options (no "perfect" solution).
- [ ] Addresses carrier rate-limiting quotas and network degradation.
- [ ] Connects the decision to explicit business SLAs and customer experience.

## Discussion / Reflection
How do you explain to a non-technical product manager why a 99% accurate cached rate returned in 10ms may provide a better business outcome than a 100% accurate live rate that occasionally times out after 3 seconds?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### Tradeoff Comparison Matrix

| Quality Attribute | Option A (Parallel Synchronous Calls) | Option B (Cached Rates + Verification) |
|---|---|---|
| **Latency (p95)** | High / Variable (~500–750ms). Dependent on slowest carrier. | Ultra-low (< 15ms) from cache. |
| **Accuracy** | 100% real-time accuracy. | Eventual accuracy (~98–99%). Rates may occasionally fluctuate before booking. |
| **Availability / Resilience** | Fragile. If 3 carriers time out, UI degrades. High risk of thread pool exhaustion. | High. Carrier outages do not impact checkout UI; cache serves last-known rates. |
| **Carrier Rate Limits** | High risk. Traffic spikes directly multiply outbound carrier API calls (4x multiplier). | Low risk. Background cache refresher rate-limits and batches requests. |
| **Operational Complexity** | Low code complexity; high operational fragility under carrier latency spikes. | Moderate complexity (cache invalidation, Redis management, rate difference reconciliation at booking). |

### Architect's Recommendation
**Adopt Option B (Cached Rates with Final Booking Verification)** for consumer checkout:
- **What we buy:** Sub-20ms checkout response times, complete immunity to carrier outages during browsing, and protection against carrier API rate-limit bans.
- **What we pay:** We must handle edge cases where a live rate changes between checkout and booking (handled by displaying "Rate verified at booking" and re-confirming if variance > 2%).
- **Revisit Trigger:** If carrier contracts require guaranteed real-time pricing without caching, or if freight shipments with highly volatile hourly fuel surcharges become primary volume.

*(Reference: [Diagram: Architectural Tradeoff Map](../diagrams/architecture-tradeoff-map.svg))*
</details>
