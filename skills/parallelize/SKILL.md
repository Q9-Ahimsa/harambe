---
name: parallelize
description: "Analyze a plan for parallel execution. Adds wave scheduling, file ownership, contracts, and agent prompts. Use after planning. Triggers on: parallelize, parallel agents, optimize for agents, agent coordination, batch the work."
---

# /parallelize

Transform an implementation plan into a parallelization strategy with wave scheduling, file ownership, cross-agent contracts, and ready-to-use agent prompts.

**Implements:** The Parallel Agent Workflow from the user's global CLAUDE.md.

---

## Phase 0: Locate the Plan

Find the plan to parallelize:

1. **If file argument provided**: `/parallelize path/to/plan.md` — use that file
2. **If no argument**: Search for `plan.md`, `implementation-plan.md`, `*-plan.md` in current directory and `.claude/plans/`
3. **If multiple found**: List them and ask user to choose
4. **If none found**: Synthesize from recent conversation history

**Critical**: The parallelization strategy MUST be written to a file. Agents need to reference it, and conversation context is lost when agents spawn. If the plan was conversation-only, create a new file.

---

## Phase 1: Codebase Exploration

Before analyzing tasks, understand the codebase:

1. **Glob** for file patterns matching task descriptions
2. **Grep** for existing type definitions, interfaces, and schemas tasks might reference
3. **Read** `architecture.md` if it exists
4. **Identify** 2-3 reference files for patterns relevant to each task

This prevents inventing new patterns when suitable implementations exist.

---

## Phase 2: Task Inventory

For **each task** in the plan, extract:

```
Task ID: [T1, T2, ...]
Description: [from plan]
Files touched: [extract from description, OR infer via codebase search]
Data consumed: [what inputs/dependencies does this task need?]
Data produced: [what outputs does this task create?]
Produces interface: [yes/no — if yes, what shape?]
Consumes interface: [yes/no — if yes, from which task?]
```

### Handling Vague Tasks

A task is **too vague** if it has:
- No file paths mentioned
- No function/class/type names
- Generic verbs like "implement", "add", "create" without specifics

**Resolution:**

1. **First**: Attempt autonomous inference — grep/glob to find existing patterns. If task says "add user endpoint", search for existing endpoint patterns and infer location.

2. **If still unclear**: Present assumptions explicitly and ask user to confirm:
   ```
   Task "Implement user authentication" is vague. I assume:
   - Create AuthService in src/services/auth.ts
   - Add /api/auth/* routes in src/routes/auth.ts

   Correct? Or should I explore further?
   ```

**Never silently assume** — parallelization errors are expensive (wasted agent time, merge conflicts).

---

## Phase 3: Dependency Graph

Build edges for **three dependency types**:

### 1. Data Dependencies
Task B reads what Task A writes → edge `A → B`

### 2. File Dependencies
Tasks A and B both touch the same file:
- **Option 1**: Assign to same agent
- **Option 2**: Sequence them (add dependency edge)

### 3. Semantic Dependencies
Task B's implementation depends on Task A's design decisions.
Example: "Design the database schema" must precede "Write migration scripts"
→ edge `A → B`

### Circular Dependency Detection

If you detect a cycle (A → B → A), **stop and ask**:
```
Circular dependency detected: A depends on B depends on A.
Which dependency is weaker and can be broken?
```

---

## Phase 4: File Ownership

**Goal**: Each file assigned to exactly one agent. No overlaps.

1. List **ALL files** touched by ALL tasks
2. For each file touched by **multiple tasks**:
   - If dependency edge exists between those tasks: OK (already sequenced)
   - If no dependency: **CONFLICT** — resolve by:
     - (a) Add a dependency edge (sequence them)
     - (b) Merge tasks into same agent
3. Output: `Agent 1 owns [files], Agent 2 owns [files], ...`
4. **Verify**: No file appears in multiple agents' ownership lists

If unresolvable conflict:
```
Tasks X and Y both modify file Z but have no valid ordering.
Options:
(a) Make X depend on Y
(b) Make Y depend on X
(c) Merge into single agent
```

---

## Phase 5: Wave Scheduling

### Compute Waves

- **Wave 1**: Tasks with zero incoming dependency edges
- **Wave 2**: Tasks whose dependencies are ALL in Wave 1
- **Wave N**: Tasks whose dependencies are ALL in Waves 1..N-1

### Verify Within-Wave Safety

Within each wave, check for file conflicts:
- If two Wave-2 tasks both touch file X → split wave or merge into one agent

### Agent Count Heuristics

- **2 agents** for 3-5 independent tasks per wave
- **3 agents** for 6-9 independent tasks per wave
- **More than 3**: Consider splitting into additional waves instead

---

## Phase 6: Contract Design

**Critical insight**: Design contracts based on what the **CONSUMER** expects, not what the producer outputs.

For each **cross-wave dependency edge** (Task A in Wave N → Task B in Wave N+1):

1. **Identify** what Task A produces that Task B needs
2. **Ask consumer-focused questions**:
   - What field names will Task B use to access this data?
   - What types does Task B expect?
   - What are example values?
3. **Consumer's answers define the contract shape**
4. **Write as concrete code**, not prose:

```typescript
// Contract: Task A output → Task B input
interface UserAuthResult {
  userId: string;        // UUID format
  token: string;         // JWT, expires in 24h
  permissions: string[]; // e.g., ["read:users", "write:orders"]
}
```

5. **This exact code block goes into BOTH agent prompts**

### Wire Format Examples (API Contracts)

When a contract defines an **HTTP API response** consumed by a separate agent (especially backend→frontend), the type definition alone is ambiguous. Pydantic/dataclass serialization has nesting and naming behaviors that aren't obvious from the class definition.

**Always include a literal JSON example alongside the type definition:**

```python
# Contract: GET /api/analytics/engagement
class EngagementResponse(BaseModel):
    sessions: TimeSeriesResponse
    messages: TimeSeriesResponse

# Wire format — what the HTTP response actually looks like:
# {
#   "sessions": {"labels": ["2026-03-01"], "values": [42], "total": 42},
#   "messages": {"labels": ["2026-03-01"], "values": [107], "total": 107}
# }
```

Without the JSON example, a frontend agent may reasonably read `EngagementResponse` as flat (`data.labels`, `data.sessions`) instead of nested (`data.sessions.labels`). The type definition is the source of truth for the producer; the wire format example is the source of truth for the consumer.

**This applies whenever:**
- A backend task produces an API response consumed by a frontend task
- Two services communicate over HTTP/JSON
- The serialized shape differs from how the type reads (nested models, computed fields, renamed keys)

### Language-Specific Formats

- **TypeScript**: `interface` or `type` definitions
- **Python**: `TypedDict`, `dataclass`, or Pydantic model
- **Go**: `struct` definition
- **No types exist**: Structured table (field, type, example, accessed by)

---

## Output Format

Append the following to the plan file:

```markdown
## Parallelization Strategy

### Wave Schedule

| Wave | Tasks | Agents |
|------|-------|--------|
| 1    | T1, T2 | 2     |
| 2    | T3     | 1     |
| 3    | T4, T5 | 2     |

### Dependency Graph

T1 ──┬──> T3 ──> T4
T2 ──┘         └──> T5

Dependencies:
- T3 depends on T1 (data: UserSession interface)
- T3 depends on T2 (file: both read config.ts)
- T4 depends on T3 (semantic: needs schema finalized)
- T5 depends on T3 (data: uses API response types)

### File Ownership

| Agent | Wave | Exclusive Files | Reads Only |
|-------|------|-----------------|------------|
| Agent 1 | 1 | src/auth.ts, src/auth.test.ts | src/types.ts |
| Agent 2 | 1 | src/api.ts, src/api.test.ts | src/types.ts |
| Agent 3 | 2 | src/middleware.ts | src/auth.ts, src/types.ts |

### Contracts

#### UserSession (T1 produces → T3 consumes)

```typescript
interface UserSession {
  id: string;
  userId: string;
  expiresAt: Date;
}
```

**Consumer access patterns:**
- `session.id` — used as cache key
- `session.expiresAt` — checked for refresh logic

**Location:** Must be exported from `src/types/auth.ts`

---

### Agent Prompts

#### Agent 1 (Wave 1) — Auth Service

```
You are implementing the authentication service.

**Files you own (ONLY modify these):**
- src/services/auth.ts
- src/types/auth.ts
- tests/auth.test.ts

**Files you may read (NO modifications):**
- src/types/index.ts

**Contract you MUST implement (exact shape):**

interface UserSession {
  id: string;
  userId: string;
  expiresAt: Date;
}

Export this interface from src/types/auth.ts.

**Your task:**
[Paste task T1 description here]

**Run when done:**
npm test -- auth
```

#### Agent 2 (Wave 1) — API Routes

[Same structure...]

---

### Post-Wave Integration

After **each wave** completes:

1. **Run full test suite**: `npm test`
2. **Primary mismatch zones** (check these first):
   - Interface boundary: src/types/auth.ts ↔ src/middleware.ts
   - Import paths in src/api.ts
3. **Budget**: ~15 min for integration fixes per wave

### Verification Checklist

Before spawning agents, verify:
- [ ] Every task is assigned to exactly one wave
- [ ] Every file is owned by exactly one agent
- [ ] Every cross-wave edge has a contract
- [ ] Contracts are code, not prose
- [ ] Agent prompts include exclusive file lists
```

---

## Failure Mode Handling

| Situation | Detection | Response |
|-----------|-----------|----------|
| **Only 1-2 tasks** | Task count < 3 | "Plan has only N tasks. Parallelization overhead may exceed benefits. Options: (a) Execute sequentially, (b) Break tasks into smaller units, (c) Proceed anyway" |
| **Everything sequential** | Dependency graph is a chain | Display the chain. Ask: "All tasks are sequential. Can any dependencies be relaxed?" Still output wave schedule for planning purposes. |
| **Unfamiliar codebase** | Grep/Glob finds no matching files | Switch to exploration mode: "I need to explore the codebase to identify file boundaries. Proceeding with analysis..." |
| **Circular dependency** | Graph cycle detected | "Circular dependency: A → B → A. Which dependency is weaker and can be broken?" |
| **Contract ambiguity** | Consumer needs unclear | "Task B needs data from Task A, but I can't determine the shape. Options: (a) My guess: [shape], (b) Let me read code patterns, (c) You specify" |
| **Unresolvable file conflict** | Two tasks must touch same file, no valid ordering | "Tasks X and Y both modify Z. Options: (a) X before Y, (b) Y before X, (c) Merge into single agent" |

---

## Checklist Before Finalizing

Before appending the parallelization strategy:

- [ ] Every task has a Task ID and clear file touchpoints
- [ ] Dependency graph has no unresolved cycles
- [ ] File ownership has no overlaps
- [ ] Every cross-wave dependency has a concrete contract (code, not prose)
- [ ] API contracts include a literal JSON wire format example (not just type definitions)
- [ ] Agent prompts include: exclusive files, read-only files, contract code, task description
- [ ] Post-wave integration section identifies mismatch zones
- [ ] Output is written to a file (not conversation-only)
