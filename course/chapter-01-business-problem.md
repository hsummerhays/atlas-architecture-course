# Chapter 1 — The Business Problem

## Finding the Domain Before Choosing the Framework

**Estimated listening time:** 18–22 minutes  
**Primary evidence label:** Teaching example  
**Teaching-chapter status:** Draft  
**Reference implementation:** Atlas Enterprise Platform

## What You Will Learn

By the end of this chapter, you should be able to:

- Explain Atlas without beginning with Java, Spring Boot, AWS, or Kubernetes.
- Identify the stable business concepts inside a landscape of carrier-specific variation.
- Explain why Atlas owns a canonical shipment model.
- Distinguish a justified boundary from speculative abstraction.
- Tell the architecture story in a way that works in both design reviews and interviews.

## Evidence Guide

This course discusses a reference implementation and a broader architectural model. The labels below keep those claims honest.

- **Implemented** — Behavior that should be demonstrable in the Atlas reference implementation.
- **Current architecture** — A description of how the reference system is presently organized.
- **Planned direction** — An intentional target that is not yet fully implemented.
- **Teaching example** — A concrete scenario used to explain a design decision.
- **Conceptual extension** — A possible evolution used to explore a tradeoff, not a committed roadmap item.

Until a statement is linked to implementation evidence, treat detailed code and infrastructure examples in this chapter as **Teaching example**.

In the narration, present-tense descriptions of Atlas refer to the course's intended responsibility model unless a statement carries a stronger evidence label. They do not assert that an implementation detail has been verified.

---

## Narration

Welcome to the Atlas team.

Before we open an IDE, inspect a deployment diagram, or name a framework, we need to understand why this system deserves to exist.

Imagine that it is Tuesday morning. A customer has finished entering an order in a business application. The address is known. The packages have been weighed. The service level has been selected. The customer clicks **Book Shipment**.

That action sounds simple because the user sees only one button.

Behind that button is a much less uniform world.

FedEx describes shipments one way. UPS describes them another way. DHL and USPS make different choices about addresses, credentials, service codes, labels, errors, and tracking states. Even when two carriers use similar words, they may not assign those words exactly the same meaning.

One carrier may accept dimensions in inches while another expects centimeters. One may represent a residential delivery as a Boolean flag while another encodes it as a service option. One may reject a request immediately. Another may time out after accepting it, leaving Atlas uncertain whether a shipment now exists.

If every business application talks to every carrier directly, each application must learn those differences.

The CRM learns FedEx.

The warehouse system learns UPS.

The customer portal learns DHL.

The reporting service learns all of them.

Now add another carrier.

The apparent convenience of direct integration turns into repeated translation logic, repeated security logic, inconsistent error handling, and several slightly different definitions of a shipment.

That is the pressure Atlas addresses.

In the course's intended responsibility model, Atlas gives its clients one stable shipping language and keeps carrier-specific languages at the edge of the system.

This is the business story we will carry through the entire course:

```text
Business application
        ↓
Atlas shipment model
        ↓
Carrier boundary
        ↓
FedEx, UPS, DHL, USPS, or another provider
```

Notice what we have not said yet.

We have not said Spring Boot.

We have not said PostgreSQL.

We have not said SNS, SQS, Kubernetes, or AI agents.

Those technologies may help implement the solution, but none of them defines the problem. If we cannot explain the problem without naming the technology, we are not ready to choose the technology.

### The outcome Atlas owns

Atlas is not trying to make every carrier identical.

That would be dishonest. Carriers have genuinely different capabilities, contracts, and failure behavior.

The preserved architectural decision is explicit: **Atlas owns a stable shipment-booking model.** In the intended responsibility model, that model creates a stable business contract for the capabilities clients need. A client can ask to book a shipment using concepts such as:

- shipper and recipient
- packages
- weight and dimensions
- requested service
- carrier preference
- references
- delivery instructions

Those are Atlas concepts. They form part of the language shared by the business and the system.

At the carrier boundary, an adapter translates that request into the external provider's model. It also translates the provider's response back into an Atlas result.

The important direction is this:

```text
Atlas does not spread carrier models inward.
Atlas translates its model outward.
```

That direction protects the center of the system from change at the edges.

If FedEx renames a field, changes an authentication flow, or returns a new error representation, the change should remain near the FedEx boundary. The shipment use case should not become a tour of FedEx implementation details.

### The canonical model

The stable Atlas-specific language is the **canonical shipment model**. It is an example of the broader architectural pattern known as a **canonical domain model**.

The word canonical can sound grander than the idea really is. It simply means that Atlas chooses one authoritative representation for the business concepts it owns.

Consider an address.

Atlas may describe an address using a name, organization, street lines, locality, region, postal code, and country. A carrier adapter is responsible for deciding how those concepts map into the carrier's request.

That does not mean Atlas should model every field offered by every carrier. If one provider exposes a highly specialized customs option that no Atlas client needs, adding it to the shared model may create complexity without business value.

The canonical model is therefore not the union of every provider schema.

It is the smallest stable language that supports Atlas's business promises.

This distinction matters. A model built by combining every external field becomes a carrier catalog disguised as a domain model. It grows whenever any provider grows, and the center of the system once again becomes coupled to the edges.

### Translation belongs at the boundary

Suppose Atlas represents weight in a consistent unit and UPS requires another representation.

Where should conversion occur?

Not in the controller. The controller handles transport concerns.

Not in the shipment use case. The use case coordinates a business operation.

Not in the database entity. Persistence is not the source of carrier knowledge.

The conversion belongs in the UPS adapter because the adapter owns knowledge of the UPS contract.

This gives us a useful architectural rule:

> Put a decision in the component that possesses the knowledge required to make it.

This is separation of concerns expressed architecturally: responsibilities are separated according to the knowledge they require and the reason they change.

The same rule will reappear throughout the course. Authentication strategies own knowledge of carrier credentials. Consumers own knowledge of their retry and idempotency behavior. Security boundaries own decisions about authority. Architecture is easier to change when knowledge has an explicit home.

### Domain language is a design tool

Words are not merely documentation. They shape the software.

If product, engineering, support, and operations use the word **shipment** to mean four different things, the code eventually reflects that ambiguity.

Does a shipment exist when Atlas accepts a request?

When the carrier accepts it?

When a label has been generated?

When a package is physically collected?

Each answer describes a different fact.

The team should name those facts precisely. A booking request, a carrier booking, a label, and a tracked shipment may be related, but they are not interchangeable.

A clear domain language helps Atlas decide:

- which state it owns
- which state a carrier owns
- which transitions must be atomic
- which outcomes may remain uncertain
- which events are safe to publish
- which claims an API may truthfully make

This is why architecture begins with the business problem. Technology can move data, but it cannot decide what the data means.

### Boundaries follow pressure

At this point it would be easy to become enthusiastic and create a framework for every possible kind of integration.

We might invent dynamic plug-in loading, a universal mapping language, a broad shared module, configurable workflow engines, or a hierarchy that anticipates every future carrier.

That would feel architectural.

It might also be waste.

A useful boundary responds to demonstrated pressure. Atlas has evidence that carriers vary in their external contracts, so a carrier adapter boundary is justified. If carriers use meaningfully different authentication mechanisms, an authentication strategy may also be justified.

But the fact that two classes contain similar code does not automatically justify a new abstraction. Similarity is an observation. A shared reason to change is the stronger signal.

The goal is not maximum flexibility.

The goal is the smallest architecture that protects the business from known change.

### A walking skeleton

How should a team begin implementing this idea?

Not by completing every carrier integration.

Not by building the full target platform.

Begin with one thin, end-to-end journey.

For example:

```text
Receive one valid shipment request
        ↓
Validate the business input
        ↓
Select one carrier adapter
        ↓
Call a controlled carrier endpoint
        ↓
Translate the result
        ↓
Persist truthful shipment state
        ↓
Return a stable Atlas response
```

This is a walking skeleton: the smallest implementation that exercises the important boundaries from entrance to outcome.

It gives the team evidence.

Can the canonical model express a real shipment?

Does the adapter boundary contain carrier variation?

Where does uncertainty appear?

Which responsibilities are missing?

Which abstractions were imagined rather than needed?

The architecture can then grow from observed constraints instead of predictions.

### What Atlas is—and is not

Atlas can be described as an enterprise shipping integration platform, but that phrase needs care.

It does not mean Atlas owns the physical delivery network.

It does not mean Atlas makes external carriers reliable.

It does not mean every carrier capability is interchangeable.

Atlas owns a stable client-facing contract, orchestration of the shipment-booking use case, the truth it persists, and the behavior it promises when dependencies fail.

External carriers remain independent systems with their own authority and failure modes.

Good architecture does not erase those boundaries. It makes them visible and manageable.

![Atlas System Context](../diagrams/atlas-system-context.svg)

*(Related Decision: [ADR-0001 — Adopt Canonical Shipment Model](../adr-examples/ADR-0001-canonical-shipment-model.md) | Hands-on Practice: [Exercise 1 — Find the Architecture in the Business Problem](../exercises/exercise-01-find-architecture.md))*

### What's Next?

Now that the business problem and domain boundary are established, the next question is how a real request moves through that architecture without blurring responsibilities. 

In **Chapter 2 — Following a Shipment**, we follow a single booking request across the network boundary, watching authentication, tenant authorization, application coordination, and carrier adapters collaborate without any single component absorbing the entire workflow.

---

## Editorial Alignment

This chapter preserves the review edition's controlling statements:

- **Preserved decision:** Atlas owns a stable shipment-booking model.
- **Architecture principle:** Begin with the business outcome and isolate proven sources of variation behind explicit boundaries.
- **Anti-pattern:** Designing a universal middleware framework before implementing one real shipment journey.

The chapter must leave the learner able to answer these review questions explicitly:

1. Can the business problem be explained without naming a framework?
2. Which concepts belong to Atlas rather than a carrier?
3. Which proposed extension points solve demonstrated variation?

---

## Engineering Commentary

### Why a canonical model instead of carrier DTOs everywhere?

Carrier DTOs optimize for a carrier's API. Atlas's domain model should optimize for Atlas's business contract. Allowing provider types into application logic causes business behavior to change whenever an external schema changes and makes multi-carrier workflows difficult to reason about.

The canonical model does impose a translation cost. That cost is worthwhile when Atlas needs a stable contract across multiple providers. If the product supported only one provider and had no reason to isolate it, the boundary would need a different justification.

### Why adapters instead of one large carrier service?

A large conditional service tends to accumulate provider-specific authentication, mapping, errors, and feature flags in one place. Separate adapters localize those reasons to change and allow contract tests to focus on one external boundary.

Adapters should not conceal meaningful business differences. If a carrier cannot provide a requested guarantee, Atlas must represent that limitation truthfully rather than manufacturing false uniformity.

### Why not design the final platform immediately?

Early architecture is built with incomplete information. Hard-to-reverse decisions deserve deliberate attention, but reversible details should remain open. A walking skeleton tests the highest-risk assumptions while the cost of correction is still low.

### Where this chapter needs implementation evidence

Before marking claims as **Implemented**, link them to the reference repository. Useful evidence would include:

- The Atlas shipment request and result types.
- The carrier port or interface.
- At least one carrier adapter and its mapping code.
- Validation at the application boundary.
- A test demonstrating that carrier types do not leak into the core use case.

---

## Interview Stops

Pause after each question and answer it aloud before reading the response.

### Senior Engineer

**Question:** Why not let every carrier define the request objects used throughout the application?

**Answer:** Because those objects express the carrier's contract, not Atlas's business contract. Spreading them inward couples application behavior to external schemas. A canonical model keeps the client-facing language stable and confines translation to adapters.

### CTO

**Question:** Are we paying for an abstraction before we need it?

**Answer:** The carrier boundary responds to observed variation across provider contracts, authentication, and failures. That makes it justified. More speculative mechanisms—such as runtime plug-ins or a universal mapping engine—should wait for evidence that their option value exceeds their present cost.

### Principal Engineer

**Question:** What happens when a carrier capability cannot fit the canonical model?

**Answer:** First determine whether the capability belongs in Atlas's product contract. If it does, evolve the model deliberately while preserving compatibility. If it is provider-specific and not part of the shared promise, expose it through a narrow capability or leave it at the boundary. Do not turn the canonical model into the union of all provider schemas.

### Product Leader

**Question:** What business value does this architecture create?

**Answer:** Clients integrate once, carrier changes have a smaller blast radius, shipment behavior becomes more consistent, and new providers can be introduced without teaching every client a new external contract.

### Skeptical Reviewer

**Question:** Why not begin with microservices?

**Answer:** Service boundaries do not define the domain automatically. Begin by establishing responsibilities, invariants, and change boundaries. Independent deployment is justified only when scaling, security, ownership, availability, or release pressure warrants its operational cost.

---

## Key Takeaways

1. Begin with the business outcome, not the technology inventory.
2. Atlas exists because client applications need one stable shipping contract across varying carriers.
3. The canonical model expresses Atlas's promises; it is not a union of provider schemas.
4. Carrier-specific knowledge belongs at the carrier boundary.
5. Precise domain language reveals ownership, state, and invariants.
6. A boundary is justified by demonstrated variation or a distinct reason to change.
7. Similar code alone is not sufficient evidence for abstraction.
8. A walking skeleton tests architectural assumptions with one real end-to-end path.
9. Uniform interfaces must not hide meaningful differences or uncertainty.
10. The smallest sufficient architecture preserves learning and reduces speculative cost.

## Related Concepts

- Domain-driven design and ubiquitous language
- Canonical data models
- Ports and adapters architecture
- Dependency inversion
- Anti-corruption layers
- Single Responsibility Principle
- YAGNI and the Rule of Three
- Walking skeletons and vertical slices
- Bounded contexts
- Coupling, cohesion, and reasons to change

## Review Exercise

Explain Atlas in two minutes without using any framework, cloud service, database, or programming-language name.

Your explanation should identify:

1. The actor and desired outcome.
2. The source of business or integration pressure.
3. The stable concepts Atlas owns.
4. The variation Atlas isolates.
5. One limitation Atlas should state honestly.

Then answer the review-edition questions directly:

- Which concepts belong to Atlas rather than a carrier?
- Which proposed extension points solve demonstrated variation?

Then answer this design challenge:

> A new carrier supports a special temperature-controlled shipping option that no current Atlas client has requested. Should the field be added to the canonical model now?

There is no automatic yes-or-no answer. State the evidence you would require, the cost of adding it now, and how difficult it would be to add later.

## Chapter Checklist

- [x] Business problem precedes technology.
- [x] Canonical model and adapter boundary are explained.
- [x] Tradeoffs and limitations are stated.
- [x] Interview stops cover multiple audiences.
- [x] Key takeaways and related concepts are included.
- [ ] Implementation claims are linked to reference-repository evidence.
- [ ] Chapter has been read aloud and edited for pacing.
- [ ] Technical review is complete.
- [ ] Editorial review is complete.

## Editorial Record

- Teaching-chapter status: Draft
- Owner:
- Related ADRs: Isolate carrier integrations behind adapters; adopt the Atlas domain language
- Related implementation:
- Last reviewed:
