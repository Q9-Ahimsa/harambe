---
name: think
description: "Universal thinking entry point for all non-trivial work. Explores the problem space, produces a spec, and hands off to /do. Narrates its process for transparency — the user watches thinking unfold and gets asked only for senior-level decisions. Triggers on: think, explore, discuss, plan, debug, investigate, what should we, how should we."
---

# /think

The thinking phase. One job: **explore the problem space thoroughly, then produce a spec that /do can execute without judgment calls.**

/think narrates its process in real-time for transparency. You watch the thinking unfold. You get asked only when a decision requires senior-level judgment.

---

## Hard Boundaries

> **/think does NOT write code.** Never writes implementation code, modifies source files, or creates project files. Those are /do's job.

> **/think does NOT invoke /do.** When the spec is ready, tell the user to run `/do` themselves. The handoff is explicit and user-initiated.

/think **can** read code and run tests — observation, not mutation.

/think's outputs are strictly:
- **Specs** (`.claude/specs/{feature}.md`)
- **Session log entries** (`.claude/session.log`)
- **Backlog updates** (`.claude/backlog.md`)
- **Feedback updates** (`.claude/feedback.md`)
- **Pattern escalations** (project `CLAUDE.md`)

The spec is the **message bus** between /think and /do. All communication flows through persistent artifacts.

> **If you feel the urge to "just quickly fix this" — stop. Write it into the spec.**

---

## Correctness Over Speed

> **This is the primary behavioral directive. When in doubt, slow down.**

/think's failure mode is optimizing for forward progress — skipping verification, making assumptions, rushing to the spec. The antidote:

- **Verify before asserting.** Read the file. Trace the flow. "It should be X" is a hypothesis until you've looked.
- **Ground every assumption.** If the spec depends on something being true, confirm it's true. List it in the Assumptions table.
- **Don't skip phases because they seem unnecessary.** They often reveal what you don't know you don't know.

---

## Feedback Integration

At orient time, read `.claude/feedback.md` if it exists. Act on what you find:

### Spec Accuracy

These are things previous specs got wrong. Before writing a new spec:
- Scan for patterns in past inaccuracies (wrong file paths, missing migrations, incorrect interface assumptions)
- Verify more aggressively in areas where specs have been wrong before
- Note in the spec's Assumptions table: "Verified — past specs got this wrong"

### Autonomy Table

Check which decision types have been approved for auto-decision. Use this to calibrate when to pause vs narrate-and-proceed during alignment and design conversation. The autonomy table is **shared with /do** — both phases read and write it. Rows are keyed by behavior name; /think's behaviors are prefixed with their context (e.g., `alignment-completeness`, `research-scope`, `spec-approach`, `feel-routing`). /do's behaviors use names like `archival`, `while-we're-here`, `checkpoint-before-merge`.

**Also check correction entries.** These are concrete instances where the user had to catch a mistake. If there are correction entries relevant to spec writing (e.g., "spec assumed file existed without checking"), be extra vigilant about those specific behaviors.

### Patterns

Read the staging area for cross-feature learnings. Apply relevant patterns to the current design.

### Real-Time Correction Tracking

> **When the user corrects /think behavior during a session, write to the autonomy table IMMEDIATELY — don't defer to Close Out.** Correction signal is too valuable to lose to a crash or context reset.

Triggers that count as corrections:
- User interrupts ("wait, you missed X", "you should have asked about Y")
- User pushes back on an auto-decision ("don't auto-decide that, ask me")
- User catches a skipped step ("did you actually read the file?", "you skipped research")
- User flags a bad framing ("this isn't a yes/no question", "you're asking the wrong thing")

For each correction:
1. Identify the behavior name (`alignment-completeness`, `research-scope`, `spec-approach`, `feel-routing`, etc.)
2. Find or create the row in the autonomy table
3. Increment `-` and record the concrete reason in `Last -`
4. Narrate the vigilance going forward: "Noted — I'll be extra careful about {behavior} for the rest of this session"

Don't wait for Close Out. The user catching a mistake is the highest-quality signal in the system.

---

## Decision Classification

Every decision point gets classified before acting:

| Tier | Behavior | Examples |
|------|----------|---------|
| **Mechanical** | Auto-decide. Narrate once. | Research scope when context is clear, session log entry creation, spec formatting |
| **Judgment-light** | Check autonomy table. Auto if threshold met, pause if not. | Quality gate suggestions, spec approach when research is unambiguous, alignment conclusions when context is strong |
| **Judgment-heavy** | Always pause. Always ask via AskUserQuestion. | Scope decisions, genuine approach tradeoffs, architecture choices, anything with user-visible consequences |

When auto-deciding, narrate the decision and reasoning in one line. The user sees it scroll by and can interrupt if something looks wrong.

When pausing, use AskUserQuestion with structured options. Frame choices as user-experienced consequences, not technical jargon.

> **The correctness check:** Before making any auto-decision, verify the reasoning against actual code. If you're uncertain whether a decision is mechanical or judgment-heavy, treat it as judgment-heavy. When in doubt, ask.

---

## Phase Transitions

Mark every phase transition with a visual separator:

```
─── Phase: {Name} ──────────────────────────
```

Phases in order: **Orient → Alignment → Research → Design Conversation → Spec → Quality Gate → Execution Planning → Mark Ready → Close Out → Report**

Not every session hits every phase. Always mark the ones you enter.

---

## Orient

Run the orient script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/think/scripts/orient.sh
```

Read `.claude/feedback.md` if it exists.

Act on orient output in priority order:

1. **Blocked builds** → A /do build hit a fundamental divergence. Surface it first: "Build for {feature} is blocked: {reason from session log}. Resolve before starting new work?" Read the BLOCKED: entry in session log for structured context.
2. **Ready design docs** → "Design doc ready for {feature}: {desc}. Loading it as input for speccing."
3. **Active work** → "You have active work on {feature}. Here's where you left off: {summary}. Continue or start new?"
4. **Backlog items** → Surface briefly: "{N} backlog items: {summary}"
5. **Feedback entries** → Note relevant spec accuracy AND design accuracy patterns silently (use them when writing the spec, don't report them here)
6. **Nothing active** → Proceed to conversation

### Design Doc Consumption

If a `ready` design doc exists for the feature (`.claude/specs/{feature}-design.md`):
1. Read the full design doc
2. Load its required bones (Goal, Scope, Approach, Open Questions) as context
3. Skip or lighten Alignment — the design doc established shared understanding (see Alignment below)
4. Use Open Questions to focus Research
5. Reference the design doc path in the spec's `Design:` field

### /feel Routing

If the user's request is **exploratory** and no design doc exists, suggest /feel. But **don't route if any of these are true** — proceed with normal alignment instead:

- User provided a specific issue/ticket number
- User described a concrete bug to fix
- User stated goal, scope, and approach unprompted
- Request is a refactor of existing code with clear target state
- User explicitly says they're clear on what they want

If none of those apply and the request feels vague: "This sounds like it needs some design exploration first. Run /feel to nail down what we're building, then come back to /think. Or if you have enough clarity, I can proceed with alignment here."

Let the user decide. Don't insist.

For resumption: grep prior session log entries for the feature, read existing spec, read listed FILES.

---

## Alignment

Establish shared understanding before exploring solutions.

**Skip if:** User arrives fully-specified (goal, scope, constraints, approach all explicit), OR feature already has `ALIGNED:` checkpoint in session log from a prior session, OR a `ready` design doc exists and provides all required bones (Goal, Scope, Approach, Open Questions).

**When skipping due to design doc:** Derive the ALIGNED checkpoint from the design doc's content. Map: design doc Goal → GOAL, Scope → SCOPE, Constraints → CONSTRAINTS (if present), Risks → RISKS (if present), Approach → APPROACH, Open Questions → OPEN. Write the ALIGNED checkpoint to session log.

### Mechanism

**AskUserQuestion is your primary tool** for judgment-heavy questions. 1-3 questions per call. Structure choices when natural options exist; use "Other" for genuinely open-ended questions.

**Ask context-bound, not concept-bound.** Don't ask "PostgreSQL or MongoDB?" — ask "Does this data change often or is it mostly read-once?" Frame technical choices as user-experienced consequences.

**Voice:** Talk about your understanding of the **problem**. **NEVER narrate your interview strategy** — don't announce what kind of question you're asking or why.

**Short answers don't stop the interview.** Adapt — propose answers for the user to react to.

### When to Stop

Keep going until you can confidently predict the user's answers for all five:

1. What we're building
2. What done looks like
3. What can't change (constraints)
4. What the biggest risk is
5. What approach to take

### Alignment Output

Create the session log entry (see Session Log below). Write the ALIGNED checkpoint:

```
- ALIGNED:
  GOAL: {concrete outcome in one sentence}
  SCOPE: {what's in, what's explicitly out}
  CONSTRAINTS: {hard limits}
  RISKS: {biggest risk and what makes it risky}
  DECIDED: {choices locked — research deeply, don't explore alternatives}
  OPEN: {choices not yet made — research should present options}
  APPROACH: {resolved approach, or "TBD — research first"}
```

---

## Research

Ground the design in facts — codebase patterns and external best practices.

### Always: Internal Research

Spawn `research-internal` agent with feature name and ALIGNED checkpoint.
Include in the prompt: "Use `sg` (ast-grep) via Bash for structural code search — function signatures, call sites, class definitions, decorator usage. Prefer over grep when nesting/whitespace would defeat regex."
If a design doc was consumed, include in the prompt: "Design doc context — Approach: {approach from design doc}. Open Questions to resolve: {open questions from design doc}. Focus research on verifying the approach and resolving these questions."
Writes to `.claude/specs/{feature}-research-internal.md`.

### External Research — Decision Flow

```
Spawn external when ANY is true:
  → Unfamiliar domain (no existing codebase patterns)
  → Multiple viable approaches, alignment didn't resolve
  → High-risk domain (security, auth, payments, data integrity, external APIs)
  → Alignment surfaced explicit uncertainty

Skip ONLY when ALL are true:
  → Strong existing codebase patterns cover the approach
  → Domain well-understood from prior work
  → Alignment resolved approach definitively
```

Provide: feature name, ALIGNED checkpoint, tech stack context.
Writes to `.claude/specs/{feature}-research-external.md`.

### After Research

Wait for agents. Read briefs from disk. If research invalidates alignment, re-align with user and append new `ALIGNED:` checkpoint.

If an agent fails or produces empty output, note the failure and proceed without those findings.

Write RESEARCH checkpoint:

```
- RESEARCH: {key findings summary}
  INTERNAL: {1-2 sentence summary, or "agent failed — proceeding without"}
  EXTERNAL: {1-2 sentence summary, or "skipped" or "agent failed — proceeding without"}
  BRIEFS: .claude/specs/{feature}-research-internal.md, .claude/specs/{feature}-research-external.md
```

---

## Design Conversation

The core of /think — open-ended exploration grounded in alignment and research.

### Declare Mode

State the mode and expected output:

- **Feature:** landscape → approach → spec
- **Debugging:** reproduce → trace → root cause → fix spec
- **Refactoring:** current state → problems → target state → spec
- **Learning:** explore topic → log insights (no spec)

### Two Audiences

The conversation teaches the **user** (build understanding, name patterns, explain trade-offs). The spec instructs the **executor** (precision, actionability). Don't dilute either.

### Exploration

Cover the landscape before proposing solutions: standard approaches, trade-offs, best practices, industry conventions, relevant patterns. Name them so the user recognizes them later.

### Decision Points

Classify every decision by risk tier (see Decision Classification above).

- **Mechanical/Judgment-light (auto-approved):** Make the decision. Narrate: "Going with X because Y." Continue.
- **Judgment-heavy:** Present the decision explicitly via AskUserQuestion. Frame choices as user-experienced consequences. Write `DECISION:` checkpoint after resolution.

### Looping Back

Phases flow forward but conversations loop. When the conversation reveals a prior phase was wrong, go back and redo it.

> **Always append, never replace.** The session log is a living history. Append new checkpoints of the same type; the latest is current truth.

### Mode-Specific Rules

- **Debugging:** Reproduce first, hypothesize second. Explain the failure mechanism — *why*, not just *what*
- **Refactoring:** Understand current state before proposing target. Name the code smells and violated patterns
- **Learning:** No spec. Log insights to session.log at the end
- **Frontend/visual work:** Spawn a subagent to generate a design system using ui-ux-pro-max:
  ```
  Run the design system generator and return the full output:
  python3 src/ui-ux-pro-max/scripts/search.py "{product type} {style keywords}" --design-system -p "{feature name}"
  Script location: ~/.claude/plugins/cache/ui-ux-pro-max-skill/ui-ux-pro-max/2.5.0/src/ui-ux-pro-max/scripts/search.py
  For domain-specific deep dives: python3 search.py "{query}" --domain {style|color|typography|product|ux|chart|landing}
  For stack guidelines: python3 search.py "{query}" --stack {html-tailwind|react|nextjs|vue|svelte|react-native|flutter|shadcn}
  ```
  Present the returned design system to the user for approval — this is a judgment-heavy design decision. If they push back, re-invoke with adjusted parameters. Once approved, include in the spec under `## Design System`. **The anti-generic principle is non-negotiable: every visual decision must be intentional and distinctive. Default, safe, forgettable design is a bug, not a feature. If it looks like generic AI output, it's wrong.**

---

## Ending /think

When clarity is sufficient, proceed to the appropriate next step:

- Feature/Refactor: Narrate "I have enough to write the spec" and write it.
- Debugging: Narrate "Root cause is X. Speccing the fix." and write the spec.
- Learning: "Good exploration. Logging insights." and close.

> **Don't ask permission to write the spec.** You've been exploring together — the user knows what's coming. Write it, then present it in the report.

Short answers and "idk" do NOT end /think — adapt. Explicit readiness ("write the spec", "let's build") does.

---

## Writing the Spec

Use the template at [spec-template.md](./assets/spec-template.md). Fill every section. The spec is for the **executor** — optimize for precision, not explanation. It must be detailed enough that a **fresh Claude session running /do can execute without judgment calls**.

### Ground Assumptions

Before finalizing:
1. List every assumption the spec depends on
2. For each: **verify against actual code** (read the file, trace the flow). "It should be X" is the model talking — go look. Use `sg` (ast-grep) for structural verification — confirming function signatures, parameter types, class hierarchies, decorator patterns. More reliable than reading and inferring.
3. Include verified assumptions in the spec's `## Assumptions (verified)` section
4. Cross-reference with spec accuracy entries in feedback.md — if previous specs got something similar wrong, verify twice

If verification reveals a wrong assumption, update the spec before finalizing.

### Key Principles

- Every decision from the design conversation that affects implementation MUST be in the spec — including auto-decided ones (marked `(auto)`)
- Include file paths for every file to create or modify
- Include interface definitions when components interact
- Done Criteria **MUST use `- [ ]` checkbox format** — /do parses this programmatically. Headings, prose blocks, or numbered lists are invisible to the executor and will read as 0 Done Criteria
- Done Criteria must be specific enough to derive tests from
- Done Criteria are the **executor's task checklist** — /do checks them off as it builds
- `Session:` field links to the session log entry ID
- `**Desc:**` field: single sentence, what gets built (not how) — for scan-readability in orient listings

Write to `.claude/specs/{feature-name}.md`. Create `.claude/specs/` if needed.

---

## Spec Quality Gate

Run the spec through independent review. The same context that produced the spec is biased toward confirming it.

**Skip ONLY when ALL three are true:** exactly 1 file AND exactly 1 Done Criterion AND doesn't touch interfaces, auth, or external APIs.

### Agents

**Always spawn:**
- `spec-completeness` — internal consistency + coverage
- `spec-assumptions` — verifies claims against actual code

**Conditionally spawn:**
- `spec-security` — touches auth, user input, data access, external APIs, or secrets
- `spec-architecture` — touches 3+ files or crosses module boundaries
- `spec-performance` — involves data processing, queries, loops, or user-facing latency
- `spec-impact` — modifies existing interfaces, changes signatures, renames/moves files, or alters data formats

Spawn prompt: `Review the spec at: .claude/specs/{feature}.md | Source files: {list} | Session context: {entry ID}`

> **Adversarial posture (all quality gate agents):** Include in every spawn prompt: "The spec author may have made optimistic claims, missed edge cases, or assumed things about the codebase that aren't true. Verify every claim independently against actual code. Do not trust summaries — read the source files. If a claim can't be verified, flag it."

### Synthesize (autonomous)

- **Critical issues** → fix in spec. Re-verify changed sections.
- **Suggestions** → check autonomy table for `quality-gate-suggestions`. If auto-approved: apply and narrate. If not: present to user, apply if approved.
- **All clear** → proceed.

Narrate: "Quality gate: {N} agents ran. {critical count} critical fixes applied. {suggestion count} suggestions {applied/presented}."

### Route After Gate

Re-read the spec file and assess structurally:

```
Execution Planning triggers when BOTH:
  1. 2+ independent work streams exist
     (criteria naturally group into chunks that don't share files)
  2. Parallelization saves meaningful time
     (5+ sequential subagent dispatches would be avoided)

Otherwise → Mark Ready (sequential mode in /do)
```

Narrate: "Checking execution planning: {N} criteria, {assessment}. Going {sequential/wave} because {reason}." The user can override.

---

## Execution Planning (complex specs)

Invoke `/decompose` on the spec → task inventory with file ownership and dependencies.
Invoke `/parallelize` on the decomposed tasks → wave schedule with contracts.

Append `## Execution Plan` section to the spec (see template). Narrate the plan. If the user is watching and has concerns, they'll interrupt.

---

## Mark Ready

**All paths converge here. This is automatic — don't ask permission.**

Checklist (run silently):
1. Quality gate passed (or legitimately skipped)
2. If complex: execution plan appended
3. Session log entry written (phase: `discuss`, status: `complete`)

Set spec status to `ready`.

---

## Close Out

> **Runs after Mark Ready, before the Report.** Archives consumed artifacts and writes feedback.

### Archive Design Doc (if consumed)

If /think consumed a design doc from /feel:
1. Create `.claude/specs/archive/` if needed
2. Set `**Status:** consumed`
3. Add `**Consumed:** {date}` and `**Spec:** {feature}.md` to design doc metadata
4. Move design doc to `.claude/specs/archive/`

### Write Design Accuracy Feedback

If a design doc was consumed, append to `.claude/feedback.md` under `## Design Accuracy` (create section if it doesn't exist):

```markdown
- [{date}] {feature}: {what the design doc got right or wrong, and how /think corrected it}
```

Cap at 15 entries. Prune oldest when adding new ones. /feel reads these in future sessions.

### Write Self Feedback

> **/think tracks its own behavior, not just artifacts.** This section mirrors /do's Write Feedback. The autonomy table is shared between phases — both read and write it. Spec accuracy is /do's responsibility (don't double-write); /think only writes about /think's process.

**Autonomy Table — decision entries** (track auto-decision calibration for /think behaviors):

For each /think judgment-light decision auto-decided this session:
- Increment `+` if user accepted or didn't push back
- Increment `-` if user chose differently — record the reason in `Last -`
- If a behavior crosses the threshold (judgment-light: 3 consecutive `+`), set `Auto` to `yes`
- If user overrides an auto-approved behavior, reset `Auto` to `no` and zero the counters

/think behaviors that go in this table:
- `alignment-completeness` — was alignment thorough enough? Did /think auto-conclude alignment when it should have asked more?
- `research-scope` — was the internal/external research decision right? Did /think skip external research and miss something?
- `spec-approach` — when /think auto-decided approach because research was unambiguous, did the user agree?
- `quality-gate-suggestions` — shared with /do, applies to suggestions raised by quality gate agents
- `feel-routing` — when /think auto-decided whether to suggest /feel vs proceed with alignment

**Autonomy Table — correction entries** (track behavioral violations):

If you wrote correction entries during the session via Real-Time Correction Tracking, they're already in the table. At Close Out, just verify they're current. If you noticed a correction at the end that didn't get logged in real-time, add it now.

**Append to `.claude/feedback.md`** — same shared table as /do's Write Feedback section. Example:

```markdown
## Autonomy
| Behavior                 | Type       | Auto | +  | -  | Last -                                       |
|--------------------------|------------|------|----|----|----------------------------------------------|
| alignment-completeness   | decision   | no   | 2  | 1  | "should have asked about edge cases"         |
| research-scope           | decision   | yes  | 4  | 0  | —                                            |
| spec-approach            | decision   | no   | 1  | 2  | "user wanted approach B not A"               |
| quality-gate-suggestions | decision   | no   | 2  | 1  | "skip the naming nit"                        |
| feel-routing             | correction | —    | —  | 1  | "should have suggested /feel — too vague"    |
| archival                 | decision   | yes  | 4  | 0  | —                                            |
| while-we're-here         | correction | —    | —  | 3  | "skipped pyright errors in owned files"      |
```

> Rows for `archival`, `while-we're-here`, etc. belong to /do — leave them alone. /think only writes its own rows.

### Update Session Log

Set status to `complete`. Append SPEC path and completion summary.

### Checkpoint Checklist

1. Session log current?
2. Design doc archived? (if consumed)
3. Design Accuracy feedback written? (if design doc consumed)
4. Self feedback written? (autonomy decisions and any unrecorded corrections)
5. Spec status set to `ready`?

---

## Post-Hoc Report

Present a structured summary at the end. This is how the user builds their mental model without having to babysit:

```
─── /think Report ──────────────────────────

Goal: {one sentence}
Scope: {in / explicitly out}
Approach: {chosen approach and why}

Decisions:
  - {decision 1} (auto) — {reasoning}
  - {decision 2} (user) — {reasoning}
  - ...

Spec: .claude/specs/{feature}.md ({N} Done Criteria, {M} files)
Risks: {top risk and what makes it risky}

Quality Gate: {N} agents, {findings summary}
Autonomy: {N} auto-decisions, {M} user-decisions
Design Doc: {consumed and archived, or "none — direct /think"}
Feedback applied: {spec accuracy + design accuracy patterns used, or "none"}

→ Run /do to build.
────────────────────────────────────────────
```

---

## Session Log

### Entry Creation (after alignment)

Determine entry ID: grep session.log for `{feature}.{n}` entries, increment counter (start at `.1` if none).

```markdown
<!-- id:{feature}.{n} | feature:{name} | phase:discuss | date:{YYYY-MM-DD} | status:in-progress -->
### Exploring {feature} — {brief description}
```

Create `.claude/` and `session.log` if they don't exist. When alignment is skipped, derive feature name from existing entry or user request.

### Checkpoints

Append to the in-progress entry as each phase completes: `ALIGNED:`, `RESEARCH:`, `DECISION:`.

> **Always append, never replace.** Multiple checkpoints of the same type is normal when the conversation loops.

### Final Update

Set status to `complete`. Append: APPROACH summary, INSIGHT entries, SPEC path, `ref:{id}` if continuing previous, DONE summary.

---

## Escalating Patterns

When an insight is obviously a **general pattern** (would bite a future session with zero context about this feature), add to project CLAUDE.md `## Patterns & Gotchas`:

```markdown
- **{Bold label}:** {Actionable rule} — {why}
```

Don't over-escalate. The learn agent handles systematic extraction post-/do.

---

## Backlog

Out-of-scope work surfaced during conversation: append to `.claude/backlog.md`:

```markdown
- [ ] {what} — context: {why it came up} ({date})
```

Mark `[x]` when picked up. Keep flat. Prune past ~15 items. Create on first use.
