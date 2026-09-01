# ADR-0002: Isolate Carrier Integrations Behind Ports and Adapters

## Status
Accepted

## Context
Atlas must communicate with multiple carrier APIs that differ significantly in communication protocols, authentication methods (OAuth2, API keys, basic auth), rate limits, and failure behaviors. Placing carrier communication directly inside application services violates the Single Responsibility Principle and couples business orchestration to third-party network SDKs.

## Decision
We apply the **Ports and Adapters (Hexagonal)** pattern. Atlas core defines clean outbound interfaces (e.g., `CarrierPort`, `RatingPort`) expressing domain intent. For each carrier, a dedicated adapter implements the port, encapsulates provider SDKs, manages provider-specific authentication strategies, and acts as an Anti-Corruption Layer (ACL).

## Alternatives Considered
1. **Monolithic Carrier Service:** A single class containing conditional branches (`if (carrier == "FEDEX") ...`). Rejected because it accumulates disparate reasons to change into one brittle class.
2. **Direct Controller-to-SDK Calls:** Invoking carrier client libraries directly inside API controllers. Rejected because it destroys testability and prevents architectural separation of concerns.

## Consequences
- **Positive:** New carriers can be introduced by implementing a new adapter without altering domain orchestration. Individual carrier integrations can be unit and contract tested in isolation.
- **Negative:** Introduces interface indirection and additional classes for each integrated carrier.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in `atlas-shipping-app` carrier integration package.
