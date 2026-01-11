---
description: Write comprehensive handoff summary for session continuity
allowed-tools: mcp__linear__get_issue, mcp__linear__list_issues, Read, Write, Glob, Bash
model: sonnet
---

# /write-handoff - Session Handoff Generator

This command creates a comprehensive handoff summary that enables seamless session resumption. It captures all critical context so the next Claude session (or agent) can pick up exactly where you left off with zero knowledge loss.

## What This Command Does

Detects Linear context, gathers git state, extracts todos, analyzes decisions, identifies blockers, determines next steps, writes handoff to `/tmp/`.

## Implementation Instructions

Follow these steps to create a complete handoff summary.

### Step 1: Detect Issue Context

Search conversation for `SPI-XXXX`, check git branch name (`git rev-parse --abbrev-ref HEAD`). If found, fetch via `mcp__linear__get_issue`.

### Step 2: Gather Git State

Run: `git rev-parse --abbrev-ref HEAD`, `git status --short`, `git log -3 --oneline`, `git diff --cached --name-only`, `git diff --name-only`, `git ls-files --others --exclude-standard`

### Step 3: Extract Todo List State

Review conversation for TodoWrite invocations. Reconstruct current state (completed/in_progress/pending) with task descriptions.

### Step 4: Analyze Session Context

Extract: architecture decisions, implementation details, trade-offs, constraints, deferred decisions, work completed, technical context.

### Step 5: Identify Open Questions & Blockers

List: explicit questions, uncertainties, blockers, pending user input, research needed. Include context and suggested approaches.

### Step 6: Determine Next Steps

Based on todo list, work completed, Linear scope, blockers: provide immediate next task, approach, prerequisites, success criteria. Be specific (file paths, commands).

### Step 7: Determine Output Filepath

If issue ID: `/tmp/{issue-id}-handoff-summary.md`. Else: `/tmp/handoff-{timestamp}.md`

### Step 8: Write Handoff Document

**Sections**: Header (created, branch, Linear issue), Issue Context, Git State, Work Completed, TDD Status, Active Todos, Key Decisions, Open Questions/Blockers, Next Steps, Context References, Session Summary, Resuming Instructions

**Structure**:

**See existing handoff examples for full format.** Include all context comprehensively with specific file paths, clear next steps.

### Step 9: Confirm Output

Write handoff, confirm success, print message with filepath, summary of captured content, and `/read-handoff` reminder.

## Special Cases

**No git repo**: Skip git sections, note in handoff
**No Linear issue**: Use timestamp filename, note "General development work"
**Empty todos**: Note "No TodoWrite active", capture implicit next steps
**Multiple issues**: Ask user to clarify or use most recent
**Minimal activity**: Create minimal handoff noting brief session

## Notes

Be thorough, specific, honest, helpful, structured. Test with active development, minimal, complex, and blocked sessions. Pairs with `/read-handoff` for session continuity.
