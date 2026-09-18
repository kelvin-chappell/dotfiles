# Progressive Review And Export Format

Render progressive snapshots directly in Copilot chat as GitHub-flavoured Markdown, then render the reconciled final review as a self-contained HTML report. Optimise the first screen for decisions and use native `<details>` elements for grouped changes. Do not put the whole result inside one outer `<details>` block.

## Progressive Contract

Post three kinds of result:

1. `Starting`: one sentence naming the PR and the bounded evidence being gathered.
2. `Initial` and `Progress`: provisional snapshots containing only grounded claims. The initial snapshot must include every changed file, even when many remain queued. Later snapshots should be event-driven: post when a material finding is established or a high-significance cluster is completed, not after every file.
3. `Complete` or `Partial`: the reconciled final report. `Complete` must account for every changed file and non-trivial hunk. Use `Partial` only when a named external blocker prevents further review, and explicitly mark every affected item.

Do not delay an initial result to create the report, run broad tests, clone a repository, or perfect the cluster taxonomy. A provisional `Unclassified / queued` cluster is preferable to hiding changes. Generate the exportable report after reconciliation, not on every progressive snapshot.

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

The example is structural only. Remove placeholders and sample content. Every cluster must use a `<details>` block, including a cluster containing one trivial file.

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

## Exportable Final Report

- Write one self-contained HTML file under `${TMPDIR:-/tmp}` with a collision-resistant name such as `semantic-pr-review-owner-repository-pr-123-20260918T094047Z.html`.
- Give the document a descriptive `<title>` and an `<h1>` naming the pull request. Show review status, coverage, elapsed time, source commit, and generation time near the top.
- Keep findings, the visible change map, automation candidates, and coverage outside collapsed sections so the decision summary prints and scans well.
- Render every grouped change as a separate native `<details>` element. Its `<summary>` must show the cluster name, review status, changed-file count, and significance. Open clusters with actionable findings by default; collapse all others by default.
- Inside each cluster, include the defining change, semantic explanation, grouped ripple, review guidance, exhaustive per-file/hunk inventory, and only the diff excerpts needed to support claims.
- Embed CSS with high-contrast screen styles and `@media print` rules. Print styles must render every `<details>` body, including sections that were collapsed on screen.
- Escape all PR-derived text before inserting it into HTML. Permit trusted GitHub links only with `https:` URLs; do not inject PR content as executable markup.
- Do not load remote scripts, fonts, styles, images, or other assets. The report must remain usable when opened offline and portable as a single file.
- Open or attach the generated report with the available environment capability and link or name it in the final chat response.

## Corrections And Completion

Progressive results are snapshots, not an append-only transcript. A later result may regroup files or correct an earlier inference, but it must call out the correction explicitly. Never silently drop an earlier finding or changed file.

The final report must end with coverage and residual risk. `Complete` means every file and non-trivial hunk is accounted for and every high-significance cluster received semantic review. Otherwise use `Partial`, name the external blocker, and leave affected items visibly marked `Partial` or `Queued`.