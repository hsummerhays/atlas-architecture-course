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

Use the bundled workspace Python runtime with:

```powershell
python tools/generate_review_docx.py
```

The generator reads `review/Atlas_Enterprise_Platform_Course_Review_Edition.md` and replaces the root `.docx`. After generation, render with LibreOffice's console launcher (`soffice.com`), inspect every page, and treat any unsynchronized manual Word edit as disposable.
