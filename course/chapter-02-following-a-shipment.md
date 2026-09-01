# Chapter 2 — Following a Shipment

## Responsibility, Dependency Direction, and the Request Path

**Estimated listening time:** 23–27 minutes  
**Primary evidence label:** Teaching example  
**Teaching-chapter status:** Draft  
**Reference implementation:** Atlas Enterprise Platform

## What You Will Learn

By the end of this chapter, you should be able to:

- Trace a shipment-booking request from the network boundary to a truthful response.
- Distinguish authentication, authorization, validation, orchestration, domain decisions, translation, and persistence.
- Explain why controllers should remain thin and application services should coordinate rather than absorb every rule.
- Describe dependency inversion using the Atlas carrier boundary.
- Identify where tenant context and carrier-specific knowledge belong.
- Recognize what Atlas can and cannot promise when an external carrier responds ambiguously.

## Evidence Guide

This lesson uses one continuous shipment journey to explain responsibility and dependency direction. Detailed class names and request shapes are illustrative until linked to the reference implementation.

- **Implemented** — Behavior demonstrable in the Atlas reference implementation.
- **Current architecture** — The presently documented organization of the reference system.
- **Planned direction** — An intentional target not yet fully implemented.
- **Teaching example** — A concrete scenario used to explain the architecture.
- **Conceptual extension** — A possible evolution used to explore a tradeoff.

Unless implementation evidence is linked in the editorial record, treat the runtime sequence below as a **Teaching example** that describes the intended responsibility model.

Present-tense descriptions of Atlas in this narration refer to that intended responsibility model unless a statement carries a stronger evidence label. They do not assert that a detailed implementation behavior has been verified.

---

## Narration

It is 9:14 on Tuesday morning.

A customer has finished entering shipment details in a business application. The destination is correct. Two packages are ready. The customer selects a service and clicks **Book Shipment**.

At that instant, Atlas receives an HTTP request.

We are going to follow that request from the first network byte to the final response. The goal is not to memorize a sequence of framework classes. The goal is to see how architecture assigns each decision to a component with the right knowledge and the right reason to change.

Our journey looks like this:

```text
Incoming request
      ↓
Authentication
      ↓
Authorization and tenant context
      ↓
Transport translation
      ↓
Input and business validation
      ↓
Application coordination
      ↓
Carrier selection
      ↓
Carrier authentication and adapter translation
      ↓
Carrier interaction
      ↓
Truthful persistence
      ↓
Stable Atlas response
```

Every arrow represents a boundary. Every boundary raises a question: who has enough knowledge to make the next decision?

### The request begins outside Atlas

The request comes from a network Atlas does not control.

Its JSON may be malformed. Its token may be expired. Its tenant identifier may be forged. Its package dimensions may be impossible. Its retry may duplicate a request that Atlas already processed.

The first architectural fact is therefore simple:

> Input is untrusted until the appropriate boundary has established what may be trusted about it.

Atlas should not begin by selecting a carrier or opening a database transaction. It begins by establishing the caller's identity.

### Authentication establishes identity

Authentication answers:

> Who is making this request?

In this teaching example, the caller presents a JSON Web Token, or JWT. The security layer verifies its signature, issuer, audience, lifetime, and required claims before constructing an authenticated principal.

The token itself is not the user. It is evidence used to establish an identity.

If authentication fails, the business use case should never begin. Carrier selection, persistence, and event publication have no reason to run for an unknown caller.

This is why authentication belongs near the system entrance rather than being copied into every controller.

```text
Unknown caller
      ↓
Credential validation
      ↓
Authenticated identity
```

A centralized boundary makes the rule consistent. It also prevents business code from becoming a collection of token-parsing routines.

### Authorization is a different decision

Authentication tells Atlas who the caller is.

Authorization at the resource boundary asks:

> Is this identity allowed to perform this action on this resource?

An authenticated warehouse user may be allowed to book shipments for one tenant but not another. An internal support identity may be allowed to read a shipment but not create one. A system-to-system identity may have a narrow scope that permits booking without administrative access.

The distinction matters because a valid identity is not universal permission.

Suppose the request contains `tenantId = northwind`, but the authenticated identity belongs to `contoso`.

If Atlas trusts the request field without comparing it to established authority, a caller may cross a tenant boundary by changing one value.

Tenant context should therefore be derived from, or validated against, trusted identity and authorization information. It should not become true merely because the client typed it.

The same rule applies to ownership checks later in the request. Endpoint-level permission may say a caller can book shipments. Resource-level permission decides whether this caller can book this shipment for this tenant and account.

### The controller translates transport

Only after the request crosses the security boundary does it reach the transport layer.

The controller has a narrow but important job. It understands HTTP.

It knows how to:

- accept a request body
- read path, query, and header values
- invoke the appropriate use case
- translate a result into an HTTP response
- map failures into stable public error representations

The controller should not know how FedEx authenticates. It should not build SQL. It should not choose a carrier by inspecting a long list of conditions. It should not publish messages directly.

Those decisions have different knowledge and different reasons to change.

A useful controller reads almost like a sentence:

```text
Translate the HTTP request
      ↓
Invoke Book Shipment
      ↓
Translate the outcome into HTTP
```

Thin does not mean unimportant. The controller protects the public transport contract. It simply avoids becoming the home of the entire application.

### Validation occurs at more than one boundary

The request may now be structurally valid JSON and still be an invalid shipment.

It helps to distinguish several kinds of validation.

Transport validation asks whether the request can be parsed and whether required public fields are present.

Application validation asks whether the use case has enough valid input to proceed. Is the tenant established? Is the requested carrier supported? Is an idempotency key properly formed?

Domain validation protects business invariants. Is the package weight positive? Is the state transition allowed? Can this shipment be booked in its present state?

External validation belongs at the provider boundary. Does the selected carrier accept this particular service for this route? Is the account authorized for the requested product?

These checks may all reject a request, but they do not belong in one giant validation method.

```text
Syntax belongs near transport.
Use-case preconditions belong near application coordination.
Business invariants belong with the domain knowledge.
Provider constraints belong at the provider boundary.
```

This keeps each rule close to the information required to evaluate it.

That is the Single Responsibility Principle in practical form. Each component has one coherent responsibility and therefore one primary reason to change; it does not mean that every component contains only one method or performs only one mechanical action.

### The application service coordinates the use case

The request now reaches the application layer.

The application service represents a use case such as **Book Shipment**. Its job is coordination.

It may:

1. Accept a transport-independent command.
2. establish the authorized tenant and actor context.
3. check idempotency or existing workflow state.
4. ask for the correct carrier capability.
5. invoke the carrier boundary.
6. interpret the result according to Atlas semantics.
7. persist the authoritative state Atlas owns.
8. return a stable application result.

The application service is allowed to know the sequence. It should not own every detail inside the sequence.

Business state transitions make the ownership boundary concrete. The domain owns transition validity and invariants. The application service coordinates when the transition occurs as part of the use case. Persistence records the resulting authoritative state. None of those responsibilities should be inferred from whichever database method happens to run last.

This is the difference between orchestration and expertise.

An orchestra conductor knows when the violin enters. The conductor does not play every instrument.

Likewise, the booking use case knows that a carrier must be selected and invoked. It does not need to know how an OAuth token is obtained or how a carrier field is named.

### Carrier selection is a policy

How does Atlas decide which adapter should handle the request?

The simplest example is an explicit carrier identifier in the booking command. The application asks a registry for the capability associated with that identifier.

```text
Requested carrier: FEDEX
      ↓
Carrier registry
      ↓
FedEx adapter
```

The registry gives selection a dedicated home. It can reject unknown carriers consistently and allows the application service to depend on a carrier contract rather than concrete provider code.

Selection may eventually become more sophisticated. Atlas might consider tenant configuration, geography, service availability, cost, or health.

That is a **Conceptual extension**, not a reason to build a universal routing engine today.

If selection becomes a genuine business policy, it should be named and tested as such. A registry answers “which implementation matches this key?” A routing policy answers “which carrier should the business choose?” Those are related but different responsibilities.

### Dependency inversion changes the direction of control

Without an explicit boundary, application code might construct a FedEx SDK client and call it directly.

Then the important dependency points outward:

```text
Book Shipment → FedEx SDK
```

The use case becomes coupled to a provider's types and lifecycle.

Atlas instead defines the capability it needs, such as booking a shipment. Carrier adapters implement that capability.

```text
                 implements
FedEx adapter ───────────────┐
                            ↓
Book Shipment ───────→ Carrier port
                            ↑
UPS adapter ─────────────────┘
                 implements
```

The application owns the abstraction because the abstraction describes what the application needs.

Concrete provider code depends on that inward-facing contract. The use case no longer depends directly on a particular carrier implementation.

Dependency inversion does not eliminate dependencies. It places them in a direction that protects the stable policy from volatile details.

### Carrier authentication has its own reason to change

The registry selects an adapter. The adapter now needs to call an external API.

Different providers may require OAuth, an API key, basic authentication, mutual TLS, or another mechanism. Credentials may have different scopes and rotation policies.

If authentication logic is copied into each operation, it becomes difficult to test and easy to make inconsistent.

A carrier authentication strategy can own the knowledge needed to produce authorized request material for one provider or authentication family.

```text
Carrier adapter
      ↓ asks for authorized request context
Authentication strategy
      ↓
Credential provider or token endpoint
```

The adapter still owns the provider operation. The authentication strategy owns how authority for that operation is established.

The controlling boundary rule is explicit: **carrier SDK models and authentication details remain inside carrier adapters and strategies.** They do not become application-service or public API types.

This separation is valuable only if authentication mechanisms vary enough to justify it. The goal is not to create patterns for their own sake. The goal is to keep independent reasons to change independent.

### The adapter translates meaning

The selected adapter receives an Atlas booking request.

Its work is not merely renaming fields. It translates between two contracts.

It may:

- convert units
- map service levels
- format addresses
- construct provider-specific requests
- attach authorized headers
- interpret provider status and error codes
- map the response into an Atlas result

This translation must preserve meaning.

If a carrier returns “label created,” the adapter should not translate that into “package delivered.” If a timeout leaves acceptance unknown, the adapter should not report a definite rejection simply because that outcome is easier to model.

Truthful translation is more important than convenient translation.

### External calls create uncertain outcomes

Now Atlas sends the request to the carrier.

Several things can happen.

The carrier can accept the request and return a booking identifier.

It can reject the request with a known business error.

It can fail before receiving the request.

Or it can accept the request and fail before Atlas receives the response.

The last case is the dangerous one.

From Atlas's perspective, the outcome is unknown.

Blindly retrying may create a duplicate shipment. Declaring failure may invite the user to submit the same booking again. Declaring success invents a fact Atlas does not possess.

The architecture must represent uncertainty honestly and use provider idempotency, lookup, reconciliation, or controlled recovery where available.

This is why timeout handling is a business design question, not merely an HTTP-client setting.

### Persistence records what Atlas knows

After interpreting the carrier result, Atlas persists the state it owns.

Persistence should not rewrite history to make the workflow look simpler than it was.

If the carrier definitively accepted the booking, Atlas can store the accepted state and carrier reference.

If the carrier definitively rejected it, Atlas can store or return the rejection according to the product's workflow.

If the result is unknown, Atlas needs a state that communicates uncertainty and supports reconciliation.

The database is not merely storage. It is part of how Atlas preserves truthful business state across failures and retries.

Later, Chapter 3 will examine how shipment state and event-publication intent can be committed together using a transactional outbox. For this chapter, the important boundary is simpler: persistence follows Atlas semantics, not whatever structure the provider returned.

### The response belongs to Atlas

Finally, the application result returns to the controller.

The public response should use Atlas's contract.

It may include a shipment identifier, current status, carrier reference, label information, or a stable error. It should not expose a provider SDK object directly.

Why?

Because the public API is another boundary. If carrier responses leak through it, clients become coupled to the carrier schema that Atlas was created to isolate.

The full path is now complete:

```text
Customer clicks Book Shipment
      ↓
Identity is established
      ↓
Authority and tenant access are checked
      ↓
HTTP becomes a transport-independent command
      ↓
The use case coordinates the workflow
      ↓
A carrier capability is selected
      ↓
Authentication and translation stay at the edge
      ↓
The carrier outcome is interpreted truthfully
      ↓
Atlas state is persisted
      ↓
An Atlas response returns to the client
```

![Shipment Request Flow](../diagrams/shipment-request-flow.svg)

*(Related Decision: [ADR-0002 — Isolate Carrier Integrations Behind Ports and Adapters](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md))*

### What's Next?

Once the synchronous request path is complete and truthful state is persisted, the next challenge is notifying the rest of the business without coupling booking availability to downstream reactions.

In **Chapter 3 — The Shipment Leaves a Message**, we explore event-driven architecture, durable transactional outboxes, fan-out messaging, and how consumers achieve idempotent reliability under at-least-once delivery.

---

## Editorial Alignment

This chapter preserves the review edition's controlling statements:

- **Preserved decisions:** Controllers translate transport requests and delegate use cases. Application services coordinate the workflow but do not own every rule. Carrier SDK models and authentication details remain inside carrier adapters and strategies.
- **Architecture principle:** Place each decision with the component that has the knowledge and the correct reason to change.
- **Anti-pattern:** A controller that validates security, selects carriers, calls SDKs, writes SQL, and constructs public responses directly.

The chapter answers the review questions as follows:

1. Tenant identity is established at the authenticated security boundary and carried into the authorized use case; it is not trusted merely because it appears in request data.
2. The domain owns transition validity and invariants, the application service coordinates the transition, and persistence records its authoritative result.
3. Carrier authentication can change inside its adapter or strategy without rewriting shipment orchestration.

---

## Engineering Commentary

### Thin controllers and substantial use cases

A thin controller is not a goal by itself. The goal is to keep HTTP concerns from owning business workflow. An application service can be substantial because coordination is real work. It becomes problematic when it absorbs provider mapping, token acquisition, persistence implementation, and every domain rule.

### Authentication, authorization, and validation

These responsibilities are often collapsed into “security” or “request checking.” Keeping them distinct improves reasoning:

- Authentication establishes identity.
- Authorization evaluates permitted action and resource scope.
- Validation determines whether input and state satisfy the relevant contract or invariant.

A request may pass one and fail another.

### Registries versus routing policies

A registry resolves a known key to an implementation. A routing policy chooses among alternatives using business criteria. Starting with a registry is often sufficient. If Atlas later chooses carriers dynamically, that selection deserves an explicit policy rather than increasingly complex registry conditionals.

### Transactions and external APIs

A database transaction cannot make an external carrier call atomic with local persistence. Holding a database transaction open across a remote call may increase contention without solving the distributed consistency problem. The workflow must define recoverable states and idempotent behavior instead of pretending the network is part of the local transaction.

### Where this chapter needs implementation evidence

Before marking the runtime sequence as **Implemented**, link it to:

- Security configuration and token validation.
- Tenant or actor context construction.
- The shipment controller and public request/response types.
- The booking application service or use case.
- Carrier registry or resolution logic.
- Carrier port, adapters, and authentication strategies.
- Persistence abstractions and shipment states.
- Tests for unauthorized tenant access and unknown carrier selection.

---

## Interview Stops

Pause after each question and answer it aloud before reading the response.

### Senior Engineer

**Question:** Why not place the entire request flow in the controller if it is easier to follow?

**Answer:** The apparent simplicity lasts only while the workflow is small. HTTP translation, authorization, business coordination, carrier mapping, and persistence change for different reasons. Keeping them separate allows each contract to evolve and be tested without making the controller the system's knowledge bottleneck.

### Security Architect

**Question:** The caller has a valid JWT containing a tenant ID. Is that enough to authorize the booking?

**Answer:** Not automatically. Atlas must validate issuer, audience, lifetime, and trusted claims, then evaluate whether the identity is authorized for this operation and resource. Request-supplied tenant data must not override established tenant authority.

### Principal Engineer

**Question:** What does dependency inversion buy us if the application still needs a carrier adapter at runtime?

**Answer:** It changes which side owns the contract. The stable application policy depends on a capability it defines, while volatile provider integrations implement that capability. Runtime wiring still supplies an adapter, but provider SDK types and lifecycle do not control the application layer.

### Reliability Engineer

**Question:** The carrier timed out after Atlas sent the request. Should Atlas retry?

**Answer:** Only if the operation is demonstrably idempotent or Atlas can reconcile the original attempt. The timeout does not prove rejection. Atlas should represent the outcome as unknown or pending and use provider idempotency keys, lookup, or reconciliation rather than risking duplicate business effects.

### Test Engineer

**Question:** Which tests provide the most architectural confidence for this path?

**Answer:** Authorization tests across tenant boundaries, use-case tests against carrier and persistence ports, adapter contract tests, idempotency tests, ambiguous-timeout tests, and an end-to-end test for the critical booking journey. Test count matters less than coverage of the important boundaries and failure semantics.

---

## Key Takeaways

1. Every request begins outside the trust boundary.
2. Authentication establishes identity; authorization evaluates permitted action and scope.
3. Tenant context must come from trusted authority, not an unchecked request field.
4. Controllers translate transport and delegate use cases.
5. Validation belongs at the boundary with the knowledge required to perform it.
6. Application services coordinate workflows without owning every implementation detail.
7. A registry resolves implementations; a routing policy makes business selections.
8. Dependency inversion lets the application own the capability contract.
9. Carrier authentication and translation stay at the integration edge.
10. External timeouts can create unknown outcomes that require idempotency or reconciliation.
11. Persistence records truthful Atlas state rather than mirroring provider payloads.
12. Public responses should remain stable Atlas contracts.

## Related Concepts

- Ports and adapters architecture
- Dependency inversion and inversion of control
- Authentication versus authorization
- Tenant isolation and resource-level authorization
- Application services and use cases
- Domain invariants
- Strategy, registry, and policy patterns
- Anti-corruption layers
- Idempotency and uncertain outcomes
- Transaction boundaries
- Contract and integration testing

## Review Exercise

Draw the shipment-booking path using one box per responsibility. For every box, write:

1. The decision it owns.
2. The information it requires.
3. Its reason to change.
4. The contract it exposes to the next box.

Then evaluate this failure:

> Atlas sends a booking request. The carrier accepts it but the response is lost. The client retries with the same idempotency key.

Explain:

- what Atlas knows after the timeout
- which component owns retry policy
- how duplication can be prevented or detected
- what state should be returned to the client
- what reconciliation evidence would resolve the uncertainty

## Chapter Checklist

- [x] The lesson follows one continuous shipment journey.
- [x] Authentication and authorization are distinguished.
- [x] Controller, application, domain, adapter, and persistence responsibilities are separated.
- [x] Dependency direction is explained.
- [x] Ambiguous external outcomes are represented honestly.
- [x] Interview stops cover security, reliability, testing, and design.
- [ ] Implementation claims are linked to reference-repository evidence.
- [ ] Chapter has been read aloud and edited for pacing.
- [ ] Technical review is complete.
- [ ] Editorial review is complete.

## Editorial Record

- Teaching-chapter status: Draft
- Owner:
- Related ADRs: Isolate carrier integrations behind adapters; separate carrier authentication strategies
- Related implementation:
- Last reviewed:
