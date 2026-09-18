# Progressive Copilot Review Format

Render the review directly in Copilot chat as GitHub-flavoured Markdown. Optimise the first screen for decisions and use native `<details>` elements for supporting detail. Do not put the whole result inside one outer `<details>` block.

## Progressive Contract

Post three kinds of result:

1. `Starting`: one sentence naming the PR and the bounded evidence being gathered.
2. `Initial` and `Progress`: provisional snapshots containing only grounded claims. The initial snapshot must include every changed file, even when many remain queued. Later snapshots should be event-driven: post when a material finding is established or a high-significance cluster is completed, not after every file.
3. `Complete` or `Complete at deadline`: the reconciled final result. It must account for every changed file and non-trivial hunk, or explicitly mark each item that was not reviewed.

Do not delay an initial result to create an artifact, run broad tests, clone a repository, or perfect the cluster taxonomy. A provisional `Unclassified / queued` cluster is preferable to hiding changes.

## Snapshot Shape

Use this shape, omitting empty repeated items:

```markdown
**PR review: owner/repository#123 · Initial**
`8/24 files reviewed · 2/5 clusters reviewed · 9s elapsed`

No grounded findings yet; analysis is in progress.

**Findings**
1. **High · Concise title** ([path:line](trusted-url))
   Impact and concrete action in two short sentences.

**Change map**
- **Reviewed · Public price contract** · 6 files · API compatibility review
- **Partial · Persistence migration** · 9 files · data/storage review
- **Queued · Tests and generated fixtures** · 9 files

<details open>
<summary><strong>Public price contract</strong> · Reviewed · 6 files · high significance</summary>

- **Defining change:** What contract or behaviour changed.
- **Why it matters:** Semantic impact.
- **Ripple grouped here:** Callers, implementations, tests, configuration, and documentation.
- **Review needed:** Expertise and reason.
- **Review focus:** Invariants, boundaries, and unresolved questions.

**Changes**
- `src/price.ts` · Reviewed · Adds currency to the public value type; hunks 1-2 define the contract.
- `src/order.ts` · Reviewed · Adapts order totals to the new value type; hunk 1 is a mechanical ripple.

**Evidence**
```diff
@@ defining hunk @@
-old source
+new source
```
</details>

<details>
<summary><strong>Tests and generated fixtures</strong> · Queued · 9 files · low significance</summary>

- `test/price.test.ts` · Queued · Test expectations changed; semantic coverage not yet assessed.
- `fixtures/prices.json` · Queued · Generated data changed; consistency check pending.
</details>

**Automation candidates**
- Generated fixture consistency · `fixtures/**` · repository generator · not covered by observed checks

**Coverage and residual risk**
- Reviewed: public contract and direct callers.
- Queued: persistence failure paths in 9 named files above.
- Checks: unit tests passing; schema compatibility check unavailable.
```

The example is structural only. Remove placeholders and sample content. Use a compact bullet instead of a `<details>` block when a cluster contains one trivial file.

## Exhaustive Change Inventory

- Keep inventory completeness separate from semantic coverage. Seeing and listing a file makes the inventory complete; only inspecting its relevant diff and context advances it from `Queued`.
- List every changed file under exactly one primary cluster in every snapshot. Preserve rename and add/delete status when known.
- Account for every non-trivial hunk in the final snapshot. Adjacent hunks with one semantic purpose may be summarised together; state the hunk count or range of hunk ordinals.
- A file may be discussed in several clusters, but mark secondary appearances as cross-references so totals are not inflated.
- Reconcile the inventory count against the PR changed-file count before final delivery.
- Put formatting, imports, generated files, lockfiles, snapshots, and other mechanical changes in low-significance clusters. These still count towards coverage.
- Use `Reviewed`, `Partial`, or `Queued` consistently. `Reviewed` means the relevant diff and semantic context were inspected, not merely that the filename was seen.
- For very large clusters, keep one compact line per path and summarise repeated mechanical hunks by purpose and count. Do not paste the full diff or expand routine entries by default.

## Expandable Detail

- Keep the change map outside `<details>` so all concepts are visible at a glance.
- Use one `<details>` block per causal cluster. The `<summary>` must include cluster name, review status, file count, and significance.
- Add `open` only to clusters with actionable findings or the highest-significance cluster currently under review. Leave routine clusters collapsed.
- Put concise semantic explanation before the file inventory inside each block, followed by only the diff excerpts needed as evidence.
- Never hide a finding solely inside a collapsed block. Repeat its title and action in the top-level findings list.

## Corrections And Completion

Progressive results are snapshots, not an append-only transcript. A later result may regroup files or correct an earlier inference, but it must call out the correction explicitly. Never silently drop an earlier finding or changed file.

The final result must end with coverage and residual risk. `Complete` means every file and non-trivial hunk is accounted for and every high-significance cluster received semantic review. Otherwise use `Complete at deadline` and leave affected items visibly marked `Partial` or `Queued`.