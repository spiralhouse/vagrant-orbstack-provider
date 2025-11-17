# Claude Scripts

This directory contains automation scripts for the vagrant-orbstack-provider project.

## baseline-check.sh

A bash wrapper script that executes project quality checks (RuboCop and RSpec) and outputs results in standardized JSON format.

### Features

- Executes RuboCop and RSpec quality checks
- Outputs results in standardized JSON format
- Gracefully handles missing tools (useful during early project lifecycle)
- Saves timestamped results to `.claude/baseline/`
- Provides colored console output for readability
- Measures execution time for each check

### Usage

```bash
# Run from project root
.claude/scripts/baseline-check.sh

# Or make it executable and run directly
chmod +x .claude/scripts/baseline-check.sh
./claude/scripts/baseline-check.sh
```

### Exit Codes

- `0` - Success (all checks passed or none available)
- `1` - Check failures (one or more checks failed)
- `2` - Script error (not in git repo, etc.)

### Output

The script generates two types of output:

1. **Console output**: Colored status messages and summary
2. **JSON file**: Detailed results saved to `.claude/baseline/{branch}-{timestamp}.json`

### JSON Output Schema

```json
{
  "timestamp": "ISO-8601 format",
  "branch": "git branch name",
  "commit": "short git SHA",
  "checks": {
    "rubocop": {
      "available": boolean,
      "status": "passed|failed|not_available",
      "files_inspected": number,
      "offenses": number,
      "offenses_by_severity": {
        "convention": number,
        "warning": number,
        "error": number,
        "fatal": number
      },
      "execution_time": number
    },
    "rspec": {
      "available": boolean,
      "status": "passed|failed|not_available",
      "examples": number,
      "failures": number,
      "pending": number,
      "execution_time": number
    }
  },
  "overall_status": "passed|failed|not_available",
  "summary": "human-readable summary"
}
```

### Requirements

- Git repository (script must be run from within a git repo)
- Bundler (uses `bundle exec` for RuboCop and RSpec)
- Optional: `jq` (for better JSON formatting, falls back to manual construction)

### Example Output

When no checks are available (early project):
```
[INFO] Starting baseline quality checks...
[INFO] Branch: main
[INFO] Commit: 168d4ea
[INFO] Checking RuboCop availability...
[WARN] RuboCop not available (bundle exec rubocop failed)
[INFO] Checking RSpec availability...
[WARN] RSpec not available (bundle exec rspec failed)
[SUCCESS] Results saved to: .claude/baseline/main-20251117-084447.json

Summary: No quality checks available yet
```

When checks are available and passing:
```
[INFO] Starting baseline quality checks...
[INFO] Branch: feature/provider-implementation
[INFO] Commit: abc123f
[INFO] Checking RuboCop availability...
[INFO] RuboCop is available, running checks...
[SUCCESS] RuboCop passed (15 files, 0 offenses)
[INFO] Checking RSpec availability...
[INFO] RSpec is available, running tests...
[SUCCESS] RSpec passed (42 examples, 0 failures, 0 pending)
[SUCCESS] Results saved to: .claude/baseline/feature-provider-implementation-20251117-091234.json

Summary: All quality checks passed
```

### Integration

This script can be integrated into:

- Git hooks (pre-commit, pre-push)
- CI/CD pipelines
- Development workflows
- Quality monitoring dashboards

### Maintenance

The script is designed to be:
- Self-contained (minimal dependencies)
- Robust (handles missing tools gracefully)
- Future-proof (easy to add new checks)
- Verbose (clear logging for debugging)
