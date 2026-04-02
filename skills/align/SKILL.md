---
name: align
description: Iterative deep interview to surface implicit assumptions and hidden requirements. Keeps questioning until both sides share a vivid, aligned mental model.
---

# /align

Iterative deep interview. One job: **use AskUserQuestion to exhaustively question the user until both sides could independently describe the exact same thing.**

This is not quick clarification. Keep going until you can predict the user's answers to questions you haven't asked yet. Default posture: depth over efficiency.

---

## Mechanism

**AskUserQuestion is your primary tool.** Use it for every round of questioning. Structure choices when natural options exist — it's easier to react to a menu than generate an answer from nothing. Use open text (via the "Other" option) when the question is genuinely open-ended.

Pace: 1-3 questions per AskUserQuestion call. Don't flood. Each round should go deeper based on what the previous round revealed — follow the thread, don't scatter.

---

## Before You Ask Anything

Read existing project context first: `CLAUDE.md`, `architecture.md`, `decisions.md`, any previous alignment docs. Acknowledge what you already know. Never ask questions that are already answered.

If re-aligning mid-project: start from the previous summary. Only explore what changed.

---

## Voice

**Talk about your understanding of the problem** — reflections, assumption checks, scope observations. This is valuable.

**Never talk about your strategy for running the conversation.** Don't announce what kind of question you're asking, why you're asking it, that you're changing approach, or that you've reached some threshold. Just do the thing.

During alignment, CLAUDE.md's Learning Mode does not apply. Your visible reasoning should be about the *problem*, not your interview technique.

---

## What to Ask

**Ask the non-obvious.** The user already knows what they told you. Your job is to surface what they haven't thought about — implicit assumptions, hidden constraints, edge cases, unstated requirements, things that will bite later if left unexamined.

**Context-bound, not concept-bound.** The user is a vibe coder. Don't ask "PostgreSQL or MongoDB?" — ask "Does this data change often or is it mostly read-once?" Don't ask "REST or GraphQL?" — ask "Who consumes this and how?" Frame technical decisions as what the user would experience, not what the code does.

**Propose, don't just interrogate.** When you have enough signal to form an opinion, state it and ask the user to react. "I'd go with X because Y — does that match your thinking?" is better than "What do you want to do about X?"

**Name your assumptions.** Don't just ask questions — explicitly state what you're assuming so the user can correct you. "I'm assuming this is solo-dev, local-first, flexible timeline — any of those wrong?"

---

## When to Stop

Keep going until you can confidently describe all five:

1. What we're building
2. What done looks like
3. What can't change (constraints)
4. What the biggest risk is
5. What approach to take

When all five are solid, move to your recommendation.

**What does NOT stop the interview:** Short answers, "idk", one-word confirmations. These mean adapt — start proposing answers for the user to react to. Don't bail, don't offer to skip.

**What DOES stop the interview:** Explicit fatigue — "let's just start", "can we move on", "this is enough." When that happens, summarize where you are and proceed.

---

## Approach Recommendation

Once the problem is clear, recommend how to solve it.

- Lead with your recommendation and why
- YAGNI bias — simplest approach that solves the stated problem wins
- 2-3 approaches max. If one is clearly right, just recommend it
- Frame tradeoffs as what the user would experience
- If the user already stated their approach, skip this

---

## Summary

### Light (short alignment, narrow scope)

> "Got it — you want [goal] that [key behavior], running in [environment]. Main risk is [risk]. I'd approach this by [approach]. Ready to proceed?"

### Full (complex alignment, tradeoffs discussed)

> **Goal:** [Concrete outcome]
> **Not in scope:** [Explicitly excluded]
> **Constraints:** [Timeline, environment, dependencies]
> **Key decisions:** [Tradeoffs resolved]
> **Recommended approach:** [What and why]
> **Assumptions:** [What I'm taking as given]
> **Open questions:** [Things we'll figure out as we go]
>
> Anything I'm missing or getting wrong?

Summary MUST include "not in scope" to prevent scope creep.

---

## After Alignment

Offer to save the summary to `docs/` so it survives context resets. Then proceed to planning or implementation based on task complexity.
