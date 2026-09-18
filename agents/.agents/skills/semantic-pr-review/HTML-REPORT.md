# Semantic PR Review HTML Report

Render each review as one standalone, dependency-free HTML5 document. The initial and final states use the same absolute path. Keep findings first, followed by significant causal changes, automation candidates, and coverage and residual risk.

## Header And Evidence Rows

The compact header shows repository, PR number and title, `Initial`, `Complete`, or `Complete at deadline` status, elapsed review time, and reviewed/total cluster coverage.

Every finding and significant causal cluster uses a responsive evidence row. Put a concise, syntax-colored, line-numbered unified-diff excerpt on the left and the semantic explanation on the right. Highlight the defining hunk. Do not include the whole diff.

The explanation contains impact, evidence separated from inference, confidence with its basis, remediation or review question, and specialist-review focus.

## Scaffold

Use this shape, expanding repeated sections as needed:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>PR review: {{escaped owner/repository}}#{{number}}</title>
  <style>
    :root { color-scheme: light; --page:#f4f2ed; --paper:#fff; --ink:#17201c; --muted:#59645e; --rule:#c7cec9; --accent:#0f6b4f; --danger:#a12a2a; --warning:#805500; --code:#17211d; --code-ink:#eef5f1; --add:#b9f2ce; --delete:#ffd0cc; --hunk:#ffe4a3; }
    * { box-sizing: border-box; }
    html { background:var(--page); color:var(--ink); font-family:Georgia,"Times New Roman",serif; }
    body { margin:0; }
    main { width:min(1180px,calc(100% - 32px)); margin:auto; padding:32px 0 64px; }
    header { border-top:6px solid var(--ink); border-bottom:1px solid var(--rule); padding:18px 0; }
    h1,h2,h3,p { margin-top:0; }
    h1 { margin-bottom:8px; font-size:clamp(1.65rem,4vw,2.6rem); letter-spacing:0; overflow-wrap:anywhere; }
    h2 { margin:36px 0 14px; font-size:1.4rem; letter-spacing:0; }
    h3 { font-size:1.05rem; letter-spacing:0; }
    a { color:var(--accent); }
    a:focus-visible { outline:3px solid var(--warning); outline-offset:3px; }
    .meta { display:flex; flex-wrap:wrap; gap:8px 18px; color:var(--muted); font:.86rem/1.4 ui-monospace,monospace; }
    .status { color:var(--paper); background:var(--accent); padding:2px 7px; font-weight:700; }
    .status.initial { background:var(--warning); }
    .status.deadline { background:var(--danger); }
    .notice { border-left:5px solid var(--accent); background:#e4f2eb; padding:14px 16px; font-weight:700; }
    .notice.provisional { border-color:var(--warning); background:#fff3d4; }
    .evidence-row { display:grid; grid-template-columns:minmax(0,1.08fr) minmax(280px,.92fr); border:1px solid var(--rule); background:var(--paper); margin-bottom:18px; }
    .diff-panel { min-width:0; background:var(--code); color:var(--code-ink); overflow:auto; }
    .diff-path { padding:10px 12px; border-bottom:1px solid #526159; color:#d7e2dc; font:.78rem/1.35 ui-monospace,monospace; overflow-wrap:anywhere; }
    .diff { width:100%; border-collapse:collapse; font:.78rem/1.45 ui-monospace,monospace; }
    .diff td { padding:0 8px; vertical-align:top; white-space:pre; }
    .diff .line { width:1%; color:#aebbb4; text-align:right; user-select:none; border-right:1px solid #526159; }
    .diff .code { width:100%; }
    .diff tr.add { color:var(--add); background:#123c28; }
    .diff tr.delete { color:var(--delete); background:#461f20; }
    .diff tr.hunk { color:var(--hunk); background:#413719; font-weight:700; }
    .syntax-keyword { color:#9ed0ff; } .syntax-string { color:#f4d28d; } .syntax-comment { color:#b8c4be; }
    .explanation { min-width:0; padding:18px; }
    .explanation dl { display:grid; grid-template-columns:max-content 1fr; gap:7px 12px; margin:0; }
    .explanation dt { color:var(--muted); font-weight:700; }
    .explanation dd { margin:0; overflow-wrap:anywhere; }
    .severity { color:var(--danger); font:700 .75rem/1.3 ui-monospace,monospace; text-transform:uppercase; }
    .empty { border:2px solid var(--accent); background:var(--paper); padding:18px; font-size:1.15rem; font-weight:700; }
    .summary-list { background:var(--paper); border-top:3px solid var(--ink); padding:16px 20px; }
    code { font-family:ui-monospace,monospace; overflow-wrap:anywhere; }
    @media (max-width:760px) { main { width:calc(100% - 20px); padding-top:18px; } .evidence-row { grid-template-columns:1fr; } .diff-panel { max-height:420px; } .explanation dl { grid-template-columns:1fr; gap:2px; } .explanation dd { margin-bottom:8px; } }
    @media print { html { background:#fff; } main { width:100%; padding:0; } .evidence-row { grid-template-columns:1fr; break-inside:avoid; } .diff-panel { overflow:visible; print-color-adjust:exact; } .diff td { white-space:pre-wrap; overflow-wrap:anywhere; } }
  </style>
</head>
<body>
<main>
  <header>
    <h1>{{escaped PR title}}</h1>
    <div class="meta"><span>{{escaped owner/repository}}#{{number}}</span><span class="status initial">{{status}}</span><span>{{elapsed}}s elapsed</span><span>{{reviewed}}/{{total}} clusters reviewed</span></div>
  </header>
  <p class="notice provisional">No grounded findings yet; analysis is in progress.</p>
  <section aria-labelledby="findings"><h2 id="findings">Findings</h2>
    <article class="evidence-row">
      <div class="diff-panel"><div class="diff-path">{{escaped path and lines}}</div>
        <table class="diff" aria-label="Unified diff excerpt"><tbody>
          <tr class="hunk"><td class="line">...</td><td class="code">@@ {{escaped defining hunk}} @@</td></tr>
          <tr class="delete"><td class="line">41</td><td class="code">- {{escaped deleted source}}</td></tr>
          <tr class="add"><td class="line">41</td><td class="code">+ {{escaped added source}}</td></tr>
        </tbody></table>
      </div>
      <div class="explanation"><p class="severity">{{severity}} · {{significance tier}}</p><h3>{{escaped title}}</h3>
        <dl><dt>Evidence</dt><dd>{{escaped observation}}</dd><dt>Inference</dt><dd>{{escaped conclusion or None}}</dd><dt>Impact</dt><dd>{{escaped impact}}</dd><dt>Confidence</dt><dd>{{level and reason}}</dd><dt>Action</dt><dd>{{escaped remediation or question}}</dd><dt>Specialist</dt><dd>{{escaped review focus}}</dd></dl>
      </div>
    </article>
  </section>
  <section aria-labelledby="changes"><h2 id="changes">Significant causal changes</h2>{{evidence rows}}</section>
  <section aria-labelledby="automation"><h2 id="automation">Automation candidates</h2>{{ranked concise list}}</section>
  <section aria-labelledby="coverage"><h2 id="coverage">Coverage and residual risk</h2>{{ranked coverage list}}</section>
</main>
</body>
</html>
```

Remove all sample rows and placeholders. In the final overwrite, replace the provisional notice. When appropriate use `<p class="empty">No semantic defects were found.</p>`.

## Diff Evidence

- Preserve unified-diff `+`, `-`, context, and `@@` cues as text so meaning never depends on color.
- Show old and new line numbers when available. Keep the source column dominant.
- Highlight only the defining hunk header or source rows.
- Apply lightweight syntax spans only with high confidence; diff meaning takes precedence.
- Include enough context to prove the explanation and identify omissions with an escaped ellipsis row.
- Construct links only from trusted GitHub coordinates and validated commit, path, and line values.

## Escaping And Safety

HTML-escape every repository, diff, PR, issue, check, and reviewer-derived string before interpolation: `&` to `&amp;`, `<` to `&lt;`, `>` to `&gt;`, `"` to `&quot;`, and `'` to `&#39;`. Escape content inside `<code>`, `<pre>`, and table cells too. URL-encode validated URL components separately. Never interpolate untrusted content into CSS, raw attributes, or event handlers. Include no scripts.

## Progressive States

The `Initial` report must be useful and explicitly provisional. Include grounded material in decreasing significance, state which high-significance analysis is in progress, expose current coverage, and never guess at defects.

The final atomic overwrite must change status to `Complete` or `Complete at deadline`, update elapsed time and coverage, remove stale provisional language, list every skipped cluster or file class, preserve decreasing significance throughout, and show the prominent no-defects statement when there are no actionable semantic findings.

## Accessibility And Layout

Use semantic headings, sections, articles, lists, definition lists, and labelled diff tables. Maintain WCAG AA text and status contrast. Additions and deletions retain literal `+` and `-` cues. Evidence rows stay as two stable desktop columns and stack diff before explanation on mobile and print. Long paths and prose wrap; code may scroll on screen and wraps in print. The report loads no scripts or remote resources and must produce no console errors.