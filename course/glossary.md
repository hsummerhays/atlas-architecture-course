# Atlas Architecture Course — Glossary

A concise architectural reference for the Atlas Enterprise Platform course. Each entry defines the concept, explains its role within Atlas, and links to related architectural ideas.

---

### Anti-Corruption Layer (ACL)

A translation boundary that isolates a domain model from external foreign models, preventing third-party contracts, schemas, or semantics from leaking into internal business logic.

**In Atlas:** Carrier adapters act as anti-corruption layers, translating between carrier-specific request/response schemas and the canonical shipment model.

**Related:** [Canonical Shipment Model](#canonical-shipment-model), [Ports and Adapters](#ports-and-adapters)

---

### Architecture Decision Record (ADR)

A structured, version-controlled document recording an important architectural choice, its context, considered alternatives, accepted tradeoffs, consequences, and review triggers.

**In Atlas:** ADRs preserve why decisions were made—such as adopting transactional outboxes, isolating carrier adapters, or separating shipping and agent execution planes—so rationale is not lost to organizational memory drift.

**Related:** [Architectural Debt](#architectural-debt), [Fitness Function](#fitness-function)

---

### Architectural Debt

The cumulative cost of deferred architectural work, obsolete assumptions, unnecessary coupling, or temporary bypasses that degrade maintainability, scalability, or operational safety over time.

**In Atlas:** Monitored via drift detection and explicit review triggers rather than allowed to accumulate silently behind local incident patches.

**Related:** [Architecture Decision Record (ADR)](#architecture-decision-record-adr), [Fitness Function](#fitness-function)

---

### Backoff and Jitter

A retry pacing strategy where delay increases exponentially after successive failures (backoff) and includes randomized variance (jitter) to prevent retrying clients from synchronizing into destructive retry waves.

**In Atlas:** Applied to carrier adapter outbound calls and asynchronous event consumers to protect recovering downstream dependencies from thundering herds.

**Related:** [Circuit Breaker](#circuit-breaker), [Retry Budget](#retry-budget)

---

### Bounded Context

An explicit boundary within a domain where a particular ubiquitous language and domain model apply consistently, isolating differing meanings of similar business terms.

**In Atlas:** Establishes clean separation between shipment booking, event notification, accounting reconciliation, and developer agent workflows.

**Related:** [Canonical Shipment Model](#canonical-shipment-model), [Control Plane and Data Plane](#control-plane-and-data-plane)

---

### Bulkhead

A structural fault-isolation pattern that partitions resources (such as thread pools, connections, CPU, or memory) so that failure or resource starvation in one area cannot exhaust capacity across the entire system.

**In Atlas:** Isolated connection pools and dedicated worker threads prevent a slow or failing carrier from exhausting Atlas's synchronous API capacity.

**Related:** [Circuit Breaker](#circuit-breaker), [Rate Limiting](#rate-limiting)

---

### Canonical Shipment Model

Atlas’s authoritative, domain-centric representation of shipment data and lifecycle transitions, independent of any third-party provider or transport protocol.

**In Atlas:** Clients and application workflows interact solely with the canonical shipment model, shielding internal logic from carrier API changes.

**Related:** [Anti-Corruption Layer (ACL)](#anti-corruption-layer-acl), [Ports and Adapters](#ports-and-adapters)

---

### Circuit Breaker

A stability mechanism that monitors calls to an external dependency. When failure thresholds are exceeded, the circuit trips open, immediately failing subsequent requests without calling the struggling dependency, allowing it time to recover.

**In Atlas:** Protects external carrier endpoints and Atlas thread capacity during upstream outages, resetting automatically once health probes succeed.

**Related:** [Backoff and Jitter](#backoff-and-jitter), [Bulkhead](#bulkhead)

---

### Control Plane and Data Plane

An architectural separation of concerns where the **data plane** executes high-throughput, low-latency business transactions (e.g., booking shipments), while the **control plane** manages configuration, lifecycle, security policy, and deployment governance.

**In Atlas:** `atlas-shipping-app` processes core shipment traffic on the data plane, while `atlas-agent-platform` and deployment pipelines govern platform operations on the control plane.

**Related:** [Least Privilege](#least-privilege), [Trust Boundary](#trust-boundary)

---

### Correlation ID and Causation ID

Contextual identifiers propagated through distributed call chains and asynchronous messages. A **Correlation ID** ties together all operations within a single end-to-end transaction; a **Causation ID** identifies the immediate preceding event or message that triggered the current action.

**In Atlas:** Attached to HTTP requests, database outbox entries, and SNS/SQS event headers to enable complete distributed tracing and incident investigation.

**Related:** [Distributed Tracing](#distributed-tracing), [Structured Logging](#structured-logging)

---

### Dead-Letter Queue (DLQ)

A dedicated secondary queue that holds messages that cannot be processed successfully after exceeding maximum retry attempts or encountering unrecoverable business errors.

**In Atlas:** SQS DLQs capture failed downstream event reactions (e.g., tracking or accounting intake) for investigation, manual remediation, or automated redelivery without blocking the primary consumer queue.

**Related:** [Idempotency](#idempotency), [Transactional Outbox](#transactional-outbox)

---

### Distributed Tracing

A diagnostic technique that tracks requests as they flow across process boundaries, networks, queues, and databases by passing trace identifiers and span contexts.

**In Atlas:** OpenTelemetry spans connect the synchronous API booking request, outbox database write, background publisher, SNS/SQS transport, and asynchronous consumer execution.

**Related:** [Correlation ID and Causation ID](#correlation-id-and-causation-id), [Golden Signals](#golden-signals)

---

### Event-Driven Architecture

An architectural style where decoupled software components communicate asynchronously by producing, detecting, and reacting to significant facts (events) that have already occurred.

**In Atlas:** Once a booking transaction commits, a `ShipmentBooked` event is published to notify notification, analytics, and accounting services asynchronously.

**Related:** [Eventual Consistency](#eventual-consistency), [Transactional Outbox](#transactional-outbox)

---

### Eventual Consistency

A consistency model where distributed replicas or downstream systems converge to a consistent state over time rather than guaranteeing immediate, atomic synchronization across all nodes.

**In Atlas:** Synchronous booking writes local state atomically; downstream reactions (e.g., email notifications, tracking initialization) converge asynchronously via reliable events.

**Related:** [Event-Driven Architecture](#event-driven-architecture), [Transactional Outbox](#transactional-outbox)

---

### Expand-and-Contract Pattern (Parallel Run)

A safe migration technique for evolving database schemas, APIs, or service boundaries in phases: first expanding the contract to support both old and new formats, migrating consumers/readers, and finally contracting by removing the deprecated format.

**In Atlas:** Used when upgrading carrier adapter contracts, event payload schemas, and database column structures without downtime or coordinated big-bang deployments.

**Related:** [Strangler Application Pattern](#strangler-application-pattern), [Tolerant Reader](#tolerant-reader)

---

### Fitness Function

An automated, objective metric or test used to evaluate and enforce architectural constraints, boundary rules, and quality attributes continuously in CI/CD.

**In Atlas:** Module dependency tests (e.g., ArchUnit-style tests) ensure shipping code never imports agent platform internals, and secret linters ensure manifests contain no unauthorized credentials.

**Related:** [Architecture Decision Record (ADR)](#architecture-decision-record-adr), [Guardrail](#guardrail)

---

### Golden Signals

The four essential metrics for monitoring user-facing distributed systems: **Latency** (time to service a request), **Traffic** (demand/throughput), **Errors** (rate of failing requests), and **Saturation** (fraction of capacity utilized).

**In Atlas:** Serves as the primary operational telemetry dashboard for API endpoints, carrier adapters, and background event processors.

**Related:** [Distributed Tracing](#distributed-tracing), [SLI, SLO, and SLA](#sli-slo-and-sla)

---

### Guardrail

An automated safety mechanism embedded into tools, libraries, or deployment pipelines that guides developers toward safe architectural practices and prevents invalid states without requiring manual approval gates.

**In Atlas:** Branch protections, automated contract tests, and pre-commit security checks act as guardrails that prevent unauthorized changes from reaching production.

**Related:** [Fitness Function](#fitness-function), [Least Privilege](#least-privilege)

---

### Idempotency

The property of an operation whereby performing it multiple times produces the same result as performing it once, without duplicate side effects.

**In Atlas:** Event consumers record processed message identifiers in an inbox table, ensuring that duplicated SQS messages do not trigger duplicate billing or notifications.

**Related:** [Dead-Letter Queue (DLQ)](#dead-letter-queue-dlq), [Transactional Outbox](#transactional-outbox)

---

### Least Privilege

A foundational security principle stating that every module, user, service account, and process should operate using only the minimal set of permissions necessary to complete its legitimate function.

**In Atlas:** The shipping runtime possesses only database and carrier API access, while agent and build automation identities have strict permissions that prohibit self-approving or deploying code changes.

**Related:** [Managed Identity](#managed-identity), [Trust Boundary](#trust-boundary)

---

### Managed Identity (Workload Identity)

An identity provided by a cloud platform (e.g., AWS IAM Roles for Service Accounts) that authenticates applications without embedding long-lived static API keys or credentials in code or configuration files.

**In Atlas:** Containers obtain short-lived, rotatable STS tokens scoped exclusively to their designated SQS queues, databases, or carrier secret stores.

**Related:** [Least Privilege](#least-privilege), [Trust Boundary](#trust-boundary)

---

### Ports and Adapters (Hexagonal Architecture)

An architectural pattern that isolates application core logic behind abstract interfaces (ports) and implements external interactions (databases, HTTP, third-party APIs) via concrete adapters.

**In Atlas:** The shipment use case interacts with an abstract `CarrierPort`; concrete adapters handle FedEx, UPS, or USPS API integrations.

**Related:** [Anti-Corruption Layer (ACL)](#anti-corruption-layer-acl), [Canonical Shipment Model](#canonical-shipment-model)

---

### Rate Limiting

A traffic management control that restricts the number of requests an entity (tenant, IP, or service) can execute within a specified time interval.

**In Atlas:** Protects Atlas services from noisy tenants and prevents outbound carrier adapters from violating third-party API rate quotas.

**Related:** [Bulkhead](#bulkhead), [Circuit Breaker](#circuit-breaker)

---

### Retry Budget

A resource-bounding policy that limits the maximum percentage or absolute rate of retries permitted across a service, preventing cascading retry storms from consuming remaining backend capacity during an incident.

**In Atlas:** Bounded retry counts and global retry limits ensure outbound carrier calls and event consumers fail fast once an outage is detected.

**Related:** [Backoff and Jitter](#backoff-and-jitter), [Circuit Breaker](#circuit-breaker)

---

### SLI, SLO, and SLA

- **SLI (Service Level Indicator):** A quantifiable metric measuring service performance (e.g., booking latency < 500ms).
- **SLO (Service Level Objective):** An internal target threshold for an SLI that the engineering team commits to maintaining (e.g., 99.9% of bookings meet the SLI).
- **SLA (Service Level Agreement):** A formal business contract specifying consequences or remedies if service levels fall below agreed commitments.

**In Atlas:** Internal SLOs trigger automated alerts and engineering focus before contractual customer SLAs are violated.

**Related:** [Golden Signals](#golden-signals), [Structured Logging](#structured-logging)

---

### Strangler Application Pattern

A legacy modernization and migration pattern that incrementally replaces specific capabilities of an existing system with new services behind an intercepting facade until the old system can be safely decommissioned.

**In Atlas:** Used when transitioning legacy middleware routing and carrier endpoints to modern Atlas platform services without a big-bang cutover.

**Related:** [Expand-and-Contract Pattern (Parallel Run)](#expand-and-contract-pattern-parallel-run), [Tolerant Reader](#tolerant-reader)

---

### Structured Logging

A logging practice where log events are emitted as machine-readable key-value pairs (e.g., JSON) with consistent schemas, including context like tenant ID, shipment ID, trace ID, and duration.

**In Atlas:** Enables fast log indexing, multi-tenant filtering, and automated anomaly detection without fragile string parsing.

**Related:** [Correlation ID and Causation ID](#correlation-id-and-causation-id), [Distributed Tracing](#distributed-tracing)

---

### Tolerant Reader

A design practice where a consumer only parses the specific fields it requires from an API or message payload and safely ignores unrecognized or newly added fields.

**In Atlas:** Enables non-breaking schema expansions in event payloads and carrier responses without requiring simultaneous consumer upgrades.

**Related:** [Expand-and-Contract Pattern (Parallel Run)](#expand-and-contract-pattern-parallel-run)

---

### Transactional Outbox

A reliability pattern that stores business-state changes and the intent to publish an event in the same local database transaction. A separate publisher process later reads the outbox table and delivers the events to the message broker.

**In Atlas:** Guarantees that a committed shipment booking will never lose its corresponding `ShipmentBooked` event, even if the application crashes or the message broker is temporarily unreachable.

**Related:** [Dead-Letter Queue (DLQ)](#dead-letter-queue-dlq), [Event-Driven Architecture](#event-driven-architecture), [Idempotency](#idempotency)

---

### Trust Boundary

A conceptual or network boundary separating subsystems that operate under different levels of trust, security clearance, or administrative control.

**In Atlas:** Established between public internet clients and Atlas APIs, between Atlas and external carrier networks, and between the shipping execution runtime and automated engineering agent processes.

**Related:** [Control Plane and Data Plane](#control-plane-and-data-plane), [Least Privilege](#least-privilege)

---

### Walking Skeleton

A minimal, end-to-end implementation of the system's primary user journey that links all architectural layers (UI/API, use cases, persistence, external adapters, and deployment pipeline) without full business functionality.

**In Atlas:** Validated the initial request path from API gateway down to mock carrier adapter and database commit before broad platform feature development began.

**Related:** [Ports and Adapters](#ports-and-adapters), [The Architect's Method](#architecture-decision-record-adr)
