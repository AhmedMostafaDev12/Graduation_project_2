# Remori — System Diagrams (spec v1)

All diagrams are Mermaid. They render on GitHub and in VS Code with a Mermaid preview extension.
They visualize [`REMORI_SPEC.md`](../../REMORI_SPEC.md) v1. `D#` refers to its §0 decision log. The resolved v0 findings are in [`SPEC_REVIEW.md`](../SPEC_REVIEW.md).

| File | Diagrams |
|---|---|
| [01-architecture.md](01-architecture.md) | System context · three tiers + degradation · glasses hardware · glasses software (Pi + ESP32) · backend components · AWS deployment · Flutter navigation · Flutter layers (shared code + Android/iOS relay) |
| [02-database-erd.md](02-database-erd.md) | ERD in three views (accounts/people/privacy · journal/audio/media · reminders/insights) · where each table lives |
| [03-sequences.md](03-sequences.md) | Onboarding + pairing · enrollment · recognition with encounters · **ambient memory** · fixed-intent question · **where am I** · free-form RAG · reminder · recording via Wi-Fi burst · smart review + OCR · unknown face → caregiver · nightly summary |
| [04-state-machines.md](04-state-machines.md) | Memory capture mode · audio segment · media asset · face identity · encounter · assistant interaction · reminder occurrence · phone relay links |
| [05-pipelines-and-usecases.md](05-pipelines-and-usecases.md) | Use cases · vision pipeline · audio pipeline (memory vs. assistant) · cloud jobs · RAG · build order |
