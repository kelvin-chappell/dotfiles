---
name: semantic-pr-review
description: 'Review a pull request given a required PR number and an optional owner/repository, defaulting to the current Git repository. Separates automatable checks from semantic review, groups ripple effects under causal changes, ignores formatting and import churn, explains significant changes, and recommends reviewer expertise. Use for PR review, change-risk assessment, or reviewer selection.'
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
- Follow repository-specific instructions relevant to the changed files.
- Treat generated output, whitespace-only edits, formatting-only edits, and import-only refactors as review noise unless they alter behavior or reveal an integration problem.
- Do not report style or simple rule violations as semantic findings when a deterministic tool can check them.
- Trace a change through definitions, callers, implementations, tests, configuration, documentation, and external contracts before deciding that edits are independent.
- Distinguish evidence from inference. State uncertainty when the diff or repository context cannot establish behavior.

## Procedure

1. Establish the review scope.
   - Resolve the target from the required PR number and the supplied or current repository.
   - Inspect the pull request description, commits, changed files, review context, and status checks when available.
   - Inspect the exact pull request diff and relevant repository context.
   - Read the PR description and linked issue for intended behavior, but verify claims against the code.

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

5. Check the whole-PR story.
   - Confirm that the clusters collectively implement the stated intent without contradictory assumptions or uncovered transitions between them.
   - Check that tests exercise the significant behavior rather than only the mechanical ripple.
   - Note missing context or unavailable validation as residual risk; do not invent conclusions.

## Output Format

Lead with actionable findings, ordered by severity. Omit the section when there are no findings, and state explicitly that no semantic defects were found.

### Findings

For each finding include:

- Severity and concise title
- File and line reference
- The affected change cluster
- Why it is a defect or material risk
- A concrete remediation or question that would resolve it

### Significant Changes

For every causal change cluster include:

- **Change:** A concise name
- **Defining change:** The contract, behavior, or responsibility that changed
- **Ripple grouped here:** The consequent callers, implementations, tests, fixtures, documentation, or configuration edits
- **Explanation:** What changed semantically and why it matters
- **Review needed:** The reviewer expertise required and the reason for it
- **Review focus:** The invariants, edge cases, compatibility concerns, or evidence that reviewer should verify

### Automation Candidates

List rule-following concerns separately from semantic review. For each include:

- The files or class of changes covered
- The concern being delegated
- The recommended tool or check
- Whether available PR checks already cover it, when known

Do not include ignored whitespace, formatting, or import-only churn unless a relevant automated check is missing or failing.

### Coverage And Residual Risk

Summarize:

- Scope reviewed and anything excluded
- Relevant validation or status checks observed
- Missing tests, unavailable context, unresolved uncertainty, or specialist review still required

Keep the report organized by causal change, not by file order. Prefer a small number of well-supported clusters over a hunk-by-hunk narration.