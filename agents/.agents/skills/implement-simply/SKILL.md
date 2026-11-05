---
name: implement-simply
description: "Implement the smallest valuable slice of a spec or set of tickets, leaving it uncommitted for review."
disable-model-invocation: true
---

Apply /implement, scoped down to the **thinnest slice**: the smallest change that delivers real value on its own.

1. Pick the slice. From the spec or tickets, choose the change with the least code that a user or caller could notice or rely on. Before writing code, state the slice and list everything you are deferring. Done when the slice fits in one sentence and every deferred item is listed.
2. Run /implement on that slice only, ending after its review step. Touch only the code the slice needs; add abstractions, options or refactors only when the slice cannot work without them.
3. Hand off for **human review**: leave every change uncommitted in the working tree. Report the slice delivered, the files changed, and the deferred list, then wait. Commit only once the human approves.
