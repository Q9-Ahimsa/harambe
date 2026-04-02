# harambe

Structured think-then-do development workflow for Claude Code. Spec-driven, TDD-first, with autonomous subagent execution, multi-agent validation, and a cross-session learning loop.

Monkey think, monkey do.

## Install

Add the marketplace and install:

```
/plugin marketplace add Q9-Ahimsa/harambe
/plugin install harambe@harambe
/reload-plugins
```

Or install from a local directory during development:

```
claude --plugin-dir /path/to/think-do
```

## Commands

| Command | What it does |
|---------|-------------|
| `/harambe:think` | Explore the problem space, align on scope, research codebase + external best practices, produce a spec |
| `/harambe:do` | Execute a spec with TDD discipline — subagent per criterion, multi-agent validation, PR creation, close-out |
| `/harambe:align` | Standalone deep interview — surfaces implicit assumptions through structured questioning |
| `/harambe:pr-review` | Blind 4-agent parallel code review (correctness, security, performance, style) |
| `/harambe:decompose` | Break a spec into agent-sized tasks with file ownership and dependencies |
| `/harambe:parallelize` | Wave scheduling, contracts, and agent prompt generation for parallel execution |

### The core loop

```
/harambe:think "feature description"
  → aligns on scope
  → researches codebase + external docs
  → explores design with you
  → writes a spec

/harambe:do
  → picks up the spec
  → builds each criterion with a subagent (TDD)
  → validates with 3 agents (verifier, security, regression)
  → simplifies, reviews, ships PR
  → extracts learnings for next cycle
```

### Run think and do in separate sessions

This is the single most important usage recommendation. **Start a fresh Claude Code instance for `/harambe:do`** — don't run it in the same session as `/harambe:think`.

Why: `/harambe:do` spawns subagents aggressively — one per Done Criteria item, three validation agents in parallel, four PR review agents. Each subagent prompt includes literal file contents, interface definitions, and behavioral rules. If your context window is already half-full from a `/harambe:think` exploration, you'll hit compaction mid-build. Compaction during execution causes drift — accumulated context gets summarized, nuance gets lost, and the subagent prompts degrade.

The spec is the handoff mechanism. `/harambe:think` writes it to disk. `/harambe:do` reads it from disk. They don't need to share a conversation.

```
# Session 1
/harambe:think "add user authentication"
# → spec written to .claude/specs/add-user-authentication.md
# → close this session

# Session 2 (fresh context)
/harambe:do
# → picks up the ready spec automatically
# → full context available for subagent work
```

If you're running multiple features in parallel, use separate terminal tabs — one `/harambe:do` per tab, each building a different spec in a worktree.

## How it works

### /think phases

**Orient** — Reads project state: active work, specs, backlog, feedback from prior builds.

**Align** — Structured interview using AskUserQuestion. Surfaces scope, constraints, risks. Produces an ALIGNED checkpoint. Skipped if you arrive fully-specified.

**Research** — Spawns a codebase research agent (always) and an external best-practices agent (when the domain is unfamiliar or high-risk). Both write research briefs to disk.

**Design Conversation** — Open-ended exploration grounded in research. You make the senior decisions; mechanical choices are auto-decided and narrated.

**Spec** — Writes a spec to `.claude/specs/`. Every assumption is verified against actual code. Template includes: What, Approach, Key Decisions, Constraints, Files, Interfaces, Assumptions (verified), Done Criteria.

**Quality Gate** — 2-6 independent agents review the spec for completeness, assumption accuracy, architecture, security, performance, and impact. Critical issues are fixed; suggestions are presented.

**Execution Planning** — For complex specs (>3 criteria or >3 files), decomposes into tasks and generates a wave schedule with contracts.

### /do phases

**Orient** — Finds ready specs, in-progress builds, or blocked builds.

**Build** — Each Done Criteria item is built by a subagent running TDD (red-green-refactor). Main context orchestrates: formulates prompts, validates output, commits atomically.

**Validation** — Three agents run in parallel: verifier (spec compliance), build-security (OWASP scan), build-regression (breakage outside scope).

**Simplify** — Runs `/simplify` on modified files.

**Build Report** — Structured summary with all criteria, divergences, fixes, and validation results. You review before shipping.

**Ship** — Pushes branch, creates PR via `gh`, links to issue.

**PR Review** — Dispatches 4 blind review agents (correctness, security, performance, style). Posts findings to GitHub.

**Address Findings** — Fixes review findings in severity order.

**Close Out** — Squash merge (with your confirmation), extract learnings, write feedback, archive spec.

### The learning loop

`/do` writes to `.claude/feedback.md` at close-out:
- **Spec accuracy** — what the spec got wrong (max 15 entries)
- **Autonomy table** — which decisions can be auto-approved based on track record
- **Patterns** — cross-feature learnings proposed by the learn agent

`/think` reads `feedback.md` before writing the next spec. The system gets smarter each cycle.

## Agents

The plugin includes 12 specialized agents:

| Agent | Spawned by | Role |
|-------|-----------|------|
| `research-internal` | /think | Investigates codebase patterns, interfaces, prior art |
| `research-external` | /think | Researches best practices, library docs, industry standards |
| `spec-completeness` | /think | Reviews spec consistency and coverage |
| `spec-assumptions` | /think | Verifies spec claims against actual code |
| `spec-architecture` | /think | Reviews pattern consistency and coupling |
| `spec-security` | /think | Reviews for security vulnerabilities |
| `spec-performance` | /think | Reviews for N+1 queries, unbounded operations |
| `spec-impact` | /think | Reviews for ripple effects and breaking changes |
| `verifier` | /do | Validates build against spec Done Criteria |
| `build-security` | /do | OWASP-aligned security scan of implemented code |
| `build-regression` | /do | Detects breakage outside the spec's scope |
| `learn` | /do | Extracts reusable patterns for project CLAUDE.md |

## Dependencies

### Required

- **Git** — for commits, branching, worktrees
- **GitHub CLI (`gh`)** — for PR creation and review
  - macOS: `brew install gh`
  - Windows: `winget install GitHub.cli`
  - Linux: see https://github.com/cli/cli/blob/trunk/docs/install_linux.md
  - Then authenticate: `gh auth login`

### Recommended

- **ast-grep (`sg`)** — structural code search used by research and validation agents
  - macOS: `brew install ast-grep`
  - Windows: `cargo install ast-grep` or download from https://ast-grep.github.io
  - Linux: `cargo install ast-grep`

### Auto-configured

- **Context7 MCP** — framework documentation fetching. Bundled in the plugin's `mcpServers` config. Accept the MCP server prompt when it appears.

## Project setup

For the full workflow experience, add these lines to your project's `.claude/CLAUDE.md` (or project root `CLAUDE.md`):

```markdown
## Workflow

### /harambe:think + /harambe:do
- Trivial tasks: just do them. No ceremony
- `/harambe:think`: explore, discuss, produce spec. Pauses only for senior-level decisions
- `/harambe:do`: execute spec with TDD. Resolves divergences inline. Full stop only if approach is broken
- Auto-decide: tests, security review, lint, quality gates, archival. Fix findings, don't ask
- Ask me: scope changes, genuine tradeoffs, architecture choices
- **While we're here**: when touching a file, fix all visible issues
- **Feedback loop**: /do writes spec accuracy + autonomy data to `.claude/feedback.md`. /think reads it next cycle

### Session Log
- Append-only at `.claude/session.log`. Query with grep, never read full file
- Entry ID: `{feature}.{n}` (e.g., `auth-redesign.1`)
- Metadata: `<!-- id:{feature}.{n} | feature:{name} | phase:{discuss|build} | date:{YYYY-MM-DD} | status:{in-progress|complete|blocked} -->`
- Prefixes: DECISION, APPROACH, PROBLEM/ROOT/FIX, INSIGHT, FILES, DONE, NEXT, BLOCKED, VALIDATED, COMMITTED, SPEC, ref:, ALIGNED, RESEARCH, AMENDED, POST

### Testing
- TDD by default. Tests before implementation

### Git
- Conventional commits: `type(scope): description`
- Small commits. Never commit secrets
```

These rules apply even when `/harambe:think` or `/harambe:do` aren't actively running. They give Claude context about the session log format, when to use the workflow, and cross-cutting conventions.

## Optional: Lint and type check hooks

The plugin enforces test execution via a Stop hook. For auto-linting and type checking on every file write, add hooks to your **project's** `.claude/settings.json`:

### Python (ruff + basedpyright)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Write\" || tool == \"Edit\"",
        "hooks": [
          {
            "type": "command",
            "command": "ruff check --fix \"$TOOL_FILE_PATH\"",
            "timeout": 30
          },
          {
            "type": "command",
            "command": "basedpyright \"$TOOL_FILE_PATH\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Node.js (eslint)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Write\" || tool == \"Edit\"",
        "hooks": [
          {
            "type": "command",
            "command": "npx eslint --fix \"$TOOL_FILE_PATH\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Runtime artifacts

The workflow creates these files in your project's `.claude/` directory:

```
.claude/
  session.log          # Append-only session history
  feedback.md          # Learning loop: spec accuracy, autonomy, patterns
  backlog.md           # Deferred out-of-scope work
  specs/
    {feature}.md       # Active specs
    {feature}-research-internal.md
    {feature}-research-external.md
    archive/           # Completed specs and research briefs
```

Add `.claude/` to `.gitignore` — these are local workflow state, not source code.

## Design philosophy

**Glass cockpit.** You watch the process unfold. You get asked only for senior-level decisions — scope, genuine tradeoffs, architecture. Everything mechanical is auto-decided and narrated.

**Spec as message bus.** All communication between /think and /do flows through persistent artifacts (specs, session log, feedback). No conversation state dependency. Survives context compaction.

**Subagents are disposable labor.** Main context is the orchestrator — precious working memory. Subagents get exact file contents, exact interfaces, exact rules. Their output is validated like a PR from a junior developer.

**Correctness over speed.** Both /think and /do optimize for getting it right, not getting it fast. The urge to "just move on" is the exact moment to pause and verify.

**The system learns.** Each /do cycle writes spec accuracy data and autonomy calibration. Each /think cycle reads it. The workflow adapts to the project and the user over time.

## License

MIT
