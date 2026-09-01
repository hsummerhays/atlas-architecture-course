# ADR-0001: Adopt Canonical Shipment Model

## Status
Accepted

## Context
Atlas integrates with multiple external shipping carriers (e.g., FedEx, UPS, DHL, USPS). Each carrier exposes proprietary request and response schemas, error representations, and lifecycle terminologies. Allowing third-party schemas to permeate application services, domain logic, and persistent storage would tightly couple Atlas to external provider changes, creating brittle code and high maintenance overhead.

## Decision
We define an authoritative, domain-centric **Canonical Shipment Model** owned exclusively by Atlas. All internal application workflows, invariants, validation rules, public APIs, and database schemas operate on this canonical representation. Carrier-specific DTOs and data transformations are strictly isolated within carrier adapters at the integration boundary.

## Alternatives Considered
1. **Pass-Through Provider Schemas:** Use provider-specific DTOs directly throughout the codebase. Rejected because carrier API updates would force sweeping changes across application logic and UI contracts.
2. **Generic Property Bags:** Represent shipment data as dynamic key-value dictionaries. Rejected because it eliminates compile-time safety, obscures domain invariants, and complicates contract testing.

## Consequences
- **Positive:** Protects core business workflows from external API churn; enables uniform multi-carrier workflows and consistent client contracts.
- **Negative:** Requires mapping code inside every carrier adapter, adding slight CPU translation overhead and data mapping maintenance.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in `atlas-shipping-app` core domain.
