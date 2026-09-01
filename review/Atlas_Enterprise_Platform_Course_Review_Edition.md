# Atlas Enterprise Platform
# Software Architecture Course
## Review & Update Edition

**Condensed editorial control copy for structured review, maintenance, and future revision.**

Prepared September 1, 2026

## How to Use This Edition

- This is a condensed editorial edition, not a verbatim transcript of the narrated course.
- Review one lesson brief at a time and use its Update Notes fields to capture revisions.
- Keep the narrated course ([course/](../course/)) as the authoritative teaching edition and this document as the maintainable control copy.
- When an architectural decision changes, update the lesson brief, ADR register, current/target state, and related fitness functions together.

## Review Status Key

| Status | Meaning | Action |
|---|---|---|
| Unreviewed | No editorial pass completed | Read and annotate |
| Revise | Content or structure should change | Create a specific revision |
| Validated | Accurately reflects current Atlas direction | Preserve unless assumptions change |
| Superseded | Replaced by a later architectural direction | Retain history and link replacement |

## Lifecycle Vocabulary

The review edition and teaching chapters track different work:

- **Editorial-review status:** Unreviewed, Revise, Validated, or Superseded. This records whether a lesson brief still reflects the agreed Atlas direction.
- **Teaching-chapter status:** Draft, Technical Review, Editorial Review, or Ready. This records whether the narrated learning asset is ready to publish.

A teaching chapter may be in Draft while its underlying review brief is Validated. Neither status implies that a detailed implementation claim has been verified.

## Terminology Convention

Use **canonical shipment model** as the preferred Atlas-specific term. Use **canonical domain model** only when discussing the broader architectural pattern. Carrier-specific request and response models remain at the integration boundary.

## Course Map
- **Chapter 1 — The Business Problem** — Finding the Domain Before Choosing the Framework
- **Chapter 2 — Following a Shipment** — Responsibility, Dependency Direction, and the Request Path
- **Chapter 3 — The Shipment Leaves a Message** — Events, Asynchronous Reactions, and Reliable Publication
- **Chapter 4 — Security** — Identity, Authority, Data Protection, and Supply-Chain Boundaries
- **Chapter 5 — Architectural Tradeoffs** — Evaluating Options, Sacrifices, and Reversibility
- **Chapter 6 — Failure Is Part of the Architecture** — Resilience, Fault Isolation, and Distributed Failure Modes
- **Chapter 7 — Observability: Understanding a Running System** — Making Atlas Explain Its Behavior
- **Chapter 8 — Evolutionary Architecture** — Fitness Functions, Safe Evolution, and Architecture Ownership
- **Chapter 9 — The Architect’s Method** — From Problem and Blueprint to Practice and Communication
- **[Course Glossary](../course/glossary.md)** — Architectural terms, patterns, and Atlas context.

---
# Chapter 1 — The Business Problem
## Finding the Domain Before Choosing the Framework
### Lesson Summary
Atlas begins as a response to carrier integration pressure. Internal systems need one reliable shipment interface while carriers expose different APIs, authentication models, data structures, and failure semantics. The chapter establishes the canonical model, domain language, separation of concerns, and the rule that extensibility must follow demonstrated variation.
### Core Concepts
- Business outcome before technology
- Canonical shipment model
- Carrier variation behind adapters
- Domain ownership and ubiquitous language
- Separation of concerns
- Avoid speculative generality
### Atlas Decisions Preserved
- Atlas owns a stable shipment-booking model.
- Carrier-specific representations remain at the integration boundary.
- New abstractions are introduced only when a lesson or demonstrated limitation requires them.
### Architecture Principle
> Begin with the business outcome and isolate proven sources of variation behind explicit boundaries.
### Anti-Pattern
Designing a universal middleware framework before implementing one real shipment journey.
### Review Questions
- Can the business problem be explained without naming a framework?
- Which concepts belong to Atlas rather than a carrier?
- Which proposed extension points solve demonstrated variation?
### Related Assets
- **Diagram:** [Atlas System Context](../diagrams/atlas-system-context.svg)
- **ADR:** [ADR-0001 — Adopt Canonical Shipment Model](../adr-examples/ADR-0001-canonical-shipment-model.md)
- **Exercise:** [Exercise 1 — Find the Architecture in the Business Problem](../exercises/exercise-01-find-architecture.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0001; `atlas-shipping-app` core domain |

---
# Chapter 2 — Following a Shipment
## Responsibility, Dependency Direction, and the Request Path
### Lesson Summary
A shipment request travels through authentication, authorization, validation, application coordination, carrier selection, authentication strategy, and persistence. The lesson uses the complete request path to distinguish orchestration from domain knowledge and demonstrates inversion of control, single responsibility, and explicit dependency direction.
### Core Concepts
- JWT authentication and tenant context
- Authorization at the resource boundary
- Controller versus application service
- Carrier registry and adapter selection
- Carrier authentication strategies
- Dependency inversion
- Single Responsibility Principle
### Atlas Decisions Preserved
- Controllers translate transport requests and delegate use cases.
- Application services coordinate the workflow but do not own every rule.
- Carrier SDK models and authentication details stay inside carrier adapters and strategies.
### Architecture Principle
> Place each decision with the component that has the knowledge and the correct reason to change.
### Anti-Pattern
A controller that validates security, selects carriers, calls SDKs, writes SQL, and constructs public responses directly.
### Review Questions
- Where is tenant identity established?
- Which layer owns business state transitions?
- Can carrier authentication change without rewriting shipment orchestration?
### Related Assets
- **Diagram:** [Shipment Request Flow](../diagrams/shipment-request-flow.svg)
- **ADR:** [ADR-0002 — Isolate Carrier Integrations Behind Ports and Adapters](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md)
- **Exercise:** [Exercise 2 — Trace a Shipment](../exercises/exercise-02-trace-a-shipment.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0002; `atlas-shipping-app` carrier ports |

---
# Chapter 3 — The Shipment Leaves a Message
## Events, Asynchronous Reactions, and Reliable Publication
### Lesson Summary
Shipment booking is separated from notification, accounting, tracking, and analytics. Atlas publishes durable business facts through a transactional outbox, uses SNS for fan-out, gives each consumer its own SQS queue, accepts at-least-once delivery, and requires bounded retries, dead-letter handling, idempotency, and reconciliation.
### Core Concepts
- Commands versus events
- Synchronous preconditions versus asynchronous reactions
- SNS fan-out and consumer-owned SQS queues
- At-least-once delivery
- Retries, backoff, jitter, and DLQs
- Idempotent consumers
- Transactional outbox
- Eventual consistency
### Atlas Decisions Preserved
- Shipment state and event-publication intent commit in one local transaction.
- Each independent consumer owns its queue, retries, DLQ, and business effect.
- Duplicate delivery is expected and handled rather than denied.
### Architecture Principle
> Preserve the authoritative business fact first, then distribute independent reactions through durable and observable messaging.
### Anti-Pattern
Saving the shipment and publishing directly to the broker as two unrelated writes.
### Review Questions
- What does ShipmentBooked mean exactly?
- Which downstream work can be delayed?
- How does each consumer prevent duplicate business effects?
### Related Assets
- **Diagram:** [Transactional Outbox & Message Flow](../diagrams/outbox-message-flow.svg)
- **ADRs:** [ADR-0003 — Transactional Outbox](../adr-examples/ADR-0003-transactional-outbox.md), [ADR-0004 — Idempotent Message Consumption](../adr-examples/ADR-0004-idempotent-message-consumption.md)
- **Exercise:** [Exercise 3 — Break the Message Flow](../exercises/exercise-03-break-the-message-flow.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0003, ADR-0004; `atlas-shipping-app` outbox publisher |

---
# Chapter 4 — Security
## Identity, Authority, Data Protection, and Supply-Chain Boundaries
### Lesson Summary
Security is treated as architecture rather than an authentication add-on. Atlas establishes identity, performs tenant-aware authorization, validates untrusted input, protects secrets and sensitive data, limits workload authority, and separates the shipping business plane from the engineering-agent control plane.
### Core Concepts
- Authentication versus authorization
- Tenant-aware resource access
- Input validation and injection defense
- Encryption in transit and at rest
- Secret isolation and rotation
- Least-privilege workload identities
- Supply-chain security
- Agent authority and separation of duties
### Atlas Decisions Preserved
- Shipping receives only shipping credentials and permissions.
- Agents may propose changes but may not approve or merge their own work.
- Security controls are enforced through code, manifests, CI, repository policy, and runtime identity.
### Architecture Principle
> Establish identity, grant the minimum authority, validate every trust boundary, and make privilege visible and revocable.
### Anti-Pattern
One broad Atlas service account and one shared secret set for every runtime and automation task.
### Review Questions
- What asset does each control protect?
- Can a valid user access another tenant’s shipment?
- What is the blast radius of a compromised agent identity?
### Related Assets
- **Diagram:** [Security Architecture & Trust Boundaries](../diagrams/security-trust-boundaries.svg)
- **ADR:** [ADR-0005 — Managed Identity, Resource Scoping, and Automation Governance](../adr-examples/ADR-0005-managed-identity-and-secret-handling.md)
- **Exercise:** [Exercise 4 — Threat-Model Atlas](../exercises/exercise-04-threat-model-atlas.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Security & Architecture |
| Proposed changes | None |
| Related ADRs or code | ADR-0005; cloud IAM policies |

---
# Chapter 5 — Architectural Tradeoffs
## Evaluating Options, Sacrifices, and Reversibility
### Lesson Summary
Atlas evaluates competing architectural properties by asking: "What are we buying, and what are we paying for it?" The chapter explores simplicity versus flexibility, immediate versus eventual consistency, performance versus reliability, and delivery speed versus operational safety, emphasizing explicit and reversible decisions.
### Core Concepts
- YAGNI and option value
- Strong local consistency versus bounded eventual consistency
- Performance versus resilience trade
- Continuous delivery versus operational safety
- Reversibility of decisions
- Accidental complexity versus essential complexity
### Atlas Decisions Preserved
- Carrier adapters are justified by observed provider variation.
- Shipment state and outbox intent are locally atomic; downstream projections converge.
- Reliability and business correctness are preserved before raw throughput.
### Architecture Principle
> Make important architectural tradeoffs visible, deliberate, and reversible where practical.
### Anti-Pattern
Building a generic framework whose primary customer is an imagined future requirement.
### Review Questions
- What are we buying with this abstraction, and what are we paying for it?
- Which facts must change atomically, and which may lag?
- What behavior degrades first when capacity is exhausted?
### Related Assets
- **Diagram:** [Architectural Tradeoff Map](../diagrams/architecture-tradeoff-map.svg)
- **Exercise:** [Exercise 5 — Make the Tradeoff](../exercises/exercise-05-make-the-tradeoff.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0001, ADR-0003 |

---
# Chapter 6 — Failure Is Part of the Architecture
## Resilience, Fault Isolation, and Distributed Failure Modes
### Lesson Summary
Distributed systems are defined by behavior during failure. Atlas bounds external work with strict timeouts, prevents retry storms using exponential backoff with full jitter, contains carrier failure using circuit breakers and bulkheads, and ensures partial failures degrade gracefully without cascading collapse.
### Core Concepts
- Normalizing distributed failure
- Transient versus terminal errors
- Timeouts and deadline propagation
- Exponential backoff and full jitter
- Circuit breaker state transitions (Closed, Open, Half-Open)
- Thread and connection bulkheads
- Dead-letter queues (DLQs)
### Atlas Decisions Preserved
- Every external call has a bounded timeout and one clear retry owner.
- Carrier capacity is isolated by carrier-specific bulkheads and circuits.
- A dependency is not fully designed until its failure behavior is understood.
### Architecture Principle
> Construct systems in which failures can happen without becoming catastrophes.
### Anti-Pattern
Increasing retries, threads, and replicas independently until downstream dependencies collapse.
### Review Questions
- How does the system behave when an external carrier hangs?
- What prevents retries from synchronizing into a destructive wave?
- How is blast radius contained across multiple tenants and providers?
### Related Assets
- **Diagram:** [Distributed Resilience & Fault Containment Flow](../diagrams/resilience-flow.svg)
- **ADR:** [ADR-0006 — Explicit Distributed Resilience Policies](../adr-examples/ADR-0006-explicit-resilience-policies.md)
- **Exercise:** [Exercise 6 — Design for Failure](../exercises/exercise-06-design-for-failure.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0006; Resilience4j client policies |

---
# Chapter 7 — Observability: Understanding a Running System
## Making Atlas Explain Its Behavior
### Lesson Summary
Logs, metrics, traces, health checks, and service-level objectives are designed around operational questions. The chapter distinguishes technical telemetry from business outcomes, explains context propagation across synchronous and asynchronous paths, and establishes golden signal monitoring, SLO error budgets, and evidence-driven diagnosis.
### Core Concepts
- Structured logs with tenant and trace context
- Golden signals (Latency, Traffic, Errors, Saturation)
- Distributed traces and W3C traceparent propagation
- Correlation ID and Causation ID
- SLI, SLO, and SLA definitions
- Alerting on user-facing degradation
- Incident triage runbooks
### Atlas Decisions Preserved
- Every important operation carries correlation, causation, tenant, and version context.
- Health endpoints do not pretend every dependency is equally critical.
- SLOs are capability-specific and owned.
### Architecture Principle
> A production system should be designed not only to perform its work, but to explain its behavior.
### Anti-Pattern
Declaring the platform healthy because every pod is running while business workflows are failing.
### Review Questions
- Can Atlas distinguish carrier failure from database failure?
- How does trace context flow from HTTP requests into asynchronous queues?
- Can an operator connect a regression to a deployed version?
### Related Assets
- **Diagram:** [Observability Context & Trace Propagation](../diagrams/observability-correlation.svg)
- **ADR:** [ADR-0007 — OpenTelemetry Instrumentation and Context Propagation Boundary](../adr-examples/ADR-0007-opentelemetry-instrumentation-boundary.md)
- **Exercise:** [Exercise 7 — Diagnose the Incident](../exercises/exercise-07-diagnose-the-incident.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | SRE & Architecture |
| Proposed changes | None |
| Related ADRs or code | ADR-0007; OpenTelemetry SDK configuration |

---
# Chapter 8 — Evolutionary Architecture
## Fitness Functions, Safe Evolution, and Architecture Ownership
### Lesson Summary
Live systems evolve through parallel change rather than atomic cutovers. Atlas implements automated architectural fitness functions to prevent decay, executes expand-and-contract migrations, preserves backward and forward schema compatibility, and sustains architecture through clear domain, service, and data ownership.
### Core Concepts
- Architectural erosion and drift
- Static, dynamic, and operational fitness functions
- ArchUnit-style dependency testing
- Expand-and-contract (parallel run) pattern
- Tolerant readers and schema evolution
- Domain, service, data, and migration ownership
- Architecture Decision Records (ADRs)
### Atlas Decisions Preserved
- Shipping must not depend on agent implementation.
- Readers become tolerant before producers emit incompatible forms.
- Record significant choices close to the code with explicit review triggers.
### Architecture Principle
> A good architecture does not merely satisfy today's requirements. It creates a disciplined way to become tomorrow's architecture.
### Anti-Pattern
Renaming fields, schemas, routes, and services in one coordinated big-bang release.
### Review Questions
- Which architectural rules are enforced by automated fitness functions?
- How does the expand-and-contract pattern eliminate maintenance windows?
- What evidence defines migration completion?
### Related Assets
- **Diagram:** [Evolutionary Architecture Feedback Loop](../diagrams/evolutionary-architecture-loop.svg)
- **ADR:** [ADR-0008 — Automated Architectural Fitness Functions in CI/CD](../adr-examples/ADR-0008-architectural-fitness-functions.md)
- **Exercise:** [Exercise 8 — Evolve Atlas Safely](../exercises/exercise-08-evolve-atlas-safely.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0008; CI ArchUnit test suite |

---
# Chapter 9 — The Architect’s Method
## From Problem and Blueprint to Practice and Communication
### Lesson Summary
The reusable method synthesizes outcomes, actors, journeys, constraints, quality-attribute scenarios, domain models, boundaries, failure matrices, walking skeletons, production evidence, and progressive communication tailored to executives, product managers, engineers, and operators.
### Core Concepts
- Problem statements and actor journeys
- Domain models and ubiquitous language
- Ports, adapters, and transaction boundaries
- Failure and recovery matrices
- Walking skeletons and thin vertical slices
- Production feedback and hypothesis testing
- Audience-tailored progressive disclosure
- Defending architectural decisions in reviews and interviews
### Atlas Decisions Preserved
- Begin with the outcome and constraints; select technology only after boundaries are defined.
- Validate end-to-end assumptions early with a walking skeleton.
- Evolve architecture based on recurring structural evidence rather than technology fashion.
### Architecture Principle
> Make important decisions explicit so that a system can serve the business today, survive failure, remain understandable, and change responsibly tomorrow.
### Anti-Pattern
Presenting one enormous diagram—or one empty business slogan—to every audience.
### Review Questions
- What decision must the audience make?
- Are transaction, authority, and failure boundaries explicit?
- What is the minimum responsible design?
### Related Assets
- **Diagram:** [The Architect's Method Process Flow](../diagrams/architects-method.svg)
- **Exercise:** [Exercise 9 — Architect a New Capability (Capstone)](../exercises/exercise-09-architect-a-new-capability.md)
### Update Notes

| Field | Value |
|---|---|
| Status | Validated |
| Owner | Architecture Team |
| Proposed changes | None |
| Related ADRs or code | ADR-0001 through ADR-0008 |

---
# Appendix A — Course-Wide Architecture Principles
- **Responsibility:** Give each responsibility a dedicated home.
- **Boundaries:** Create boundaries where reasons to change, authority, ownership, failure, or lifecycle differ.
- **Consistency:** Use the strongest consistency required to protect each invariant and bounded eventual consistency elsewhere.
- **Reliability:** Preserve truthful state, bound work, isolate failure, and design recovery before failure occurs.
- **Security:** Establish identity, grant minimum authority, validate trust boundaries, and make privilege revocable.
- **Simplicity:** Preserve only future options whose value justifies their present cost.
- **Delivery:** Release small, compatible, observable changes and expand exposure only while evidence remains healthy.
- **Evolution:** Turn important decisions into continuously evaluated constraints and change them deliberately.
- **Ownership:** Assign important outcomes, contracts, datasets, and capabilities to accountable owners.
- **Evidence:** Treat architecture as a hypothesis tested by business, operational, security, delivery, and human outcomes.
- **Communication:** Explain the same architectural truth through the view required for each audience’s decision.

# Appendix B — Atlas Current and Target State
## Current State
- `atlas-shipping-app` is the independently packaged and deployed business runtime.
- `atlas-agent-platform` is independently built and tested but not independently containerized or deployed.
- CI tests both modules and deploys shipping only.
- Shipping manifests contain no GitHub, Claude, webhook, or other agent-only secrets.
- Airflow still uses legacy middleware-oriented naming or routing for agent work.
## Target State
- Dedicated agent image, Kubernetes Deployment, Service, workload identity, and secrets.
- Independent agent CI/CD deployment path.
- Direct `atlas_agent_api` Airflow routing.
- Removal of legacy middleware routes, names, permissions, and compatibility paths after verified cutover.
## Agent Deployment Trigger
Complete runtime separation when production agent workload, distinct scaling, security ownership, or release coupling justifies the operating cost.

# Appendix C — Initial ADR Register
- [ADR-0001 — Adopt Canonical Shipment Model](../adr-examples/ADR-0001-canonical-shipment-model.md)
- [ADR-0002 — Isolate Carrier Integrations Behind Ports and Adapters](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md)
- [ADR-0003 — Guaranteed Event Publication via Transactional Outbox](../adr-examples/ADR-0003-transactional-outbox.md)
- [ADR-0004 — Idempotent Message Consumption with Dedicated Consumer Queues](../adr-examples/ADR-0004-idempotent-message-consumption.md)
- [ADR-0005 — Managed Identity, Resource Scoping, and Automation Governance](../adr-examples/ADR-0005-managed-identity-and-secret-handling.md)
- [ADR-0006 — Explicit Distributed Resilience Policies](../adr-examples/ADR-0006-explicit-resilience-policies.md)
- [ADR-0007 — OpenTelemetry Instrumentation and Context Propagation Boundary](../adr-examples/ADR-0007-opentelemetry-instrumentation-boundary.md)
- [ADR-0008 — Automated Architectural Fitness Functions in CI/CD](../adr-examples/ADR-0008-architectural-fitness-functions.md)

# Appendix D — Editorial Change Log
| Date | Section | Change | Owner | Status |
|---|---|---|---|---|
| 2026-09-01 | Whole Course | Reconciled canonical 9-chapter sequence, normalized terminology, added diagrams, ADRs, glossary, and exercises | Architecture Team | Complete |
