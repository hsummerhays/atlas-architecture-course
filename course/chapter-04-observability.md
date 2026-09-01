# Chapter 4 — Observability

## Making Atlas Explain Its Behavior

**Estimated listening time:** 20–24 minutes

**Primary evidence label:** Teaching example

**Teaching-chapter status:** Draft

**Reference implementation:** Atlas Enterprise Platform

## What You Will Learn

By the end of this chapter, you should be able to:

- Explain why observability begins with operational questions rather than logging tools.
- Distinguish structured logs, metrics, traces, and business-integrity signals by the questions they answer.
- Carry correlation, causation, tenant, event, shipment, and release context across distributed work.
- Distinguish liveness, readiness, startup, dependency health, and business health.
- Explain the difference between an SLI, SLO, and SLA.
- Design bounded metrics that remain useful as Atlas scales.
- Use release markers to connect behavioral changes to deployments.
- Follow one shipment across synchronous and asynchronous boundaries during an incident.
- Explain why healthy infrastructure does not necessarily mean a healthy business capability.
- Design observability around evidence that allows operators to explain what happened.

## Evidence Guide

This chapter continues to distinguish the course’s intended responsibility model from verified implementation.

- **Implemented** — Behavior linked to code, configuration, tests, or operational evidence in the repository.
- **Current architecture** — A description linked to an authoritative current-state artifact.
- **Planned direction** — An intended change whose completion criteria or trigger is stated.
- **Teaching example** — A concrete scenario used to explain a design decision.
- **Conceptual extension** — A possible evolution used to explore a tradeoff, not a committed roadmap item.

Until implementation evidence is linked, detailed runtime examples in this chapter are **Teaching example**. Present-tense descriptions of Atlas refer to the course’s intended responsibility model, not to verified deployed behavior.

---

## Narration

Wednesday morning.

Yesterday, our shipment left a message.

The carrier accepted the booking. Atlas committed the authoritative shipment state and its outbox record in one transaction.

The outbox publisher sent `ShipmentBooked`.

SNS distributed the event.

Independent SQS queues received their copies.

Notification reacted.

Accounting intake reacted.

Tracking reacted.

Analytics reacted.

At least, that is what the architecture says should happen.

Then customer support calls.

A customer booked a shipment twenty minutes ago. The carrier confirmation number is visible in Atlas, so the booking clearly succeeded.

But the customer never received an email.

Accounting cannot see the shipment.

Tracking has not started.

An engineer opens the Kubernetes dashboard.

Every pod is green.

CPU utilization is normal.

Memory looks fine.

No container is restarting.

The engineer says:

“The system looks healthy.”

Does it?

That question takes us into observability.

### Healthy machinery is not the same as a healthy system

A running process tells us something.

It tells us that the process is running.

That is useful.

It does not tell us that shipments can be booked.

It does not tell us that events are being published.

It does not tell us that accounting intake is converging.

It does not tell us that customers are receiving notifications.

And it certainly does not explain what happened to the shipment customer support just asked about.

This gives us the central principle of this chapter:

> Instrument the questions operators must answer, not merely the components the system contains.

Observability is not the presence of logs, dashboards, and traces.

Those are mechanisms.

Observability is our ability to use evidence emitted by the system to understand its behavior.

A useful observability design begins with questions.

Can customers book shipments?

How long does booking take?

Which carrier is failing?

Did Atlas commit the shipment?

Was `ShipmentBooked` published?

Which consumers received it?

Which business effects completed?

Which ones are delayed?

Did the problem begin after a deployment?

Is one tenant affected or everyone?

Can we trace this exact shipment through the system?

Those questions determine what evidence Atlas needs to produce.

### Start with the shipment, not the dashboard

Return to our customer-support call.

We know one useful fact:

```text
shipmentId = SHP-48219
```

Perhaps support also has:

```text
tenantId = TENANT-42
carrierCode = FEDEX
```

That is already more useful than knowing that a pod is green.

An operator should be able to begin with a business identifier and follow the operation.

The booking request might have carried a correlation identifier:

```text
correlationId = 7f5b...
```

The `BookShipment` command used that context.

The carrier adapter logged against it.

The resulting shipment retained relevant diagnostic context.

The `ShipmentBooked` event carried the correlation identifier forward.

Its `eventId` identified the particular event.

Its `causationId` identified what directly caused it.

The outbox publisher recorded the publication attempt.

Each consumer continued the correlation context while performing its own work.

Now an operator can ask:

```text
Show me everything associated with SHP-48219.
```

or:

```text
Show me the journey associated with correlation 7f5b...
```

That is much closer to observability.

### Correlation is a thread through distributed work

In a monolith, one request may remain inside one process.

In a distributed architecture, one business journey crosses boundaries.

The HTTP request ends.

An outbox publisher wakes later.

SNS distributes a message.

SQS delivers it later still.

A notification worker processes one copy.

A tracking worker processes another.

There is no longer one call stack that explains the journey.

We have to create our own continuity.

Correlation provides that continuity.

Consider the identifiers we already introduced:

```text
shipmentId
tenantId
eventId
correlationId
causationId
bookingVersion
schemaVersion
```

They do different jobs.

`shipmentId` identifies the business entity.

`tenantId` provides tenant context.

`eventId` identifies the integration event.

`correlationId` connects activity belonging to the broader business journey.

`causationId` identifies the immediate command or event that caused the current work.

`bookingVersion` helps reason about business ordering.

`schemaVersion` helps reason about contract compatibility.

None of these should be confused with one another.

A trace identifier may also exist.

That trace identifier is useful for distributed tracing, but we should not require customer support to know it.

Operational evidence should let us move between technical identifiers and business identifiers.

The customer says:

“My shipment is missing.”

The operator should not have to reply:

“Do you happen to know the OpenTelemetry trace ID?”

### Structured logs tell a story we can query

Suppose Atlas writes this:

```text
Shipment booking completed
```

That may be readable.

It is not very queryable.

Now consider a structured record:

```text
timestamp=...
level=INFO
event=shipment.booking.completed
shipmentId=SHP-48219
tenantId=TENANT-42
carrierCode=FEDEX
carrierShipmentReference=...
correlationId=7f5b...
durationMs=842
releaseVersion=1.7.3
```

The message still communicates meaning to a human.

But the fields also let machines group, filter, aggregate, and correlate the evidence.

We can ask:

```text
show booking failures for FEDEX
```

or:

```text
show all records for SHP-48219
```

or:

```text
compare failures before and after release 1.7.3
```

Structured logging turns prose into evidence.

That does not mean logging everything.

A system that emits enormous quantities of undisciplined data can become harder to understand, not easier.

Logs should record meaningful transitions and diagnostic context.

They should not casually contain secrets.

They should not expose carrier credentials.

They should not copy access tokens.

They should not dump complete customer payloads merely because serialization is convenient.

Observability does not override data minimization.

### Logs answer individual questions; metrics reveal patterns

Logs are useful when we are investigating a particular shipment.

Metrics answer a different kind of question.

How many bookings are succeeding?

What percentage are failing?

How long do bookings take?

How old is the oldest unpublished outbox record?

How deep is the tracking queue?

How many messages are entering a DLQ?

Metrics turn repeated behavior into trends.

For example:

```text
shipment_booking_total
shipment_booking_failure_total
shipment_booking_duration
outbox_pending_count
outbox_oldest_pending_age
consumer_processing_duration
consumer_failure_total
queue_oldest_message_age
dlq_message_count
```

These names are only teaching examples.

The important part is what they allow an operator to ask.

A count of pending outbox records is useful.

The age of the oldest pending record may be more useful.

Why?

Imagine Atlas normally publishes an event within five seconds.

Now there are ten pending outbox rows.

Is that bad?

Maybe.

If all ten were created during the last half second, the publisher may simply be working.

But if the oldest row is forty minutes old, Atlas has a convergence problem.

The metric becomes meaningful when it represents operational pressure.

### Metric labels need boundaries

Metrics often contain labels.

For example:

```text
shipment_booking_total{
    carrier="FEDEX",
    outcome="success"
}
```

That lets us compare carriers and outcomes.

But labels can become dangerous.

Suppose we add:

```text
shipmentId="SHP-48219"
```

Now every shipment creates a new metric series.

At large scale, cardinality explodes.

The metrics platform spends increasing amounts of memory and compute indexing values that belong in logs or traces.

So we distinguish dimensions that have bounded operational meaning from identifiers with effectively unbounded variation.

Good metric labels might include:

```text
carrier
operation
outcome
failureClass
consumer
region
releaseVersion
```

depending on the system and the cardinality of each.

Poor metric labels often include:

```text
shipmentId
eventId
customerEmail
requestId
```

Those belong elsewhere.

A useful rule is:

> Metrics summarize populations. Logs and traces explain individual journeys.

### Traces show where time and failure travel

Now imagine bookings have become slow.

The request takes eight seconds.

A log can tell us that the booking took eight seconds.

A metric can tell us that p95 booking latency has increased.

A distributed trace can help explain where those eight seconds went.

Perhaps the journey looks like:

```text
POST /shipments/book                 8.1s
  ├─ validate request                12ms
  ├─ authorize resource              18ms
  ├─ load carrier configuration      25ms
  ├─ carrier adapter                 7.7s
  │    ├─ acquire token              110ms
  │    └─ carrier booking request    7.5s
  └─ persist shipment + outbox       48ms
```

Now we know something very different.

Atlas itself is not spending eight seconds performing domain logic.

The carrier call dominates the request.

That changes the investigation.

Maybe one carrier is slow.

Maybe DNS is failing.

Maybe connection reuse disappeared after a release.

Maybe the carrier is throttling Atlas.

Maybe the request is retrying.

The trace gives us the shape of the latency.

But traces are not magic either.

A trace shows what was instrumented.

A missing span is not proof that no work occurred.

A sampled trace may not exist for every request.

And an asynchronous event may begin a new execution context long after the original HTTP request has completed.

That is why correlation context and business identifiers still matter.

### Observability crosses asynchronous boundaries

Our shipment journey did not stop when the HTTP response returned.

The outbox publisher may process the event seconds later.

The accounting-intake consumer may process it another second later.

Tracking might wait thirty seconds.

Notification might retry for five minutes.

If tracing stops at the HTTP boundary, the most interesting part of the business journey disappears.

The event therefore needs enough context to continue the story.

When the outbox publisher sends `ShipmentBooked`, telemetry can associate publication with:

```text
eventId
shipmentId
tenantId
correlationId
causationId
releaseVersion
```

When the accounting consumer receives it, the consumer records:

```text
event received
processing started
business effect committed
message acknowledged
```

If processing fails:

```text
failure classification
attempt number
next retry state
```

If the retry budget is exhausted:

```text
dead-letter transition
```

Now the operator can reconstruct the path.

The point is not to log every method call.

The point is to preserve evidence at meaningful ownership and state boundaries.

### The three kinds of "up"

A common health endpoint answers:

```text
UP
```

That word hides several different questions.

Is the process alive?

Can it accept traffic?

Has it finished starting?

Can it perform its important business capabilities?

Those are not the same thing.

#### Liveness

Liveness asks:

> Is this process alive enough that restarting it is likely to help if the answer is no?

A liveness check should usually be narrow.

If the carrier API is unavailable, killing and restarting every Atlas pod will not repair the carrier.

If the database has a temporary outage, restarting healthy application processes may make the incident worse.

A liveness probe should not become a referendum on the entire distributed system.

#### Readiness

Readiness asks:

> Should this instance receive new traffic right now?

An application can be alive but not ready.

Perhaps required configuration is unavailable.

Perhaps startup initialization has not completed.

Perhaps the instance cannot reach a dependency required for the request path.

Removing that instance from traffic may be appropriate even though restarting it is not.

#### Startup

Startup answers another question:

> Has the application completed the initialization required before normal health evaluation begins?

This matters when legitimate startup work takes longer than ordinary liveness thresholds.

Without that distinction, an orchestrator can repeatedly kill a healthy application simply because it has not finished starting.

These health semantics exist because different failures require different actions.

### Dependency health is not business health

Suppose the shipping API reports:

```text
application = UP
database = UP
```

SNS is accepting publications.

SQS is available.

Every pod is ready.

Yet the oldest unpublished outbox record is forty-five minutes old because a publisher bug incorrectly marks rows as ineligible.

Technically, all dependencies are available.

Operationally, Atlas is failing to distribute booked shipments.

Or suppose every event is published successfully, but the accounting-intake consumer rejects every message because of a schema incompatibility.

The broker is healthy.

The queue is healthy.

The consumer process is alive.

Accounting convergence is broken.

This is why health must eventually connect to business integrity.

A business-integrity signal might ask:

```text
What percentage of booked shipments reached required downstream states
within their defined objectives?
```

That is a much stronger statement than:

```text
Are all pods running?
```

### Business health needs explicit objectives

We need to be careful here.

Not every downstream effect has the same urgency.

Customer notification might have one objective.

Tracking initialization might have another.

Analytics might tolerate a longer delay.

Accounting intake might have a stricter business objective.

An authoritative financial posting may have stronger controls still.

So we should not create one giant metric called:

```text
atlas_health = 1
```

and pretend it captures reality.

Health is capability-specific.

The same is true of service objectives.

### SLI, SLO, and SLA

These terms are related but not interchangeable.

An **SLI**, or service-level indicator, is a measurement.

For shipment booking, an SLI might be:

```text
successful valid booking requests
---------------------------------
total valid booking requests
```

Another SLI might measure latency:

```text
percentage of successful bookings completed within 2 seconds
```

For event publication, an SLI might be:

```text
percentage of committed ShipmentBooked outbox records
published within 30 seconds
```

An **SLO**, or service-level objective, is the target we set for an SLI.

For example:

```text
99.9% of valid shipment-booking requests succeed,
excluding explicitly classified carrier rejection.
```

Or:

```text
99.5% of ShipmentBooked publication intents
are published within 30 seconds.
```

Those numbers are examples, not Atlas commitments.

The important point is that the objective belongs to a capability and has an owner.

An **SLA**, or service-level agreement, is usually a contractual commitment with consequences.

An internal SLO may be stricter than an external SLA so the engineering team has room to respond before customers experience a contractual violation.

We should not casually call every dashboard threshold an SLA.

### Choose indicators from the customer's experience

Infrastructure metrics matter.

CPU matters.

Memory matters.

Thread pools matter.

Database connections matter.

They help explain failures.

But they are usually not the primary expression of customer success.

Imagine CPU rises from 20 percent to 70 percent.

Is that an incident?

Not necessarily.

Perhaps Atlas is efficiently handling increased demand.

Now imagine CPU is 10 percent, but every booking request fails.

That is clearly an incident.

So the most important indicators should begin near the business capability:

```text
booking success
booking latency
publication convergence
consumer convergence
oldest required work
```

Infrastructure evidence helps explain why those indicators changed.

This creates a useful hierarchy:

```text
Business outcome
      ↓
Capability SLI
      ↓
Application evidence
      ↓
Dependency evidence
      ↓
Infrastructure evidence
```

When we reverse that hierarchy, teams can spend hours staring at CPU charts while customers are telling them exactly what is broken.

### Error rates need meaningful classification

Suppose a carrier rejects a shipment because the destination postal code is invalid.

Atlas returns a useful validation or carrier-rejection response.

Should that count as platform failure?

Probably not in the same way as a timeout.

Suppose the carrier returns HTTP 500.

That is different.

Suppose Atlas cannot deserialize the response because the carrier changed its contract.

Different again.

Suppose Atlas cannot connect to its own database.

Again, different.

A useful failure model might distinguish:

```text
validation
authorization
carrier_rejection
carrier_timeout
carrier_throttle
carrier_contract
database
internal
configuration
```

The exact taxonomy can evolve.

The important thing is that an error counter without classification can hide very different operational realities.

If all failures become:

```text
shipment_booking_failure_total++
```

we know something is wrong.

We do not know what kind of wrong.

### Release markers answer "what changed?"

Thursday morning, booking latency jumps.

Nothing obvious changed in traffic.

Carrier status pages are green.

Database latency is normal.

Then someone asks:

“What did we deploy?”

That question should be cheap to answer.

Telemetry should carry release context.

A dashboard can show a marker:

```text
10:14 — shipping-app 1.7.3 deployed
```

At 10:16, carrier latency begins increasing.

Logs from the affected requests include:

```text
releaseVersion=1.7.3
```

Traces show a new token acquisition span on every booking.

Now the team has a hypothesis.

Perhaps release 1.7.3 accidentally removed token caching.

Without release markers, operators correlate incidents with deployments by memory, chat history, or guesswork.

With release markers, the system provides evidence.

This is especially important when deployment frequency increases.

Fast delivery without release observability turns incident diagnosis into archaeology.

### Observability should preserve architecture boundaries

Telemetry itself can damage architecture if we are careless.

Imagine every domain object knows how to call a monitoring SDK.

Now business logic depends directly on an observability vendor.

Or every method accepts a giant telemetry context object even when it has no architectural meaning.

Or logging becomes a hidden side-effect scattered throughout the domain model.

We still want dependency direction to remain intentional.

Infrastructure adapters can implement telemetry ports where abstraction is justified.

Framework instrumentation can capture HTTP, database, and messaging behavior.

Application boundaries can record meaningful operation transitions.

Domain code can expose meaningful outcomes without knowing where metrics are stored.

The goal is not to hide all telemetry behind an elaborate framework.

The goal is to prevent observability concerns from becoming accidental business dependencies.

### An incident is a question-and-evidence exercise

Return to our missing shipment reactions.

Customer support gives us:

```text
shipmentId = SHP-48219
```

The operator begins there.

**Question one: Did booking actually succeed?**

Shipment state says yes.

The carrier reference exists.

The booking version is correct.

**Question two: Was publication intent committed?**

The outbox contains `ShipmentBooked`.

Good.

**Question three: Was it published?**

The outbox record shows a successful publication attempt.

Telemetry contains the event ID.

**Question four: Did SNS distribute it?**

Broker evidence indicates delivery to the subscriptions.

**Question five: What happened to each consumer?**

Notification completed.

Tracking completed.

Analytics completed.

Accounting intake did not.

The accounting queue shows repeated delivery attempts.

**Question six: Why?**

The consumer logs show:

```text
failureClass=schema_version_unsupported
eventSchemaVersion=3
consumerReleaseVersion=2.4.1
```

Now we have an explanation.

The shipment booking was healthy.

Event publication was healthy.

Three consumers converged.

One consumer could not understand the new contract.

The incident is not:

> Atlas is down.

It is:

> Accounting intake for `ShipmentBooked` schema version 3 is failing because consumer release 2.4.1 does not support that version.

That sentence is operationally useful.

It tells us what failed.

It tells us what still works.

It tells us where ownership lies.

It gives us a likely recovery path.

That is what observability should enable.

### Runbooks turn evidence into action

Evidence alone is not enough if nobody knows what to do with it.

Suppose messages are entering the accounting DLQ.

A useful runbook might say:

1. Confirm the affected event type and schema version.
2. Identify the first failing release and consumer version.
3. Determine whether the failure is transient, data-specific, or contract-related.
4. Stop uncontrolled redrive if the failure is deterministic.
5. Correct code, configuration, or compatibility.
6. Validate the fix with a representative event.
7. Redrive through the controlled recovery path.
8. Verify the business effect.
9. Confirm queue age and DLQ depth return to objective.
10. Record the incident and prevention action.

Notice step eight.

Verify the business effect.

Do not stop at:

```text
DLQ depth = 0
```

An empty DLQ tells us that messages left the DLQ.

It does not prove accounting state is correct.

Again, the evidence must follow the business outcome.

### Alerts should point toward action

A useful alert tells an owner that a meaningful condition requires attention.

An alert such as:

```text
CPU > 70%
```

may or may not require action.

An alert such as:

```text
99th percentile booking latency exceeded objective
for 15 minutes
```

is closer to customer impact.

An alert such as:

```text
oldest unpublished ShipmentBooked event > 5 minutes
```

describes a convergence failure.

An alert such as:

```text
accounting-intake DLQ contains 37 messages
and oldest failure is 22 minutes
```

provides even more operational context.

The exact thresholds depend on objectives.

The principle is broader:

> Alert on conditions that require ownership and action, not merely on values that look unusual.

Otherwise, teams learn to ignore alarms.

An alert that nobody trusts is not observability.

It is noise.

### Observability has a cost

Telemetry consumes resources.

Logs consume storage.

Metrics consume memory and indexing capacity.

Traces consume processing and retention.

High-cardinality dimensions can become expensive.

Verbose payload capture can create privacy and security risk.

Instrumentation can add latency.

Observability therefore has architecture tradeoffs just like everything else.

We do not collect everything forever.

We decide what evidence is necessary.

We choose retention deliberately.

We sample where appropriate.

We preserve critical audit and business-integrity evidence differently from high-volume diagnostic traces.

We bound metric dimensions.

We redact sensitive values.

And we continually ask:

> Does this evidence help us answer a question we actually need to answer?

### The observability test

There is a useful way to evaluate an architecture before production.

Imagine an operator receives this message:

> Shipment SHP-48219 was booked successfully, but accounting has not received it.

Can the operator answer:

- When was the shipment booked?
- Which tenant owns it?
- Which carrier accepted it?
- Which application version processed the booking?
- Was the shipment and outbox intent committed?
- What event ID represents the booking?
- When was the event published?
- How old was the outbox record when published?
- Which queues received it?
- Which consumers completed their effects?
- Which consumer failed?
- What failure class occurred?
- How many times was it retried?
- Did it enter a DLQ?
- Which release introduced the failure?
- Is the problem isolated to one shipment, one tenant, one carrier, one consumer, or the whole platform?
- Has the business state now converged?

If Atlas cannot answer those questions, adding another dashboard may not help.

The missing capability is evidence design.

### Observability is part of architecture

Observability is sometimes treated as something operations adds after development.

That is too late.

Correlation has to cross boundaries.

Event contracts need diagnostic context.

Applications need meaningful failure classification.

Consumers need to expose convergence.

Deployments need release identity.

Health endpoints need semantics.

SLOs need capability ownership.

Runbooks need recoverable system behavior.

Those are architectural concerns.

They influence contracts, boundaries, deployment, security, and ownership.

A system that cannot explain itself is harder to operate safely.

And a system that cannot be operated safely is not finished merely because its code works.

### The end-to-end story

Our shipment journey now has another dimension.

Previously, we described the business flow:

```text
Carrier accepts booking
      ↓
Atlas commits shipment + outbox
      ↓
Publisher sends ShipmentBooked
      ↓
SNS fans out
      ↓
Consumers apply effects
      ↓
Retries and DLQs handle failure
      ↓
Reconciliation checks convergence
```

Now imagine evidence traveling alongside it:

```text
Booking request
  correlationId
  shipmentId
  tenantId
  releaseVersion
      ↓
Carrier interaction
  trace spans
  carrierCode
  duration
  outcome
      ↓
Shipment + outbox commit
  eventId
  bookingVersion
  commit evidence
      ↓
Publication
  attempt count
  publication latency
  failure classification
      ↓
SNS / SQS
  queue age
  delivery attempts
      ↓
Consumer
  consumer version
  effect result
  processing latency
      ↓
Business convergence
  required outcome achieved
  objective met or missed
```

The telemetry does not replace the architecture.

It makes the architecture explainable.

That distinction matters.

We are not instrumenting Atlas because dashboards look professional.

We are instrumenting Atlas so that when reality differs from our design, we can determine where, when, why, and for whom.

The pods may all be green.

The system may still be failing.

A healthy architecture is not merely running.

It can explain what it is doing.

In Chapter 5, we will ask a different question.

Now that Atlas can identify users, tenants, shipments, events, consumers, and workloads across the system, who should be allowed to do what?

We will move from visibility to trust.

We will examine identity, authorization, secrets, tenant isolation, workload identity, dependency boundaries, and the uncomfortable fact that observability itself can expose information if we do not design it carefully.

**Narrated-edition note:** The narration ends here. Editorial Alignment, Engineering Commentary, Interview Stops, the review exercise, checklists, and the editorial record remain in Markdown as review and instructor material and may be excluded from the narrated edition.

---

## Editorial Alignment

This chapter preserves the review edition’s controlling statements:

- **Preserved decisions:** Every important operation carries correlation and version context. Health endpoints do not pretend every dependency is equally critical. SLOs are capability-specific and owned.
- **Architecture principle:** Instrument the questions operators must answer, not merely the components the system contains.
- **Anti-pattern:** Declaring the platform healthy because every pod is running while business workflows are failing.

The chapter answers the review questions as follows:

1. Atlas distinguishes carrier failure from database failure by recording meaningful operation boundaries, dependency context, failure classifications, and trace evidence rather than reducing all failures to one generic error.
2. Customer-facing convergence is represented by capability-specific indicators that measure whether authoritative business facts reach required downstream outcomes within their objectives.
3. Release markers and release-version context allow operators to connect behavioral changes to deployed versions.
4. Detailed runtime examples remain teaching examples until linked repository evidence supports stronger labels.

---

## Engineering Commentary

### Why not just log everything?

Because volume is not understanding.

Undisciplined logging increases storage cost, search noise, security exposure, and operational burden. Useful logging records meaningful state transitions, failures, ownership context, and identifiers that help reconstruct a business journey.

### Why structured logs?

Structured fields allow operators and machines to query evidence consistently. `shipmentId`, `carrierCode`, `failureClass`, `correlationId`, and `releaseVersion` are more useful as defined fields than when buried unpredictably inside prose.

### Why metrics if we already have logs?

Logs explain individual events. Metrics expose population behavior and trends efficiently. Booking success rate, latency distributions, outbox age, queue age, and DLQ depth are operational questions that should not require scanning millions of log records.

### Why bounded metric labels?

Unbounded identifiers such as shipment IDs and event IDs create high-cardinality metric series and can make a metrics system expensive or unstable. Individual identifiers belong primarily in logs and traces. Metrics summarize bounded dimensions.

### Why traces if we already have correlation IDs?

Correlation IDs connect evidence across a business journey. Distributed traces add timing and parent-child execution structure. They are complementary. Correlation remains useful when traces are sampled, asynchronous work begins later, or operators start from a business identifier rather than a trace identifier.

### Why not put every dependency into liveness?

Because dependency failure and process failure require different recovery actions. Restarting a healthy application because a remote carrier is unavailable does not restore the carrier and may amplify an incident. Liveness should answer whether restarting this process is appropriate.

### Why business-integrity signals?

Infrastructure health proves infrastructure state. It does not prove business convergence. A queue can be empty because work completed correctly, because messages were lost, or because a consumer discarded them. Business-integrity evidence verifies the outcome that matters.

### Where this chapter needs implementation evidence

Before marking the described behavior as **Implemented**, link it to:

- Structured logging configuration and field conventions.
- Correlation propagation through HTTP, outbox publication, messaging, and consumers.
- Trace instrumentation and exporter configuration.
- Metrics definitions and bounded label policies.
- Shipping API liveness, readiness, and startup endpoints.
- Dependency-health semantics.
- Outbox backlog and oldest-pending-age telemetry.
- SQS queue-age and DLQ metrics.
- Consumer processing and failure classifications.
- Release/version metadata in logs, metrics, or traces.
- Capability SLI and SLO definitions.
- Dashboards and alert rules.
- Runbooks and incident-response ownership.
- Reconciliation or business-integrity checks.
- Tests demonstrating correlation propagation and health semantics.

---

## Interview Stops

Pause after each question and answer it aloud before reading the response.

### Senior Engineer

**Question:** What is the difference between logging and observability?

**Answer:** Logging is one telemetry mechanism. Observability is the ability to infer and explain system behavior from the evidence the system emits. Logs, metrics, traces, health semantics, release context, and business-integrity signals all contribute to that ability.

### Principal Engineer

**Question:** Every Atlas pod is healthy, but booked shipments are not reaching accounting. Is the platform healthy?

**Answer:** Not for that business capability. Process and infrastructure health are necessary evidence, but they do not prove business convergence. I would inspect shipment state, outbox age and publication evidence, queue age, consumer failures, DLQ state, and the accounting business effect.

### Reliability Engineer

**Question:** What is the difference between liveness and readiness?

**Answer:** Liveness asks whether the process is alive enough that restarting it is an appropriate recovery action. Readiness asks whether this instance should receive new traffic. A process may be alive but temporarily unready, and a remote dependency outage should not automatically make every application instance fail liveness.

### Security Architect

**Question:** Why is observability a security concern?

**Answer:** Telemetry can expose tenant identifiers, personal information, credentials, tokens, request payloads, or internal topology if collected carelessly. Observability must follow data-minimization, access-control, retention, and redaction rules just like other data systems.

### Skeptical Reviewer

**Question:** Why do we need traces if logs already contain a correlation ID?

**Answer:** Correlation lets us find related evidence. Traces additionally show execution structure and where latency travels across instrumented boundaries. Neither completely replaces the other, especially when traces are sampled or asynchronous work outlives the original request.

### Staff or Principal Engineer

**Question:** What metric would you alert on for the outbox?

**Answer:** Pending count is useful, but oldest-pending age is usually closer to the business risk because it measures how long committed facts have failed to publish. I would relate the alert threshold to the publication SLO rather than choose an arbitrary infrastructure number.

---

## Key Takeaways

1. Observability begins with operational questions, not telemetry products.
2. Healthy infrastructure does not prove healthy business workflows.
3. Business identifiers and correlation context must survive distributed and asynchronous boundaries.
4. Structured logs explain individual operations using queryable context.
5. Metrics summarize population behavior and should use bounded labels.
6. Traces show execution structure and where latency and failure travel.
7. Liveness, readiness, startup, dependency health, and business health answer different questions.
8. SLIs measure behavior; SLOs define owned targets; SLAs are contractual commitments.
9. Release markers connect behavioral changes to deployments.
10. Failure classifications should preserve operational meaning.
11. Alerts should identify conditions that require ownership and action.
12. Runbooks connect evidence to controlled recovery.
13. Business-integrity signals verify convergence beyond transport and infrastructure success.
14. Observability is an architectural responsibility because the evidence needed for safe operation crosses contracts, boundaries, deployments, and ownership.

## Related Concepts

- Structured logging
- OpenTelemetry
- Distributed tracing
- Correlation and causation
- RED and USE methods
- High-cardinality telemetry
- Histograms and latency percentiles
- Liveness, readiness, and startup probes
- Service-level indicators
- Service-level objectives
- Service-level agreements
- Error budgets
- Release markers
- Incident response
- Runbooks
- Alert fatigue
- Business observability
- Reconciliation
- Data minimization and telemetry security

## Review Exercise

A customer reports that shipment `SHP-48219` was booked successfully but no accounting intake record exists twenty minutes later.

Assume:

- The carrier confirmation is present.
- Atlas uses a transactional outbox.
- `ShipmentBooked` fans out through SNS to independent SQS queues.
- Accounting intake is expected to converge within five minutes.
- All application pods report healthy.
- A new accounting-consumer release was deployed thirty minutes ago.

Design the investigation.

Produce:

1. The business identifiers you would begin with.
2. The structured log fields needed to follow the shipment.
3. The metrics you would inspect.
4. The trace boundaries that would help.
5. The distinction between application health and business health.
6. The SLI that demonstrates whether accounting intake is meeting its objective.
7. The release evidence needed to evaluate the new deployment.
8. The failure classifications you would expect the consumer to emit.
9. The alert that should have detected the problem before customer support called.
10. The runbook steps for recovery if affected events are already in the DLQ.
11. The business-integrity check proving that recovery succeeded.

Then answer this question:

> If the accounting queue becomes empty after redrive, what evidence proves the incident is actually resolved?

Your answer should distinguish transport success from business convergence.

## Chapter Checklist

- [x] The lesson continues the shipment journey.
- [x] Observability begins with operational questions.
- [x] Structured logs, metrics, and traces have distinct responsibilities.
- [x] Correlation across asynchronous boundaries is explained.
- [x] Metric cardinality and bounded labels are addressed.
- [x] Liveness, readiness, and startup semantics are distinguished.
- [x] Infrastructure health is separated from business health.
- [x] SLI, SLO, and SLA are distinguished.
- [x] Release markers and failure classification are explained.
- [x] Incident investigation and runbooks connect evidence to action.
- [x] Business-integrity signals and convergence are explicit.
- [x] Editorial Alignment matches the review edition.
- [ ] Implementation claims are linked to repository evidence.
- [ ] Chapter has been read aloud and edited for pacing.
- [ ] Technical review is complete.
- [ ] Editorial review is complete.

## Editorial Record

- **Teaching-chapter status:** Draft
- **Owner:**
- **Reviewers:**
- **Evidence links:**
- **Related ADRs:** Confirm during implementation-evidence review.
- **Open questions:** Confirm implemented telemetry stack, correlation propagation, health endpoints, release markers, capability SLOs, alert ownership, runbooks, and business-integrity checks before promoting runtime claims beyond Teaching example.