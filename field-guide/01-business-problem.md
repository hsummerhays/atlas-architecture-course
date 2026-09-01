# Field Guide 01 — The Business Problem

> **Chapter Reference:** [Chapter 1 — The Business Problem](../course/chapter-01-business-problem.md)  
> **ADR:** [ADR-0001 — Adopt Canonical Shipment Model](../adr-examples/ADR-0001-canonical-shipment-model.md)  
> **Exercise:** [Exercise 1 — Find the Architecture in the Business Problem](../exercises/exercise-01-find-architecture.md)

---

## 1. Core Principle
> **Begin with the business problem and domain invariants before selecting technology. Isolate proven external variation behind explicit boundaries, and never allow third-party schemas to dictate the core domain.**

---

## 2. 30-Second Elevator Pitch
"Atlas exists because business applications need a single, stable interface to book and track shipments across FedEx, UPS, DHL, and regional carriers without coupling application logic to proprietary provider schemas. We solve this by establishing an authoritative **Canonical Shipment Model** and placing carrier-specific transformations inside dedicated **Ports and Adapters**. We translate our domain model *outward* to the carriers rather than spreading carrier models *inward* across our database, controllers, and business logic."

---

## 3. The Whiteboard Sketch

```text
┌────────────────────────┐
│  Business Application  │ (CRM, WMS, ERP, Checkout)
└───────────┬────────────┘
            │ 1. Canonical Command (BookShipment)
            ▼
┌────────────────────────┐
│  Atlas Shipment Core   │ (Owns business rules, invariants, & state)
└───────────┬────────────┘
            │ 2. Outbound Port (CarrierPort)
            ▼
┌────────────────────────┐
│  Carrier Adapter Layer │ (Anti-Corruption Layer: Auth, Mapping, Units)
└───┬────────────────┬───┘
    │                │
    ▼                ▼
┌───────────┐  ┌───────────┐
│ FedEx API │  │  UPS API  │ (Proprietary DTOs, SOAP/REST/GraphQL)
└───────────┘  └───────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** Enterprise shippers operate heterogeneous client applications (CRMs, warehouse management systems, customer portals).
- **Integration Pressure (Illustrative):** External carriers vary in protocol, units, authentication, and dispatch timing (e.g., REST vs. SOAP/GraphQL, imperial vs. metric units, synchronous vs. asynchronous callback webhooks).
- **The Architectural Hazard:** Direct integration forces every client app to learn carrier-specific authentication, schema quirks, and error semantics, resulting in duplicate translation logic and domain pollution.

---

## 5. Diagram & Boundary Map
- **Diagram:** [Atlas System Context](../diagrams/atlas-system-context.svg)
- **Atlas Owns:** `ShipmentId`, `OriginAddress`, `DestinationAddress`, `Weight` (canonical grams/kg), `ServiceLevel` (Standard/Express), `Status` (`PENDING`, `BOOKED`, `FAILED`).
- **Adapters Own:** Token acquisition, payload envelope generation, unit conversions, provider HTTP timeouts, and carrier error code translation.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Client Stability:** Clients integrate once against Atlas's stable API contract. | **Mapping Overhead:** Every carrier requires custom mapping classes and contract tests. |
| **Blast Radius Containment:** Carrier schema or API changes only impact that single adapter. | **Lowest-Common-Denominator Risk:** Specialized carrier features (e.g., custom hazardous cargo flags) don't automatically exist in the canonical model. |
| **Isolated Testability:** Core domain logic can be tested in isolation using test doubles for carrier ports. | **Model Impedance:** Some provider concepts won't map cleanly to the canonical model and require deliberate capability/extension handling. |

---

## 7. 2-Minute Architectural Defense

### Context
"When building a multi-carrier shipping platform, the initial temptation is to pass provider DTOs straight through from the UI to the carrier SDK to ship fast."

### Decision
"We rejected pass-through carrier DTOs and established an explicit **Canonical Shipment Model** with **Ports and Adapters** (ADR-0001, ADR-0002). Atlas defines the `CarrierPort` interface; carrier adapters implement it as Anti-Corruption Layers."

### Tradeoffs Accepted
"We buy long-term maintainability and client decoupling at the cost of maintaining translation layers for each provider. We deliberately avoid making the canonical model a union of all carrier fields; it represents only the minimum stable language required for Atlas's business promises."

### Alternatives Rejected
1. *Direct Pass-Through Carrier DTOs:* Rejected because a change in FedEx's schema would break client UIs and corrupt database rows.
2. *Universal Dynamic Mapping Engine:* Rejected under YAGNI/Rule of Three. Dynamic reflection/JSON-path mapping adds runtime fragility before carrier volume justifies the complexity.

### Revisit Trigger
"Revisit if provider-specific capabilities become the dominant source of product differentiation and the canonical abstraction begins obstructing rather than isolating necessary variation."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "Why not make the canonical model a union of every field offered by FedEx, UPS, and DHL?"
- **Strong Answer:** "A union model is a carrier catalog disguised as a domain model. It grows uncontrollably whenever any provider adds a field, couples the core domain to external changes, and creates confusing sparse objects where 80% of fields are null for any given carrier. The canonical model should only contain fields Atlas makes business promises about."

### Q2: "A new carrier supports a specialized temperature-control flag that no other carrier has. How do you handle it?"
- **Strong Answer:** "First, ask if temperature control is a core Atlas business promise. If yes, add it deliberately to the canonical model as an optional capability with feature-flagged adapter support. If it's a proprietary one-off not in our SLA, leave it at the adapter boundary or pass it via structured extension metadata without polluting core booking logic."

### 🚩 Common Interview Pitfalls
- ❌ **Starting with Frameworks:** Beginning your answer with "I'd use Spring Boot with Kafka and PostgreSQL..." before defining what a shipment is and who the actors are.
- ❌ **False Uniformity:** Claiming that adapters make all carriers identical. (Carriers have real differences in failure semantics and capabilities; good architecture makes them manageable, not invisible).
- ❌ **Speculative Generality:** Designing a dynamic plugin engine or bytecode transformer on Day 1 when you only support two carriers.

---

**Deep dive:** [Chapter 1 — The Business Problem](../course/chapter-01-business-problem.md) · [ADR-0001](../adr-examples/ADR-0001-canonical-shipment-model.md) · [Exercise 1](../exercises/exercise-01-find-architecture.md)
