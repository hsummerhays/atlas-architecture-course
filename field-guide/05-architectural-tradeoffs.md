# Field Guide 05 — Architectural Tradeoffs

> **Chapter Reference:** [Chapter 5 — Architectural Tradeoffs](../course/chapter-05-tradeoffs.md)  
> **ADRs:** [ADR-0001](../adr-examples/ADR-0001-canonical-shipment-model.md) · [ADR-0003](../adr-examples/ADR-0003-transactional-outbox.md)  
> **Exercise:** [Exercise 5 — Make the Tradeoff](../exercises/exercise-05-make-the-tradeoff.md)

---

## 1. Core Principle
> **Architecture is choosing which properties matter enough to pay for their consequences. The senior engineer's core question is not "What is the best architecture?", but "What are we buying, and what are we paying for it?"**

---

## 2. 30-Second Elevator Pitch
"In Atlas, we evaluate architectural options by explicitly balancing competing quality attributes: simplicity versus flexibility, strong local consistency versus bounded eventual consistency, performance versus resilience, and build versus buy. We resist speculative abstractions under YAGNI and the Rule of Three, choosing abstractions only where external variation is demonstrated (like carrier integrations). Every major design choice is documented in an Architecture Decision Record (ADR) that records not just what we gained, but the operational costs accepted and the assumptions that would trigger reconsideration."

---

## 3. The Whiteboard Sketch

```text
       [ Business Pressure & Quality Attributes ]
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
┌──────────────┐                        ┌──────────────┐
│ Option A     │                        │ Option B     │
│ (Live Calls) │                        │ (Rate Cache) │
└──────┬───────┘                        └──────┬───────┘
       │                                       │
       ▼                                       ▼
 ┌───────────┐                           ┌───────────┐
 │ Gained:   │ Real-time accuracy        │ Gained:   │ < 15ms Latency, Outage Isolation
 │ Paid:     │ 4x Carrier load, fragile  │ Paid:     │ Eventual sync, Cache infra
 └───────────┘                           └───────────┘
                           │
                           ▼
          [ Architect's Explicit Defense ]
          "We buy X at the cost of paying Y."
```

---

## 4. The Atlas Scenario
- **Business Context:** The checkout service needs carrier rate comparisons (FedEx, UPS, DHL, USPS) within 800ms while avoiding third-party rate-limit bans.
- **The Competing Options:**
  - *Option A (Live Parallel Fan-Out):* 4 concurrent HTTP calls with 700ms timeout. High accuracy, fragile availability under carrier latency spikes.
  - *Option B (Pre-computed Rate Cache):* Cached rates in Redis (< 15ms) refreshed in the background with final verification at booking. High availability, eventual rate freshness.

---

## 5. Diagram & Boundary Map
- **Diagram:** [Architectural Tradeoff Map](../diagrams/architecture-tradeoff-map.svg)
- **Local Consistency Boundary:** Shipment booking state + Outbox message (Atomic in PostgreSQL).
- **Eventual Consistency Boundary:** Downstream notification, analytics, tracking projections, and accounting intake.
- **Decision Reversibility:** Easy to add caching later; difficult to decouple shared monolith databases once coupled.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Explicit Decision Making:** Decisions are based on measured business constraints rather than technology trends. | **No "Perfect" Solutions:** Every design choice introduces an explicit operational or architectural cost. |
| **Reversibility:** High-impact, irreversible decisions are made deliberately; reversible details stay open. | **Initial Deliberation:** Requires upfront tradeoff analysis and ADR documentation before building. |
| **Simplicity First:** YAGNI prevents maintaining unused dynamic plugin frameworks. | **Refactoring Discipline:** Code must be refactored when genuine variation emerges (Rule of Three). |

---

## 7. 2-Minute Architectural Defense

### Context
"When designing real-time carrier rating comparisons, teams often clash between demanding 100% live carrier accuracy versus demanding ultra-fast sub-20ms checkout response times."

### Decision
"We adopted **Cached Rates with Final Booking Verification** (Option B). Checkout serves cached rate tables from Redis in < 15ms. The final booking step validates the live rate before charging the customer."

### Tradeoffs Accepted
"We buy sub-20ms checkout speed, complete immunity to third-party carrier outages during browsing, and protection against API rate limits. We pay the operational cost of managing Redis and writing reconciliation logic to handle the 1% of edge cases where a rate fluctuates between checkout and booking."

### Alternatives Rejected
1. *Synchronous Parallel HTTP Fan-Out:* Rejected because a single slow carrier degrades the entire checkout UI and traffic spikes directly multiply outbound carrier API costs (4x multiplier).
2. *Building a Proprietary Custom In-Memory Database:* Rejected under Build vs. Buy; managed Redis provides mature caching without custom operational burden.

### Revisit Trigger
"Revisit if carrier contracts legally mandate real-time pricing without intermediate caching, or if freight shipments with hourly volatile fuel surcharges become majority volume."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "Is microservices architecture better than a modular monolith for Atlas?"
- **Strong Answer:** "Neither is universally 'better.' A modular monolith buys development velocity, zero network serialization latency, and simple transactional integrity, paying in shared deployment coupling. Microservices buy independent deployment and isolated scaling, paying in distributed complexity (eventual consistency, network latency, distributed tracing). We start with a modular monolith and split services only when independent scaling or separate team ownership warrants the operational cost."

### Q2: "What is the difference between code duplication and knowledge duplication?"
- **Strong Answer:** "Code duplication is two classes looking similar today. Knowledge duplication is two components sharing business logic that must change together. Extracting a shared library for incidental code duplication creates tight architectural coupling across services (a distributed monolith). We tolerate code duplication when the underlying business concepts evolve for different reasons."

### 30-Second Interview Response Formula:
> **"We chose [Decision] because [Quality Attribute] matters most here. This gives us [Benefit], but costs us [Explicit Cost]. We will reconsider if [Revisit Trigger] occurs."**

### 🚩 Common Interview Pitfalls
- ❌ **Declaring a Technology "Best Practice":** Claiming "Kafka is best practice for events" without explaining the operational cost of Zookeeper/KRaft, partition rebalancing, and retention management versus SQS/SNS.
- ❌ **Denying Consequences:** Pitching an architecture as having "no downsides."
- ❌ **Premature Generalization:** Building a dynamic multi-cloud abstraction layer when you have no business requirement to run on multiple clouds.

---

**Deep dive:** [Chapter 5 — Architectural Tradeoffs](../course/chapter-05-tradeoffs.md) · [ADR-0001](../adr-examples/ADR-0001-canonical-shipment-model.md) · [Exercise 5](../exercises/exercise-05-make-the-tradeoff.md)
