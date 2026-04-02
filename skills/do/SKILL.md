---
name: do
description: "Execution phase that takes a spec produced by /think and builds it with TDD discipline. Reads the spec, writes tests first, implements, commits atomically, validates, simplifies, and closes out. Narrates progress for transparency — pauses only for senior-level decisions. Triggers on: do, build this, execute, let's build, implement."
---

# /do

The doing phase. One job: **take a spec and turn it into working, tested code.**

/do narrates its process in real-time for transparency. You watch the build unfold. You get asked only when a decision requires senior-level judgment.

> **/do does NOT invoke /think.** When a divergence needs a design decision, /do pauses, asks the user directly via AskUserQuestion, and continues. The only full stop: when the entire spec approach is fundamentally broken and needs re-speccing.

---

## Hard Rules

These are non-negotiable behavioral constraints. They exist because /do's natural failure mode is optimizing for forward progress over correctness. Every rule here was earned by a real incident.

### Correctness Over Speed

> **When in doubt, slow down.** The urge to "just move on" is the exact moment to pause and verify.

### While We're Here (fix-as-you-touch)

> **When touching a file for any reason, fix all visible issues — lint, types, pre-existing bugs, review feedback.** Default: fix it. A single-line fix, a type annotation, a lint warning — these ALWAYS get fixed, no exceptions. The only escape hatch: if the fix would take **over an hour** and requires changes across multiple files you don't currently own. In that case, narrate why you're deferring and let the user override ("fix it" / "backlog it"). **Never silently backlog something fixable.**

### Quality Gates Run Last

> **Quality gates run after the LAST code change, not after the last PLANNED code change.** Any edit after validation resets the "done" state — re-run tests, type checks, lint before declaring anything complete. **No exceptions.**

### Rejection Is Information

> **When a command rejects an action** (git add warns about ignored file, permission denied, test framework refuses, etc.), **treat the rejection as information, not an obstacle.** STOP. Ask why it was rejected. **Never** escalate with force flags (`-f`, `--force`, `--no-verify`) to bypass safety mechanisms.

### Never Dismiss Test Failures

> **A failing test is a finding, not noise.** Never dismiss a test failure as "pre-existing" or "unrelated" without user confirmation. If a test fails and you didn't cause it, say so — but do NOT skip it, mark it as acceptable, or proceed as if it passed. Present the failure to the user: "Test X fails — appears pre-existing. Investigate or defer?" The user decides, not you.

### Worktree Exit Gate

> **Do NOT exit a worktree until the PR is created, linked to an issue, and CI is triggered.** The worktree is your workspace — leaving early orphans work. If you need to exit before shipping, use `ExitWorktree(action: "keep")` and narrate what's unfinished.

### Checkpoint Hygiene

> **At every natural checkpoint** (post-criterion, post-validation, post-simplify, post-PR-create, post-review-fix, post-rebase), **run this checklist before reporting status:**
>
> 1. Session log current?
> 2. Branch up to date with main?
> 3. CI passing?
> 4. PR reviews pending/addressed?
> 5. Quality gates green since last edit?
>
> Don't wait to be asked. If any item fails, fix it or flag it — don't just report the happy path.

---

## Feedback Integration

At orient time, read `.claude/feedback.md` if it exists.

### Spec Accuracy

Note what previous specs got wrong. Be extra vigilant when the current spec touches similar areas — verify those assumptions before trusting them.

### Autonomy Table

Check which decision types are auto-approved. Use this to calibrate when to pause vs narrate-and-proceed during the build.

**Also check correction entries.** If you've violated a behavior before (while-we're-here, checkpoint-before-merge, etc.), narrate extra vigilance at the relevant moment: "Running checkpoint checklist (correction history: missed step 2 on {date})."

### Patterns

Apply relevant cross-feature learnings to the current build.

---

## Subagent Execution Model

> **Default to subagents. Main context is the orchestrator, not the builder.**

Context window is finite. Compaction accumulates drift and hallucinations. Every line of implementation detail in main context is a line that might be lost or corrupted. Subagents work in fresh context with exactly the information they need — no accumulated baggage.

**Use subagents for:** each Done Criteria item (or logical group), each wave task, each investigation, any work where only the result matters.

**Keep in main context:** spec reading, prompt formulation, pre-flight validation, post-flight scrutiny, commits, state management, divergence decisions, session log updates.

### Pre-Flight (before spawning)

Prepare the subagent prompt with full context. The subagent has ZERO context about the project — everything it needs must be in the prompt.

1. **Read all source files** the subagent will need. Paste relevant sections as literal code — not descriptions, not summaries, not "see file X"
2. **Paste exact interfaces and contracts** — types, function signatures, data shapes
3. **Specify the Done Criteria items** being built
4. **Include the Hard Rules** — while-we're-here, rejection-is-information. Subagents don't inherit behavioral rules from /do's skill definition
5. **Specify file ownership** — what can be modified, what is read-only
6. **Specify what NOT to do** — don't commit, don't modify outside ownership, don't improvise past divergences
7. **Include test commands** — how to run the test suite, what passing looks like
8. **For frontend/visual criteria** — if the spec has a `## Design System` section, paste the relevant design system values (colors, typography, spacing, style) into the subagent prompt. For implementation lookups (font imports, exact hex codes, component patterns), include the ui-ux-pro-max search command:
   `python3 ~/.claude/plugins/cache/ui-ux-pro-max-skill/ui-ux-pro-max/2.5.0/src/ui-ux-pro-max/scripts/search.py "{query}" --domain {domain}`
   Domains: `style`, `color`, `typography`, `product`, `ux`, `chart`, `landing`, `google-fonts`. Stacks: `html-tailwind`, `react`, `nextjs`, `vue`, `svelte`, `react-native`, `flutter`, `shadcn`

> **Crosscheck the prompt before sending.** Read it as if you're the subagent. Is anything ambiguous? Missing? Could it be misinterpreted? If the prompt is unclear, the output will be wrong — and you'll spend more context fixing it than you saved.

### Post-Flight (after collection)

> **Never trust subagent output blindly. Validate everything.**

1. **Read every file** the subagent created or modified — full read, not diff summary
2. **Run the full test suite** — not just the new tests. Pre-existing tests must still pass
3. **Cross-reference against spec** — does the output match the criterion? Does it do exactly what was asked, not more, not less?
4. **Run type checks and lint** on all modified files
5. **Scrutinize for behavioral regression** (see below)
6. **Only commit after all checks pass**

If validation fails: fix in main context if the issue is small. Re-spawn with corrected prompt if the output is fundamentally wrong. Do NOT silently accept partial results.

### Behavioral Regression Scrutiny

After each subagent completes, specifically check for:

- **Changed existing behavior?** Look at functions the subagent modified (not just added). Did any existing function's behavior change? Use `sg` (ast-grep) via Bash to structurally compare function signatures before and after — catches parameter changes, return type changes, and decorator modifications that diffs can miss. If an existing test was modified rather than a new test added — why? This is a red flag.
- **While-we're-here violations?** Did the subagent skip pre-existing issues in files it touched? If yes, fix them in main context before committing.
- **Force-bypass violations?** Did the subagent use `--force`, `--no-verify`, or similar flags? If yes, undo and investigate.
- **Scope creep?** Did it modify files outside its ownership? Add imports or dependencies that seem unrelated? Introduce configuration changes that affect more than the current feature?
- **Silent regressions?** Functions that return different types, error handling that was weakened or removed, defaults that changed, edge cases that were dropped. These hide in diffs — read carefully.
- **Security surface changes?** New inputs not validated, auth checks removed, secrets handling changed.

> **Treat subagent output like a PR from a junior developer.** Trust the intent, verify the execution.

---

## Phase Transitions

Mark every phase transition:

```
─── Phase: {Name} ──────────────────────────
```

Phases in order: **Orient → Build → Validation → Simplify → Quality Re-run → Build Report → Ship → PR Review → Address Findings → Close Out**

---

## Orient and Load

Run the orient script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/do/scripts/orient.sh
```

Read `.claude/feedback.md` if it exists.

**With argument** (`/do auth-redesign`): read `.claude/specs/{arg}.md` directly.

**Without argument**, use orient output:
- **Ready Specs** — one → use it. Multiple → present list, offer worktree (see below), ask which one. None → "No ready specs. Run /think first."
- **In-Progress Builds** → "Resume build for {feature}?" If yes, continue from last unchecked criterion in spec
- **Blocked Builds** → Read the block reason, determine if it's been resolved

### Worktree Execution (optional)

When multiple ready specs exist, offer: "Found {N} ready specs. Want to build {feature} in a worktree? That keeps main clean so you can run another /do in a separate session."

If the user accepts, or explicitly requests a worktree:

1. **Record the main directory path** — store the current working directory as `MAIN_DIR` (absolute path). You'll need this for all `.claude/` operations because `.claude/` is gitignored and won't exist in the worktree.
2. **Enter worktree** using the `EnterWorktree` tool: `EnterWorktree(name: "{feature-name}")`. This creates `.claude/worktrees/{feature-name}/` with a new branch based on HEAD and **switches the entire session** into it — all tools automatically operate in the worktree.
3. **Run the full normal ceremony** — same phases, same touchpoints, same rigor. **But all `.claude/` operations use absolute paths to `MAIN_DIR`:**
   - Read spec: `{MAIN_DIR}/.claude/specs/{feature}.md`
   - Check off criteria: edit spec at `{MAIN_DIR}/.claude/specs/{feature}.md`
   - Session log: `{MAIN_DIR}/.claude/session.log`
   - Feedback: `{MAIN_DIR}/.claude/feedback.md`
   - Backlog: `{MAIN_DIR}/.claude/backlog.md`
   - Archive: `{MAIN_DIR}/.claude/specs/archive/`
   - Code operations (source files, tests, commits) use the worktree CWD normally.
4. At close-out, after the build is complete and user has reviewed the report:
   - Narrate: "Build complete in worktree on branch `{branch-name}`. Merge to main when ready, or leave for now."
   - Do NOT auto-merge — the user controls when worktree branches get merged
5. **Exit worktree** using `ExitWorktree(action: "keep")` — returns session to original directory, worktree stays on disk for merge later. Or `ExitWorktree(action: "remove")` if the user wants to clean up (will refuse if uncommitted changes exist).

> **The ceremony is identical.** Worktree execution doesn't change any /do behavior — same TDD, same subagents per criterion, same validation, same close-out. Code lives in the worktree, state lives in the main directory. You stay hands-on with full override and pivot capability.

### After selecting a spec:
1. Set spec status to `building`
2. Read every file in the spec's Files section
3. Read the session log entry referenced by the spec's Session field
4. Read spec accuracy entries from feedback.md for related areas
5. **Detect mode:** `## Execution Plan` present → **wave mode**. Otherwise → **sequential mode**

---

## Sequential Mode (default)

The spec's Done Criteria is your task checklist. Work through it in order. **Each criterion is built by a subagent, validated by main context.**

### Per-Criterion Loop

For each Done Criteria item:

**1. Pre-flight (main context)**

Prepare the subagent prompt following the Subagent Execution Model:

```
You are implementing a single feature criterion for {feature-name}.

## Criterion
{the specific Done Criteria item being built}

## Context
{spec approach, key decisions, constraints — relevant excerpts}

## Source Files
{literal file contents for every file the subagent needs to read or modify}

## Interfaces
{exact type definitions, function signatures, data shapes}

## Rules
- TDD: write a failing test FIRST, then implement, then refactor
- Write the simplest implementation that passes. Do not optimize, do not add adjacent functionality
- Fix all visible issues in files you touch — lint, types, pre-existing bugs (while-we're-here rule)
- When a command rejects an action, STOP and report. Never use --force or --no-verify
- Do NOT commit — the orchestrator handles commits
- If reality diverges from the spec, write a PROBLEM note and stop — do not improvise
- Use `sg` (ast-grep) via Bash for structural code search — finding function signatures, call sites, class definitions, decorator usage. Prefer over grep when nesting/whitespace would defeat regex. Example: `sg -p 'def $FUNC($$$ARGS)' -l py` to find Python function definitions

## File Ownership
Modify: {specific files}
Read-only: {specific files}

## Test Command
{exact command to run tests}
```

**2. Execute (subagent)**

Spawn the subagent. It runs the TDD cycle:
- **Red** — write a failing test. Run the suite. Confirm correct failure reason
- **Green** — simplest implementation that passes
- **Refactor** — clean up + while-we're-here fixes

**3. Post-flight (main context)**

Run the full validation protocol from the Subagent Execution Model:
- Read every modified file
- Run full test suite (not just new tests)
- Cross-reference against the criterion
- Type check and lint
- **Behavioral regression scrutiny** — changed existing behavior? Modified existing tests? Scope creep? Silent regressions?

**Autonomous retry loop (max 3 attempts):**

If tests or lint fail after a subagent's work:

1. **Attempt 1:** Analyze the failure. If it's a small fix (import, typo, type error, off-by-one), fix it directly in main context. Re-run tests.
2. **Attempt 2:** If still failing, re-spawn the subagent with the failure output appended to its prompt: "Previous attempt failed: {test output}. Fix the issue." Re-run post-flight.
3. **Attempt 3:** If still failing, log the failure context and **ASK the user**: "Criterion {X} failing after 3 attempts: {failure summary}. Investigate together, skip for now, or abort?"

Do NOT silently move to the next criterion with a failing test. Do NOT dismiss failures as "pre-existing" without user confirmation. The retry loop is autonomous — the escalation is not.

**4. Commit (main context)**

Only after all post-flight checks pass:
- Atomic commit: `feat(scope): describe behavior`
- Stage only files touched in this cycle
- Codebase must be working with all tests passing

**5. Check off (main context)**

Update the spec file: `- [ ]` → `- [x] {criterion} ← {short commit hash}`

> **Do NOT batch commits. Do NOT defer to end.** Each criterion gets its own commit.

Narrate: "Building: {criterion}. Subagent complete → Post-flight passed → Committed {hash}."

Move to next Done Criteria item. Repeat.

---

## Wave Mode (parallel)

For specs with `## Execution Plan`. Execute waves in order, tasks within each wave in parallel.

### Wave Loop

For each wave:

**1. Spawn sub-agents** — one per task:

```
You are building task {T[N]} for feature {feature-name}.

## Your Task
{task description from execution plan}

## File Ownership
Modify (yours exclusively): {files from Tasks table}
Read-only (shared): {files from Tasks table}

## Contracts
{Pasted interface definitions from Contracts section — exact code, not descriptions}

## Done Criteria (your scope)
{The specific Done Criteria items this task maps to}

## Rules
- Write tests first, then implementation
- Only modify files in your ownership list
- Fix pre-existing issues in files you own (while-we're-here rule)
- Do NOT commit — the orchestrator handles commits
- If you hit a divergence, write a PROBLEM note and stop — do not improvise
```

**2. Collect** — wait for all agents. Each returns working code + tests or a PROBLEM note.

**3. Integration pass** — read all changes, check post-wave mismatch zones (import paths, interface boundaries, shared state), run full test suite, fix integration issues.

**4. Commit** — one per completed task: `feat(scope): add X (T1)`. Integration fixes: `fix({feature}): resolve wave {n} integration`.

**5. Check off** — update spec Done Criteria for completed items.

**6. Handle failures** — classify via divergence protocol. Blocks next wave → pause. Isolated → continue, report gap at end.

**7. Next wave.**

---

## Handling Divergence

Divergence detection is **structural, not optional.** It happens during post-flight validation — when main context compares subagent output against the spec. You cannot skip divergence detection because it's part of the validation you're already required to run.

> **The old system relied on /do self-detecting divergences during the build. /do's forward-progress bias meant it almost never did. The new system catches divergences structurally: post-flight comparison against spec is mandatory, and any mismatch IS a divergence.**

### Where Divergences Surface

1. **Post-flight validation** — you read the subagent's output and compare against the spec. Mismatch? That's a divergence.
2. **Subagent PROBLEM notes** — the subagent couldn't proceed and reported why. That's a divergence.
3. **Test failures** — tests fail in ways the spec didn't predict. That's a divergence.

### How to Handle

```
Mismatch found during post-flight
│
├─ Can I fix this in main context without a judgment call?
│  (import path differs, file renamed, trivial mismatch)
│  └─ FIX — fix it, log as AMENDED in session log, surface in build report
│
├─ Needs a decision from the user?
│  └─ ASK — pause, AskUserQuestion, log as DECISION:, continue
│
└─ Subagent returned PROBLEM or multiple criteria hit the same mismatch?
   └─ STOP — the approach is broken. See below.
```

Two paths, not four. The decision is binary: **can I handle this, or do I need you?**

### FIX — handle it, log it

Mismatch is clear and the correct resolution is obvious. Fix in main context. Log:

```markdown
- AMENDED: {what differed from spec and how it was resolved}
  CRITERION: {which Done Criteria item}
  RATIONALE: {why the fix is clearly correct}
```

All fixes are surfaced collectively in the build report.

### ASK — needs user judgment

**Trigger list — if ANY of these apply, ask:**
- Spec approach doesn't fit actual code shape (e.g., spec says add column, should be join table)
- Interface/API/data structure differs from spec's assumption
- Implementation requires coupling to something spec didn't account for
- Trade-off the spec didn't address (performance vs simplicity, sync vs async)
- Tests fail suggesting wrong approach, not wrong implementation
- File doesn't exist that spec says to modify (don't just create it — ask why it's missing)
- Spec's behavioral assumption is wrong
- **You're reasoning about whether it's "close enough"** — that means it's not close enough. Ask.

Pause. Present via AskUserQuestion with structured options. Log:

```markdown
- DECISION: {what was decided}
  CRITERION: {which Done Criteria item}
  OPTIONS: {what was considered}
  CHOSEN: {what was picked and why}
```

Continue building.

### STOP — approach is broken

The subagent returned a PROBLEM note indicating the spec's approach doesn't work, OR multiple criteria hit the same root mismatch.

**Partial block:** If the divergence blocks some criteria but others are independent, continue building the independent ones. Report at end: "Completed {n} of {m} criteria. {blocked criteria} need re-speccing because {reason}."

**Full block:** If the divergence blocks everything downstream, halt the build.

In either case, write a structured BLOCKED entry in the session log:

```markdown
- BLOCKED: {what diverged and why the approach doesn't work}
  CRITERIA: {which Done Criteria items are blocked}
  INDEPENDENT: {which criteria can still proceed, or "none"}
  ROOT: {the fundamental mismatch — what the spec assumed vs what's true}
  OPTIONS: {possible alternative approaches, if you can see them}
```

Set spec status to `blocked`. Tell user: "The spec's approach doesn't fit reality because {reason}. Need to re-spec via /think."

### Backlog — only for genuinely large work

Out-of-scope work **not in files you're touching** AND **over an hour to fix**: `- [ ] {what} — context: {why} ({date})` in `.claude/backlog.md`.

If the issue IS in a file you're touching → while-we're-here rule applies. Fix it.

> **Never silently backlog.** If you think something should go to backlog, narrate why and let the user decide. A single-line fix, a missing type annotation, a lint warning — these NEVER go to backlog regardless of scope.

---

## Validation

> **Stop building. Validation mode.**

When all Done Criteria are checked off and tests pass, validate.

### Quality Gates (pre-agent)

Run silently — fix any failures before spawning agents:
- [ ] All tests pass
- [ ] No security flags (secrets, injection, auth gaps)
- [ ] Linted and formatted
- [ ] Follows existing codebase patterns
- [ ] Type checks pass (for Python: `uv tool run basedpyright` on modified files)

### Spawn Three Agents (all in a single message)

**1. Verifier** (`subagent_type: "harambe:verifier"`):
```
Verify the build for feature '{feature-name}'.
Spec path: .claude/specs/{feature}.md
Test command: {test command}
Session log summary: {PROBLEM/FIX entries, adaptations, amendments, inline decisions}
```

**2. Build Security** (`subagent_type: "harambe:build-security"`):
```
Security scan for feature '{feature-name}'.
Spec path: .claude/specs/{feature}.md
Files created or modified: {file list}
```

**3. Build Regression** (`subagent_type: "harambe:build-regression"`):
```
Regression check for feature '{feature-name}'.
Spec path: .claude/specs/{feature}.md
Files created or modified: {file list}
Test command: {test command}
```

### Wait for All Agents

> **Do NOT proceed until all three agents have returned.** Read each agent's full output before synthesizing.

### Verdict Synthesis (autonomous)

1. **SECURITY-HOLD** → fix immediately. Do NOT proceed until resolved. Re-run agents after fix.
2. **GAPS** → fix if possible. If the fix requires a design decision → ask the user.
3. **PASS-WITH-DRIFT** → note in build report. Proceed.
4. **PASS** → proceed.

Narrate: "Validation: {verdict}. {details if not clean PASS}."

> **Do NOT ask the user about PASS or PASS-WITH-DRIFT.** These are mechanical. Proceed to simplify.

---

## Simplify Pass

Use the **Skill tool** to invoke `/simplify`. Pass the list of files modified during the build.

```
Skill: "simplify"
```

Narrate: "Running /simplify on {file list}."

The /simplify skill will review for reuse opportunities, quality issues, and efficiency improvements. Apply all recommendations that improve code quality (deduplication, naming, structure). If a recommendation would change behavior (not just quality), skip it and note why.

> **If simplify changes any code, the quality re-run is mandatory.** See next phase.

---

## Quality Re-run (conditional)

> **This phase exists because of a hard rule: quality gates run after the LAST code change.**

If the simplify pass (or any other post-validation step) changed code:

1. Run full test suite
2. Run type checks on modified files
3. Run lint
4. Fix any new issues
5. If fixes introduce more changes → repeat until stable

If no code changed since validation, skip this phase.

Narrate: "Post-simplify quality re-run: {pass/all clean}." or "Post-simplify quality re-run: found {N} issues, fixed."

---

## Build Report

> **The report comes BEFORE close-out.** This is your review point — you can push back on anything here before it gets archived.

Present a structured summary. Include enough detail that the user can challenge decisions:

```
─── /do Report ────────────────────────────

Feature: {name}
Spec: .claude/specs/{feature}.md

Criteria Built:
  [x] {criterion 1} ← {hash}
      Files: {files touched}. Tests: {N} added.
  [x] {criterion 2} ← {hash}
      Files: {files touched}. Tests: {N} added.
  ...

Divergences:
  - FIX ({N}):
    - {what differed} → {how resolved} (criterion: {which})
    - ...
  - ASK ({N}):
    - {decision made} — chose {option} over {alternatives} because {reason}
    - ...
  - STOP: {blocked criteria, if any}

While-We're-Here Fixes:
  - {file}: {what was fixed} ({lint/type/pre-existing bug})
  - ...

Validation: {verdict from verifier/security/regression agents}
  - Verifier: {summary}
  - Security: {summary}
  - Regression: {summary}

Simplify: {N} changes applied — {summary of what changed}
Quality Re-run: {pass/clean or details}

Commits: {count} commits, {insertions}+ {deletions}-
Autonomy: {N} auto-decisions, {M} user-decisions

→ Proceed to ship?
────────────────────────────────────────────
```

> **Wait for user acknowledgment before proceeding to Ship.** The user can push back ("revert that divergence fix", "don't archive yet", "re-check criterion 2"). If the user says nothing or confirms, proceed.

---

## Ship

> **Push the branch and create the PR.**

### Steps

1. **Push branch** to remote: `git push -u origin {branch}`
2. **Create PR** via `gh pr create`:
   - Title: conventional commit format matching the feature
   - Body: spec summary + done criteria checklist + test plan + `Co-Authored-By:` line
   - Link to issue: body includes `Closes #{issue}` or use `gh issue develop` relationship
   - Labels: set type label if applicable
   - Assign: `--assignee @me`
3. **Verify** PR created: `gh pr view {N} --json number,url`
4. **Append to session log**: `- SHIPPED: PR #{N} created, linked to issue #{I} ({date})`
5. **Narrate**: "PR #{N} created: {url}. Running blind review."

> **Mandatory:** Every PR MUST be linked to an issue. If no issue exists, ask the user before proceeding.

### Worktree Considerations

If building in a worktree:
- Push happens from the worktree (the branch lives there)
- PR creation happens from the worktree
- `.claude/` operations still use `MAIN_DIR` absolute paths (session log, specs, feedback)

---

## PR Review

> **Blind parallel code review — same-session, no anchoring.**

Use the **Skill tool** to invoke `/pr-review`. Pass the PR number from the Ship phase as the argument.

```
Skill: "pr-review"
Args: "{PR_NUMBER}"
```

Narrate: "Running /pr-review on PR #{N}."

**OVERRIDE:** After /pr-review completes, ignore its standalone "Next Steps." Resume the /do pipeline at Address Findings.

Narrate: "PR review complete: {X} critical, {Y} warning, {Z} nit."

---

## Address Findings

> **Fix review findings in severity order.**

### Triage

| Severity | Action |
|----------|--------|
| **Critical** | Fix immediately. These block merge. |
| **Warning** | Fix if straightforward (< 30 min). If fix requires design decision → ASK user. |
| **Nit** | Fix if trivial (< 5 min). Otherwise skip — note as "acknowledged, deferred." |

### Zero Findings

If /pr-review returned 0 critical and 0 warning: skip this phase entirely. Narrate "Clean review — no findings." Proceed to Close Out.

### Execution

For each finding being addressed:
1. Fix the code
2. Run targeted tests for the affected area
3. Stage and commit: `fix(scope): address review — {brief description}`

After all fixes:
1. Push to PR branch
2. Post follow-up comment on PR: "Addressed {N} of {M} findings: {summary of what was fixed}."

### Quality Re-run (post-review)

If ANY code was changed during Address Findings:
1. Run full test suite
2. Run type checks on modified files
3. Run lint
4. Fix any new issues
5. Push if additional fixes made

If no code changed (all findings were nits that were skipped), skip.

Narrate: "Post-review quality re-run: {pass/details}."

### Session Log

Append: `- REVIEWED: {X} critical, {Y} warning, {Z} nit — addressed {N} ({date})`

---

## Close Out

> **Runs after review findings are addressed (or skipped).**

### Merge

Before any bookkeeping, ship the code:

1. **Verify CI** — `gh pr checks {N} --watch` (wait for all checks to pass)
2. **Confirm with user** — "All checks green. Squash merge PR #{N}?"
   - If user confirms → squash merge: `gh pr merge {N} --squash --subject "{conventional commit} (#{N})" --body "{summary}" --delete-branch`
   - If user declines → note in session log: `- POST: merge deferred by user ({date})`. Proceed with remaining close-out steps.
3. **Post-merge** (if merged):
   - Switch to main: `git checkout main && git pull`
   - Verify local main matches remote
   - Clean up local branch if it still exists
   - Append to session log: `- MERGED: squash merge {hash} to main ({date})`

> **Confirmation gate:** Merge is the ONE step that always asks. Everything else in /do is autonomous. This is the point of no return.

### Extract Learnings

Spawn the `learn` agent (**foreground, not background**). Pass feature name and session log entry ID:

```
"Analyze entries for feature `{feature}`, most recent entry ID `{feature}.{n}`."
```

**Wait for it to return.** Present its proposals (if any) to the user for approval. If approved:

> **Write to the PROJECT's CLAUDE.md file** — the one in the project root or `.claude/CLAUDE.md` — under a `## Patterns & Gotchas` section (create it if it doesn't exist). Format: `- **{Bold label}:** {Actionable rule} — {why}`
>
> **Do NOT write to:** memory files (MEMORY.md or memory/*.md), architecture docs, README files, or any other location. CLAUDE.md is always-loaded context — patterns there are visible in every session automatically. Memory and docs are selectively loaded, which means a critical pattern might be missed.

### Write Feedback

Append to `.claude/feedback.md` (create with section headers if it doesn't exist):

**Spec Accuracy** — for each FIX, ASK, or STOP from this build:
```markdown
- [{date}] {feature}: {what the spec got wrong and how it was resolved}
```
Cap at 15 entries. Prune oldest when adding new ones.

**Autonomy Table** — two kinds of entries, same table:

*Decision entries* — tracks auto-decision calibration:
- Increment `+` for decisions where user confirmed or rubber-stamped
- Increment `-` for decisions where user chose differently, record the reason
- If a decision type crosses the auto-approval threshold (mechanical: 2, judgment-light: 3), set `Auto` to `yes`
- If user overrides an auto-approved type, reset `Auto` to `no` and zero the counters

*Correction entries* — tracks behavioral violations the user had to catch:
- When the user corrects agent behavior (interrupts, says "you missed X", "don't skip Y"), add or update a row **immediately** — don't defer to close-out. Correction signal is too valuable to lose to a crash.
- Increment `-` for each violation. Record what happened concretely
- Both phases read these at orient: "I've violated {behavior} {N} times — be extra vigilant here"
- Narrate the vigilance: "Checkpoint checklist (reminder: I missed step 2 last time — running it now)"

```markdown
## Autonomy
| Behavior                  | Type       | Auto | +  | -  | Last -                                          |
|--------------------------|------------|------|----|----|--------------------------------------------------|
| archival                 | decision   | yes  | 4  | 0  | —                                                |
| quality-gate-suggestions | decision   | no   | 2  | 1  | "skip the naming nit"                            |
| checkpoint-before-merge  | correction | —    | —  | 1  | "jumped to merge without checking branch status" |
| while-we're-here         | correction | —    | —  | 3  | "skipped pyright errors in owned files"          |
```

**Patterns** — add learn agent's approved proposals to the Patterns staging area.

### Archive

1. Create `.claude/specs/archive/` if needed
2. Add `**Completed:** {date}` to spec metadata
3. Move spec + research briefs to `.claude/specs/archive/`

### Update Session Log

1. Status → `complete`
2. Append: `- VALIDATED: {verdict} | {date}`
3. Append: `- COMMITTED: {list of commit hashes}`
4. If divergences: append summaries
5. Append: `- DONE: {summary of what was built}`

### Run Checkpoint Checklist

Before declaring done (this is the Checkpoint Hygiene rule):
1. Session log current? ✓ (just updated)
2. Branch up to date with main? → check, rebase if needed
3. CI passing? → check if remote is configured
4. PR reviews pending/addressed? → N/A if no PR yet
5. Quality gates green since last edit? ✓ (just verified)

### Session Log Post-Close Updates

> **The session log entry stays open for post-close activities.** PR reviews, rebases, CI fixes, and other post-session work get appended:

```markdown
- POST: {what happened after initial close-out} ({date})
```

Only consider the feature fully complete when ALL post-session activities are done. Update status at that point.

---

## Session Log

**At start:**

```markdown
<!-- id:{feature}.{n} | feature:{name} | phase:build | date:{YYYY-MM-DD} | status:in-progress -->
### Building {feature} — {brief description}

- SPEC: .claude/specs/{feature}.md
- ref:{discuss-entry-id}
- FILES: {list from spec}
- NEXT: {first Done Criteria item}
```

**During:** Append PROBLEM/ROOT/FIX, AMENDED, DECISION, BLOCKED lines as divergences surface during post-flight. Update NEXT after each criterion completes.

**At shipping:** Append SHIPPED, REVIEWED, MERGED checkpoints:

```markdown
- SHIPPED: PR #{N} created, linked to issue #{I} ({date})
- REVIEWED: {X} critical, {Y} warning, {Z} nit — addressed {N} ({date})
- MERGED: squash merge {hash} to main ({date})
```

**At completion:** Set status to `complete`. Append DONE, VALIDATED, COMMITTED. See Close Out section for full list.

**Post-close:** Append POST entries for any post-session activities. See Session Log Post-Close Updates.
