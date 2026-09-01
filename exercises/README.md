# Atlas Architecture Course — Exercises

These hands-on architectural exercises accompany the nine chapters of the Atlas Architecture Course.

## Purpose

These exercises are designed to practice **architectural reasoning, tradeoff analysis, fault modeling, and evidence-based diagnosis** rather than testing vocabulary or syntax. 

In software architecture, multiple designs can be valid. What distinguishes senior engineering work is:
1. Identifying the true business invariants and constraints.
2. Making tradeoffs explicit (*"What are we buying, and what are we paying for it?"*).
3. Designing for failure, telemetry, security, and safe evolution from the start.

## Structure of Each Exercise

Each exercise includes:
- **Scenario:** The concrete business or operational situation inside Atlas.
- **Your Task:** The specific architectural challenge you must solve.
- **Constraints:** Technical, organizational, or domain rules that must remain true.
- **Architecture Questions:** Guiding questions to structure your analysis.
- **Deliverable:** The concrete architectural output (blueprint, threat model, tradeoff matrix, or diagnostic runbook).
- **Run-Through Checklist:** Criteria to self-evaluate your solution.
- **Discussion / Reflection:** Deeper questions to consider in engineering reviews or architecture interviews.
- **Suggested Approach:** A collapsible reference solution (`<details>`) outlining one strong way to reason through the problem. Try solving the exercise before expanding the suggested approach!

## Exercise Map

| Chapter | Title | Core Task | Link |
|---|---|---|---|
| **1** | Find the Architecture in the Business Problem | Turn business requirements into capabilities, constraints, actors, and boundaries | [Exercise 1](exercise-01-find-architecture.md) |
| **2** | Trace a Shipment | Walk a shipment end-to-end and identify ownership, state changes, and dependencies | [Exercise 2](exercise-02-trace-a-shipment.md) |
| **3** | Break the Message Flow | Inject failures into the outbox/broker/consumer path and reason about delivery guarantees | [Exercise 3](exercise-03-break-the-message-flow.md) |
| **4** | Threat-Model Atlas | Identify trust boundaries, credentials, authorization decisions, and attack surfaces | [Exercise 4](exercise-04-threat-model-atlas.md) |
| **5** | Make the Tradeoff | Compare two plausible architectures and defend one using explicit quality attributes | [Exercise 5](exercise-05-make-the-tradeoff.md) |
| **6** | Design for Failure | Given provider latency/outage scenarios, choose timeout, retry, backoff, circuit-breaker, and bulkhead behavior | [Exercise 6](exercise-06-design-for-failure.md) |
| **7** | Diagnose the Incident | Use simulated logs/metrics/traces to determine why a shipment workflow is failing | [Exercise 7](exercise-07-diagnose-the-incident.md) |
| **8** | Evolve Atlas Safely | Migrate a capability without a big-bang rewrite using compatibility and fitness functions | [Exercise 8](exercise-08-evolve-atlas-safely.md) |
| **9** | Architect a New Capability (Capstone) | Apply the complete Architect's Method to design tenant-owned Webhook Subscriptions | [Exercise 9](exercise-09-architect-a-new-capability.md) |
