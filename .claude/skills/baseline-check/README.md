# Baseline Check Skill

An autonomous Claude Code skill that tracks code quality baselines throughout the development lifecycle.

## Overview

The `baseline-check` skill provides automated quality tracking by:
- Running RuboCop (Ruby style/lint checks) and RSpec (test suite)
- Establishing quality baselines before development work
- Detecting regressions after code changes
- Comparing metrics across development sessions
- Providing actionable feedback on code health

## How It Works

### Autonomous Activation

This skill activates automatically when Claude detects relevant triggers:
- Before starting development work
- After completing code changes
- When quality concerns are mentioned
- Before creating pull requests
- When running tests is appropriate

### Quality Tracking Process

1. **Execute Checks**: Runs `baseline-check.sh` wrapper script
2. **Capture Metrics**: Saves results to `.claude/baseline/{branch}-{timestamp}.json`
3. **Compare Baselines**: Finds previous baseline for the same branch
4. **Analyze Trends**: Identifies improvements, regressions, or stability
5. **Report Findings**: Provides clear, actionable feedback

## Components

### 1. SKILL.md
Instructs Claude on when and how to use the skill, including:
- Trigger conditions for autonomous activation
- Step-by-step execution instructions
- Baseline comparison logic
- Report formatting guidelines

### 2. baseline-check.sh
Wrapper script that:
- Executes RuboCop and RSpec via `bundle exec`
- Outputs standardized JSON format
- Gracefully handles missing tools
- Tracks git branch and commit context
- Measures execution time

### 3. Baseline Storage
Quality snapshots stored in `.claude/baseline/`:
- Format: `{branch}-{yyyymmdd-hhmmss}.json`
- Timestamped for comparison over time
- Branch-specific for isolation
- Gitignored (local development artifacts)

## JSON Output Schema

```json
{
  "timestamp": "2025-11-17T09:15:42Z",
  "branch": "feat/new-feature",
  "commit": "abc123f",
  "checks": {
    "rubocop": {
      "available": true,
      "status": "passed",
      "files_inspected": 15,
      "offenses": 3,
      "offenses_by_severity": {
        "convention": 2,
        "warning": 1,
        "error": 0,
        "fatal": 0
      },
      "execution_time": 1.45
    },
    "rspec": {
      "available": true,
      "status": "passed",
      "examples": 42,
      "failures": 0,
      "pending": 2,
      "execution_time": 3.21
    }
  },
  "overall_status": "passed",
  "summary": "All checks passed"
}
```

## Usage

### Manual Execution

Run the script directly from project root:

```bash
./.claude/skills/baseline-check/baseline-check.sh
```

### Autonomous Execution

The skill runs automatically when Claude determines it's appropriate. No explicit invocation needed.

### Exit Codes

- `0` - Success (all checks passed or none available)
- `1` - Check failures (one or more checks failed)
- `2` - Script error (not in git repo, JSON generation failed)

## Example Workflow

### Initial Baseline

```
User: "I want to add SSH support to the provider"

Claude: [baseline-check skill activates]
Running quality baseline check...

Baseline Quality Check - Initial Assessment
==========================================

Branch: main
Commit: 168d4ea

RuboCop: 15 files, 0 offenses ✓
RSpec: 42 examples, 0 failures ✓

Overall Status: PASSED ✓

This is the first baseline for this branch. Future checks will compare against these metrics.

[Proceeds with implementation...]
```

### Post-Development Comparison

```
Claude: [After implementation, baseline-check skill activates again]
Running quality baseline check...

Baseline Quality Check - Regression Analysis
============================================

RuboCop Changes:
  Files Inspected: 15 → 18 (+3)
  Total Offenses: 0 → 2 (+2) ⚠️ REGRESSION
    - Convention: 0 → 2 (+2)

RSpec Changes:
  Examples: 42 → 48 (+6) ✓ IMPROVEMENT
  Failures: 0 → 0 (stable)

FINDINGS:
⚠️  2 new RuboCop convention offenses
✓  6 new tests added

RECOMMENDATION:
Consider addressing the new RuboCop offenses before committing.
Run 'bundle exec rubocop -a' to auto-fix.
```

## Integration Points

### Git Workflow
- Pre-commit: Establish baseline before changes
- Post-implementation: Detect regressions
- Pre-push: Ensure quality standards met

### Development Cycle
- Feature start: Initial quality snapshot
- During development: Periodic checks
- Feature complete: Final verification
- Pull request: Include quality metrics

### Quality Gates
- Block commits with fatal errors or test failures
- Warn on convention/warning increases
- Celebrate quality improvements

## Best Practices

1. **Run Before Starting**: Establishes clean baseline
2. **Run After Changes**: Catches issues early
3. **Don't Ignore Warnings**: Small regressions accumulate
4. **Fix Criticals First**: Never commit with fatals/errors/failures
5. **Track Trends**: Review baselines over feature lifecycle

## Requirements

- Git repository (must be run from within repo)
- Ruby project with Bundler
- Optional: RuboCop gem (for style checks)
- Optional: RSpec gem (for test suite)
- Optional: `jq` (for prettier JSON, falls back gracefully)

## Maintenance

The skill is designed to be:
- **Self-contained**: All files colocated in skill directory
- **Portable**: No hardcoded paths, works in any Ruby project
- **Robust**: Handles missing tools gracefully
- **Extensible**: Easy to add new quality checks
- **Informative**: Clear logging and detailed reports

## Files

```
.claude/skills/baseline-check/
├── SKILL.md              # Claude instructions for skill execution
├── baseline-check.sh     # Wrapper script for quality checks
└── README.md            # This file - skill documentation
```

## See Also

- `SKILL.md` - Detailed skill execution instructions for Claude
- `.claude/baseline/` - Baseline storage directory (gitignored)
- `CLAUDE.md` - Project workflow documentation
