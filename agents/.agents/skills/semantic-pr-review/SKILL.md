---
name: semantic-pr-review
description: 'Review a pull request as a time-boxed visual HTML report, given a required PR number and an optional owner/repository that defaults to the current Git repository. Separates automatable checks from semantic review, groups ripple effects under causal changes, ranks material by significance, and recommends reviewer expertise. Use for PR review, change-risk assessment, or reviewer selection.'
---

# Semantic Pull Request Review

Review a pull request for correctness and risk while concentrating human attention on meaningful changes.

## Invocation

Use the portable argument form:

`<pr-number> [owner/repository]`

- Require `pr-number` as a positive integer. If it is missing or invalid, ask for it before beginning the review.
- Treat `owner/repository` as optional. When omitted, resolve it from the current workspace's Git repository and primary remote.
- When the current workspace is not a Git repository, has no identifiable GitHub remote, or resolves ambiguously, ask for `owner/repository`.
- When supplied, require `owner/repository` exactly; do not infer a similarly named repository.

## Principles

- Review only. Do not modify code, branches, commits, or pull request state unless separately asked.
- Keep generated reports outside the reviewed repository. Report generation must not alter its working tree.
- Follow repository-specific instructions relevant to the changed files.
- Treat generated output, whitespace-only edits, formatting-only edits, and import-only refactors as review noise unless they alter behavior or reveal an integration problem.
- Do not report style or simple rule violations as semantic findings when a deterministic tool can check them.
- Trace a change through definitions, callers, implementations, tests, configuration, documentation, and external contracts before deciding that edits are independent.
- Distinguish evidence from inference. State uncertainty when the diff or repository context cannot establish behavior.

## Review Clock And Significance

Start a monotonic review clock as soon as the PR target is resolved. These deadlines are hard limits:

- **By 10 seconds:** write and open an `Initial` report containing all grounded findings and significant changes established so far. If there are none, say `No grounded findings yet; analysis is in progress.` Never speculate to fill the report.
- **From 10 to 45 seconds:** deepen analysis in descending significance.
- **At 45 seconds:** stop opening investigative branches. Do not start another search, history query, test, linked-issue traversal, or specialist investigation. Consolidate evidence and enumerate skipped scope.
- **By 60 seconds:** overwrite the same report as `Complete`, or `Complete at deadline` when scope remains. Stop regardless and report every unreviewed cluster or file class as residual risk.

Prefer bounded operations with explicit result limits. Abandon unavailable, rate-limited, or slow context instead of breaching the deadline. External calls may outlive a requested timeout, so use conservative cut-offs and do not depend on late results.

Use this significance order for investigation and presentation:

1. Security, privacy, data loss, authentication, authorization, and permission boundaries.
2. Public contracts, persisted data, schemas, compatibility, and migrations.
3. Core behavior, state transitions, concurrency, and failure paths.
4. Performance, operations, reliability, and observability.
5. Tests, documentation, generated output, and supporting changes.

Within a tier, rank by user impact, then blast radius, confidence, and difficulty of reversal. Apply this model to findings, causal clusters, automation candidates, and residual risks.

## Procedure

1. Establish the review scope.
   - Resolve the target from the required PR number and the supplied or current repository.
   - Start the review clock immediately after resolution.
   - In one bounded parallel batch, gather PR metadata and description, the changed-file summary, status checks, and exact diff evidence for the highest-significance candidate changes.
   - Delegate deterministic checks as described below; do not run slow or exhaustive checks during the semantic review.
   - Read the PR description and linked issue for intended behavior, but verify claims against the code.
   - Create the report path once, write the initial report, and open it before the 10-second deadline as described in [HTML-REPORT.md](HTML-REPORT.md).
   - After initial delivery, inspect commits, prior review context, the remaining exact diff, and relevant repository context in significance order and within the remaining clock.

2. Partition the diff before semantic review.
   - Ignore whitespace-only and trivial formatting changes.
   - Ignore refactored import sections, including sorting, grouping, and mechanically updated imports, unless symbol resolution, initialization order, side effects, or dependency boundaries changed.
   - Identify changes suitable for deterministic checking: formatting, lint rules, type errors, compilation, dead code, spelling, dependency policy, generated-file consistency, API/schema compatibility, or other simple rule conformance.
   - Put these changes aside as automation candidates. Name the most appropriate concrete tool or tool category, such as the repository formatter, linter, type checker, compiler, test runner, dependency scanner, secret scanner, schema checker, or API compatibility checker.
   - Do not spend the semantic review reproducing those tools by hand.

3. Build causal change clusters.
   - Find each change that introduces a new behavior, contract, invariant, data shape, control-flow decision, dependency, permission boundary, or architectural responsibility.
   - Group mechanically consequent edits beneath that cause. Examples include callers updated for a changed method signature, implementations updated for an interface change, fixtures regenerated for a schema change, and tests adjusted for a new contract.
   - Do not count each ripple edit as a separate significant change.
   - If one changed file belongs to multiple causes, discuss the relevant hunks in their respective clusters.
   - Treat a broad ripple as evidence of impact and compatibility risk, even when each individual edit is trivial.

4. Review every significant cluster.
   - Explain what changed, why it appears to have changed, and how behavior or contracts differ from before.
   - Identify the causal or defining edit and summarize its grouped ripple effects.
   - Inspect boundary conditions, failure paths, state transitions, concurrency, compatibility, security, performance, observability, migration, and test coverage when relevant.
   - Look for missed ripple effects outside the diff by searching for callers, implementations, serialized forms, configuration consumers, and public interfaces.
   - Record concrete defects or risks as findings, grounded in file paths and line numbers.
   - Recommend the kind of human review the cluster needs and explain why. Be specific: security, privacy, domain/product, language/runtime, framework, data/storage, API compatibility, distributed systems, accessibility, performance, operations/SRE, or another relevant specialty.
   - Use `general software engineer` only when no narrower expertise is material.
   - Work in significance order. At 45 seconds, stop expanding the review and move to finalization even when a cluster is incomplete.

5. Check the whole-PR story.
   - Confirm that the clusters collectively implement the stated intent without contradictory assumptions or uncovered transitions between them.
   - Check that tests exercise the significant behavior rather than only the mechanical ripple.
   - Note missing context or unavailable validation as residual risk; do not invent conclusions.
   - Overwrite the initial report at the same path no later than 60 seconds. Use `Complete at deadline` and identify all skipped scope when coverage is incomplete.

## HTML Delivery

Write a fresh standalone HTML5 report using [HTML-REPORT.md](HTML-REPORT.md). It must have inline CSS and no CDN, remote asset, package, runtime, server, or repository dependency.

- Resolve the temp directory from `${TMPDIR:-/tmp}` on Unix-like systems or `%TEMP%` on Windows.
- Sanitize owner, repository, and PR filename components to letters, digits, `.`, `_`, and `-`; replace the owner/repository separator with `-`.
- Create `${TMPDIR:-/tmp}/semantic-pr-review-<owner>-<repo>-pr-<number>-<timestamp>.html`. Never reuse a report from another invocation.
- Write both states atomically through a sibling temporary file. Open the initial report using `$BROWSER` when set, then `xdg-open` on Linux, `open` on macOS, or `start` on Windows. Opening failure must not delay analysis.
- Overwrite that exact path for the final report so the user has one stable artifact.
- Always tell the user the absolute report path and its final status.

Lead with actionable findings in decreasing severity and significance. For each finding include:

- Severity and concise title
- File and line reference
- The affected change cluster
- Why it is a defect or material risk
- Evidence, clearly separated from inference and confidence
- A concrete remediation or question that would resolve it
- The specialist review focus

When there are no final findings, show a prominent statement: `No semantic defects were found.` Do not imply exhaustive coverage beyond the coverage section.

For every significant causal change cluster include:

- **Change:** A concise name
- **Defining change:** The contract, behavior, or responsibility that changed
- **Ripple grouped here:** The consequent callers, implementations, tests, fixtures, documentation, or configuration edits
- **Explanation:** What changed semantically and why it matters
- **Review needed:** The reviewer expertise required and the reason for it
- **Review focus:** The invariants, edge cases, compatibility concerns, or evidence that reviewer should verify

List rule-following concerns separately from semantic review. For each include:

- The files or class of changes covered
- The concern being delegated
- The recommended tool or check
- Whether available PR checks already cover it, when known

Do not include ignored whitespace, formatting, or import-only churn unless a relevant automated check is missing or failing.

End with coverage and residual risk, including:

- Scope reviewed and anything excluded
- Relevant validation or status checks observed
- Missing tests, unavailable context, unresolved uncertainty, or specialist review still required
- Every skipped or unreviewed cluster when the deadline expires

Keep the report organized by causal change, not by file order. Prefer a small number of well-supported clusters over a hunk-by-hunk narration. Rank every section with the same significance model.