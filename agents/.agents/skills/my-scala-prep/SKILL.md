---
name: my-scala-prep
description: 'Prepare a Scala repository for new work from a clean surface. Use when asked for Scala codebase preparation or dependency hygiene: upgrade outdated dependencies, flag dependencies with no releases for over a year, resolve high or critical runtime vulnerabilities reported by GitHub, identify unused declared dependencies, and eliminate errors, warnings and deprecations. Verify the full supported build matrix and ask for a decision on unresolvable diagnostics.'
argument-hint: 'Prepare this Scala repository for new work'
---

# Scala preparation

Produce a verified clean starting point for new work, preserving application behaviour, public APIs and supported consumers. Execute the audit and fixes, not just recommendations. Work in small, independently validated batches.

## Contract

- **Ecosystem scope:** change only Scala code, build configuration, resources and files belonging to the Scala/Java/Maven ecosystem (sbt, Maven coordinates, JVM tooling and their CI/tool-version declarations). Never inspect for upgrade, edit or regenerate dependencies in other ecosystems, such as `package.json`, npm/yarn/pnpm lockfiles, pip, Go modules or GitHub Actions versions. Leave those files untouched even when they contribute to the build, and report them as out of scope if relevant.
- Interpret **latest** as the newest stable, non-prerelease release verified from authoritative sources at execution time. A major release is eligible; migrate affected usage when compatibility can be preserved. Record both latest available and latest compatible versions when they differ, and explain every retained older version.
- Inspect every module and dependency scope: production, test, provided, optional, integration, compiler plugins, build plugins, and build tooling. Audit resolved transitive dependencies as well as declarations. Treat tooling and test vulnerabilities separately from deployed runtime vulnerabilities.
- Preserve the existing Scala binary lines, cross-publishing matrix, minimum JVM and platforms unless the user explicitly approves changing them. Update patch releases within supported lines where compatible. A newer dependency requiring a compiler-line migration is a reported compatibility blocker, not permission to change language support. Use `my-scala-lts-upgrade` for an explicitly approved Scala migration if available, respecting its checkpoints.
- Use mise for tool versions and `.tool-versions` as their source of truth; keep existing CI and launcher declarations consistent. Preserve the build system and established checks. Install audit tooling only when necessary, version it, and prefer temporary session-local integration over permanent build changes.
- Keep edits focused on preparation, including pre-existing diagnostics within this scope. Preserve unrelated dirty worktree changes. Leave commits, pushes, remote publication and advisory dismissal to an explicit user request.
- A successful exit code alone is insufficient. A **clean surface** requires all required checks to run with zero errors, warnings and deprecations; no unresolved high or critical runtime advisory; and every dependency accounted for. An exception, skipped check, unknown audit result or inaccessible source leaves the outcome incomplete.

## 1. Establish scope and baseline

Read repository instructions, worktree status, build definitions, version catalogues, lockfiles, CI and release configuration. Identify the GitHub repository from its configured remote rather than assuming the current directory name.

For the runtime vulnerability review, invoke the `security-review` agent first, if available, before conducting your own security review. Bound its task to GitHub high/critical dependency advisories and the resolved production graph; request advisory identifiers, affected versions, runtime paths, fixes and source evidence. Await and incorporate its result, follow the environment's security-report requirements, and perform the remaining preparation yourself. If unavailable, use the GitHub advisory procedure in step 3 and state the limitation.

Record modules, supported Scala/JVM/platform combinations, packaged runtime classpaths and commands for compilation, unit/integration tests, documentation, lint, formatting, binary compatibility and packaging. Include maintained examples and generated-source tasks.

Before editing, run the existing compile and relevant test baseline. Capture complete output, tool versions, command exit codes and pre-existing diagnostics in session artefacts, not repository planning files. Resolve missing tools or credentials where authorised; record inaccessible services explicitly. Static inspection is not a passing baseline.

**Gate:** all modules and validation targets are enumerated, and baseline outcomes or concrete blockers are recorded.

## 2. Inventory versions, release age and usage

Use the [sbt-updates](https://github.com/rtimush/sbt-updates) sbt plugin to find the latest versions of dependencies and build plugins. If it is not already installed, add it temporarily through a session-local global plugin (for example `~/.sbt/1.0/plugins/plugins.sbt`, using the latest version from the plugin's README) rather than committing it, and remove it afterwards unless the repository already uses it. Run `sbt dependencyUpdates` (all modules, including the aggregate `;reload plugins; dependencyUpdates` pass for build plugins) and record the output in session artefacts. Treat its results as the primary source for upgrade candidates, still verifying stability and cross-built artifact availability as below. Use sbt's `dependencyTree`/`update` reports for resolution detail. Fall back to Maven's `versions:display-dependency-updates` only for Maven-built modules.

Build a ledger with:

| Field | Evidence required |
|---|---|
| Identity | Group, artifact, resolved version, declaration file and line, module, scope, Scala/platform suffix |
| Resolution | Direct or transitive; introducing dependency paths; evictions, overrides and exclusions |
| Upgrade | Latest stable version, compatible target, source URL and verification time |
| Maintenance | Newest stable upstream release date, evidence URL, age and status |
| Usage | Used, confirmed unused, candidate unused or unknown, with evidence |
| Outcome | Updated, removed, already current or blocked, with reason and validation |

Include version aliases, dependency-management entries, platform/BOM constraints, bundled libraries and inherited dependencies. Do not inventory or update non-JVM manifests (for example node); note them as out of scope. Explicitly mark any unresolved or inaccessible portion instead of claiming complete coverage.

### Latest and maintenance evidence

Query the actual publisher's repository metadata, release notes or official release API. For Maven artifacts, use the configured authoritative Maven repository, accounting for mirrors and private registries. Verify release stability rather than trusting `<latest>` or `<release>`; exclude snapshots, milestones, release candidates, previews, nightly builds, alpha and beta releases. Confirm cross-built artifacts actually exist for every supported Scala/platform combination.

Measure inactivity from the **newest stable upstream release**, not the pinned version, last commit or cached metadata date. Resolve cross-built artifacts to their upstream project and inspect releases across its actively published variants; report the specific artifact as discontinued when the project remains active but that variant has stopped.

Flag a dependency when its newest stable release is **strictly older than one calendar year before the audit date**, using UTC and calendar arithmetic, with 29 February clamped to 28 February where necessary. Report the exact release date and age. An archived upstream project merits a separate flag. Missing dates produce **unknown maintenance status**, not an inactivity claim. Inactivity alone is not proof of insecurity or justification for an automatic replacement.

### Unused declarations

Inspect source imports and fully qualified usages, generated code, resources, configuration and resolved classpaths. Use an existing unused-dependency analysis tool when available, treating its results as leads rather than proof.

Account for reflection, `ServiceLoader`, framework discovery, macros, annotation processing, compiler/build plugins, JDBC/logging providers, test discovery, native libraries, assembly rules and intentionally exported dependencies of published libraries. Absence of imports does not establish non-use.

Remove a declaration only with concrete evidence and an isolated removal check covering compilation, tests, packaging and relevant startup/runtime paths across affected configurations. Check whether the artifact still arrives transitively; a passing build in that case does not prove the direct declaration is unnecessary if code relies on it. Keep uncertain cases and explain the missing evidence. Remove redundant version aliases only when no references remain.

**Gate:** every declaration and resolved dependency has a ledger entry, including explicit unknowns; each outdated, inactive or potentially unused item has evidence.

## 3. Resolve GitHub high/critical runtime advisories

Use `gh` to read all pages of open Dependabot alerts for the identified repository, for example:

```sh
gh api --paginate "repos/OWNER/REPO/dependabot/alerts?state=open&per_page=100"
```

Inspect severity, advisory/CVE identifiers, manifest, package, affected range and first patched version. Also paginate alerts with `state=dismissed` and reassess high/critical risk exceptions against the current runtime graph; a dismissal does not establish that the vulnerable package is absent or fixed. Preserve the recorded rationale for genuine false positives. Read relevant code-scanning alerts if GitHub also reports high/critical runtime code vulnerabilities; do not conflate their findings with dependency advisories.

Match alerts against **resolved and packaged** runtime dependencies in every deployed module. Ignore alerts for other ecosystems (for example npm); list them as out of scope without changing them. Treat GitHub scope labels as evidence, not definitive classpath classification. Include provided libraries supplied by the deployment environment. An uncertain runtime classification remains potentially affected until resolved.

A 403/404, disabled alert access, missing permission or unavailable dependency graph means the GitHub audit is **unverified**, not that there are no vulnerabilities. Explain the missing access or feature. Where supported, use an existing local advisory scanner for additional evidence without sending private source or dependency inventories to an unauthorised service; it does not substitute for unavailable GitHub results.

Prioritise high/critical runtime fixes. Prefer upgrading the direct dependency that introduces the vulnerable version. Use an override only when no suitable upstream update exists and compatibility is demonstrated; inspect evictions, binary compatibility and packaged artifacts. A patched version is the minimum safe version, not automatically the latest target. If no fix exists, investigate a behaviour-preserving removal, replacement or documented mitigation; present unresolved risk for a decision instead of asserting it is fixed.

Verify each remedy against the newly resolved and packaged graph, advisory ranges, regression tests and relevant runtime checks. Recheck the GitHub alert state when available, but distinguish **fixed locally** from **closed on GitHub**: an unpushed local change cannot update the default-branch alert. Never dismiss an alert to make the audit look clean.

**Gate:** every high/critical runtime finding has a verified local remedy or an explicit unresolved blocker with affected paths and evidence.

## 4. Upgrade and clean in small batches

Apply compatible dependency upgrades, including required API migrations, in cohesive batches. Validate the narrowest affected compile/test target after each batch; repair regressions before proceeding. Update central declarations, lockfiles, tool versions, CI, generated build inputs and directly related documentation consistently. Regenerate derived files with repository tooling.

Prefer upstream transitive upgrades through their owning direct dependencies. Record transitive versions constrained by the upstream graph rather than forcing every leaf to its independent latest release. Confirm that obsolete overrides and exclusions can be removed safely.

Enable version-appropriate deprecation, feature, unchecked and unused diagnostics for all maintained compilation scopes. Enable warnings-as-errors using the compiler/build equivalent, preserving existing stronger checks and compatibility across the matrix. Discover supported compiler flags; ignored options themselves fail the clean-surface gate. Review diagnostic filters and ensure they are not concealing issues relevant to this audit.

Fix causes: deprecated APIs, unused imports/code, unsafe patterns, discarded effects, build-plugin diagnostics and documentation/lint failures. Preserve effect sequencing, completion and failure propagation. Consume or sequence non-`Unit` effects rather than discarding them to silence warnings. Update generators or responsible upstream dependencies for generated-source warnings where feasible.

Do not relax diagnostics, add suppressions, exclude maintained sources, disable checks or delete tests to pass. An unfixable third-party/generated warning is a blocker even if a narrow suppression could hide it.

### Unresolvable diagnostics and decisions

For each warning, error or deprecation that cannot be resolved safely, record the exact message, location, reproducing command, root cause, attempted fixes, upstream issue/release evidence and compatibility impact.

Use `ask_user` to explain why it remains and ask what to do. Offer concrete choices appropriate to the case: approve a compatibility-changing migration or replacement, approve a narrowly scoped documented exception, defer the affected change, or stop. Explain the consequences before editing. Apply only the selected action.

If interaction is unavailable, continue independent safe work, then finish with **blocked, awaiting a decision** and the exact choices. Never silently choose an exception. An approved exception remains a reported exception to the strict clean-surface goal, not a zero-warning success.

**Gate:** each upgrade/removal is validated; every remaining diagnostic has either a safe remedy or a pending/recorded user decision.

## 5. Verify the clean surface and report

Run formatting checks, a clean rebuild of all maintained compilation scopes, unit and integration tests, documentation compilation, lint, binary compatibility, packaging and CI-equivalent checks. Cover every supported Scala/JVM/platform combination, starting with the lowest supported versions. Perform relevant startup or packaged consumer smoke tests, especially after changes affecting reflection, providers, frameworks or runtime dependencies. Use local packaging, not remote publication.

Inspect complete logs, including build-tool startup, dependency resolution, generated sources, tests and documentation, for errors, warnings and deprecations even when exit codes are zero. A cached incremental build, disabled warning output or skipped suite cannot establish a clean result.

Refresh the final dependency graph and ledger. Confirm that targets are installed, removals are reflected in declarations and packaged artifacts, and high/critical runtime advisory ranges no longer match. Distinguish deliberate compatible constraints from failed updates.

Report concisely:

- **Status:** clean, clean with explicitly approved exceptions, or blocked/incomplete. Claim the strict clean surface only when the contract is met.
- **Upgrades:** previous, current and latest stable versions; changed files; reasons for every retained outdated dependency.
- **Maintenance:** dependencies inactive for over one year, release dates, evidence URLs, archived/discontinued variants and unknowns.
- **Usage:** removed declarations, confirmed-used exceptions, and candidates retained with evidence gaps.
- **Security:** high/critical runtime findings and local fixes, unresolved risks, GitHub audit coverage and remote alert status; keep lower-severity and non-runtime findings separate.
- **Validation:** exact commands and outcomes by supported target, baseline failures versus regressions, and whether there are zero errors, warnings and deprecations.
- **Decisions:** unresolved diagnostics, reasons, approved exceptions and any required next action.

Leave the verified changes in the worktree for review. If anything is blocked or unverified, identify precisely what prevents a clean starting point.
