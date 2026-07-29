# Atlas Enterprise Platform
# Software Architecture Course
## Review & Update Edition

**Condensed editorial control copy for structured review, maintenance, and future revision.**

Prepared July 29, 2026

## How to Use This Edition

- This is a condensed editorial edition, not a verbatim transcript of the narrated course.
- Review one lesson brief at a time and use its Update Notes fields to capture revisions.
- Keep the narrated course as the teaching edition and this document as the maintainable control copy.
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
- **Chapter 4 — Observability** — Making Atlas Explain Its Behavior
- **Chapter 5 — Security** — Identity, Authority, Data Protection, and Supply-Chain Boundaries
- **Chapter 6 — Architectural Tradeoffs** — Part 1 — Simplicity Versus Flexibility
- **Chapter 6 — Architectural Tradeoffs** — Part 2 — Consistency Versus Availability
- **Chapter 6 — Architectural Tradeoffs** — Part 3 — Performance Versus Reliability
- **Chapter 6 — Architectural Tradeoffs** — Part 4 — Delivery Speed Versus Operational Safety
- **Chapter 7 — Evolutionary Architecture** — Part 1 — Architecture That Can Detect Its Own Decay
- **Chapter 7 — Evolutionary Architecture** — Part 2 — Safe Evolution
- **Chapter 7 — Evolutionary Architecture** — Part 3 — Architecture Ownership
- **Chapter 7 — Evolutionary Architecture** — Part 4 — Architecture Decision Records
- **Chapter 8 — The Architect’s Method** — Part 1 — Begin With the Problem, Not the Technology
- **Chapter 8 — The Architect’s Method** — Part 2 — From Model to Blueprint
- **Chapter 8 — The Architect’s Method** — Part 3 — Architecture in Practice
- **Chapter 8 — The Architect’s Method** — Part 4 — Communicating Architecture

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
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

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
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

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
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 4 — Observability
## Making Atlas Explain Its Behavior
### Lesson Summary
Logs, metrics, traces, health checks, and service-level objectives are designed around operational questions. The chapter distinguishes liveness, readiness, and business health; connects technical telemetry to business outcomes; and establishes incident response, correlation, release markers, and evidence-driven diagnosis.
### Core Concepts
- Structured logs
- Metrics and bounded labels
- Distributed traces and correlation
- Liveness, readiness, and startup
- SLI, SLO, and SLA
- Release markers
- Incident response and runbooks
- Business integrity signals
### Atlas Decisions Preserved
- Every important operation carries correlation and version context.
- Health endpoints do not pretend every dependency is equally critical.
- SLOs are capability-specific and owned.
### Architecture Principle
> Instrument the questions operators must answer, not merely the components the system contains.
### Anti-Pattern
Declaring the platform healthy because every pod is running while business workflows are failing.
### Review Questions
- Can Atlas distinguish carrier failure from database failure?
- Which metric represents customer-facing convergence?
- Can an operator connect a regression to a deployed version?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 5 — Security
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
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 6 — Architectural Tradeoffs
## Part 1 — Simplicity Versus Flexibility
### Lesson Summary
Atlas resists speculative abstractions and preserves only future options whose current value exceeds their cost. The lesson evaluates interfaces, registries, dynamic plugins, shared modules, configuration-driven behavior, and the temptation to solve hypothetical enterprise requirements.
### Core Concepts
- YAGNI and option value
- Rule of Three
- Stable versus speculative variation
- Configuration versus code
- Shared-library coupling
- Reversibility
### Atlas Decisions Preserved
- Carrier adapters are justified by observed provider variation.
- A broad atlas-common module is avoided.
- Dynamic plugin loading is deferred until runtime extensibility is demonstrated.
### Architecture Principle
> Preserve only future options whose value justifies their present complexity and operating cost.
### Anti-Pattern
Building a generic framework whose primary customer is an imagined future requirement.
### Review Questions
- Which flexibility is actively used?
- What present cost does the extension point impose?
- Can the option be added later without a destructive migration?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 6 — Architectural Tradeoffs
## Part 2 — Consistency Versus Availability
### Lesson Summary
Atlas protects critical invariants with strong local consistency while allowing downstream projections and reactions to converge later. The lesson covers CAP reasoning, read-your-writes behavior, sagas and compensation, ordering, reconciliation, stale reads, and truthful representation of pending or unknown outcomes.
### Core Concepts
- Strong local consistency
- Bounded eventual consistency
- CAP under partition
- Read-your-writes
- Sagas and compensation
- Ordering and version checks
- Reconciliation
- Pending and unknown states
### Atlas Decisions Preserved
- Shipment state and outbox intent are locally atomic.
- Notification, analytics, tracking, and accounting reactions may lag within defined objectives.
- The UI and API communicate freshness and uncertainty honestly.
### Architecture Principle
> Protect critical invariants strongly and permit bounded disagreement only where delayed convergence is safe and visible.
### Anti-Pattern
Claiming immediate global consistency while relying on independent networks, stores, and consumers.
### Review Questions
- Which facts must change atomically?
- How stale may each projection become?
- What happens when an external outcome cannot be known immediately?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 6 — Architectural Tradeoffs
## Part 3 — Performance Versus Reliability
### Lesson Summary
Performance is treated as the behavior of the entire business path rather than isolated code speed. Atlas bounds work, manages deadlines, prevents retry amplification, uses bulkheads and backpressure, protects downstream systems, and evaluates tail latency, capacity, resource pools, caching, batching, and graceful degradation.
### Core Concepts
- Critical path and tail latency
- Timeouts and deadline propagation
- Retry ownership and budgets
- Circuit breakers and bulkheads
- Connection pools and Little’s Law
- Backpressure and bounded queues
- Caching and stampede prevention
- Load, stress, spike, soak, and failure tests
### Atlas Decisions Preserved
- Every external call has a bounded timeout and one clear retry owner.
- Carrier capacity is isolated by carrier-specific limits and circuits.
- Reliability and business correctness are preserved before raw throughput.
### Architecture Principle
> Optimize the complete business path, bound every source of work, and preserve reliability before pursuing raw speed.
### Anti-Pattern
Increasing retries, threads, and replicas independently until downstream systems collapse.
### Review Questions
- What is the real bottleneck?
- How does overload propagate?
- What behavior degrades first when capacity is exhausted?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 6 — Architectural Tradeoffs
## Part 4 — Delivery Speed Versus Operational Safety
### Lesson Summary
Atlas makes releases small, traceable, compatible, and progressively exposed. The lesson distinguishes continuous integration, delivery, and deployment; treats the pipeline as executable safety policy; and covers immutable artifacts, tests, approvals, migrations, canaries, feature flags, rollback, roll-forward, and agent governance.
### Core Concepts
- Lead time, deployment frequency, change failure, recovery time
- Small batches
- Continuous integration and delivery
- Immutable artifact promotion
- Risk-based approvals
- Rolling, blue-green, and canary deployment
- Feature flags and kill switches
- Expand-and-contract migrations
- Rollback versus roll-forward
### Atlas Decisions Preserved
- Build once and promote the same verified artifact.
- Use progressive rollout with explicit success and abort criteria.
- Agents cannot self-approve, merge, or deploy their changes.
### Architecture Principle
> Release small, traceable, backward-compatible changes and increase exposure only while evidence remains healthy.
### Anti-Pattern
Accumulating months of change and deploying everything at once behind ceremonial approvals.
### Review Questions
- Can old and new versions coexist?
- What is the realistic recovery path?
- Which release controls are automated guardrails versus meaningful human judgment?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 7 — Evolutionary Architecture
## Part 1 — Architecture That Can Detect Its Own Decay
### Lesson Summary
Atlas distinguishes intended architecture from actual dependencies, data access, permissions, deployment, and runtime behavior. Important decisions become architectural fitness functions using module tests, policy as code, behavioral tests, SLOs, drift detection, ratchets, and explicit exceptions.
### Core Concepts
- Architectural erosion and drift
- Static, dynamic, and operational fitness functions
- ArchUnit-style dependency tests
- Database and secret boundaries
- Ratchets and baselines
- Policy as code
- Architecture health and exceptions
### Atlas Decisions Preserved
- Shipping must not depend on agent implementation.
- Shipping manifests must not reference agent-only secrets.
- Fitness functions protect meaning rather than freezing incidental package layout.
### Architecture Principle
> Turn important architectural decisions into continuously evaluated constraints and change those constraints only deliberately.
### Anti-Pattern
Maintaining a beautiful architecture diagram while actual dependencies and permissions drift unnoticed.
### Review Questions
- Which decisions are important enough to fail the build?
- Which qualities require runtime evidence?
- How are temporary exceptions owned and expired?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 7 — Evolutionary Architecture
## Part 2 — Safe Evolution
### Lesson Summary
Live systems evolve through parallel change rather than atomic cutover. Atlas expands contracts and schemas, migrates readers, writers, traffic, and authority incrementally, measures old-path use and correctness, and contracts only after compatibility and retention windows close.
### Core Concepts
- Expand, migrate, contract
- Backward and forward compatibility
- Tolerant readers
- API and event evolution
- Backfills and dual writes
- Shadow reads
- Authority switches
- Strangler migration
- Compatibility windows
### Atlas Decisions Preserved
- Readers become tolerant before producers emit incompatible forms.
- One system remains authoritative during migration.
- The future agent deployment uses a staged dark launch, canary, Airflow cutover, and legacy cleanup.
### Architecture Principle
> Expand compatibility first, migrate authority and traffic incrementally, and remove old paths only after evidence proves they are unnecessary.
### Anti-Pattern
Renaming fields, schemas, routes, and services in one coordinated big-bang release.
### Review Questions
- Which old and new versions must coexist?
- Where is the point of no return?
- What evidence defines migration completion?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 7 — Evolutionary Architecture
## Part 3 — Architecture Ownership
### Lesson Summary
Architecture is sustained through domain, service, data, contract, operational, security, and migration ownership. The lesson explores accountability versus responsibility, team boundaries, paved roads, guardrails versus gates, RACI, decision rights, on-call capability, debt ownership, and retirement.
### Core Concepts
- Domain and service ownership
- Data and contract ownership
- Operational and security ownership
- Platform as a product
- Paved roads
- Guardrails versus gates
- RACI and decision rights
- Migration and retirement ownership
### Atlas Decisions Preserved
- Shipping owns shipment truth and booking contracts.
- Consumers own their queues, retries, idempotency, and effects.
- A temporary migration owner coordinates the remaining agent deployment sequence end to end.
### Architecture Principle
> Assign every important capability, contract, dataset, and operational outcome to an accountable owner with enough authority to evolve it.
### Anti-Pattern
Declaring that “everyone owns it” while alerts, migrations, and decommissioning have no clear home.
### Review Questions
- Who owns business meaning?
- Who can act during an incident?
- Who is accountable for removing the old path?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 7 — Evolutionary Architecture
## Part 4 — Architecture Decision Records
### Lesson Summary
ADRs preserve why Atlas made significant choices, which alternatives were considered, what costs were accepted, which assumptions matter, and what evidence should trigger reconsideration. Records are version-controlled, concise, linked to fitness functions, and superseded rather than rewritten.
### Core Concepts
- ADR context, decision, alternatives, and consequences
- Assumptions and review triggers
- Proposed, accepted, rejected, deprecated, superseded
- Decision ownership
- Negative decisions
- Linking ADRs to tests and operations
### Atlas Decisions Preserved
- Create ADRs for carrier adapters, outbox, messaging topology, shipping-agent separation, one repository, and deferred agent deployment.
- Keep historical ADRs when later decisions supersede them.
- Do not create ADR bureaucracy for routine implementation details.
### Architecture Principle
> Record significant choices close to the system, including why they were made, how they are protected, and what evidence should cause reconsideration.
### Anti-Pattern
Allowing the rationale for an important design to remain only in a meeting or one person’s memory.
### Review Questions
- Would a future engineer understand the accepted cost?
- Which assumption could make the decision wrong later?
- Which fitness function protects the decision?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 8 — The Architect’s Method
## Part 1 — Begin With the Problem, Not the Technology
### Lesson Summary
The reusable method begins with outcomes, actors, journeys, constraints, quality-attribute scenarios, business invariants, state transitions, trust boundaries, failure models, assumptions, and risks. Technology selection follows only after the problem and tradeoffs are understood.
### Core Concepts
- Problem statements and actor goals
- Real versus assumed constraints
- Quality-attribute scenarios
- Business invariants
- Commands, events, and state models
- Trust and failure boundaries
- Walking skeletons and vertical slices
- Smallest sufficient architecture
### Atlas Decisions Preserved
- Atlas architecture is derived from demonstrated pressures rather than fashionable components.
- Hard-to-reverse decisions are made early; reversible details remain open.
- A thin end-to-end slice validates assumptions before broad framework construction.
### Architecture Principle
> Begin with the outcome and constraints, identify what must remain true, and choose technology only after boundaries and failure behavior are understood.
### Anti-Pattern
Selecting microservices, brokers, orchestration, and AI tooling before defining the business workflow.
### Review Questions
- What happens if the system is wrong rather than unavailable?
- Which constraints are actually negotiable?
- What is the minimum responsible design?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 8 — The Architect’s Method
## Part 2 — From Model to Blueprint
### Lesson Summary
The architect converts reasoning into an implementable blueprint: scope, boundary statements, capabilities, use cases, commands, domain concepts, ports, adapters, contracts, authoritative data, transaction boundaries, failure matrices, security, deployment, observability, ownership, ADRs, fitness functions, and a vertical-slice backlog.
### Core Concepts
- Architecture blueprint
- Boundary and capability statements
- Command and domain models
- Ports and adapters
- API and event contracts
- Data and transaction boundaries
- Security and authority maps
- Failure and recovery matrices
- Current, transition, and target states
### Atlas Decisions Preserved
- Specify architecture-significant constraints while leaving reversible class-level details open.
- Document current, transition, and target architecture separately.
- Connect every major decision to ownership, failure behavior, and evidence.
### Architecture Principle
> Specify the decisions that protect system-wide qualities and leave ordinary reversible implementation details open to learning.
### Anti-Pattern
Either prescribing every class before implementation or providing only vague principles with no contracts or boundaries.
### Review Questions
- Can engineers implement one vertical slice coherently?
- Are transaction and authority boundaries explicit?
- Does the blueprint describe migration and failure, not only final structure?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 8 — The Architect’s Method
## Part 3 — Architecture in Practice
### Lesson Summary
Production evidence tests architectural hypotheses. Atlas evaluates business outcomes, SLOs, incidents, change coupling, security findings, toil, cost, support cases, and team experience. Reviews may preserve, tune, strengthen, simplify, migrate, or retire parts of the architecture.
### Core Concepts
- Business and operational evidence
- Leading and lagging indicators
- Change coupling and hotspots
- Operational toil
- Metric theater and Goodhart’s Law
- Architecture experiments
- Trigger-based debt
- Preserve, tune, strengthen, simplify, migrate, retire
### Atlas Decisions Preserved
- Architectural change follows recurring structural pressure rather than isolated defects or technology fashion.
- Deferred agent deployment is activated by explicit workload, security, or release-coupling triggers.
- Successful controls and containment are evaluated and preserved.
### Architecture Principle
> Treat architecture as a testable hypothesis and evolve only when evidence demonstrates meaningful pressure.
### Anti-Pattern
Treating the original diagram as permanent truth while repeated incidents are patched locally for years.
### Review Questions
- Which assumption became false?
- Is the pressure structural or local?
- What is the smallest sufficient architectural response?
### Update Notes

| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

---
# Chapter 8 — The Architect’s Method
## Part 4 — Communicating Architecture
### Lesson Summary
One coherent architecture is communicated through views adapted to the audience’s decision. Executives need outcomes, cost, and risk; product needs workflow semantics; engineers need contracts and boundaries; operators need failure and recovery; security needs authority and trust; consumers need precise event guarantees.
### Core Concepts
- Architecture views
- Audience and decision framing
- Progressive disclosure
- Business, runtime, data, security, and operational views
- Architecture narratives
- Current versus target communication
- Layered interview answers
- Precise tradeoff and risk statements
### Atlas Decisions Preserved
- Begin explanations with outcome and pressure rather than technology inventory.
- Keep meaning consistent while translating terminology and depth.
- Mark diagrams and roadmaps clearly as current, transition, or target state.
### Architecture Principle
> Use the view and level of detail required for the audience’s decision while preserving the same truth, tradeoffs, and limitations.
### Anti-Pattern
Presenting one enormous diagram—or one empty business slogan—to every audience.
### Review Questions
- What decision must the audience make?
- Which concrete scenario will make the tradeoff clear?
- Have current limitations and uncertainty been stated honestly?
### Update Notes
| Field | Value |
|---|---|
| Status | Unreviewed |
| Owner | |
| Proposed changes | |
| Related ADRs or code | |

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

- ADR-0001 — Adopt Atlas naming and package namespace
- ADR-0002 — Isolate carrier integrations behind adapters
- ADR-0003 — Separate carrier authentication strategies
- ADR-0004 — Use SNS fan-out and one SQS queue per independent consumer
- ADR-0005 — Use a transactional outbox
- ADR-0006 — Separate shipping and agent application modules
- ADR-0007 — Keep one repository initially
- ADR-0008 — Defer independent agent deployment
- ADR-0009 — Prevent agents from approving their own changes
- ADR-0010 — Use bounded eventual consistency for downstream reactions
- ADR-0011 — Do not create a broad common module

# Appendix D — Editorial Change Log
| Date | Section | Change | Owner | Status |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |
