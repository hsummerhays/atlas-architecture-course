# ADR-0007: OpenTelemetry Instrumentation and Context Propagation Boundary

## Status
Accepted

## Context
Diagnosing production incidents in a multi-tenant, event-driven platform is impossible when logs are unstructured and trace context is lost across process and network boundaries. When an operator asks *"Why is shipment booking slow for tenant X?"*, they must be able to trace the request through HTTP endpoints, database commits, outbox dispatch, message queues, and worker consumers.

## Decision
1. **OpenTelemetry Standardization:** Atlas adopts OpenTelemetry (OTel) APIs and SDKs for generating vendor-neutral distributed traces, metrics, and logs.
2. **Context Propagation:** All inbound HTTP requests establish or extract W3C `traceparent` headers. `trace_id`, `span_id`, `correlation_id`, `causation_id`, and `tenant_id` are injected into database outbox entries and SNS/SQS event metadata.
3. **Structured JSON Logs:** All application logging emits structured JSON containing active trace and tenant context dimensions.
4. **SLI/SLO Telemetry:** Core booking latency and error rates are captured as standard RED (Rate, Errors, Duration) metrics.

## Alternatives Considered
1. **Proprietary APM Vendor Agents:** Relying on vendor-specific bytecode auto-instrumentation. Rejected to avoid proprietary lock-in and retain control over high-cardinality telemetry costs.
2. **Unstructured String Logging:** Printing text logs (`log.info("Saved shipment")`). Rejected because querying across distributed multi-tenant logs requires brittle regular expressions.

## Consequences
- **Positive:** Enables end-to-end distributed tracing across synchronous and asynchronous paths; eliminates guesswork during production incidents.
- **Negative:** Telemetry emission introduces minor CPU/network overhead; high-cardinality labels must be managed deliberately to avoid excessive storage costs.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in `atlas-shipping-app` telemetry and middleware configuration.
