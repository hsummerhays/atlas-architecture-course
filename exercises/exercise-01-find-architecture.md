# Exercise 1 — Find the Architecture in the Business Problem

## Scenario
A multinational retail customer wants Atlas to integrate with three regional express couriers (NordicSpeed in Scandinavia, FastTrans in Central Europe, and IberiaPost in Spain/Portugal). Each carrier has different requirements:
- NordicSpeed uses GraphQL, requires weight in kilograms, and returns pickup tracking numbers synchronously.
- FastTrans uses SOAP/XML, requires weight in grams, and processes bookings asynchronously via callback webhooks.
- IberiaPost uses REST/JSON, requires customs documentation attachments, and only accepts API requests during daytime European business hours.

The business product manager asks: *"Can we just add an if/else block to our existing shipment controller to support these three carriers by next Friday?"*

## Your Task
Analyze this business requirement and formulate a clean architectural boundary that satisfies the business without destroying maintainability.

## Constraints
1. The Atlas public API client contract must remain canonical (shippers should not change their code to use a new carrier).
2. Carrier-specific variations (SOAP vs REST vs GraphQL, grams vs kilograms, daytime-only quotas) must not leak into core order processing.

## Architecture Questions
1. Which business concepts belong to Atlas's domain, and which belong strictly to carrier integration adapters?
2. How should Atlas handle FastTrans's asynchronous callback model without breaking the synchronous booking experience for clients?
3. What is the cost of implementing a canonical abstraction now versus letting provider schemas leak into the application?

## Deliverable
A brief architectural boundary proposal (1–2 pages) identifying:
- The Canonical Shipment Model fields needed.
- The Ports and Adapters boundary structure.
- How provider-specific variations are isolated.

## Run-Through Checklist
- [ ] Explicitly separates Atlas domain concepts from external provider DTOs.
- [ ] Identifies Anti-Corruption Layers (ACL) for all three carriers.
- [ ] Avoids speculative generality for features no carrier currently needs.

## Discussion / Reflection
In an architecture review, a stakeholder asks: *"If we only integrate with one carrier today, isn't creating an adapter premature optimization?"* How do you defend the boundary using the Rule of Three and demonstrated variation?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### 1. Domain vs. Adapter Boundary
- **Atlas Owns:** `ShipmentId`, `OriginAddress`, `DestinationAddress`, `PackageDimensions`, `Weight` (normalized to canonical unit, e.g., grams/kg), `ServiceLevel` (Standard, Express), and `Status` (`PENDING`, `BOOKED`, `FAILED`).
- **Adapters Own:** SOAP/GraphQL envelope wrapping, token acquisition, unit conversions (grams to kg), and scheduling/queueing for daytime-only APIs.

### 2. Handling Asynchronous Callback Providers
FastTrans cannot be treated as immediately booked if it only acknowledges receipt via webhook. Atlas can:
- Return `Status: PENDING_CARRIER_CONFIRMATION` to the client if the client supports asynchronous polling/webhooks.
- Or, if clients require synchronous booking, designate FastTrans as an asynchronous batch carrier with explicit SLA disclaimers in the UI.

### 3. Tradeoff Statement
We buy carrier independence and UI stability at the cost of writing three separate adapter mapping classes and maintaining unit conversions. This trade is justified because carrier variation is demonstrated, not hypothetical.

*(Reference: [ADR-0001](../adr-examples/ADR-0001-canonical-shipment-model.md), [ADR-0002](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md))*
</details>
