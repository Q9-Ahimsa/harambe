#!/usr/bin/env bash
# /feel orient script — gathers design state for exploration orientation
# Reads .claude/ directory relative to cwd, outputs structured markdown

set -euo pipefail

# --- Shared helpers ---
# Sourced from scripts/orient-lib.sh three dirs up (plugin root, or ~/.claude
# when used as a local skill). Prefers CLAUDE_PLUGIN_ROOT when set.
# shellcheck disable=SC1090
source "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}/scripts/orient-lib.sh"

# --- Output ---

echo "# /feel — Orient"
echo ""

# Active Feel Sessions
echo "## Active Feel Sessions"
active=$(extract_entries ".claude/session.log" "phase:feel.*status:in-progress")
if [ -n "$active" ]; then
  echo "$active"
else
  echo "None"
fi
echo ""

# Design Docs
echo "## Design Docs"
designs_found=false
if [ -d ".claude/specs" ]; then
  for design_file in .claude/specs/*-design.md; do
    [ -f "$design_file" ] || continue
    fname=$(basename "$design_file")
    status=$(spec_field "$design_file" "Status")
    desc=$(spec_field "$design_file" "Desc")
    [ -z "$desc" ] && desc="(no desc)"
    card=$(cardinality_marker "$design_file")
    echo "- ${fname} [${status}, ${card}] — ${desc}"
    designs_found=true
  done
fi
if [ "$designs_found" = false ]; then
  echo "None"
fi
echo ""

# Backlog
echo "## Backlog"
if [ -f ".claude/backlog.md" ]; then
  content=$(tr -d '\r' < ".claude/backlog.md")
  if [ -n "$content" ]; then
    echo "$content"
  else
    echo "None"
  fi
else
  echo "None"
fi
echo ""

# Feedback — Design Accuracy
echo "## Feedback"
if [ -f ".claude/feedback.md" ]; then
  echo "File exists."
  # Show design accuracy entry count
  design_section=$(sed -n '/^## Design Accuracy/,/^## /p' ".claude/feedback.md" 2>/dev/null || true)
  if [ -n "$design_section" ]; then
    design_count=$(echo "$design_section" | grep -c '^\- \[' 2>/dev/null || echo "0")
    echo "  Design accuracy entries: ${design_count}"
  else
    echo "  Design accuracy: no entries yet"
  fi
else
  echo "None"
fi
echo ""

# Git (minimal — /feel doesn't need deep git context)
echo "## Git"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\r')
  echo "Branch: ${branch}"
else
  echo "Branch: not a git repo"
fi
