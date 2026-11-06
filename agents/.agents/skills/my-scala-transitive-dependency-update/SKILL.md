---
name: my-scala-transitive-dependency-update
description: 'Update transitive dependencies in sbt-managed Scala projects. Use when asked to upgrade or remove an indirect dependency, or maintain a transitive dependency pin. Establish dependency coordinates and scopes, remove unused dependencies first, recommend Guardian upstream upgrades when sufficient, otherwise pin the latest stable release using the Amigo safeTransitiveDependencies pattern.'
---

# Update an sbt transitive dependency

Work on the requested dependency only. Apply the following gates in order. Edit the build where a gate calls for a change, then show the resulting Scala code block. Preserve unrelated work and existing build conventions.

## Prerequisite: establish the dependency axis

Before deciding on removal or an upgrade, identify:

- Organisation, artefact, declared and resolved versions, and any classifier.
- Cross-version scheme (`%`, `%%`, or an explicit `CrossVersion`), the actual published artefact name, and each supported Scala/platform variant.
- Every affected subproject and configuration, including Compile, Test, Runtime and any custom integration-test or Provided configurations.
- Direct declarations, existing pins or overrides, exclusions and version variables that affect resolution.

Ask for clarification if the requested dependency cannot be identified unambiguously. Inspect the build, project instructions and documented validation commands. Use mise-managed tools and `.tool-versions` for tool versions.

Run both `dependencyTree` and `dependencyList` for every affected subproject and configuration. For example, replace `app` with the actual project identifier:

```sh
mise exec -- sbt \
  'app / Compile / dependencyTree' 'app / Compile / dependencyList' \
  'app / Test / dependencyTree' 'app / Test / dependencyList' \
  'app / Runtime / dependencyTree' 'app / Runtime / dependencyList'
```

Include custom configurations and supported cross-build variants where relevant. Check task availability with the build's sbt version; use its supported dependency-tree facility. If enabling a plugin or changing the build tool is necessary, explain the prerequisite and obtain approval first. Failed or unavailable reports are blockers, not evidence that a dependency is absent.

Record each introducing path from a declared dependency to the target, the selected version, evicted versions and the configurations that contain it. Distinguish configuration inheritance from independent usage. The prerequisite is complete only when both reports establish the target's source and resolution on every affected axis.

## Gate 1: remove an unused dependency and stop

Determine whether compilation, tests or runtime require the target. Combine the graph with source, generated code, framework configuration, service loading, reflection and packaging evidence. Absence of an import alone does not establish that a transitive dependency is unused.

Where an existing pin makes usage unclear, temporarily remove only that pin and rerun the scoped reports. An older version reappearing establishes an upstream dependency, not that it is safe to exclude. Restore any diagnostic-only edits before proceeding to another gate.

If the target is unused across all relevant axes:

1. Remove its redundant declaration, pin or override. If an unused artefact is still pulled transitively, apply the narrowest justified exclusion on its introducing path or paths, rather than removing a parent that is still needed.
2. Remove only version variables and comments made obsolete by this change.
3. Rerun both reports and relevant compile, test and packaging/runtime checks. Confirm the target is absent and behaviour is preserved.
4. Report the removal, its evidence and the resulting build code. **Stop.** Do not look for an upgrade or add a replacement pin.

If the target is already absent with nothing to remove, report that finding and stop. If usage or removal safety remains unresolved, explain the uncertainty and ask for the missing information rather than guessing.

## Gate 2: prefer an upstream Guardian upgrade and stop

For a required dependency, inspect Guardian-maintained libraries on every introducing path, including Guardian transitive parents. Establish ownership from repository or publication metadata, not solely from a group-name guess.

Check current stable Guardian releases and their published POMs, build definitions or dependency reports. Determine whether upgrading reachable Guardian dependencies would automatically upgrade the target without adding or increasing a target-specific pin. If the Guardian parent is itself transitive, identify the directly declared dependency that must change to select its newer version.

Account for all paths, competing pins, eviction and supported Scala/JDK/platform variants. Verify the resulting target version using published metadata and, when necessary, a temporary build change followed by both scoped reports. Restore only your diagnostic edits.

When a Guardian upgrade is sufficient, tell the user:

- Which declared Guardian dependencies to upgrade, with current and proposed versions, and any intermediate Guardian parent involved.
- Which target version would resolve, on which axes, and the evidence/source URLs.
- Any compatibility prerequisites or existing redundant pin that would need removing.

**Stop without leaving dependency changes or adding a target pin.** This is a recommendation to the user, not permission to perform the upstream upgrades. If release information is inaccessible, report the blocker rather than assuming this gate does not apply.

## Gate 3: select the latest stable release and edit the build

Only reach this gate when the dependency is required and Gate 2 does not provide an upstream solution.

Resolve the latest stable release at execution time from the artefact's authoritative repository metadata and upstream release notes. Verify publication for the exact coordinates and every required cross-version. Exclude snapshots, milestones, release candidates, alpha/beta, nightly and other prereleases; do not assume the metadata's `release` field guarantees stability or sort version strings lexicographically.

Record the selected version and source URLs. Check Scala, JDK, binary/API and related-module compatibility. If the latest stable release requires a migration beyond this task, explain the blocker and ask before expanding scope or selecting an older release. Never silently label an older compatible release as the latest stable.

Follow the structure of the pinned [Amigo build template](https://github.com/guardian/amigo/blob/e959726e58988140f7c8ebc29e5f2af40b546b95/build.sbt#L74-L80): a maintenance comment, a `safeTransitiveDependencies` value containing a `Seq`, and that sequence appended to the relevant `libraryDependencies`. Read adjacent lines to see the complete declaration and wiring. Reuse an existing equivalent block rather than creating duplicates.

Illustrative shape only; substitute verified coordinates, version, cross-version operator and scope:

```scala
/*
 * To check whether a pin is still needed, temporarily remove it and inspect
 * dependencyList in each affected configuration. Keep it if an older version
 * returns; otherwise remove the redundant entry after validation.
 */
val safeTransitiveDependencies = Seq(
  "organisation" % "artefact" % "verified-stable-version" % Runtime
)

libraryDependencies ++= Seq(
  // Existing direct dependencies remain here.
) ++ safeTransitiveDependencies
```

Keep the sequence local to the affected project, or reuse shared definitions only where all consumers need the same pin. Update an existing target entry instead of adding another. Retain the correct `%`/`%%` and any necessary cross-version configuration. Use aligned version variables for modules that upstream requires to move together, explaining any necessary companion changes.

## Gate 4: assign the correct scope and validate

Scope is part of the edit, not an optional follow-up. Select the narrowest configuration or explicit configuration mapping that covers all demonstrated uses:

| Demonstrated need | Declaration scope |
| --- | --- |
| Main compilation and normal production use | Default Compile scope, usually no suffix |
| Tests only | `% Test` |
| Production runtime only, including reflective/service-loaded implementations | `% Runtime` |
| Compilation with the dependency supplied by the deployment environment | `% Provided`, only with evidence of that contract |
| Custom or multiple independent configurations | The build's explicit configuration mapping covering those uses |

Apply sbt's actual configuration inheritance. A runtime or test pin does not update an independently resolved Compile graph. Conversely, do not promote a test-only or runtime-only artefact into Compile merely to influence version selection. Preserve existing custom mappings where they remain correct.

After editing:

1. Rerun `dependencyTree` and `dependencyList` on every affected axis. Verify the expected version is selected, older versions are not selected, and the artefact has not leaked into unintended configurations. An evicted node is not a selected dependency.
2. Run the affected compilation and tests, plus packaging or a focused runtime smoke check when runtime behaviour is involved. Use repository-standard formatting checks for touched build files.
3. Review the final diff for duplicate pins, unused version variables, scope widening and leftover diagnostic edits. If normal `libraryDependencies` version selection does not select the requested release, investigate competing constraints and report the cause rather than silently introducing a global override.

Report the changed files, introducing dependency path, old and new resolved versions, chosen scope and rationale, release sources, and the actual updated Scala code block. State any failed or unrun checks and their causes explicitly; an unverified change remains incomplete.
