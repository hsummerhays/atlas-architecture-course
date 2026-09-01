# Atlas Architecture Course

Reference implementation: atlas-enterprise-platform

This repository contains the teaching, architecture, and portfolio artifacts for the Atlas Enterprise Platform. It is structured to be the primary source of truth for the course materials.

## Start Here

The course is a narrated tour of the system, not a reading of the reference implementation's documentation. Begin with [Chapter 1](course/chapter-01-business-problem.md), which establishes the voice and lesson format used by the teaching edition.

The authoritative editorial control copy is [the review edition](review/Atlas_Enterprise_Platform_Course_Review_Edition.md). Review decisions, terminology, status, ADR alignment, and current/target-state descriptions are maintained there before they are expanded into narrated chapters.

Each teaching chapter combines:

- Conversational narration organized around an architectural story.
- Engineering commentary that explains why a decision was made.
- Interview stops that invite the listener to answer before reading on.
- Key takeaways and related concepts for later review.
- Explicit evidence labels so current behavior is not confused with a future target or teaching example.

## Course Material Labels

Please note that this course describes both the current boundary of the platform and its future target. All material should be clearly labeled as one of the following to distinguish its role:

- **Implemented**: Currently available in the reference implementation.
- **Current architecture**: Describes the current state of the architecture.
- **Planned direction**: Represents a future target state not yet fully implemented.
- **Teaching example**: Illustrative examples meant for instruction.
- **Conceptual extension**: Theoretical expansions on the core concepts.

## Structure

- `course/` — The authoritative narrated teaching edition.
- `review/` — The condensed editorial control copy used to track decisions and review status.
- `diagrams/` — Current, transition, target, and teaching views referenced by lessons.
- `adr-examples/` — Architecture Decision Records used by the course.
- `exercises/` — Hands-on exercises and expected outcomes.
- `tools/` — Deterministic publishing and validation utilities.

Markdown is authoritative for both editorial and teaching content. The root `Atlas_Enterprise_Platform_Course_Review_Edition.docx` is generated from the review Markdown and must not be edited independently.

## Generate the Review Edition

Run the complete publishing and verification sequence with:

```powershell
powershell -ExecutionPolicy Bypass -File tools/publish_review.ps1
```

The command generates the root DOCX from the authoritative review Markdown, converts it directly with LibreOffice's console launcher (`soffice.com`), rasterizes every PDF page, and verifies the page sequence and image output. Generated QA artifacts are written beneath `.build/review/` and are ignored by Git. A successful machine check does not replace the required visual inspection of every page.

The narrated teaching edition includes:
- [Chapter 1 — The Business Problem](course/chapter-01-business-problem.md)
- [Chapter 2 — Following a Shipment](course/chapter-02-following-a-shipment.md)
- [Chapter 3 — The Shipment Leaves a Message](course/chapter-03-events-and-reliability.md)
- [Chapter 4 — Security](course/chapter-04-security.md)
- [Chapter 5 — Architectural Tradeoffs](course/chapter-05-tradeoffs.md)
- [Chapter 6 — Failure Is Part of the Architecture](course/chapter-06-failure-is-part-of-the-architecture.md)
- [Chapter 7 — Observability: Understanding a Running System](course/chapter-07-observability-understanding-a-running-system.md)
- [Chapter 8 — Evolutionary Architecture](course/chapter-08-evolutionary-architecture.md)
- [Chapter 9 — The Architect's Method](course/chapter-09-the-architects-method.md)
