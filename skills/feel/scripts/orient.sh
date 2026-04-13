#!/usr/bin/env bash
# /feel orient script — gathers design state for exploration orientation
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

# Extract a frontmatter field value from a spec or design doc
# $1 = file path, $2 = field name (e.g., "Status", "Desc")
# Tries bold-asterisk format first (**Field:** value), then falls back to
# YAML frontmatter (case-insensitive). This handles drift where /feel writes
# YAML-style frontmatter instead of the template's bold-asterisk format.
spec_field() {
  local file="$1" field="$2" line
  [ -f "$file" ] || return 0

  # Format 1: bold-asterisk — **Field:** value
  line=$(grep -m1 "^\*\*${field}:\*\*" "$file" 2>/dev/null || true)
  if [ -n "$line" ]; then
    echo "$line" | sed "s/\*\*${field}:\*\* *//" | tr -d '\r\`'
    return 0
  fi

  # Format 2: YAML frontmatter (between --- markers, case-insensitive field)
  awk -v field="$field" '
    BEGIN { lc_field = tolower(field); in_yaml = 0 }
    /^---[[:space:]]*$/ {
      if (in_yaml) exit
      in_yaml = 1
      next
    }
    in_yaml {
      lc_line = tolower($0)
      if (lc_line ~ "^[[:space:]]*"lc_field"[[:space:]]*:") {
        sub(/^[[:space:]]*[^:]+:[[:space:]]*/, "")
        gsub(/^["\047]|["\047]$/, "")
        print
        exit
      }
    }
  ' "$file" | tr -d '\r\`'
  return 0
}

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
    echo "- ${fname} [${status}] — ${desc}"
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
