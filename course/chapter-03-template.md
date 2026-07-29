# Chapter 3 — The Shipment Leaves a Message

## Events, Asynchronous Reactions, and Reliable Publication

**Template status:** Structure validated against Chapters 1 and 2; narrative not drafted.

**Teaching-chapter status:** Draft

**Estimated listening time:** To be established after narration is drafted.

**Primary audience:** Senior engineers, architects, technical leads, and engineering managers.

## What You Will Learn

- [Learning objective tied to the shipment journey.]
- [Learning objective distinguishing commands from events.]
- [Learning objective covering reliable publication and delivery semantics.]
- [Learning objective connecting the design to operational evidence.]

## Evidence Guide

Use evidence labels consistently:

- **Implemented:** Link to repository evidence.
- **Current architecture:** Link to an authoritative current-state artifact.
- **Planned direction:** State the intended future change and its trigger.
- **Teaching example:** Mark illustrative code or scenarios explicitly.
- **Conceptual extension:** Identify material that goes beyond demonstrated Atlas requirements.

Until implementation evidence is linked, describe behavior as “In the course’s intended responsibility model…” or “Planned direction…” rather than asserting that “Atlas does” it today.

## Narration

> [Opening architectural story: begin with the business fact and the downstream reaction, not the messaging technology.]

### [Narrative movement 1]

[Narrative placeholder.]

### [Narrative movement 2]

[Narrative placeholder.]

### [Narrative movement 3]

[Narrative placeholder.]

### [Narrative movement 4]

[Narrative placeholder.]

## Editorial Alignment

**Architecture principle:** Preserve the authoritative business fact first, then distribute independent reactions through durable and observable messaging.

**Anti-pattern:** Saving the shipment and publishing directly to the broker as two unrelated writes.

Explicitly answer:

- What does `ShipmentBooked` mean exactly?
- Which downstream work can be delayed?
- How does each consumer prevent duplicate business effects?
- Which statements are demonstrated by repository evidence, and which remain intended responsibility or planned direction?

## Engineering Commentary

### [Decision and tradeoff 1]

[Commentary placeholder.]

### [Decision and tradeoff 2]

[Commentary placeholder.]

### [Implementation evidence still required]

[List the exact code, tests, ADRs, diagrams, or operational evidence needed before making current-architecture claims.]

## Interview Stops

### Senior Engineer

[Question and expected reasoning.]

### Principal Engineer

[Question and expected reasoning.]

### Reliability Engineer

[Question and expected reasoning.]

### Security Architect

[Question and expected reasoning.]

### Skeptical Reviewer

[Question testing whether the design solves demonstrated variation.]

## Key Takeaways

- [Takeaway.]
- [Takeaway.]
- [Takeaway.]

## Related Concepts

- [Concept and relationship to this chapter.]
- [Concept and relationship to this chapter.]

## Review Exercise

[Scenario, constraints, and expected decision record.]

## Chapter Checklist

- [ ] Evidence labels are applied to architectural claims.
- [ ] Current and planned states are separated.
- [ ] The authoritative fact and transaction boundary are explicit.
- [ ] Delivery semantics, retries, idempotency, and reconciliation are explained.
- [ ] Editorial Alignment matches the review edition verbatim.
- [ ] Listening time is recalculated after narration is complete.
- [ ] Relevant ADRs, diagrams, code, tests, and exercises are linked.

## Editorial Record

- **Teaching-chapter status:** Draft
- **Owner:**
- **Reviewers:**
- **Evidence links:**
- **Related ADRs:** ADR-0004, ADR-0005, ADR-0010
- **Open questions:**
