#!/usr/bin/env bash
#
# baseline-check.sh
#
# Executes project quality checks (RuboCop, RSpec) and outputs results in
# standardized JSON format. Designed to gracefully handle missing tools during
# early project lifecycle.
#
# Exit codes:
#   0 - Success (all checks passed or none available)
#   1 - Check failures
#   2 - Script error (not in git repo, etc.)
#

set -o pipefail

# --- Color codes for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper functions ---

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check if jq is available
has_jq() {
  command -v jq >/dev/null 2>&1
}

# Escape string for JSON (when jq not available)
json_escape() {
  local string="$1"
  # Escape backslashes, quotes, and control characters
  printf '%s' "$string" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

# --- Git information extraction ---

get_git_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

get_git_commit() {
  git rev-parse --short HEAD 2>/dev/null
}

# --- RuboCop check ---

check_rubocop() {
  local available="false"
  local status="not_available"
  local files_inspected=0
  local offenses=0
  local convention=0
  local warning=0
  local error=0
  local fatal=0
  local execution_time=0

  log_info "Checking RuboCop availability..."

  if bundle exec rubocop --version >/dev/null 2>&1; then
    available="true"
    log_info "RuboCop is available, running checks..."

    local start_time=$SECONDS
    local rubocop_output
    local rubocop_exit_code

    # Run RuboCop with JSON format
    rubocop_output=$(bundle exec rubocop --format json 2>&1)
    rubocop_exit_code=$?
    execution_time=$((SECONDS - start_time))

    # Parse JSON output
    if has_jq && echo "$rubocop_output" | jq empty 2>/dev/null; then
      # Valid JSON, parse with jq
      files_inspected=$(echo "$rubocop_output" | jq '.summary.inspected_file_count // 0')
      offenses=$(echo "$rubocop_output" | jq '.summary.offense_count // 0')

      # Count offenses by severity
      convention=$(echo "$rubocop_output" | jq '[.files[].offenses[] | select(.severity == "convention")] | length')
      warning=$(echo "$rubocop_output" | jq '[.files[].offenses[] | select(.severity == "warning")] | length')
      error=$(echo "$rubocop_output" | jq '[.files[].offenses[] | select(.severity == "error")] | length')
      fatal=$(echo "$rubocop_output" | jq '[.files[].offenses[] | select(.severity == "fatal")] | length')

      if [ "$rubocop_exit_code" -eq 0 ]; then
        status="passed"
        log_success "RuboCop passed ($files_inspected files, $offenses offenses)"
      else
        status="failed"
        log_warn "RuboCop failed ($files_inspected files, $offenses offenses)"
      fi
    else
      log_warn "Could not parse RuboCop output as JSON"
      status="failed"
    fi
  else
    log_warn "RuboCop not available (bundle exec rubocop failed)"
  fi

  # Return values as pipe-delimited string
  echo "$available|$status|$files_inspected|$offenses|$convention|$warning|$error|$fatal|$execution_time"
}

# --- RSpec check ---

check_rspec() {
  local available="false"
  local status="not_available"
  local examples=0
  local failures=0
  local pending=0
  local execution_time=0

  log_info "Checking RSpec availability..."

  if bundle exec rspec --version >/dev/null 2>&1; then
    available="true"
    log_info "RSpec is available, running tests..."

    local start_time=$SECONDS
    local rspec_output
    local rspec_exit_code

    # Run RSpec with JSON format
    rspec_output=$(bundle exec rspec --format json 2>&1)
    rspec_exit_code=$?
    execution_time=$((SECONDS - start_time))

    # Parse JSON output
    if has_jq && echo "$rspec_output" | jq empty 2>/dev/null; then
      # Valid JSON, parse with jq
      examples=$(echo "$rspec_output" | jq '.summary.example_count // 0')
      failures=$(echo "$rspec_output" | jq '.summary.failure_count // 0')
      pending=$(echo "$rspec_output" | jq '.summary.pending_count // 0')

      if [ "$rspec_exit_code" -eq 0 ]; then
        status="passed"
        log_success "RSpec passed ($examples examples, $failures failures, $pending pending)"
      else
        status="failed"
        log_warn "RSpec failed ($examples examples, $failures failures, $pending pending)"
      fi
    else
      log_warn "Could not parse RSpec output as JSON"
      status="failed"
    fi
  else
    log_warn "RSpec not available (bundle exec rspec failed)"
  fi

  # Return values as pipe-delimited string
  echo "$available|$status|$examples|$failures|$pending|$execution_time"
}

# --- Main execution ---

main() {
  log_info "Starting baseline quality checks..."

  # Verify we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not in a git repository"
    exit 2
  fi

  # Extract git information
  local branch
  local commit
  branch=$(get_git_branch)
  commit=$(get_git_commit)

  if [ -z "$branch" ] || [ -z "$commit" ]; then
    log_error "Could not extract git branch or commit"
    exit 2
  fi

  log_info "Branch: $branch"
  log_info "Commit: $commit"

  # Generate timestamp
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local file_timestamp
  file_timestamp=$(date -u +"%Y%m%d-%H%M%S")

  # Run checks
  local rubocop_result
  local rspec_result

  rubocop_result=$(check_rubocop)
  rspec_result=$(check_rspec)

  # Parse results
  IFS='|' read -r rubocop_available rubocop_status rubocop_files rubocop_offenses \
    rubocop_convention rubocop_warning rubocop_error rubocop_fatal rubocop_time <<< "$rubocop_result"

  IFS='|' read -r rspec_available rspec_status rspec_examples rspec_failures \
    rspec_pending rspec_time <<< "$rspec_result"

  # Determine overall status
  local overall_status="not_available"
  local any_available=false

  if [ "$rubocop_available" = "true" ] || [ "$rspec_available" = "true" ]; then
    any_available=true
    overall_status="passed"

    if [ "$rubocop_status" = "failed" ] || [ "$rspec_status" = "failed" ]; then
      overall_status="failed"
    fi
  fi

  # Generate summary
  local summary=""
  if [ "$any_available" = false ]; then
    summary="No quality checks available yet"
  elif [ "$overall_status" = "passed" ]; then
    summary="All quality checks passed"
  else
    summary="Some quality checks failed"
  fi

  # Build JSON output
  local json_output

  if has_jq; then
    # Use jq to build JSON (ensures proper escaping)
    json_output=$(jq -n \
      --arg timestamp "$timestamp" \
      --arg branch "$branch" \
      --arg commit "$commit" \
      --arg rubocop_available "$rubocop_available" \
      --arg rubocop_status "$rubocop_status" \
      --argjson rubocop_files "$rubocop_files" \
      --argjson rubocop_offenses "$rubocop_offenses" \
      --argjson rubocop_convention "$rubocop_convention" \
      --argjson rubocop_warning "$rubocop_warning" \
      --argjson rubocop_error "$rubocop_error" \
      --argjson rubocop_fatal "$rubocop_fatal" \
      --argjson rubocop_time "$rubocop_time" \
      --arg rspec_available "$rspec_available" \
      --arg rspec_status "$rspec_status" \
      --argjson rspec_examples "$rspec_examples" \
      --argjson rspec_failures "$rspec_failures" \
      --argjson rspec_pending "$rspec_pending" \
      --argjson rspec_time "$rspec_time" \
      --arg overall_status "$overall_status" \
      --arg summary "$summary" \
      '{
        timestamp: $timestamp,
        branch: $branch,
        commit: $commit,
        checks: {
          rubocop: {
            available: ($rubocop_available == "true"),
            status: $rubocop_status,
            files_inspected: $rubocop_files,
            offenses: $rubocop_offenses,
            offenses_by_severity: {
              convention: $rubocop_convention,
              warning: $rubocop_warning,
              error: $rubocop_error,
              fatal: $rubocop_fatal
            },
            execution_time: $rubocop_time
          },
          rspec: {
            available: ($rspec_available == "true"),
            status: $rspec_status,
            examples: $rspec_examples,
            failures: $rspec_failures,
            pending: $rspec_pending,
            execution_time: $rspec_time
          }
        },
        overall_status: $overall_status,
        summary: $summary
      }')
  else
    # Manual JSON construction (fallback when jq not available)
    log_warn "jq not available, using manual JSON construction"
    json_output=$(cat <<EOF
{
  "timestamp": "$(json_escape "$timestamp")",
  "branch": "$(json_escape "$branch")",
  "commit": "$(json_escape "$commit")",
  "checks": {
    "rubocop": {
      "available": $([[ "$rubocop_available" == "true" ]] && echo "true" || echo "false"),
      "status": "$(json_escape "$rubocop_status")",
      "files_inspected": $rubocop_files,
      "offenses": $rubocop_offenses,
      "offenses_by_severity": {
        "convention": $rubocop_convention,
        "warning": $rubocop_warning,
        "error": $rubocop_error,
        "fatal": $rubocop_fatal
      },
      "execution_time": $rubocop_time
    },
    "rspec": {
      "available": $([[ "$rspec_available" == "true" ]] && echo "true" || echo "false"),
      "status": "$(json_escape "$rspec_status")",
      "examples": $rspec_examples,
      "failures": $rspec_failures,
      "pending": $rspec_pending,
      "execution_time": $rspec_time
    }
  },
  "overall_status": "$(json_escape "$overall_status")",
  "summary": "$(json_escape "$summary")"
}
EOF
    )
  fi

  # Ensure baseline directory exists
  local baseline_dir=".claude/baseline"
  mkdir -p "$baseline_dir"

  # Write output file
  local output_file="${baseline_dir}/${branch}-${file_timestamp}.json"
  echo "$json_output" > "$output_file"

  log_success "Results saved to: $output_file"
  echo ""
  echo "Summary: $summary"
  echo ""

  # Pretty print JSON if jq available
  if has_jq; then
    echo "$json_output" | jq '.'
  else
    echo "$json_output"
  fi

  # Exit with appropriate code
  if [ "$overall_status" = "failed" ]; then
    exit 1
  else
    exit 0
  fi
}

# Run main function
main "$@"
