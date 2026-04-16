---
name: pr-review
description: "Blind parallel code review for pull requests. Dispatches 4 independent review agents (correctness, security, performance, style) with only the raw diff and spec criteria — no narrative framing. Posts findings to GitHub for provenance. Triggers on: pr review, review this pr, review PR, blind review."
---

# /pr-review

Blind parallel code review. One job: **dispatch 4 independent review agents with raw artifacts only, synthesize findings mechanically, post for provenance.**

The orchestrator is a dumb pipe. It does not interpret, summarize, or explain the code. It reads raw artifacts and pastes them verbatim into agent prompts. This prevents truth-anchoring bias when run same-session with /do.

---

## Hard Rules

> **The orchestrator must NEVER:**
> 1. Read source files (only the diff)
> 2. Describe what the PR does or why
> 3. Add its own findings to the review
> 4. Filter, downgrade, or dismiss agent findings
> 5. Add narrative framing ("this looks like a solid PR...")
> 6. Reference conversation context in agent prompts
> 7. Summarize the diff for agents (they read it themselves)

These rules exist because the entire value of /pr-review is blind, unanchored review. Any interpretation by the orchestrator defeats the purpose.

---

## Phase Transitions

Mark every phase transition:

```
─── Phase: {Name} ──────────────────────────
```

Phases in order: **Locate PR → Gather Artifacts → Dispatch Blind Agents → Synthesize → Post & Report**

---

## Locate PR

**With argument** (`/pr-review 367`): Use the PR number directly.

**Without argument**: Detect from current branch:

```bash
gh pr view --json number,title,headRefName,baseRefName -q '.number'
```

**Validate:** PR exists and is open. If closed or merged, stop: "PR #{N} is {state}. Nothing to review."

**Collect metadata** (for the GitHub comment header only):
- PR number
- PR title
- Branch name
- Base branch

> **Do NOT read the PR description or body.** The title is used only for the comment header. Nothing else from PR metadata enters agent prompts.

---

## Gather Artifacts

> **Dumb pipe. Mechanical data extraction only.**

Collect exactly two artifacts:

### Artifact 1: Raw Diff

```bash
gh pr diff {N}
```

Store the output verbatim. Do not edit, truncate, or annotate it.

**Large diff handling:** If the diff exceeds ~15,000 lines, narrate the size and split by file. Dispatch agents with file-grouped chunks. Each agent still gets the full spec criteria.

### Artifact 2: Spec Criteria

Look for a spec file. Check orient output or search `.claude/specs/` for a spec whose feature name matches the PR branch:

1. If a spec exists with `## Done Criteria` → read that section verbatim
2. If no spec exists → set criteria to: `"No spec provided — review the diff on its own merits."`

> **Anti-patterns:** Do NOT read source files beyond the diff. Do NOT add context about intent or approach. Do NOT summarize the diff. Do NOT mention anything from the current conversation or session. The orchestrator touches `gh pr diff`, one optional file read, and nothing else.

---

## Dispatch Blind Agents

Spawn all 4 agents in a **single message** (parallel execution). Each agent gets the IDENTICAL artifact block plus their specific lens.

### Common Artifact Block

Paste this verbatim into every agent prompt:

```
## Pull Request Diff

{RAW_DIFF}

## Acceptance Criteria

{SPEC_CRITERIA}
```

### Agent 1: Correctness Reviewer

Spawn with `subagent_type: "general-purpose"`:

```
You are reviewing a pull request for CORRECTNESS. You have no context about this code beyond what appears below. Review it cold.

{ARTIFACT_BLOCK}

## Your Review Lens

Focus exclusively on:
- Logic errors, off-by-one, wrong conditions, missing returns
- Edge cases not handled (nulls, empty collections, boundary values)
- Spec compliance — does the implementation satisfy each acceptance criterion?
- Test coverage gaps — are critical paths tested? Are assertions meaningful?
- Error handling — are failures caught and handled appropriately?
- Data integrity — are transactions, constraints, and invariants preserved?

## Output Format

Rate each finding: **critical** (blocks merge), **warning** (should fix), **nit** (nice to have).

## Correctness Review

### Critical
- `file:line` — {description of issue and why it matters}

### Warning
- `file:line` — {description}

### Nit
- `file:line` — {description}

### Summary
{1-2 sentence overall correctness assessment}

If you find no issues in a severity tier, write "None found."
Do NOT invent issues to fill sections. Only report genuine concerns.
Do NOT write code. Do NOT read files beyond the diff. Your output is the review text above, nothing else.
```

### Agent 2: Security Reviewer

Spawn with `subagent_type: "general-purpose"`:

```
You are reviewing a pull request for SECURITY. You have no context about this code beyond what appears below. Review it cold.

{ARTIFACT_BLOCK}

## Your Review Lens

Focus exclusively on:
- Input validation — are user inputs sanitized before use?
- Authentication/authorization — are auth checks present and correct?
- Injection vectors — SQL injection, XSS, command injection, template injection
- Secrets handling — hardcoded keys, tokens, passwords in code or config?
- Data exposure — sensitive data in logs, error messages, API responses?
- OWASP Top 10 — any applicable vulnerability patterns?
- Dependency risks — new dependencies with known vulnerabilities?

## Output Format

Rate each finding: **critical** (blocks merge), **warning** (should fix), **nit** (nice to have).

## Security Review

### Critical
- `file:line` — {description of vulnerability and exploitation risk}

### Warning
- `file:line` — {description}

### Nit
- `file:line` — {description}

### Summary
{1-2 sentence overall security assessment}

If you find no issues in a severity tier, write "None found."
Do NOT invent issues to fill sections. Only report genuine concerns.
Do NOT write code. Do NOT read files beyond the diff. Your output is the review text above, nothing else.
```

### Agent 3: Performance Reviewer

Spawn with `subagent_type: "general-purpose"`:

```
You are reviewing a pull request for PERFORMANCE. You have no context about this code beyond what appears below. Review it cold.

{ARTIFACT_BLOCK}

## Your Review Lens

Focus exclusively on:
- N+1 queries — loops that issue database queries per iteration
- Unbounded operations — missing LIMIT, no pagination, unbounded loops
- Missing indexes — queries on columns without indexes (if schema visible)
- Caching opportunities — repeated expensive computations or fetches
- Memory usage — large objects held unnecessarily, missing cleanup
- Algorithmic complexity — O(n^2) or worse where O(n) is possible
- I/O bottlenecks — synchronous blocking, missing connection pooling

## Output Format

Rate each finding: **critical** (blocks merge), **warning** (should fix), **nit** (nice to have).

## Performance Review

### Critical
- `file:line` — {description of issue and expected impact}

### Warning
- `file:line` — {description}

### Nit
- `file:line` — {description}

### Summary
{1-2 sentence overall performance assessment}

If you find no issues in a severity tier, write "None found."
Do NOT invent issues to fill sections. Only report genuine concerns.
Do NOT write code. Do NOT read files beyond the diff. Your output is the review text above, nothing else.
```

### Agent 4: Style & Consistency Reviewer

Spawn with `subagent_type: "general-purpose"`:

```
You are reviewing a pull request for STYLE AND CONSISTENCY. You have no context about this code beyond what appears below. Review it cold.

{ARTIFACT_BLOCK}

## Your Review Lens

Focus exclusively on:
- Naming conventions — do names follow existing codebase patterns?
- Code structure — does the organization match existing patterns?
- Duplication — is there copy-pasted code that should be extracted?
- Dead code — unreachable code, unused imports, commented-out blocks
- Documentation — are complex decisions explained? Are docstrings present where expected?
- API design — are interfaces clean, consistent, and unsurprising?
- Type safety — are types used correctly? Missing type annotations where expected?

## Output Format

Rate each finding: **critical** (blocks merge), **warning** (should fix), **nit** (nice to have).

## Style & Consistency Review

### Critical
- `file:line` — {description}

### Warning
- `file:line` — {description}

### Nit
- `file:line` — {description}

### Summary
{1-2 sentence overall style assessment}

If you find no issues in a severity tier, write "None found."
Do NOT invent issues to fill sections. Only report genuine concerns.
Do NOT write code. Do NOT read files beyond the diff. Your output is the review text above, nothing else.
```

---

## Synthesize

> **Wait for ALL 4 agents to return. Do NOT proceed until all have reported.**

Read each agent's full output. Then synthesize mechanically:

1. **Collect** all findings from all 4 agents
2. **Deduplicate** — same `file:line` + same issue across agents → keep the most specific version, tag with all lenses that flagged it (e.g., `[correctness, security]`)
3. **Group by severity** — all criticals first, then warnings, then nits (across all lenses)
4. **Count** — total findings by severity
5. **NO filtering** — every finding survives synthesis. The orchestrator does not judge quality or relevance
6. **NO editorializing** — no "overall this PR looks good" or "minor issues only." Let the findings speak

### Output Structure

```markdown
## PR Review: #{N} — {PR title}

**Reviewers:** Correctness, Security, Performance, Style
**Findings:** {X} critical, {Y} warning, {Z} nit

### Critical

- `file:line` [{lens}] — {description}
- ...

### Warning

- `file:line` [{lens}] — {description}
- ...

### Nit

- `file:line` [{lens}] — {description}
- ...

---
*Blind parallel review — 4 independent agents, raw diff only, no author framing.*
```

If a severity tier has no findings across all agents, write "None."

---

## Post & Report

1. **Post to GitHub** for provenance:

```bash
gh pr comment {N} --body "{SYNTHESIZED_REVIEW}"
```

2. **Output to console** — display the same synthesized review for in-session consumption

3. **Narrate**: "PR review posted: {X} critical, {Y} warning, {Z} nit."

---

## Standalone vs Pipeline Use

### Standalone (`/pr-review 367`)

Full cycle: Locate → Gather → Dispatch → Synthesize → Post.

After posting, present findings and ask:

```
Found {X} critical, {Y} warning, {Z} nit. Address findings now?
```

If yes: work through findings in severity order (critical first). For each finding, fix the code, run tests, commit.

If no: end. Findings are posted to GitHub for later.

### Within /do Pipeline (auto-invoked)

Same cycle, but after posting:

**OVERRIDE:** Ignore the standalone "Next Steps" above. Return findings to /do. The /do pipeline owns the flow from here — it handles Address Findings, Quality Re-run, and Close Out.

The return value /do needs: the finding counts (critical, warning, nit) and the full synthesized review text.
