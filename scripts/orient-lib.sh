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
