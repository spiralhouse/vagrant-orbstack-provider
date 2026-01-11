---
description: Analyze Linear issue and create comprehensive development plan
argument-hint: "[SPI-xxx]"
allowed-tools: mcp__linear__get_issue, mcp__linear__update_issue, mcp__linear__create_comment, Grep, Read, WebFetch, Glob
model: sonnet
---

# /develop - Engineering Manager Workflow

This command implements the Engineering Manager workflow for analyzing Linear issues and creating comprehensive development plans. It's the centerpiece of our development workflow automation.

## What This Command Does

Fetches Linear issue + hierarchy, searches docs, analyzes scope/complexity, determines delegation, updates Linear status, posts plan.

## Workflow Instructions

Follow these steps in order. Be thorough but respect YAGNI principles.

### Step 1: Fetch Linear Issue Hierarchy

Fetch issue via `mcp__linear__get_issue($1)`, recursively fetch parents (subtask → story → epic). Handle missing parents gracefully.

### Step 2: Search Related Documentation

Check `docs/PRD.md` and `docs/DESIGN.md`. Use `Grep` for issue keywords, component names. Note missing docs if none found.

### Step 3: Deep Analysis

Analyze: scope (in/out), complexity (Fibonacci: 1-21 points), technical approach, YAGNI, design doc needs, testing, documentation, risks.

**Design doc needed?** Only for architecture changes, major new systems, complex integrations, or high risk. Skip for small features, bugs, docs.

### Step 4: Agent Delegation Strategy

**Agents**: test-engineer, ruby-developer, software-architect, documentation-writer, code-reviewer, release-engineer

**Typical sequence**: RED (test-engineer) → GREEN (ruby-developer) → REFACTOR (architect → dev → test-engineer) → docs (documentation-writer) → review (code-reviewer)

Provide context: what to build/test, design decisions, constraints, success criteria, files.

### Step 5: Identify Clarifying Questions

List unclear requirements, multiple approaches, missing criteria. Don't ask about things in PRD/DESIGN or already decided.

### Step 6: Check for Subtask/Issue Needs

Recommend breakdown if > 13 points, multiple components, or parallelizable. Flag in plan, don't auto-create.

### Step 7: Update Linear Issue

Use `mcp__linear__update_issue` (state: `a433a32b-b815-4e11-af23-a74cb09606aa`). Use `mcp__linear__create_comment` to post plan. Handle failures gracefully.

### Step 8: Present Development Plan

**Format sections**: Executive Summary, Hierarchy, Scope (In/Out/YAGNI), Technical Approach, TDD Workflow, Agent Delegation, Testing, Docs, Success Criteria, Risks, Estimate, Questions, Next Steps

**TDD Workflow section**: Include RED/GREEN/REFACTOR phases with agent assignments and TDD mandate warning.

**See existing plan examples in Linear for full format.**

## Quality Guidelines

Balance quality with YAGNI. Stay in scope, ask clarifying questions if unclear. Follow Ruby style guide, YARD comments, conventional commits. Check DESIGN.md for patterns.

## Notes

Be thorough but efficient. Use all context (hierarchy, docs, conventions). Apply YAGNI, be specific (file paths, class names), update Linear reliably.
