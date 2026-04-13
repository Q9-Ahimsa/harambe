#!/usr/bin/env bash
# /do orient script — gathers build state for execution orientation
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
# Tries bold-asterisk format first (**Field:** value), then falls back to
# YAML frontmatter (case-insensitive). This handles drift where /think writes
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
