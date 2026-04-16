#!/usr/bin/env bash
# Shared helpers for /feel, /think, /do orient scripts.
# Sourced via: source "${CLAUDE_PLUGIN_ROOT}/scripts/orient-lib.sh"
# Location follows the standard plugin layout (sibling to skills/, hooks/).

# Extract session log entries whose <!-- id: ... --> metadata matches an awk regex.
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

# Read a frontmatter field from a spec or design doc.
# Prefers the canonical bold-asterisk format; falls back to YAML for drift tolerance.
spec_field() {
  local file="$1" field="$2" line
  [ -f "$file" ] || return 0

  line=$(grep -m1 "^\*\*${field}:\*\*" "$file" 2>/dev/null || true)
  if [ -n "$line" ]; then
    echo "$line" | sed "s/\*\*${field}:\*\* *//" | tr -d '\r\`'
    return 0
  fi

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

# Returns the Cardinality field value, or "mono" if absent (backwards compatible).
# $1 = file path
cardinality_marker() {
  local file="$1" value
  value=$(spec_field "$file" "Cardinality")
  if [ -z "$value" ]; then
    echo "mono"
  else
    echo "$value"
  fi
}

# List all specs that back-link to a given design doc.
# Searches both .claude/specs/ and .claude/specs/archive/.
# $1 = design doc filename or absolute path
# Output: one spec file path per line
specs_for_design() {
  local design="$1"
  local design_basename
  design_basename=$(basename "$design")

  for dir in .claude/specs .claude/specs/archive; do
    [ -d "$dir" ] || continue
    for spec in "$dir"/*.md; do
      [ -f "$spec" ] || continue
      # Skip design docs and research briefs
      case "$(basename "$spec")" in
        *-design.md|*-research-*.md) continue ;;
      esac
      local link
      link=$(spec_field "$spec" "Design")
      [ -z "$link" ] && continue
      if [[ "$(basename "$link")" == "$design_basename" ]]; then
        echo "$spec"
      fi
    done
  done
}

# Count terminal slices for a given multi design doc.
# $1 = design doc path
# Output: "complete_count cancelled_count total_listed"
count_terminal_slices() {
  local design="$1"
  local listed
  listed=$(spec_field "$design" "Slices")
  [ -z "$listed" ] && { echo "0 0 0"; return 0; }

  local total
  total=$(echo "$listed" | tr ',' '\n' | grep -c .)

  local complete=0 cancelled=0
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    local status
    status=$(spec_field "$spec" "Status")
    case "$status" in
      complete) complete=$((complete + 1)) ;;
      cancelled) cancelled=$((cancelled + 1)) ;;
    esac
  done < <(specs_for_design "$design")

  echo "$complete $cancelled $total"
}
