# Chapter 6 — Failure Is Part of the Architecture

One of the easiest mistakes in software architecture is designing primarily for the successful path.

A request arrives. The service processes it. The database commits. A message is published. Another service consumes it. An external provider responds successfully.

Everything works.

Real systems are defined just as much by what happens when those assumptions stop being true.

Networks become unavailable. Requests time out. Containers restart. Credentials expire. Databases become overloaded. Messages arrive twice. Consumers crash after partially completing work. External providers throttle traffic. Deployments introduce defects. Entire cloud regions can become unavailable.

These events are not exceptional in the sense that they are surprising.

They are normal characteristics of distributed computing.

A mature architecture therefore asks a different question.

Not:

> **How do we prevent failure?**

But:

> **How does the system behave when failure occurs?**

Atlas treats failure handling as part of the architecture rather than something added afterward.

---

## 6.1 From Error Handling to Resilience

Traditional application development often treats failure locally.

```text
Operation
   ↓
try
   ↓
work
   ↓
catch
   ↓
handle error
```

That remains useful, but distributed systems introduce failures that cannot be understood entirely within one method.

Consider a simple Atlas operation:

```text
Atlas
  ↓
Carrier API
```

Several outcomes are possible:

```text
Request
   │
   ├── Success
   │
   ├── Explicit failure
   │
   ├── Timeout
   │
   ├── Connection failure
   │
   ├── Authentication failure
   │
   ├── Rate limited
   │
   └── Unknown outcome
```

The last case is particularly interesting.

Suppose Atlas sends a shipment request.

The carrier creates the shipment.

The network connection fails before Atlas receives the response.

What happened?

From the carrier's perspective:

```text
Shipment created
```

From Atlas's perspective:

```text
Operation failed?
```

Retrying blindly could create a second shipment.

The problem is no longer simply exception handling.

It is a distributed-state problem.

That distinction is the beginning of resilience engineering.

---

## 6.2 Timeouts Are Architectural Boundaries

Every network operation should have a finite expectation for how long it is allowed to consume resources.

Without a timeout:

```text
Atlas
  ↓
External Service
  ↓
wait
  ↓
wait
  ↓
wait
  ↓
?
```

The caller cannot distinguish between:

- a slow service,
- a failed service,
- a broken network,
- a lost response,
- a request that is still processing.

Meanwhile, resources remain occupied.

Enough slow operations can exhaust:

- worker threads,
- database connections,
- HTTP connections,
- memory,
- request queues,
- container capacity.

The failure of one dependency can then become the failure of Atlas itself.

A timeout creates a boundary:

```text
Request
   ↓
Wait ≤ configured duration
   │
   ├── Response → Continue
   │
   └── Timeout  → Apply failure policy
```

The timeout does not make the dependency more reliable.

It protects Atlas from waiting indefinitely for something outside its control.

### Choosing a Timeout

Timeout values should not simply be copied from framework defaults.

They should reflect the behavior of the operation.

A request used during an interactive user workflow may have a very different tolerance from a background synchronization process.

For example:

```text
Interactive request
Expected: hundreds of milliseconds
Tolerance: seconds

Background import
Expected: several seconds
Tolerance: potentially much longer
```

The important concept is that timeout configuration expresses an architectural decision:

> **How much of our capacity are we willing to spend waiting for this dependency?**

---

## 6.3 Retries Are Not Automatically Safe

When something fails temporarily, retrying seems obvious.

```text
Request
   ↓
Failure
   ↓
Retry
   ↓
Success
```

For transient failures, this works remarkably well.

Cloud systems routinely experience brief failures caused by:

- connection resets,
- service transitions,
- temporary throttling,
- container startup,
- load balancing changes,
- short database contention,
- network interruptions.

Retries hide many of these events from users.

But retries also create danger.

Suppose 1,000 Atlas requests are calling an overloaded dependency.

The dependency begins failing.

Every request immediately retries three times.

Instead of receiving 1,000 requests, the struggling service may suddenly receive approximately 4,000 attempts.

```text
Dependency overloaded
        ↓
Requests fail
        ↓
Clients retry
        ↓
More requests
        ↓
Dependency becomes more overloaded
        ↓
More failures
```

A resilience mechanism has become a failure amplifier.

---

## 6.4 Backoff and Jitter

Retries should generally become less aggressive as failures continue.

A simple exponential backoff might behave like:

```text
Attempt 1 → immediate
Attempt 2 → wait 1 second
Attempt 3 → wait 2 seconds
Attempt 4 → wait 4 seconds
Attempt 5 → wait 8 seconds
```

This gives the dependency time to recover.

But another problem remains.

Imagine 500 application instances encounter the same outage simultaneously.

They all calculate:

```text
Retry in 2 seconds.
```

Two seconds later:

```text
500 requests arrive together.
```

They fail again.

Then they all wait four seconds.

Four seconds later:

```text
500 requests arrive together again.
```

The retry policy has synchronized the clients.

This is sometimes called a **thundering herd** problem.

Jitter introduces controlled randomness:

```text
Base retry delay: 4 seconds

Instance A → 3.7 seconds
Instance B → 4.3 seconds
Instance C → 4.8 seconds
Instance D → 3.9 seconds
```

The requests spread over time instead of arriving simultaneously.

A more resilient retry strategy therefore looks like:

```text
Failure
   ↓
Is failure transient?
   │
   ├── No → Fail
   │
   └── Yes
        ↓
   Backoff + Jitter
        ↓
      Retry
```

---

## 6.5 Retry Only What Can Succeed

Not every failure deserves another attempt.

Consider:

```text
401 Unauthorized
```

Retrying the identical request with the identical expired credential is unlikely to help.

Likewise:

```text
400 Bad Request
```

If the request is structurally invalid, sending it five more times accomplishes nothing.

Compare that with:

```text
503 Service Unavailable
```

or:

```text
429 Too Many Requests
```

Those conditions may genuinely be temporary.

Atlas therefore distinguishes between **transient** and **permanent** failures.

```text
Failure
   │
   ├── Validation failure ─────→ Do not retry
   ├── Authorization failure ──→ Usually do not retry
   ├── Not found ──────────────→ Context dependent
   ├── Rate limit ─────────────→ Retry according to policy
   ├── Timeout ────────────────→ Possibly retry
   └── Service unavailable ────→ Usually retry
```

The policy should understand the semantics of the dependency rather than treating every exception identically.

---

## 6.6 Idempotency Makes Retries Safer

Retries become especially dangerous when operations modify state.

Suppose Atlas sends:

```text
POST /shipments
```

The provider processes the request but Atlas times out before receiving the response.

Atlas retries.

Without protection:

```text
Attempt 1 → Shipment #1001 created
              ↓
          response lost

Attempt 2 → Shipment #1002 created
```

One logical request has created two physical shipments.

An **idempotency key** changes the interaction.

```text
POST /shipments

Idempotency-Key:
atlas-7f3a...
```

Atlas retries with the same logical operation identifier.

The provider—or Atlas's own integration layer—can recognize the duplicate.

```text
Attempt 1
Key ABC
   ↓
Shipment #1001

Attempt 2
Key ABC
   ↓
Already processed
   ↓
Return Shipment #1001
```

This illustrates an important principle:

> **Retry policy and idempotency policy belong together.**

Retries without idempotency can turn transient infrastructure failures into duplicated business operations.

---

## 6.7 Circuit Breakers Protect the System

Retries assume a dependency may recover soon.

Sometimes it clearly has not.

Imagine every Atlas request continues calling an unavailable carrier API.

Each request waits for a timeout.

Each retries.

Each waits again.

Atlas wastes substantial capacity proving something it already has strong evidence to believe:

```text
The dependency is unhealthy.
```

A circuit breaker remembers recent failures.

Conceptually, it has three states.

```text
             failure threshold
CLOSED ─────────────────────────→ OPEN
  ↑                                │
  │                                │ wait
  │                                ↓
  └──────── success ───────── HALF-OPEN
```

### Closed

Requests flow normally.

Failures are monitored.

### Open

Requests are rejected immediately without calling the dependency.

### Half-open

After a recovery interval, a limited number of requests are allowed through.

If they succeed, the circuit closes.

If they fail, it opens again.

This provides two benefits.

First, Atlas avoids wasting resources on calls that are unlikely to succeed.

Second, the failing dependency gets time to recover without being continuously hammered by traffic.

---

## 6.8 Bulkheads Limit the Blast Radius

Circuit breakers protect Atlas from unhealthy dependencies.

Bulkheads protect one part of Atlas from another.

The term comes from ships.

A ship's hull can be divided into watertight compartments.

If one compartment floods:

```text
┌─────┬─────┬─────┬─────┐
│ OK  │ OK  │FAIL │ OK  │
└─────┴─────┴─────┴─────┘
```

the entire vessel does not necessarily sink.

Software can use the same principle.

Suppose Atlas integrates with three carriers.

Without resource isolation:

```text
Shared Worker Pool
       │
 ┌─────┼─────┐
 ↓     ↓     ↓
FedEx  UPS  USPS
```

If one provider becomes extremely slow, its requests may consume the entire worker pool.

Healthy integrations are now affected by an unrelated failure.

With bulkheads:

```text
FedEx Pool → FedEx

UPS Pool   → UPS

USPS Pool  → USPS
```

one provider can exhaust its allocated capacity without consuming everything.

Bulkheads can exist at many levels:

- thread pools,
- connection pools,
- queues,
- containers,
- service instances,
- concurrency limits,
- Kubernetes workloads,
- cloud accounts or subscriptions.

The principle remains the same:

> **Failure should consume a bounded amount of the system.**

---

## 6.9 Rate Limiting Protects Both Sides

Atlas may need protection from excessive inbound traffic.

Its dependencies may also need protection from Atlas.

These are related but distinct concerns.

### Inbound Rate Limiting

Suppose a client accidentally begins sending thousands of requests per second.

Without limits:

```text
Client
  ↓↓↓↓↓↓↓↓↓↓↓
Atlas
  ↓
Resource exhaustion
```

A rate limiter can enforce a policy such as:

```text
Tenant A
100 requests / second
```

Requests beyond the allowed capacity may be:

- rejected,
- delayed,
- queued,
- throttled.

### Outbound Rate Limiting

External APIs frequently impose quotas.

For example:

```text
Carrier API
Maximum: 500 requests/minute
```

Atlas should avoid discovering that limit exclusively through repeated `429` responses.

Instead, outbound concurrency and throughput can be controlled deliberately.

```text
Atlas workload
      ↓
Rate limiter
      ↓
Allowed throughput
      ↓
Carrier
```

This turns provider limits into explicit system behavior.

---

## 6.10 Queues Are Shock Absorbers

Queues do more than enable asynchronous communication.

They absorb differences between production rate and consumption rate.

Suppose Atlas receives a burst of 10,000 synchronization events.

Without buffering:

```text
10,000 events
      ↓
Consumer
      ↓
Overload
```

With a queue:

```text
10,000 events
      ↓
┌───────────────┐
│     Queue     │
│ █████████████ │
└───────┬───────┘
        ↓
Consumers process
at sustainable rate
```

The queue converts a traffic spike into backlog.

This is enormously useful.

But the work has not disappeared.

It has merely moved.

A growing queue therefore represents stored latency.

If producers continuously create 1,000 messages per second while consumers can process only 800:

```text
+1000/sec
- 800/sec
---------
+ 200/sec backlog
```

No amount of queue durability fixes the underlying capacity mismatch.

Eventually something must change:

- scale consumers,
- slow producers,
- shed work,
- increase processing efficiency,
- accept greater latency.

Queue depth is therefore an important operational signal.

---

## 6.11 Dead-Letter Queues

Some messages will never succeed automatically.

Consider a message containing data that violates a newly introduced business rule.

The consumer attempts processing.

It fails.

The broker retries.

It fails again.

Without a termination policy:

```text
Message
   ↓
Fail
   ↓
Retry
   ↓
Fail
   ↓
Retry
   ↓
Fail
   ↓
forever
```

This wastes resources and can block useful work.

After an appropriate number of attempts, Atlas can move the message to a **dead-letter queue**.

```text
Main Queue
    ↓
Consumer
    ↓
Repeated failure
    ↓
Dead-Letter Queue
```

The message is preserved for investigation without continuously disrupting normal processing.

But creating a dead-letter queue is only half the architecture.

Someone must answer:

> **What happens to messages after they arrive there?**

A mature system needs an operational process:

```text
Dead-letter message
        ↓
Alert / dashboard
        ↓
Investigation
        ↓
Correct data or software
        ↓
Replay / discard
```

A dead-letter queue nobody monitors is merely a durable place to lose messages.

---

## 6.12 Poison Messages

A poison message is one that repeatedly causes processing failure.

Examples include:

- malformed payloads,
- incompatible schema versions,
- impossible business state,
- corrupted data,
- unexpected null values,
- bugs triggered by particular input.

Poison messages are dangerous because they can repeatedly crash consumers.

A robust consumer therefore needs to distinguish between:

```text
Temporary processing failure
```

and:

```text
This particular message cannot be processed.
```

The former deserves retry.

The latter deserves isolation and investigation.

This distinction prevents one bad piece of data from becoming a system-wide availability problem.

---

## 6.13 Duplicate Delivery Is Normal

Many messaging systems provide **at-least-once delivery**.

That means the system promises:

> The message should not be silently lost.

It does not necessarily promise:

> The message will arrive exactly once.

Consider:

```text
Broker
  ↓
Consumer receives Message 42
  ↓
Consumer updates database
  ↓
Consumer crashes
  ↓
Acknowledgement never reaches broker
  ↓
Broker delivers Message 42 again
```

The broker cannot know that the database update succeeded.

Redelivery is therefore the safe choice.

Atlas must assume duplicates are possible.

A consumer can maintain an inbox or idempotency ledger:

```text
Message arrives
      ↓
Have we processed ID 42?
      │
   ┌──┴──┐
   │     │
  Yes    No
   │     │
Ignore  Process
         ↓
      Record 42
```

This converts duplicate delivery from an exceptional event into normal processing behavior.

---

## 6.14 Ordering Is More Complicated Than It Appears

Imagine Atlas publishes:

```text
1. ShipmentCreated
2. ShipmentCancelled
```

A consumer naturally expects:

```text
Created
   ↓
Cancelled
```

Distributed processing may produce:

```text
Cancelled
   ↓
Created
```

if messages travel through different partitions, retries, or processing paths.

Global ordering is expensive and often unnecessary.

The better question is usually:

> **Which events actually require ordering relative to one another?**

Often ordering is only required for a particular entity.

```text
Shipment 123 events → same partition
Shipment 456 events → another partition
```

This preserves useful ordering without forcing the entire platform through one serial pipeline.

Again, the architecture comes from understanding the business invariant rather than demanding a technically convenient absolute guarantee.

---

## 6.15 Graceful Degradation

A resilient system does not always need every dependency to provide useful service.

Suppose the primary rating provider is unavailable.

Atlas might still:

- display previously cached rates,
- accept the shipment for later processing,
- use another carrier,
- provide partial results,
- clearly report temporary unavailability.

This is **graceful degradation**.

```text
Full system capability
        ↓
Dependency failure
        ↓
Reduced capability
        ↓
Core system remains usable
```

The alternative is brittle architecture:

```text
One dependency fails
        ↓
Everything fails
```

Graceful degradation requires product and business decisions.

Engineering cannot independently decide that stale pricing is acceptable, for example.

The business must define what degraded operation means.

Resilience therefore crosses organizational boundaries.

---

## 6.16 Health Checks Need Meaning

Modern platforms frequently ask applications whether they are healthy.

A simple endpoint might return:

```text
200 OK
```

But what does *healthy* mean?

There are at least two useful questions.

### Is the process alive?

```text
Liveness
```

If not, the platform may restart it.

### Can the process currently serve traffic?

```text
Readiness
```

If not, the load balancer may temporarily stop routing requests to it.

These questions should not be confused.

Suppose Atlas temporarily loses access to a downstream carrier.

Should Kubernetes restart Atlas?

Probably not.

Restarting a perfectly functional application because another company is experiencing an outage can make matters worse.

Health checks should therefore reflect what the orchestrator can actually fix.

A useful rule is:

> **Do not fail a liveness check because of a condition that restarting the process cannot repair.**

---

## 6.17 Observability Completes Resilience

A retry policy can hide transient failures from users.

That is useful.

It can also hide a deteriorating dependency from operators.

Suppose:

```text
Monday:
99.9% requests succeed first attempt

Friday:
60% succeed first attempt
39.9% succeed after retries
0.1% fail
```

From the user's perspective, availability still appears excellent.

Operationally, the system is telling us something important.

Without telemetry, the retry mechanism masks the warning.

Atlas therefore needs visibility into:

- retry counts,
- timeout rates,
- circuit-breaker state,
- queue depth,
- dead-letter messages,
- processing latency,
- dependency response time,
- rate-limit events,
- error categories,
- idempotency collisions,
- consumer lag.

Resilience without observability can turn visible failures into invisible deterioration.

---

## 6.18 Resilience Policies Must Compose Carefully

One of the subtler problems appears when individually reasonable resilience policies are combined.

Imagine:

```text
API Gateway retries 3 times
        ↓
Atlas retries 3 times
        ↓
Service B retries 3 times
        ↓
Database client retries 3 times
```

A single user operation may generate far more attempts than anyone intended.

Conceptually:

```text
1 request
   ↓
3 gateway attempts
   ↓
3 service attempts each
   ↓
3 downstream attempts each
```

The amplification can become enormous.

This is why resilience cannot be configured independently at every layer without considering the entire call chain.

The architecture must decide:

- which layer owns retries,
- where timeouts apply,
- what the total latency budget is,
- which operations are idempotent,
- where circuit breakers belong,
- how retry counts interact.

Otherwise, defensive mechanisms can collectively create offensive traffic.

---

## 6.19 The Failure Budget

There is another important realization.

Perfect availability is not achievable.

Moving from:

```text
99%
```

to:

```text
99.9%
```

requires additional engineering.

Moving from:

```text
99.9%
```

to:

```text
99.99%
```

requires substantially more.

Each additional nine generally demands more redundancy, automation, operational discipline, infrastructure, testing, and expense.

Architecture therefore needs a target.

If Atlas has an availability objective of 99.9%, that implies a finite amount of acceptable unavailability.

That becomes part of the engineering conversation.

The question changes from:

> “Can this ever fail?”

to:

> **“Does the system meet the reliability level the business actually requires?”**

This prevents teams from spending enormous amounts of engineering effort eliminating failure modes whose business consequences do not justify the cost.

---

## 6.20 Designing the Failure Path

For an important Atlas operation, we can now ask a structured set of questions.

Suppose Atlas calls an external provider.

```text
Atlas
  ↓
Provider
```

The architecture should consider:

**How long will Atlas wait?**

Timeout.

**Which failures should be attempted again?**

Retry classification.

**How quickly should retries occur?**

Backoff and jitter.

**Can repeating the operation cause duplicate business effects?**

Idempotency.

**What happens if the provider remains unavailable?**

Circuit breaker.

**Can this dependency consume all Atlas resources?**

Bulkhead or concurrency limit.

**Can work wait until the provider recovers?**

Queue.

**What happens to work that repeatedly fails?**

Dead-letter handling.

**How will operators know any of this is happening?**

Observability.

That gives us a much richer architecture:

```text
                    ┌──────────────┐
                    │ Observability│
                    └──────┬───────┘
                           │
                           ↓
Request
   ↓
Rate / concurrency limit
   ↓
Circuit breaker
   ↓
Timeout
   ↓
Provider
   │
   ├── Success
   │
   └── Transient failure
             ↓
       Backoff + jitter
             ↓
           Retry
             ↓
       Failure threshold
             ↓
     Queue / DLQ / fallback
```

The failure path is no longer an afterthought.

It is part of the design.

---

## 6.21 Failure Domains

Perhaps the most useful way to think about resilience is in terms of **failure domains**.

Ask:

> If this component fails, what else fails with it?

Consider several architectures.

```text
Single process
    ↓
Process failure
    ↓
Everything unavailable
```

Or:

```text
Multiple services
    ↓
Shared database
    ↓
Database failure
    ↓
Everything unavailable
```

Or:

```text
Multiple services
    ↓
Independent storage
    ↓
One database failure
    ↓
One capability degraded
```

Distributed architecture does not automatically improve resilience.

It improves resilience only when boundaries actually isolate failure.

Splitting a monolith into twenty services while making all twenty depend synchronously on the same critical service may create more failure paths rather than fewer.

The architectural goal is not simply distribution.

It is controlled dependency.

---

## 6.22 Failure Is Information

Failures reveal assumptions.

A timeout tells us we assumed a dependency would respond within a particular period.

A duplicate message tells us we assumed delivery semantics that may not exist.

A cascading outage tells us we assumed one dependency's failure would remain isolated.

A dead-letter message tells us some production data violated assumptions embedded in our code.

A capacity incident tells us our expected workload model was incomplete.

This makes production failure valuable—provided the organization learns from it.

The mature response to an incident is therefore not simply:

```text
Fix the bug.
```

It is:

```text
What assumption failed?
        ↓
Why did the architecture permit
this failure to spread?
        ↓
What signal could have warned us?
        ↓
What boundary could contain it?
        ↓
How do we make recurrence less likely?
```

This is why incident reviews can become an important source of architectural knowledge.

---

## 6.23 The Senior Engineer's Question

When reviewing a system diagram, it is easy to focus on the arrows.

```text
A → B → C
```

A senior engineer should mentally replace every arrow with several questions:

```text
A → B

What if B is slow?

What if B is unavailable?

What if the request reaches B
but the response never returns?

What if A retries?

What if B processes it twice?

What if B stays unavailable for an hour?

What if thousands of A instances
all retry simultaneously?

How will we know?
```

That way of thinking fundamentally changes architecture.

The happy path explains how the system works.

The failure path explains whether the system can survive reality.

And this leads to one of the most important principles in Atlas:

> **A dependency is not fully designed until its failure behavior is understood.**

Failures will happen.

Networks will misbehave.

Containers will disappear.

Messages will be duplicated.

Providers will throttle.

Databases will slow down.

Deployments will occasionally be wrong.

The engineering achievement is not constructing a system in which none of those things happen.

It is constructing a system in which they can happen **without becoming catastrophes**.

That is resilience.

And resilience is architecture.
