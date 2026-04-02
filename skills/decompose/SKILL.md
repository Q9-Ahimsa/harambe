---
name: decompose
description: "Break an implementation plan into atomic, agent-sized tasks with file ownership and dependency mapping. This skill should be used after planning and before parallelization. Produces a numbered task inventory ready for /parallelize or sequential execution. Triggers on: decompose, break this down, task breakdown, split into tasks, atomize."
---

# /decompose

Break an implementation plan into atomic, agent-sized tasks. Each task is completable by one agent in one pass with clear file boundaries.

**Input:** A plan — file path argument, plan file in `.claude/plans/`, or conversation context.
**Output:** Numbered task inventory with file touchpoints and dependency arrows.

---

## Phase 0: Locate the Plan

1. **If file argument provided**: `/decompose path/to/plan.md` — use that file
2. **If no argument**: Search for `plan.md`, `implementation-plan.md`, `*-plan.md` in current directory and `.claude/plans/`
3. **If multiple found**: List them and ask user to choose
4. **If none found**: Synthesize from recent conversation history

If the plan already contains a clear task breakdown (numbered steps with file paths), validate and refine rather than starting from scratch.

---

## Phase 1: Codebase Scan

Before decomposing, ground in reality:

1. **Glob** for file patterns mentioned in the plan
2. **Grep** for existing types, interfaces, and schemas the plan references
3. **Read** key files to understand current patterns and structure
4. **Identify** which files exist vs. need creation

This prevents inventing tasks for files that don't exist or missing tasks for files that do.

---

## Phase 2: Extract Tasks

For each logical unit of work in the plan, create a task entry:

```
Task ID: T[N]
Description: [What this task accomplishes — one sentence]
Files touched: [Exact file paths — created or modified]
Produces: [Interfaces, types, or data this task creates for others]
Consumes: [Interfaces, types, or data from other tasks]
```

### Granularity Rules

A task is the right size when:
- **One agent, one pass** — completable without needing output from a concurrent task
- **Clear file boundaries** — each file appears in at most one task (exceptions: read-only shared files like types or config)
- **Testable in isolation** — the task has a way to verify it worked (test file, linter, manual check)
- **Under ~500 lines of change** — if larger, split further

A task is too big when:
- It touches 5+ files across different concerns
- It requires both creating an interface AND consuming it
- Description uses "and" to join two unrelated actions

A task is too small when:
- It's a single line change with no standalone meaning
- It can't be tested independently
- It only makes sense as part of another task

### Splitting Strategies

| Pattern | Split approach |
|---------|---------------|
| New module + tests | T1: module implementation, T2: test file (sequential — T2 reads T1 output) |
| API endpoint | T1: route + handler, T2: validation/middleware, T3: tests |
| Data model change | T1: schema/migration, T2: model logic, T3: consumers of the model |
| UI feature | T1: component, T2: state/logic, T3: integration/wiring |
| Refactor | T1: extract interface, T2: migrate consumers, T3: remove old code |

---

## Phase 3: Map Dependencies

For each pair of tasks, check three dependency types:

### Data Dependencies
Task B reads what Task A writes → `T[A] → T[B]`

Example: T1 creates `UserSession` type, T3 imports it → `T1 → T3`

### File Dependencies
Tasks A and B both modify the same file → assign to same task or sequence them.

Read-only access doesn't create a dependency. If T2 only *reads* `types.ts` but T1 *writes* it, that's a data dependency, not a file conflict.

### Semantic Dependencies
Task B's implementation depends on decisions made in Task A.

Example: "design the API shape" must precede "implement the client" → `T[A] → T[B]`

### Output Format

```
Dependencies:
- T2 → T3 (data: T2 produces AuthResult interface, T3 consumes it)
- T1 → T2 (file: both modify src/config.ts — sequenced)
- T3 → T4 (semantic: T4 needs T3's API shape finalized)
```

If a circular dependency is detected, stop and surface it:
> "Circular dependency: T2 → T3 → T2. Which dependency is weaker?"

---

## Phase 4: Validate

Before presenting the decomposition, verify:

- [ ] Every file mentioned in the plan appears in at least one task
- [ ] No file appears as "modified" in multiple tasks (read-only sharing is fine)
- [ ] Every task has at least one file touchpoint
- [ ] Dependency graph has no cycles
- [ ] Each task passes the granularity rules (one agent, one pass, testable)
- [ ] Task descriptions are concrete (file paths, function names — not vague verbs)

If validation fails, fix the issue and re-validate before presenting.

---

## Output

Present the decomposition as a structured table followed by the dependency graph:

```markdown
## Task Decomposition

| ID | Description | Files (modify) | Files (read-only) | Produces | Consumes |
|----|-------------|-----------------|-------------------|----------|----------|
| T1 | Create auth service with login/logout | src/auth.ts | src/types.ts | AuthResult interface | — |
| T2 | Add auth middleware | src/middleware.ts | src/auth.ts, src/types.ts | — | AuthResult (from T1) |
| T3 | Add auth API routes | src/routes/auth.ts | src/auth.ts | — | AuthResult (from T1) |
| T4 | Write auth tests | tests/auth.test.ts | src/auth.ts, src/middleware.ts | — | T1, T2 complete |

### Dependencies

T1 ──┬──> T2
     └──> T3
T1, T2 ──> T4

- T2 depends on T1 (data: AuthResult interface)
- T3 depends on T1 (data: AuthResult interface)
- T4 depends on T1, T2 (semantic: needs implementation to test against)

### Summary

4 tasks, 2 waves possible (T1 alone → T2, T3 parallel → T4).
Ready for /parallelize or sequential execution.
```

---

## Standalone vs. Pipeline Use

**Standalone** (`/decompose path/to/plan.md`): Present the full output and ask if the user wants to proceed to `/parallelize` or execute sequentially.

**Within /cook pipeline**: Present the output, wait for user confirmation at the checkpoint, then hand off to the next phase. Do not offer next-step choices — /cook controls the flow.

---

## Anti-Patterns

- **Vague tasks** — "implement the feature" is not a task. Every task needs file paths and concrete actions.
- **God tasks** — One task that does everything. If it touches 5+ files across concerns, split it.
- **Premature parallelism** — Don't force parallel structure. If tasks are naturally sequential, say so.
- **Ignoring the codebase** — Don't decompose in a vacuum. Grep for existing patterns first.
- **Recreating what exists** — If the plan already has a good task breakdown, validate and annotate it rather than starting over.
