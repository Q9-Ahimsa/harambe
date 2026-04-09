# Spec: {feature-name}

**Type:** spec
**Created:** {date}
**Status:** draft | ready | building | complete
**Session:** {feature-name}.{n}
**Design:** {.claude/specs/{feature}-design.md, or omit if no design doc was consumed}
**Desc:** {single-line summary of the outcome — what, not how}

---

## What

{1-3 sentences describing what we're building and why. Not the approach — the outcome.}

## Approach

{The chosen approach and why it was chosen over alternatives. Include enough reasoning that a fresh session won't second-guess it.}

## Key Decisions

{Decisions made during /think that constrain the implementation. Mark auto-decided ones with (auto). Each one should have enough reasoning that a builder won't reverse it.}

- **{Decision}** — {reasoning}
- **{Decision}** (auto) — {reasoning}

## Constraints

{Hard limits: things that cannot change, external dependencies, compatibility requirements.}

- {constraint}

## Files

{Every file to create or modify. This is the builder's roadmap.}

- `path/to/file.py` (new) — {what this file does}
- `path/to/other.py` (modify) — {what changes and why}

## Interfaces

{API shapes, data models, function signatures — anything that defines the contract between components. Only include if applicable.}

```
{concrete interface definitions, not prose}
```

## Assumptions (verified)

> Populated during /think's "Ground Assumptions" step. Every assumption the spec depends on, verified against actual code. Cross-referenced with feedback.md spec accuracy entries where applicable.

| Assumption | Status | Evidence |
|-----------|--------|----------|
| {claim about existing code/config/behavior} | verified / wrong / unverifiable | {what was checked} |

## Done Criteria

> /do uses this as its task checklist. Each criterion gets checked off with a commit hash as it's completed.

- [ ] {criterion}
- [ ] {criterion}
- [ ] All tests pass
- [ ] Type checks pass
- [ ] Linted

## Execution Plan

> Auto-populated by /decompose + /parallelize for complex specs (>3 criteria OR >3 files).
> If this section is absent, /do executes Done Criteria sequentially.

### Tasks

| ID | Description | Files (modify) | Files (read-only) | Produces | Consumes |
|----|-------------|-----------------|-------------------|----------|----------|
| T1 | {task} | {files} | {files} | {output} | {input} |

### Waves

| Wave | Tasks | Agent Count |
|------|-------|-------------|
| 1 | T1, T2 | 2 |
| 2 | T3, T4 | 2 |

### Contracts

{Consumer-driven interface definitions for cross-wave dependencies. Exact code — pasted into both producer and consumer agent prompts.}

### Post-Wave Checks

{Integration mismatch zones to verify after each wave completes. Import paths, interface boundaries, shared state.}
