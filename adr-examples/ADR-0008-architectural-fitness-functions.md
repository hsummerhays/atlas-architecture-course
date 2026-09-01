# ADR-0008: Automated Architectural Fitness Functions in CI/CD

## Status
Accepted

## Context
Architectural decay occurs gradually when code changes inadvertently bypass domain boundaries, introduce forbidden cross-module dependencies (such as shipping code importing internal agent automation classes), or check in unverified secret references. Visual architecture diagrams do not prevent drift unless boundaries are executable and tested continuously.

## Decision
We implement automated **Architectural Fitness Functions** executed as mandatory gates in the CI/CD pipeline:
1. **Module Boundary Tests (ArchUnit):** Static analysis tests assert that `atlas-shipping-app` has zero dependencies on `atlas-agent-platform` internals, and domain entities do not depend on external carrier adapter DTOs.
2. **Contract & Schema Compatibility Verification:** Automated schema linters check that event schemas and API contracts only introduce backward-compatible expansions (tolerant reader rules).
3. **Secret & Manifest Linting:** Pre-commit and CI scanners detect hardcoded credentials and prevent agent manifests from binding shipping runtime secrets.

## Alternatives Considered
1. **Manual Code Reviews Alone:** Relying on human reviewers to spot boundary violations. Rejected because subtle dependency leaks and transitive imports easily escape human inspection.
2. **Post-Incident Architecture Audits:** Reviewing architecture diagrams periodically once a quarter. Rejected because reversing accumulated boundary violations is exponentially more expensive after code has reached production.

## Consequences
- **Positive:** Catches architectural violations before code merges; transforms passive architectural guidelines into executable, failing unit tests.
- **Negative:** Adds a small amount of test execution time to CI/CD builds; requires developers to update tests when legitimate boundary evolutions occur.

## Evidence / Atlas Status
- **Atlas Status:** Implemented in CI build pipeline tests; planned direction for expanded multi-repo contract testing.
