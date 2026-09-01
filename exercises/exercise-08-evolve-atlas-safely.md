# Exercise 8 — Evolve Atlas Safely

## Scenario
Atlas currently stores carrier authentication tokens in a shared configuration table `carrier_configs.auth_token`. As Atlas expands to enterprise customers, security mandates that all carrier credentials must be migrated to an external cloud secret vault (e.g., AWS Secrets Manager / Azure Key Vault) with encrypted ARN references `carrier_configs.secret_arn` and automatic 90-day rotation.

There are currently 450 active enterprise tenants processing live shipments 24/7. An engineer suggests:
> *"Let's schedule a 4-hour maintenance window this Saturday night, run a SQL migration script to drop the `auth_token` column, add `secret_arn`, deploy the new code version, and migrate all secrets at once."*

As the lead architect, you reject a big-bang maintenance window migration.

## Your Task
Design a zero-downtime evolutionary migration using the **Expand-and-Contract (Parallel Run) Pattern** and **Automated Fitness Functions**.

## Constraints
1. Zero downtime: Live shipment booking must continue uninterrupted 24/7.
2. Backward and forward compatibility: Old and new application versions must be able to run concurrently during rolling deployments.
3. Once migration is complete, an automated fitness function must prevent any code from ever accessing the deprecated plain text column again.

## Architecture Questions
1. What are the three distinct phases of the Expand-and-Contract pattern for this database schema and application code change?
2. How should the application handle reading secrets during the transition window when some tenants have been migrated to Secrets Manager and others still have database tokens?
3. How do you implement a CI/CD architectural fitness function to verify that the old `auth_token` access is fully dead before executing the final contract phase?

## Deliverable
A Staged Safe Migration Plan:
- **Phase 1: Expand** (Schema, Code, and Tolerant Reader support).
- **Phase 2: Migrate** (Background secret copy, dual-read logic, shadow verification, traffic switch).
- **Phase 3: Contract** (Deprecation verification, fitness function test, schema cleanup).
- **Automated Fitness Function Definition:** Concrete CI test assertion.

## Run-Through Checklist
- [ ] Database schema evolution is non-breaking across rolling container updates.
- [ ] Application operates as a tolerant reader during migration.
- [ ] Automated ArchUnit / CI checks ensure architectural decay does not reintroduce deprecated columns.

## Discussion / Reflection
Why are big-bang cutovers with maintenance windows considered an anti-pattern in modern cloud architecture? How does the expand-and-contract pattern reduce release risk to almost zero?

<details>
<summary><b>Suggested Approach (Click to expand)</b></summary>

### 1. The Staged Expand-and-Contract Plan

#### Phase 1: Expand (Non-breaking additive change)
- **Database:** Add column `secret_arn VARCHAR(255) NULL` to `carrier_configs`. (Do NOT remove `auth_token`).
- **Code Release v1.1:** Deploy updated `CarrierAuthStrategy` that acts as a **Tolerant Reader**:
  ```java
  public String getCarrierSecret(CarrierConfig config) {
      if (config.getSecretArn() != null) {
          return secretsManager.getSecretValue(config.getSecretArn());
      }
      return config.getAuthToken(); // Fallback for unmigrated tenants
  }
  ```
- *Result:* Zero impact on running traffic.

#### Phase 2: Migrate (Dual Write & Background Migration)
- **Secret Migration Script:** A rate-limited background worker reads each `auth_token`, creates a secret in AWS Secrets Manager, and updates `carrier_configs.secret_arn = :arn`.
- **Shadow Verification:** Telemetry compares tokens fetched via ARN against DB tokens to verify 100% parity.
- **Switch Authority:** Once all 450 tenants have valid `secret_arn` entries, update application code to only read `secret_arn`. Null out `auth_token` fields in database.

#### Phase 3: Contract (Cleanup & Verification)
- **Code Release v1.2:** Remove fallback logic and `getAuthToken()` method from domain models.
- **Database:** Drop column `carrier_configs.auth_token`.
- *Result:* Schema and code are clean with zero downtime and zero maintenance windows.

### 2. Automated Architectural Fitness Function (ArchUnit)
Add an automated CI test in `AtlasArchitectureTests.java`:
```java
@ArchTest
public static final ArchRule no_code_should_reference_plaintext_carrier_tokens =
    noClasses()
        .should().dependOnClassesThat().haveSimpleNameEndingWith("CarrierConfig")
        .andShould().callMethodWhere(name("getAuthToken"))
        .because("ADR-0005 and ADR-0008 mandate all carrier secrets must resolve via SecretArn");
```

*(Reference: [Diagram: Evolutionary Architecture Feedback Loop](../diagrams/evolutionary-architecture-loop.svg), [ADR-0005](../adr-examples/ADR-0005-managed-identity-and-secret-handling.md), [ADR-0008](../adr-examples/ADR-0008-architectural-fitness-functions.md))*
</details>
