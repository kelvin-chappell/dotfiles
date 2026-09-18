---
name: global-pre-commit-review
description: 'Review changes before a Git commit in any repository. Use when asked for a pre-commit review, commit readiness check, staged diff review, secret scan, accidental-file check, or validation before committing.'
argument-hint: 'Describe the changes or paths to review before committing'
---

# Global Pre-Commit Review

Review intended changes for correctness, safety, and commit readiness without modifying the working tree or index.

## Preconditions

- Treat the repository as shared and potentially dirty.
- Review only by default. Do not edit files, stage changes, create commits, amend commits, or push unless the user separately requests that action.
- Preserve unrelated staged and unstaged work.
- Follow repository-specific contributor and agent instructions relevant to the changed files.

## Procedure

1. Inspect repository state with `git status --short --branch`.
2. Determine the intended review set.
   - Use paths or scope supplied by the user.
   - Otherwise review staged changes when the index is non-empty.
   - If nothing is staged, review tracked working-tree changes and clearly state that scope.
   - Ask before including ambiguous untracked files or unrelated changes.
3. Inspect the exact patch and file summary.
   - For staged changes, use `git diff --cached --stat`, `git diff --cached --check`, and `git diff --cached`.
   - For unstaged changes, use `git diff --stat`, `git diff --check`, and `git diff`.
   - Inspect relevant untracked files explicitly without blanket staging.
4. Check for accidental or unsafe content.
   - Secrets, credentials, private keys, tokens, connection strings, or personal data.
   - Environment files, local configuration, editor state, logs, caches, temporary files, large binaries, test artifacts, and build output.
   - Generated files or dependency lockfiles whose changes are unexplained by the intended work.
   - Debugging statements, disabled checks, focused tests, conflict markers, and commented-out code.
5. Review behavioral quality.
   - Look for defects, regressions, insecure behavior, incomplete error handling, compatibility risks, and mismatches between implementation, tests, and documentation.
   - Prioritize concrete findings over stylistic preferences.
   - Verify that each changed file belongs to one coherent commit.
6. Run the narrowest relevant validation available.
   - Prefer focused tests, linting, type checking, compilation, or repository-provided checks.
   - Do not fix unrelated failures.
7. Assess the proposed commit message when one is supplied.
   - Require Conventional Commits: `<type>(<optional-scope>): <description>`.
   - Confirm the type, scope, and description match the reviewed patch.
   - Ensure breaking changes use `!` and a `BREAKING CHANGE:` footer.
8. Report findings first, ordered by severity and grounded in file paths and line numbers.
9. Give a final readiness verdict: `ready`, `ready with noted risks`, or `not ready`.

## Decision Points

- **No changes found:** Report that there is nothing to review.
- **Mixed staged and unstaged changes:** Review the requested set only and explain what was excluded.
- **Likely secret or credential:** Mark the review `not ready`, avoid reproducing the secret value, and recommend revocation if exposure may already have occurred.
- **Generated or large file:** Confirm that it is expected and reproducible before marking the commit ready.
- **Validation unavailable:** Perform static review, state what could not be run, and include the resulting residual risk.
- **Validation failure:** Distinguish failures caused by the intended patch from unrelated baseline failures; mark readiness accordingly.
- **No findings:** Say so explicitly, then note any remaining test gaps or residual risk.

## Completion Checks

A pre-commit review is complete only when:

- The reviewed scope and any excluded changes are explicit.
- The exact staged or unstaged patch has been inspected.
- Accidental files and sensitive content have been checked.
- Relevant focused validation has run when available.
- Findings are ordered by severity with actionable locations.
- A clear readiness verdict and remaining risks are reported.
