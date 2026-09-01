# Field Guide 02 — Following a Shipment

> **Chapter Reference:** [Chapter 2 — Following a Shipment](../course/chapter-02-following-a-shipment.md)  
> **ADR:** [ADR-0002 — Isolate Carrier Integrations Behind Ports and Adapters](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md)  
> **Exercise:** [Exercise 2 — Trace a Shipment](../exercises/exercise-02-trace-a-shipment.md)

---

## 1. Core Principle
> **Place each decision with the component that possesses the required knowledge and reason to change. Dependency inversion means the high-level business policy defines what it needs; low-level infrastructure satisfies that need.**

---

## 2. 30-Second Elevator Pitch
"In Atlas, a shipment request traverses an explicit chain of single-responsibility stages: JWT authentication establishes identity, resource-level authorization binds the trusted tenant context, thin HTTP controllers delegate transport DTOs to application services, and application use cases orchestrate carrier adapter selection without leaking carrier SDKs. We invert dependencies so the core booking use case defines the `CarrierPort` and `ShipmentRepository` interfaces, while infrastructure adapters implement them. When external carrier calls time out, Atlas persists truthful uncertainty rather than fabricating success or premature failure."

---

## 3. The Whiteboard Sketch

```text
[ Incoming HTTP Request ]
          │
          ▼
┌────────────────────────┐
│  Security Interceptor  │ (AuthN: Validates JWT ➔ AuthZ: Derives TenantContext)
└─────────┬──────────────┘
          │
          ▼
┌────────────────────────┐
│  Shipment Controller   │ (Transport translation only; delegates command)
└─────────┬──────────────┘
          │
          ▼
┌────────────────────────┐
│ BookShipment Use Case  │ (Coordinates invariants, domain entity, & ports)
└─────────┬──────────────┘
     ┌────┴──────────────────────────┐
     ▼                               ▼
┌────────────────────────┐     ┌────────────────────────┐
│  CarrierPort (Adapter) │     │  ShipmentRepository    │
│  (FedEx / UPS Adapter) │     │  (Postgres Persistence)│
└────────────────────────┘     └────────────────────────┘
```

---

## 4. The Atlas Scenario
- **Business Context:** A shipper initiates an HTTP `POST /api/v1/shipments` request with tenant credentials and package details.
- **The Architectural Hazard:** In monolithic or poorly layered systems, the controller method validates tokens, extracts tenant IDs from unverified JSON bodies, makes raw HTTP calls to FedEx SDKs, opens database connections, and formats responses—creating a fragile, untestable bottleneck.
- **Atlas Resolution:** Separation of transport, coordination, domain rules, and external provider translation into distinct layers with strict inward dependency direction.

---

## 5. Diagram & Boundary Map
- **Diagram:** [Shipment Request Flow](../diagrams/shipment-request-flow.svg)
- **Controller Owns:** Deserialization, HTTP status codes, headers, and public error representation.
- **Application Service Owns:** Workflow coordination, domain entity lifecycle, carrier port invocation, and persistence coordination.
- **Carrier Adapter Owns:** Carrier SDK translation, carrier authentication strategies, and external HTTP execution.
- **Repository Owns:** Mapping domain state to PostgreSQL relational schemas.

---

## 6. The Central Tradeoff

| What We Buy | What We Pay |
|---|---|
| **Layered Independence:** Controllers, use cases, and carrier SDKs can be refactored or replaced independently. | **Indirection & Boilerplate:** Multiple distinct classes (Controller, Command DTO, Use Case, Port, Adapter, Entity, Repository) for a single request path. |
| **Testability:** The entire booking workflow can be tested without spinning up an HTTP server or connecting to a live carrier. | **Coordination Overhead:** Data must be mapped between transport DTOs, domain models, and provider SDK models. |
| **Truthful State:** Ambiguous timeouts are handled explicitly without corrupting business state. | **Multi-Model Maintenance:** Engineers must maintain separate domain, transport, and adapter models. |

---

## 7. 2-Minute Architectural Defense

### Context
"When implementing a business request journey, teams often debate whether thin controllers with application services introduce unnecessary indirection."

### Decision
"Atlas enforces thin controllers, dependency inversion, and strict layer isolation (ADR-0002). The controller only handles HTTP concerns and passes an immutable `TenantContext` and `BookShipmentCommand` to the `BookShipmentService`. The service coordinates the domain entity and calls the outbound `CarrierPort`."

### Tradeoffs Accepted
"We accept the boilerplate of maintaining distinct transport, domain, and persistence models in exchange for decoupling business policy from volatile delivery mechanisms (HTTP/gRPC/CLI) and third-party SDKs."

### Alternatives Rejected
1. *Smart Controllers (Fat Controllers):* Rejected because embedding carrier SDK calls and SQL inside controllers destroys unit testability and ties domain logic to HTTP semantics.
2. *Domain Entities Calling External APIs:* Rejected because domain entities must remain pure in-memory models representing invariants, free of I/O side effects.

### Revisit Trigger
"Revisit if Atlas pivots from a multi-carrier enterprise platform to an ultra-low-latency single-carrier proxy where sub-millisecond serialization overhead outweighs architectural maintainability."

---

## 8. Interview Questions, Follow-ups & Red Flags

### Q1: "The caller provides a valid JWT containing `tenantId: tenant-A`, but the JSON body says `tenantId: tenant-B`. Which wins?"
- **Strong Answer:** "The authenticated identity in the validated token always controls. Client-supplied body fields are untrusted input. Atlas must validate the token's claims at the security boundary, construct an immutable `TenantContext`, and reject the request with HTTP 403/400 if body parameters attempt cross-tenant privilege escalation."

### Q2: "The carrier call hangs for 5 seconds and returns an HTTP 504 Gateway Timeout. What state does Atlas persist?"
- **Strong Answer:** "Atlas persists an explicit uncertain state (`UNKNOWN_PENDING_RECONCILIATION`), not `FAILED`. A timeout means the carrier may have successfully booked the shipment, but the response was lost. Marking it failed could cause the shipper to retry and create a duplicate booking. Background reconciliation resolves the ambiguity."

### 🚩 Common Interview Pitfalls
- ❌ **Confusing Package Layout with Inversion of Control:** Thinking dependency inversion is just putting interfaces in one folder and classes in another. (It is about high-level policy defining the interface contract that low-level infrastructure implements).
- ❌ **Treating Timeouts as Failures:** Assuming a network timeout means the remote operation did not happen.
- ❌ **Bypassing Tenant Authorization:** Checking permissions globally without scoping queries with `WHERE tenant_id = :authenticated_tenant_id`.

---

**Deep dive:** [Chapter 2 — Following a Shipment](../course/chapter-02-following-a-shipment.md) · [ADR-0002](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md) · [Exercise 2](../exercises/exercise-02-trace-a-shipment.md)
