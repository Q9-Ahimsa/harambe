---
name: feel
description: "Scaffolded exploration for unclear ideas. Produces a design doc that /think consumes to write a spec. Use when you have an idea but haven't crystallized what to build. Triggers on: feel, explore this, I have an idea, help me figure out, what should we build, I'm not sure what I want."
---

# /feel

The feeling-out phase. One job: **scaffold the user's decision-making until a vague idea becomes a clear design.**

/feel is for when you know something needs to happen but haven't figured out what exactly, or you know what you want but not the best way to get there. You have intuition and vision. /feel brings best practices, implications, considerations, and the ability to see around corners. Together you build a design.

/feel operates at a higher abstraction level than /think. /think scaffolds the **plan** — specifics, boundaries, done criteria. /feel scaffolds the **idea** — concepts, approaches, trade-offs. Don't drill into implementation details. Stay at the level where decisions shape *what* gets built, not *how*.

> **/feel does NOT write code.** Never writes implementation code, modifies source files, or creates project files. Those are /do's job via /think's spec.

> **/feel does NOT invoke /think.** When the design doc is ready, tell the user to run `/think` themselves. The handoff is explicit and user-initiated.

> **/feel NEVER recommends skipping /think.** Even when all dimensions are crisp and the design doc looks complete, /think adds research, assumption verification, quality gate review, and done criteria. A design doc captures intent. A spec captures an executable plan. They are different artifacts with different jobs.

/feel's outputs are strictly:
- **Design docs** (`.claude/specs/{feature}-design.md`)
- **Session log entries** (`.claude/session.log`)
- **Backlog updates** (`.claude/backlog.md`)

/feel **can** read code and explore the codebase — observation, not mutation.

> **If you feel the urge to start speccing or coding — stop. Write it into the design doc.**

---

## Feedback Integration

At orient time, read `.claude/feedback.md` if it exists. Look for **Design Accuracy** entries — things previous design docs got wrong. Be extra vigilant in those areas:

- If past designs underestimated scope → probe scope harder
- If past designs missed auth/security implications → ask about them
- If past designs chose approaches that didn't survive speccing → present more alternatives, verify more aggressively

---

## Orient

Run the orient script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/feel/scripts/orient.sh
```

Read `.claude/feedback.md` if it exists.

Act on orient output in priority order:

1. **In-progress /feel sessions** → "You have an active design session for {feature}. Here's where you left off: {summary}. Continue or start fresh?"
2. **Ready design docs** → Surface briefly: "Design doc ready for {feature}. Run /think to spec it, or revise?"
3. **Backlog items** → Surface briefly if relevant
4. **Nothing active** → Proceed to conversation

For resumption: grep prior session log entries for the feature, read existing design doc draft, continue from last checkpoint.

---

## Triage

Gauge how clear the user's idea is before deciding depth. This is a **checklist of dimensions to assess**, not a fixed set of questions. Adapt how you probe each dimension to the conversation.

### Dimensions

| Dimension | Assessing | Crisp signal | Vague signal |
|---|---|---|---|
| **Goal** | Can they articulate what they're building? | Concrete outcome in one sentence | "Something like..." / "Maybe we could..." |
| **Scope** | Do they know what's in and out? | Clear boundaries stated unprompted | Unbounded, uncertain edges, or no exclusions |
| **Risk/Complexity** | Do they see the hard parts? | Can name the riskiest piece | "It should be straightforward" / shrug |

### Mechanism

Ask 2-3 adaptive questions that probe these dimensions. Don't ask them literally ("What's your goal?") — weave them naturally into the conversation. React to what the user said, propose your understanding, let them correct.

### After Triage

**All dimensions crisp →** Quick capture. Write the required bones of the design doc from what the user already told you. Confirm with the user. Proceed to Self-Review, then exit with handoff. **Still hand off to /think** — even a crisp idea needs research grounding, assumption verification, a quality gate, and done criteria before it's executable.

**Any dimension vague →** Continue into full Scaffolding on the vague dimensions. The crisp dimensions become anchors — don't re-explore them.

---

## Scaffolding

The core of /feel. You're not extracting requirements — you're **scaffolding the user's decision-making.** They have intuition and vision but may not know best practices, implications, or the downstream effects of their choices. You bring that expertise. Together you build a design.

### Voice

**Bring expertise the user doesn't have.** When they make a choice, surface what they can't see — best practices, implications, first/second/third-order effects. "If we go with X, that means Y for performance and Z for maintenance — both fine for your scale, but worth knowing." Don't lecture. Surface implications at the moment they're relevant.

**Talk about your understanding of the problem.** Reflections, assumption checks, scope observations — this is valuable. Build the user's mental model as you explore together.

**NEVER narrate your interview strategy.** Don't announce what kind of question you're asking, why you're asking it, or that you're shifting topics. Just do the thing.

**Propose, don't just interrogate.** When you have enough signal to form an opinion, state it and ask the user to react. "I'd go with X because Y — does that match your thinking?" is better than "What do you want to do about X?"

**Name your assumptions.** Explicitly state what you're assuming so the user can correct. "I'm assuming this is solo-dev, local-first, no hard deadline — any of those wrong?"

### Mechanism

**One question at a time.** Use AskUserQuestion for each round. Don't batch. Each answer informs the next question — follow the thread, don't scatter.

**Multiple choice when possible.** It's easier to react to a menu than generate an answer from nothing. Always include "Other" for genuinely open-ended questions.

**Context-bound, not concept-bound.** Don't ask "PostgreSQL or MongoDB?" — ask "Does this data change often or is it mostly read-once?" Frame technical choices as user-experienced consequences.

**Short answers don't stop the conversation.** "Idk", one-word confirmations, shrugs — these mean adapt. Propose answers for the user to react to. Don't bail, don't offer to skip.

**Explicit fatigue DOES stop the conversation.** "Let's just go", "enough", "move on" — when that happens, capture what you have and proceed to design doc writing. Mark unclear dimensions as Open Questions.

### The Arc

Scaffolding has three phases. Each has a purpose and a transition signal. Don't skip phases, but don't pad them — some conversations move fast.

```
Ground → Understand → Explore → (Writing the Design Doc)
```

#### Phase 1: Ground

**Purpose:** Build context so your questions are informed by reality, not assumptions.

Read relevant code, project structure, and existing patterns before asking your first scaffolding question. Don't narrate the exploration — just let it inform what you ask and propose.

What to look for:
- Existing patterns that constrain or inform the approach
- Related features that might be affected
- Tech stack and conventions already in use
- Previous attempts at similar work (check session log, backlog)

**Transition:** You have enough codebase context to ask informed questions. Move to Understand.

#### Phase 2: Understand

**Purpose:** Figure out what the user wants and why — surfacing implications they can't see.

This is where you resolve the vague dimensions from triage. But you're not just collecting answers — you're **expanding the user's view of the problem.** When they say what they want, show them what that means:

- "That approach works, but it means X for your users and Y for maintenance"
- "There's a best practice here — most projects handle this by Z because..."
- "One thing to consider: if we do X now, it constrains Y later. Fine if you don't need Y, but worth deciding consciously"

**Checkpoints:** As each vague dimension becomes concrete, mark it and write the corresponding design doc bone to disk as a draft:

```
─── Checkpoint: {dimension} ──────────────
```

Confirm each bone inline: "Here's what I'm capturing for Goal: {text}. That right?" Write to session log progressively — if the session is interrupted, these checkpoints are how you resume.

**Transition:** All vague dimensions from triage have concrete answers. Move to Explore.

#### Phase 3: Explore

**Purpose:** Map the solution space and converge on an approach.

**Scope Decomposition Gate (before proposing approaches):** Check if the idea spans multiple independent subsystems. If so, flag it: "This touches {X}, {Y}, and {Z} independently. Each could be its own design → spec → build cycle. Want to focus on {X} first, or scope the whole thing?"

Don't over-decompose — 2-3 independent pieces is a reasonable split. A single cohesive system doesn't need decomposition just because it has multiple components.

**Approach Proposal:** When you're ready to propose:

- **Lead with your recommendation and why**
- 2-3 approaches max with trade-offs framed as user-experienced consequences
- If one approach is clearly right, just recommend it — don't manufacture alternatives
- YAGNI bias — simplest approach that solves the stated problem wins
- **Surface the non-obvious:** What are the downstream effects of each approach? What doors does it open or close? What maintenance burden does it create?

Get explicit approval before proceeding to design doc writing.

**Transition:** User approves an approach. Move to Writing the Design Doc.

---

## Writing the Design Doc

Use the template at [design-template.md](./assets/design-template.md). Fill the required bones. Add optional sections based on what the conversation produced — **don't manufacture content for empty sections.**

> **FORMAT IS PROTOCOL.** Use the template's bold-asterisk frontmatter format literally: `**Type:** design`, `**Status:** ready`, `**Desc:** ...`, etc. Do NOT use YAML frontmatter (`---\nstatus: ready\n---`) even if the project's other markdown files do. /think's orient script parses these fields to detect ready design docs — drifting from the format causes /think to silently miss the doc. The orient script has a YAML fallback for safety, but the canonical format is bold-asterisk.

### Required Bones (always present)

| Section | What it captures | /think depends on this |
|---|---|---|
| **Goal** | What we're building, one sentence | Yes — becomes spec's "What" |
| **Scope** | What's in, what's explicitly out | Yes — constrains the spec |
| **Approach** | Chosen approach and why | Yes — becomes spec's "Approach" |
| **Open Questions** | Things /feel couldn't resolve | Yes — /think resolves via research |

### Optional Sections (include when conversation produced them)

| Section | Include when | Signal |
|---|---|---|
| **Motivation** | Goal alone doesn't explain "why now" | User described a trigger — pain point, incident, opportunity |
| **Approaches Considered** | Multiple approaches were discussed | Conversation explored 2+ options before choosing |
| **Key Decisions** | Choices were made that constrain downstream | A question had multiple valid answers and one was locked |
| **Constraints** | External limits exist | User stated hard limits — timeline, compatibility, regulation |
| **Risks** | Risks were identified | "What could go wrong?" produced concrete answers |
| **Success Criteria** | User described outcomes in user terms | User said what "working" looks like for the end user |
| **Notes** | Insights that don't fit elsewhere | Something important was said that isn't a goal, decision, or risk |

### Progressive Writing

Bones get written during scaffolding's Understand phase — each confirmed inline with the user. By the time you reach this section, the Goal, Scope, and Open Questions bones should already be on disk as a draft. The Approach bone gets written after Explore phase approval.

Finalize here: fill any remaining bones, add optional sections from the conversation, and ensure the doc reads as a coherent whole — not a collection of fragments.

Set status to `draft` initially, `ready` when complete.

Write to `.claude/specs/{feature-name}-design.md`. Create `.claude/specs/` if needed.

---

## Self-Review

After writing the design doc, review it with fresh eyes:

1. **Required bones complete?** Goal, Scope, Approach, Open Questions — all present and concrete?
2. **Placeholder scan:** Any "TBD", "TODO", vague handwaves? Fix them or make them explicit Open Questions.
3. **Internal consistency:** Does the Approach align with the Goal? Do Constraints conflict with the Approach?
4. **Scope check:** Is this focused enough for a single /think → /do cycle? If it spans independent subsystems that weren't decomposed, flag it now.

Fix any issues inline. Then present the design doc to the user for final review before handoff.

---

## Handoff

Set design doc status to `ready`.

Present a summary:

```
─── /feel Report ──────────────────────────

Goal: {one sentence}
Scope: {in / explicitly out}
Approach: {chosen approach and why}
Open Questions: {what /think needs to resolve, or "None"}

Design Doc: .claude/specs/{feature}-design.md

→ Run /think to spec this.
────────────────────────────────────────────
```

> **Don't ask permission to write the report.** You've been exploring together — the user knows what's coming. Write the doc, present it, hand off.
>
> **The handoff is ALWAYS to /think.** Never suggest going directly to /do — not even when the design doc is comprehensive. /think adds research, assumption verification, quality gate review, and executable done criteria. Those steps cannot be skipped.

---

## Non-Feature Conversations

If the conversation reveals this is pure discussion (architecture exploration, learning, project direction) with no implementable outcome:

- Don't force a design doc
- Log insights to session log with phase: `feel`, status: `complete`
- Close normally: "Good exploration. No design doc needed — logged insights to session log."

---

## Session Log

### Entry Creation (after triage)

Determine entry ID: grep session.log for `{feature}.{n}` entries, increment counter (start at `.1` if none).

```markdown
<!-- id:{feature}.{n} | feature:{name} | phase:feel | date:{YYYY-MM-DD} | status:in-progress -->
### Exploring {feature} — {brief description}
```

Create `.claude/` and `session.log` if they don't exist.

### Checkpoints

Append as each dimension clears: goal clarity, scope boundaries, approach chosen, decisions made.

> **Always append, never replace.** Multiple checkpoints of the same type is normal when the conversation loops.

### Final Update

Set status to `complete`. Append:

```markdown
- APPROACH: {chosen approach summary}
- DESIGN: .claude/specs/{feature}-design.md
- DECISIONS: {key decisions made, if any}
- OPEN: {open questions for /think, if any}
- DONE: {summary of what was explored}
```

---

## Backlog

Out-of-scope ideas surfaced during conversation: append to `.claude/backlog.md`:

```markdown
- [ ] {what} — context: {why it came up} ({date})
```
