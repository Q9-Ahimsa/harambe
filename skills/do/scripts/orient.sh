#!/usr/bin/env bash
# /do orient script — gathers build state for execution orientation
# Reads .claude/ directory relative to cwd, outputs structured markdown

set -euo pipefail

# --- Shared helpers ---
# Sourced from scripts/orient-lib.sh three dirs up (plugin root, or ~/.claude
# when used as a local skill). Prefers CLAUDE_PLUGIN_ROOT when set.
# shellcheck disable=SC1090
source "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}/scripts/orient-lib.sh"

# --- Output ---

echo "# /do — Orient"
echo ""

# Ready Specs
echo "## Ready Specs"
ready_found=false
if [ -d ".claude/specs" ]; then
  for spec_file in .claude/specs/*.md; do
    [ -f "$spec_file" ] || continue
    fname=$(basename "$spec_file")
    # /do only acts on specs, not design docs or research briefs.
    # Design docs belong to /feel and /think — they're upstream of /do's scope.
    [[ "$fname" == *-design.md ]] && continue
    [[ "$fname" == *-research-*.md ]] && continue
    status=$(spec_field "$spec_file" "Status")
    if [ "$status" = "ready" ]; then
      fname=$(basename "$spec_file")
      desc=$(spec_field "$spec_file" "Desc")
      [ -z "$desc" ] && desc="(no desc)"
      criteria_count=$(grep -c '^\- \[ \]' "$spec_file" 2>/dev/null || true)
      echo "- ${fname} — ${desc} (${criteria_count} Done Criteria)"
      ready_found=true
    fi
  done
fi
if [ "$ready_found" = false ]; then
  echo "No ready specs. Run /think first."
fi
echo ""

# In-Progress Builds
echo "## In-Progress Builds"
in_progress=$(extract_entries ".claude/session.log" "phase:build.*status:in-progress")
if [ -n "$in_progress" ]; then
  echo "$in_progress"
else
  echo "None"
fi
echo ""

# Blocked Builds
echo "## Blocked Builds"
blocked=$(extract_entries ".claude/session.log" "phase:build.*status:blocked")
if [ -n "$blocked" ]; then
  echo "$blocked"
else
  echo "None"
fi
echo ""

# Feedback
echo "## Feedback"
if [ -f ".claude/feedback.md" ]; then
  echo "File exists. Sections:"
  accuracy_count=$(grep -c '^\- \[' ".claude/feedback.md" 2>/dev/null || echo "0")
  echo "  Spec accuracy entries: ${accuracy_count}"
  if grep -q '| Decision Type' ".claude/feedback.md" 2>/dev/null; then
    auto_count=$(grep -c '| yes ' ".claude/feedback.md" 2>/dev/null || echo "0")
    echo "  Autonomy: ${auto_count} auto-approved decision types"
  else
    echo "  Autonomy: no table yet"
  fi
  pattern_section=$(sed -n '/^## Patterns/,/^## /p' ".claude/feedback.md" 2>/dev/null | grep -c '^\- ' 2>/dev/null || echo "0")
  echo "  Staged patterns: ${pattern_section}"
else
  echo "None"
fi
echo ""

# Git
echo "## Git"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\r')
  echo "Branch: ${branch}"

  dirty_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' \r')
  if [ "$dirty_count" -gt 0 ]; then
    echo "Dirty: yes (${dirty_count} files)"
  else
    echo "Dirty: no"
  fi
else
  echo "Branch: not a git repo"
  echo "Dirty: n/a"
fi
