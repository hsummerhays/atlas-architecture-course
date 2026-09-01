# Exercise 2 — Trace a Shipment

## Scenario
A shipper issues an HTTP `POST /api/v1/shipments` request to Atlas. The request includes customer details, origin/destination addresses, package weight, and requests carrier selection for FedEx. During execution, the following chain of events occurs:
1. The API Gateway forwards the request with a JWT token.
2. Atlas validates the JWT and checks tenant authorization.
3. The shipment use case coordinates rating and carrier adapter invocation.
4. FedEx responds with HTTP 200 and a tracking number `TRK-987654`.
5. Atlas persists the shipment record and returns a canonical response.

However, during a code review, an engineer discovers that the controller method itself was calling the FedEx SDK, opening a database connection, and querying carrier credentials directly.

## Your Task
Refactor the conceptual request journey into an explicit sequence of single-responsibility stages with clear dependency inversion.

## Constraints
1. The API controller must know nothing about database connections or carrier SDKs.
2. Tenant identity must be extracted and validated at the security boundary and carried as immutable execution context.
3. Carrier credentials must be resolved dynamically by an authentication strategy, not hardcoded in the adapter.

## Architecture Questions
1. What are the distinct responsibilities along the request path (transport, authentication, authorization, validation, coordination, adapter translation, persistence)?
2. Why should the application service coordinate the use case rather than the domain model or controller?
3. What should happen if FedEx responds with HTTP 504 Gateway Timeout after 3 seconds? What truthful state should Atlas record?

## Deliverable
A step-by-step Request Journey Sequence Diagram (or ASCII flowchart) showing:
- Component names and interface contracts.
- Exact direction of source code dependencies (Inversion of Control).
- Error paths when external carrier calls fail or time out.

## Run-Through Checklist
- [ ] Dependencies point inward toward core application logic.
- [ ] Controllers remain thin transport translators.
- [ ] Truthful persistence states are defined for timeouts and partial responses.

## Discussion / Reflection
Why is "thin controller" an architectural principle rather than merely a code style rule? How does separating coordination from transport allow Atlas to support gRPC or message-queue triggers for the same booking use case?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### 1. The Correct Layered Journey
1. **Controller (`ShipmentApiController`):** Deserializes HTTP, extracts JWT claims into `TenantContext`, converts HTTP DTO to `BookShipmentCommand`, and calls `ShipmentApplicationService`.
2. **Security Interceptor:** Validates that `TenantContext.TenantId` matches resource ownership rules.
3. **Application Service (`BookShipmentUseCase`):** Coordinates validation, invokes domain entity factory (`Shipment.create(...)`), asks `CarrierRegistry` for the matching `CarrierPort` implementation, and invokes the port.
4. **Carrier Adapter (`FedExCarrierAdapter`):** Injected with `FedExAuthStrategy`, translates canonical command to FedEx SDK DTO, executes outbound HTTP call with bounded timeout.
5. **Persistence (`ShipmentRepository`):** Receives domain entity and persists state atomically.

### 2. Handling Carrier Timeout
If FedEx returns HTTP 504 or times out:
- Atlas must NOT mark the shipment as `FAILED` (FedEx may have processed the booking).
- Atlas marks status as `UNKNOWN_PENDING_RECONCILIATION` and returns an HTTP 202 Accepted or explicit uncertainty error code.
- A background reconciliation worker queries FedEx later using the business idempotency key.

*(Reference: [Diagram: Shipment Request Flow](../diagrams/shipment-request-flow.svg), [ADR-0002](../adr-examples/ADR-0002-ports-and-adapters-for-providers.md))*
</details>
