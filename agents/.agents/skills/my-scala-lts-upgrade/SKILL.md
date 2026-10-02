---
name: my-scala-lts-upgrade
description: 'Upgrade a Scala repository incrementally to the latest Scala LTS with minimal changes. Use when asked to upgrade, migrate, modernise, or bump Scala, including Scala 2.12 and Scala 2.13 to Scala 3 migrations. Requires reviewing Guardian Scala upgrade issue #16 and its links only when starting from Scala 2.13. Advances one LTS-line checkpoint per invocation, ignores Scala Next lines as upgrade targets, follows the official Scala 3.9 upgrade order and compiler rewrites, requires zero errors, warnings, and deprecated usages, and enforces brace syntax with -no-indent on Scala 3.'
argument-hint: 'Upgrade this repository by one checkpoint towards the latest Scala LTS'
---

# Scala LTS Upgrade

Upgrade Scala conservatively, one verified LTS-line checkpoint at a time. Preserve behaviour and public APIs unless compatibility requires a change.

Authoritative migration guidance: <https://scala-lang.org/news/3.9/#recommended-upgrade-order>

## Non-negotiable rules

- Perform exactly one Scala version checkpoint per invocation for the upgrade target, preserving any user-approved cross-publishing versions. After that checkpoint passes, report the next target and stop. Never begin it in the same invocation.
- Do not commit unless the user explicitly asks. Recommend a commit at each completed checkpoint because the official guidance requires independently reviewable steps.
- Make the smallest changes needed for the current checkpoint. Do not combine dependency modernisation, formatting churn, refactoring, or adoption of new language features with the compiler upgrade.
- The checkpoint is incomplete until all compile, test, documentation, and enabled lint tasks finish with zero errors and zero warnings, including deprecation warnings.
- Never silence a diagnostic merely to pass. Remove deprecated usage and fix causes. Use a narrowly scoped suppression only for generated source or an unfixable third-party diagnostic, explain it in code, and report it as a blocker to the strict zero-warning requirement.
- From the first Scala 3 checkpoint onward, source must use braces rather than significant indentation. Permanently add `-no-indent` to every Scala 3 compilation scope and convert existing indentation syntax with the compiler before hand-editing.
- For Scala upgrade tasks, this brace requirement overrides general Scala style guidance that prefers braceless or significant-indentation syntax.
- Preserve the repository's build tool, formatter, test framework, dependency-update mechanism, and local conventions.
- Respect dirty worktrees. Never discard unrelated user changes.

## Terminology and route

An LTS line is a `major.minor` line officially designated as Long Term Support, such as Scala 3.3 or 3.9. Scala Next lines between LTS lines are migration source levels, not upgrade targets. For the Scala 2 to Scala 3 bridge, the latest supported patch of the current Scala 2 line and Scala 2.13 are also permitted checkpoints. A checkpoint target is the latest stable, non-prerelease patch in one of these selected lines.

Build the complete route before editing:

1. If currently on Scala 2, end the current Scala 2 line at its latest stable patch and pass through the latest Scala 2.13 patch.
2. Advance through each officially designated Scala 3 LTS line after the current version.
3. End at the latest stable patch of the current Scala LTS line, not merely its `.0` release.

Do not add Scala Next lines such as 3.4, 3.5, 3.6, 3.7, or 3.8 to the durable route. Migration flags for crossed source levels still run in order. As of Scala 3.9, `3.7.4` may be used temporarily before the 3.8 standard-library boundary and `3.9.0` may be used for the improved `with`-type rewrite, but a temporary rewrite compiler is not a checkpoint and must not remain as the repository's selected Scala version.

If the current version is a Scala Next line, target the next later LTS directly while applying every crossed migration mode; do not first move to the latest patch of that Scala Next line. If the current version already equals a route target, omit that no-op target. If the repository is newer than the latest LTS, do not downgrade automatically; explain the situation and stop.

## Phase 0: Identify the starting version and select guidance

On every invocation, first inspect the build's Scala version declarations to identify the current version of the modules being upgraded.

When starting from Scala 2.12, proceed directly to Phase 1 using the normal checkpoint route through Scala 2.13. Skip the Guardian issue and its links for this invocation; their availability does not block Scala 2.12 work. Apply the review on a later invocation that starts from Scala 2.13. For other starting versions, also proceed directly to Phase 1.

Only when starting from Scala 2.13, complete this prerequisite before further repository inspection, upgrade advice, planning, prerequisite changes, or implementation:

1. Read the current body and comments of [guardian/maintaining-scala-projects#16](https://github.com/guardian/maintaining-scala-projects/issues/16), whose starting assumption is Scala 2.13.
2. Open every link in the issue body and comments. The current starting references are [guardian/pan-domain-authentication#165](https://github.com/guardian/pan-domain-authentication/pull/165), [guardian/permissions#433](https://github.com/guardian/permissions/pull/433), and the [Scala 3 upgrade document](https://docs.google.com/document/d/17wOlbVzYJF01yjZpRzgNifb--SFDDjPpanffv0eaGRg/edit?usp=sharing). Discover additions from the live issue rather than treating this list as exhaustive.
3. For linked migration PRs, inspect their descriptions, relevant diffs, comments, and inline review discussions, including later corrections. Follow further links that explain migration decisions or compatibility constraints; unrelated deployment links do not require investigation.
4. Record the applicable lessons and their source URLs before proceeding. In particular, assess downstream JVM and bytecode baselines, published-library cross-builds, Play overload return types and implicit imports, case-class `unapply` changes, and version-independent assembly paths. Treat examples as evidence, not instructions to copy their historical Scala versions or drop supported consumers. Reconcile them with current official guidance and the repository's compatibility requirements in Phase 1.

If the linked Google Doc is inaccessible, skip it and continue using the accessible sources. Exclude it from citations and recommendations; do not infer its contents or request access.

For a Scala 2.13 starting version, this prerequisite is complete only when the issue and required linked guidance have been reviewed and their implications recorded, with inaccessible Google Docs excluded. If any other required source is inaccessible, report its URL and access failure, request access or user-provided contents, and stop before upgrade work. A cached summary or an unread required link does not satisfy the review.

## Phase 1: Inspect and plan

Before editing, determine:

- every place defining Scala, JDK, sbt/Mill/Scala CLI, Scala.js, compiler plugin, and formatter versions
- modules, cross-build matrices, and cross-publishing configuration, including `crossScalaVersions`, build matrices, and release workflows
- compile, test, integration-test, Scaladoc, formatting, lint, MiMa, and packaging commands used by CI
- current compiler options and warning policy in every configuration
- Scala.js usage, Scala 2.13 TASTy-reader consumers, macros, compiler plugins, and runtime `scala-reflect` use
- dirty files that must be preserved

### Cross-publishing decision

If the repository has cross-publishing configuration, obtain an explicit user decision before any upgrade or prerequisite edits. Present the current published modules and exact Scala version matrix, identify the lowest supported version per module, and prompt with these options using `ask_user` when available:

1. **Keep cross-publishing as is:** retain the existing published Scala versions unchanged.
2. **Change the versions:** ask for the exact versions to retain, add, or replace, and confirm the resulting matrix.
3. **Remove cross-publishing:** ask which single Scala version to support and confirm the affected published modules.

Explain downstream compatibility consequences before confirming the choice. If a retained publishing version prevents the proposed upgrade, report the conflict and ask for a revised decision rather than silently changing the matrix. If the user is unavailable, pause before editing; an automatic default does not satisfy this decision gate. A previously explicit decision may be reused if its module scope and version matrix still apply.

Record the approved matrix and lowest supported version for each published module. Honour this decision throughout the route, build settings, dependencies, source migrations, CI, release workflows, and documentation. The checkpoint route advances only the selected upgrade target; retained publishing versions are compatibility targets, not extra checkpoints to upgrade automatically. If keeping publishing unchanged leaves no published version to upgrade, clarify whether the upgrade applies to non-published modules or requires a revised publishing decision.

Keep shared sources, public APIs, dependencies, compiler options, and generated code compatible with every approved version, especially the lowest. Use existing version-specific source directories and conditional build settings when necessary, and restrict compiler rewrites to compatible source scopes. Newer-language syntax and APIs belong only in source sets that exclude older supported versions.

Resolve versions from primary sources at execution time:

- stable Scala 2 versions: Maven metadata for `org.scala-lang:scala-compiler`
- stable Scala 3 versions: Maven metadata for `org.scala-lang:scala3-compiler_3`
- LTS identity: the current official Scala LTS announcement or support page

Ignore versions containing `RC`, `M`, `SNAPSHOT`, `NIGHTLY`, `alpha`, or `beta`. Do not assume Maven's `<release>` is stable. Record the full route, identify only the next checkpoint, and state the cheapest command that can falsify the proposed change.

### Pre-edit validation baseline

Before any source, version, prerequisite, or compiler-option edits, run the narrowest existing compile and relevant test commands for the affected modules under their current Scala versions. For cross-published modules, include the existing supported matrix, starting with its lowest version. Record the exact commands, toolchain versions, outcomes, and existing warnings or failures so later diagnostics can be compared with the baseline.

Report pre-existing failures separately from upgrade regressions, without fixing unrelated issues or relaxing the final zero-warning gate. If baseline execution is blocked, report the command and cause and resolve the blocker before editing; static inspection alone does not establish a passing baseline.

## Phase 2: Prepare prerequisites in official order

Apply this order without changing Scala prematurely:

1. Upgrade the build tool only if the next Scala target requires it. Validate and stop if this itself is a substantial migration; resume the Scala checkpoint on the next invocation.
2. Move to the target's minimum supported JDK while retaining the current Scala version where possible. Scala 3.8 and later require JDK 17 or newer. Distinguish the build JDK from published bytecode and downstream runtime baselines; preserve the approved matrix's compatibility requirements and use version-specific release targets where necessary. Update all version declarations consistently, including `.tool-versions` when the repository uses mise.
3. Upgrade Scala.js before Scala if required. Account for downstream baseline changes; Scala 3.9 fixes Scala.js 1.22 for that LTS line.
4. Upgrade the Scala compiler for the current checkpoint and apply only the required source migrations.
5. Upgrade libraries only after the Scala compiler checkpoint needs them. Change only incompatible dependencies and compiler plugins; defer unrelated updates.

Validate after each prerequisite edit before continuing. A prerequisite-only invocation still stops at its own clean checkpoint rather than claiming the Scala version checkpoint is complete.

## Phase 3: Apply migrations

### Scala 2 to Scala 3

- Reach the latest Scala 2.13 patch first and make it clean.
- Use the repository's established migration tooling where present. Otherwise use Scala 2.13 `-Xsource:3` and relevant linting to expose incompatibilities before changing the compiler.
- Adapt obsolete Scala 2 compiler options rather than carrying ignored options into Scala 3. An ignored compiler option is a warning and therefore fails the gate.
- At the first Scala 3 checkpoint, run `-rewrite -no-indent` over Scala 3 sources, review the generated diff, then retain `-no-indent` without `-rewrite` in normal compiler options.
- Configure Scalafmt for a Scala 3-compatible dialect while retaining braces. Do not configure or run a rewrite that removes optional braces.

### Crossing Scala Next source levels through 3.9

When crossing these source levels, run every applicable migration mode in ascending order; later modes do not replay earlier rewrites:

1. `-source:3.4-migration -rewrite`
2. `-source:3.5-migration -rewrite`
3. `-source:3.6-migration -rewrite`
4. `-source:3.7-migration -rewrite`
5. `-source:3.8-migration -rewrite`
6. `-source:3.9-migration -rewrite`

Apply only modes above the repository's starting source level and at or below the target being crossed. Run one mode at a time, inspect its diff, compile, and fix non-rewritable changes before proceeding. Remove temporary `-source:*-migration` and `-rewrite` options after each rewrite. Never leave migration mode as the final source policy.

Choose a temporary rewrite compiler as recommended by Scala 3.9 without making it a durable upgrade target:

- use `3.7.4` when explicit arguments to standard-library context parameters need `using` inserted before crossing into 3.8
- use `3.9.0` when many `with` types need rewriting to `&`, because its rewrite is more reliable

Before crossing 3.8, explicitly check:

- JDK 17 or newer
- Scala 2.13 consumers using `-Ytasty-reader`, which cannot consume Scala 3.8+ artifacts
- dependencies that initialise `scala.reflect.runtime.universe`, which can fail with the Scala 3-compiled standard library
- embedded REPL users, which now need the separate `scala3-repl` artifact

Treat an older `-source:3.x` setting as a temporary, subproject-local escape hatch only when migration is otherwise blocked. Report it as unfinished migration and do not declare the final LTS checkpoint complete while it remains.

## Phase 4: Enforce clean compilation

Ensure the project's equivalent of these diagnostics is enabled for all maintained source sets, using version-appropriate spellings:

- deprecations: `-deprecation`
- feature and unchecked warnings: `-feature`, `-unchecked`
- unused code/imports: `-Wunused:all` where supported, otherwise the closest complete equivalent
- discarded values and non-Unit statements where supported: `-Wvalue-discard`, `-Wnonunit-statement`
- warnings as errors: `-Werror` or the repository's equivalent
- Scala 3 brace syntax: `-no-indent`

Do not blindly add duplicate or unsupported flags. Ask the selected compiler for its supported options and adapt conditional build settings for cross-built modules.

### Value discards and effect sequencing

Keep new `for` comprehensions and statement blocks free of redundant discard bindings. Introduce `val _ = expression` or `_ = expression` only when an observed diagnostic requires an explicit, intentional discard of a non-`Unit` value and the expression's completion and failure are already handled. Leave `Unit`-returning statements unwrapped when the supported compilers accept them.

For operations returning `Future`, `Either`, `Try`, or another effect type, consume or sequence the result using the repository's established approach. In a compatible `for` comprehension, use a generator such as `_ <- operation` when the result is unused but completion and failure must participate in the chain. Verify evaluation order, eager or lazy execution, and failure propagation before changing a binding into a generator; it is not a mechanical replacement for every discard.

Review every newly introduced discard binding against its diagnostic and behaviour. A discarded effect or a binding added merely to make warning output disappear fails the checkpoint.

Search source and generated-code configuration for deprecated API use that compilation may not cover. Replace deprecated code with the documented equivalent while preserving behaviour.

## Phase 5: Validate the checkpoint

Run the narrow compile immediately after the first version edit. Repair only the current migration slice and rerun it. Then run, in repository order:

1. formatter check or formatting of touched files
2. all compile configurations with a clean rebuild to defeat stale incremental output
3. unit and integration tests
4. Scaladoc or documentation compilation
5. configured lint, MiMa, packaging, and CI-equivalent checks

For cross-published modules, run these checks for every version in the approved matrix, explicitly selecting the lowest version first. Verify that CI and release configuration build the same matrix and that local packaging or publishing checks produce each expected artifact, without publishing remotely. When cross-publishing is removed, verify that only the approved single version remains configured. An unsupported lowest version or an untested retained version fails the checkpoint; success on the newest version alone is insufficient.

For JVM artifacts, run relevant tests or a consumer smoke test on the minimum supported JVM for each published module and Scala artifact, exercising the packaged artifact and its runtime dependencies. A newer build JDK or a compatible bytecode release target alone does not prove runtime compatibility. Use mise-managed toolchains and the repository's `.tool-versions` conventions where applicable. If test tooling requires a newer JVM, use a minimal consumer smoke test on the supported minimum instead. An unavailable minimum JVM or a failed runtime check is a blocker; report it rather than claiming compatibility or raising the runtime baseline without approval.

Inspect complete output for warnings even when commands exit successfully. Also check startup or a focused runtime smoke test when reflection, macros, serialization, or framework bootstrapping is involved.

The gate fails on any warning, ignored option, deprecation, skipped required suite, compile error, test failure, or unexplained source-compatibility flag.

## Checkpoint report and mandatory stop

At the end, report:

- previous and current Scala versions
- prerequisite, build, source, and dependency files changed
- rewrites applied and temporary flags removed
- exact validation commands and outcomes, explicitly confirming zero errors, warnings, and deprecations
- pre-edit baseline outcomes and any pre-existing failures distinguished from upgrade regressions
- known compatibility risks checked
- the cross-publishing decision, approved version matrix, and validation outcome for each version, explicitly identifying the lowest supported version per published module
- minimum supported JVMs and the artifact-level runtime checks performed on them
- the next planned checkpoint
- a recommendation to review and commit this checkpoint

Then stop. Do not edit for, test against, or begin the next Scala target until the user invokes the skill again.