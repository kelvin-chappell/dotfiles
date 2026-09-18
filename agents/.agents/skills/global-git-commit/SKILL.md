---
name: global-git-commit
description: 'Create careful Git commits in any repository. Use when asked to commit changes, prepare a commit, write a commit message, stage files for a commit, amend a commit, or verify a commit before creation.'
argument-hint: 'Describe the changes to commit and any message or scope requirements'
---

# Global Git Commit

Create a focused, reviewable Git commit while preserving unrelated work.

## Preconditions

- Create a commit only when the user explicitly asks for one.
- Treat the working tree as shared and potentially dirty.
- Never discard, overwrite, or revert changes that are outside the requested commit.
- Never amend, force-push, or bypass hooks unless the user explicitly requests that action.

## Procedure

1. Inspect the repository state with `git status --short --branch`.
2. Review repository instructions and commit conventions when available:
   - Read nearby contributor or agent instruction files relevant to the changed files.
   - Inspect a small sample of recent subjects with `git log -n 10 --format=%s` for useful scope and wording patterns.
3. Identify the exact files and hunks belonging to the requested change.
   - Review unstaged changes with `git diff -- <paths>`.
   - Review staged changes with `git diff --cached -- <paths>`.
   - If ownership of a change is ambiguous, ask before staging it.
4. Run the narrowest relevant validation available for the intended changes.
   - Prefer focused tests, linting, type checking, or compilation.
   - Do not fix unrelated failures as part of the commit.
5. Stage only the intended files or hunks.
   - Prefer explicit paths: `git add -- <paths>`.
   - Use patch staging when a file contains unrelated changes.
   - Do not use blanket staging such as `git add .` or `git add -A` unless the user explicitly confirms that every current change belongs in the commit.
6. Review the exact staged patch with `git diff --cached --check` and `git diff --cached`.
7. Write a concise commit message:
   - Follow explicit user requirements first.
   - Otherwise use Conventional Commits: `<type>(<optional-scope>): <description>`.
   - Choose the narrowest accurate type, typically `feat`, `fix`, `docs`, `test`, `refactor`, `build`, `ci`, `perf`, `style`, `revert`, or `chore`.
   - Use an optional scope only when it adds meaningful context; prefer established repository scopes when available.
   - Write the description in imperative, lower-case wording without a trailing period.
   - Mark breaking changes with `!` before the colon and explain them in a `BREAKING CHANGE:` footer.
   - Keep the subject focused and omit a body unless it adds useful rationale or context.
8. Create the commit normally so configured hooks run: `git commit -m '<subject>'`.
   - Use additional `-m` arguments for body paragraphs when needed.
   - Never use `--no-verify` unless explicitly requested after explaining the risk.
9. Verify the result with `git status --short --branch` and `git show --stat --oneline --decorate HEAD`.
10. Report the commit hash and subject, validation performed, committed files, and any remaining uncommitted changes.

## Decision Points

- **Nothing to commit:** Report that no commit was created; do not create an empty commit unless explicitly requested.
- **Mixed changes in one file:** Use patch staging if practical. If reliable separation is not possible, ask the user how to divide the work.
- **Existing staged changes:** Treat them as intentional user work. Confirm they belong in the requested commit before changing the index or committing.
- **Validation failure:** Do not commit by default. Report the relevant failure and either fix the requested change or ask whether the user wants to proceed despite it.
- **Hook failure:** Keep the failed commit uncreated, inspect the hook output, and fix only issues caused by the intended changes.
- **Sensitive or generated files:** Stop and ask before committing likely secrets, credentials, large binaries, build output, or dependency artifacts that appear accidental.
- **Amend request:** Confirm the current `HEAD` is the intended commit and that rewriting it is acceptable before using `git commit --amend`.
- **Push request:** Treat pushing as a separate operation. Confirm the branch and remote; never force-push unless explicitly requested.

## Completion Checks

A commit is complete only when:

- The staged patch contained only the requested change.
- Relevant validation passed, or the user explicitly accepted a clearly reported failure.
- Commit hooks completed successfully unless the user explicitly authorized bypassing them.
- The new commit hash and subject were verified.
- Remaining working-tree changes were preserved and reported.
