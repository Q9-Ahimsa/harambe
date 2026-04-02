#!/usr/bin/env bash
# /think orient script — gathers project state for session orientation
# Reads .claude/ directory relative to cwd, outputs structured markdown

set -euo pipefail

# --- Helpers ---

# Extract full session log entries matching a metadata pattern
# $1 = file path, $2 = awk regex to match on metadata lines
extract_entries() {
  local file="$1" pattern="$2"
  [ -f "$file" ] || return 0
  tr -d '\r' < "$file" | awk -v pat="$pattern" '
    /^<!-- id:/ {
      if (buf && keep) printf "%s\n", buf
      buf = $0; keep = 0
      if ($0 ~ pat) keep = 1
      next
    }
    { buf = buf "\n" $0 }
    END { if (buf && keep) printf "%s\n", buf }
  '
}

# Extract a frontmatter field value from a spec file
# $1 = file path, $2 = field name (e.g., "Status", "Desc")
spec_field() {
  local line
  line=$(grep -m1 "^\*\*${2}:\*\*" "$1" 2>/dev/null || true)
  [ -n "$line" ] && echo "$line" | sed "s/\*\*${2}:\*\* *//" | tr -d '\r\`'
  return 0
}

# --- Output ---

echo "# /think — Orient"
echo ""

# Active Work
echo "## Active Work"
active=$(extract_entries ".claude/session.log" "status:(in-progress|blocked)")
if [ -n "$active" ]; then
  echo "$active"
else
  echo "None"
fi
echo ""

# Specs in Flight
echo "## Specs in Flight"
specs_found=false
if [ -d ".claude/specs" ]; then
  for spec_file in .claude/specs/*.md; do
    [ -f "$spec_file" ] || continue
    fname=$(basename "$spec_file")
    [[ "$fname" == *-research-*.md ]] && continue
    status=$(spec_field "$spec_file" "Status")
    desc=$(spec_field "$spec_file" "Desc")
    [ -z "$desc" ] && desc="(no desc)"
    echo "- ${fname} [${status}] — ${desc}"
    specs_found=true
  done
fi
if [ "$specs_found" = false ]; then
  echo "None"
fi
echo ""

# Research Briefs
echo "## Research Briefs"
briefs_found=false
if [ -d ".claude/specs" ]; then
  for brief_file in .claude/specs/*-research-internal.md .claude/specs/*-research-external.md; do
    [ -f "$brief_file" ] || continue
    bname=$(basename "$brief_file")
    # Extract feature name: strip -research-{type}.md suffix
    feature=$(echo "$bname" | sed 's/-research-\(internal\|external\)\.md$//')
    # Extract type: internal or external
    btype=$(echo "$bname" | sed 's/.*-research-\(internal\|external\)\.md$/\1/')
    # Extract date from file
    bdate=$(grep -m1 '^\*\*Date:\*\*' "$brief_file" 2>/dev/null | sed 's/\*\*Date:\*\* *//' | tr -d '\r\n' || echo "unknown")
    echo "- ${feature} [${btype}] — ${bdate}"
    briefs_found=true
  done
fi
if [ "$briefs_found" = false ]; then
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

# Feedback
echo "## Feedback"
if [ -f ".claude/feedback.md" ]; then
  echo "File exists. Sections:"
  # Show spec accuracy entry count
  accuracy_count=$(grep -c '^\- \[' ".claude/feedback.md" 2>/dev/null || echo "0")
  echo "  Spec accuracy entries: ${accuracy_count}"
  # Show autonomy table presence
  if grep -q '| Decision Type' ".claude/feedback.md" 2>/dev/null; then
    auto_count=$(grep -c '| yes ' ".claude/feedback.md" 2>/dev/null || echo "0")
    echo "  Autonomy: ${auto_count} auto-approved decision types"
  else
    echo "  Autonomy: no table yet"
  fi
  # Show pattern count
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

  echo "Recent:"
  recent=$(git log --oneline -5 2>/dev/null | tr -d '\r')
  if [ -n "$recent" ]; then
    echo "$recent" | sed 's/^/  /'
  else
    echo "  no commits"
  fi
else
  echo "Branch: not a git repo"
  echo "Dirty: n/a"
  echo "Recent: n/a"
fi
