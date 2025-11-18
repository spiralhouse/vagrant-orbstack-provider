---
description: Write comprehensive handoff summary for session continuity
allowed-tools: mcp__linear__get_issue, mcp__linear__list_issues, Read, Write, Glob, Bash
model: sonnet
---

# /write-handoff - Session Handoff Generator

This command creates a comprehensive handoff summary that enables seamless session resumption. It captures all critical context so the next Claude session (or agent) can pick up exactly where you left off with zero knowledge loss.

## What This Command Does

When you run `/write-handoff`, Claude will:

1. Detect the current Linear issue context (if any)
2. Gather git repository state
3. Extract active todo list state
4. Analyze the conversation for key decisions and context
5. Identify open questions and blockers
6. Determine next steps
7. Write a comprehensive handoff document to `/tmp/`
8. Provide the filepath for the next session to resume

## Implementation Instructions

Follow these steps to create a complete handoff summary.

### Step 1: Detect Issue Context

**Objective**: Determine if there's a Linear issue actively being worked on.

**Actions**:
1. Search conversation history for recent Linear issue mentions:
   - Look for issue IDs in format `SPI-XXXX`
   - Check for `/develop` command invocations
   - Look for explicit issue references
2. Check current git branch for issue reference:
   - Run: `git rev-parse --abbrev-ref HEAD`
   - Parse branch name for pattern: `*/spi-XXXX-*` (case insensitive)
   - Extract issue ID if found
3. If issue ID found, fetch full issue details:
   - Use `mcp__linear__get_issue` with the issue ID
   - Capture: title, description, status, parent hierarchy
   - Handle errors gracefully (issue might not exist)

**Output**: Issue ID and full context, or NULL if no active issue detected

### Step 2: Gather Git State

**Objective**: Capture complete repository state for context.

**Actions**:
1. Get current branch:
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

2. Get repository status:
   ```bash
   git status --short
   ```

3. Get recent commits (last 3):
   ```bash
   git log -3 --oneline --no-decorate
   ```

4. Check for staged changes:
   ```bash
   git diff --cached --name-only
   ```

5. Check for unstaged changes:
   ```bash
   git diff --name-only
   ```

6. List untracked files:
   ```bash
   git ls-files --others --exclude-standard
   ```

**Output**: Complete git state snapshot including branch, commits, and all file changes

### Step 3: Extract Todo List State

**Objective**: Capture the current TodoWrite list with all statuses.

**Note**: TodoWrite maintains a list of tasks with statuses (completed/in_progress/pending).

**Actions**:
1. Review conversation history for TodoWrite invocations
2. Identify all tasks that have been:
   - Added to the list
   - Marked as completed
   - Marked as in progress
   - Updated or modified
3. Reconstruct the complete current state
4. Preserve task details including:
   - Task description
   - Status (✓ completed, → in progress, ☐ pending)
   - Any active forms or sub-items for in-progress tasks
   - Order/sequence of tasks

**Output**: Complete todo list in structured format

### Step 4: Analyze Session Context

**Objective**: Extract key decisions, discussions, and technical context from the session.

**Actions**:
1. Review conversation for:
   - **Architecture decisions**: Technical approach choices, design patterns selected
   - **Implementation details**: Code written, files created/modified, approaches taken
   - **Trade-offs discussed**: Options considered and why certain paths were chosen
   - **Constraints identified**: Technical limitations, dependencies, requirements
   - **Deferred decisions**: What was explicitly postponed and why

2. Identify work completed:
   - Features implemented
   - Tests written
   - Documentation updated
   - Commands/scripts created
   - Configuration changes

3. Extract technical context:
   - Which components were discussed/modified
   - Integration points touched
   - APIs or interfaces involved
   - External tools/services referenced

**Output**: Structured summary of session activities and decisions

### Step 5: Identify Open Questions & Blockers

**Objective**: Capture anything blocking progress or requiring resolution.

**Actions**:
1. Review conversation for:
   - **Explicit questions**: Direct questions asked to user
   - **Implicit uncertainties**: Areas where approach wasn't finalized
   - **Blockers**: Technical issues, missing information, external dependencies
   - **Pending user input**: Decisions waiting on user confirmation
   - **Research needed**: Areas requiring further investigation

2. For each item, capture:
   - The question/blocker description
   - Why it matters (context)
   - What decision is needed
   - Any suggested approaches or defaults

**Output**: List of open questions and blockers with context

### Step 6: Determine Next Steps

**Objective**: Provide clear guidance for resuming work.

**Actions**:
1. Based on:
   - Current todo list state
   - Work completed so far
   - Linear issue scope (if applicable)
   - Open questions/blockers

2. Identify:
   - **Immediate next task**: The specific next action to take
   - **Approach**: How to tackle it
   - **Required context**: What needs to be reviewed/understood first
   - **Prerequisites**: Any setup or decisions needed before proceeding
   - **Success criteria**: How to know the next task is complete

3. Provide:
   - Clear, actionable next steps (numbered list)
   - Specific file paths or commands when relevant
   - Links to relevant documentation
   - Estimated effort or complexity if known

**Output**: Clear, actionable next steps for session resumption

### Step 7: Determine Output Filepath

**Objective**: Choose an appropriate filename for the handoff document.

**Logic**:
```
IF Linear issue ID detected:
  filename = "/tmp/{issue-id}-handoff-summary.md"
  (e.g., "/tmp/spi-1146-handoff-summary.md")
ELSE:
  timestamp = current ISO 8601 timestamp
  filename = "/tmp/handoff-{timestamp}.md"
  (e.g., "/tmp/handoff-2025-11-17T143045Z.md")
```

**Note**: Always use `/tmp/` directory for handoff files to avoid cluttering the repository.

### Step 8: Write Handoff Document

**Objective**: Create a comprehensive, well-structured handoff markdown file.

**Document Structure**:

```markdown
# Session Handoff: {Issue ID or "General Work"}

**Created**: {ISO 8601 timestamp with timezone}
**Branch**: {git branch name}
**Linear Issue**: {issue ID and link, or "N/A"}
**Session Duration**: {estimated duration if determinable}

---

## Issue Context

{IF Linear issue detected:}

**Issue**: [{Issue ID}] {Issue Title}
**Status**: {Current status}
**Link**: https://linear.app/spiral-house/issue/{issue-id}

### Issue Description
{Brief summary or full description from Linear}

### Issue Hierarchy
{If parent issues exist, show hierarchy:}
Epic: [SPI-XXX] {Epic Title}
  └─ Story: [SPI-XXX] {Story Title}
      └─ Subtask: [SPI-XXX] {Subtask Title} ← **This Issue**

{IF no Linear issue:}
No active Linear issue detected. This session involved general development work.

---

## Git Repository State

**Branch**: `{branch name}`
**Status**: {Summary: clean, modified files, untracked files, etc.}

### Recent Commits
{Last 3 commits if any}
```
{commit hash} {commit message}
{commit hash} {commit message}
{commit hash} {commit message}
```

### File Changes

#### Staged Changes
{List of staged files, or "None"}
- {file path}
- {file path}

#### Unstaged Changes
{List of modified files, or "None"}
- {file path}
- {file path}

#### Untracked Files
{List of untracked files, or "None"}
- {file path}
- {file path}

---

## Work Completed

{Bulleted list of tasks/features completed this session}

- ✓ {Completed task 1}
- ✓ {Completed task 2}
- ✓ {Completed task 3}

### Files Created/Modified
{List significant files with brief description}
- `{file path}` - {what was done}
- `{file path}` - {what was done}

### Tests Written
{List tests if any}
- {Test description}

### Documentation Updated
{List docs updated if any}
- {Doc file and what changed}

---

## TDD Status

**Current Phase**: [RED/GREEN/REFACTOR/Complete]

**Test Coverage**:
- Unit tests: [count] examples, [count] failures
- Integration tests: [count] examples, [count] failures
- Overall: [X]% coverage (from latest baseline-check)

**Pending Tests**:
- [ ] [Test scenario not yet written]
- [ ] [Test scenario not yet written]

**Technical Debt** (from software-architect):
- [Issue identified during REFACTOR phase]
- [Pattern improvement opportunity]

**TDD Workflow Notes**:
- [Which phase was in progress]
- [Any blockers in RED-GREEN-REFACTOR cycle]

---

## Active Todo List

{Complete TodoWrite state with all tasks}

### Completed
- [x] {Task 1}
- [x] {Task 2}

### In Progress
- [→] {Task 3}
  {Any active form or sub-items}

### Pending
- [ ] {Task 4}
- [ ] {Task 5}
- [ ] {Task 6}

---

## Key Decisions & Context

{Important technical decisions and context from the session}

### Architecture Decisions
1. **{Decision topic}**: {What was decided and why}
2. **{Decision topic}**: {What was decided and why}

### Technical Approach
{High-level description of approach taken}

### Trade-offs Considered
- **{Option A vs Option B}**: Chose {selection} because {rationale}

### Deferred Decisions
{Decisions explicitly postponed}
- **{Decision}**: Deferred because {reason}

### Important Context
{Any other critical context for continuity}
- {Context item 1}
- {Context item 2}

---

## Open Questions & Blockers

{IF there are open questions or blockers:}

### Questions Requiring Resolution
1. **{Question}**
   - **Context**: {Why this matters}
   - **Impact**: {What depends on this}
   - **Suggested Approach**: {If applicable}

### Blockers
1. **{Blocker description}**
   - **Type**: {Technical/External/Waiting on user/etc.}
   - **Impact**: {What's blocked}
   - **Resolution Path**: {How to unblock}

{IF no blockers:}
No open questions or blockers identified.

---

## Next Steps

{Clear, actionable steps for resuming work}

### Immediate Next Task
{Specific description of the next action to take}

### Recommended Approach
1. {Step 1 - be specific}
2. {Step 2 - include commands/files when relevant}
3. {Step 3}

### Prerequisites
{Anything needed before starting}
- {Prerequisite 1}
- {Prerequisite 2}

### Success Criteria
{How to know the next task is complete}
- [ ] {Criterion 1}
- [ ] {Criterion 2}

---

## Context References

### Documentation Reviewed
- `{doc path}` - {what section}
- `{doc path}` - {what section}

### Key Code Files
- `{file path}` - {what component}
- `{file path}` - {what component}

### Linear Issues Related
- [{Issue ID}]({link}) - {relation}

### External Resources
- {URL or resource} - {what it covers}

---

## Session Summary

{2-3 sentence summary of what was accomplished and the state of work}

---

## Resuming This Session

To resume this work in a new session:

1. Read this handoff: `/read-handoff {filepath}`
2. Review the Linear issue: https://linear.app/spiral-house/issue/{issue-id}
3. Check git status: `git status`
4. Continue with: {Immediate next task summary}

---

*Handoff generated at {timestamp} by Claude Code*
```

**Quality Guidelines**:

- **Be comprehensive**: Include all relevant context, err on the side of too much info
- **Be specific**: Use exact file paths, class names, line numbers when relevant
- **Be actionable**: Next steps should be crystal clear
- **Be structured**: Use consistent formatting and headings
- **Be scannable**: Use lists, bold text, and clear sections
- **Be honest**: Note uncertainties and open questions clearly

### Step 9: Confirm Output

**Objective**: Inform user of successful handoff creation.

**Actions**:
1. Write the handoff document to the determined filepath
2. Confirm file was written successfully
3. Print clear message to user with:
   - Filepath where handoff was saved
   - Brief summary of what was captured
   - Reminder about `/read-handoff` command for resumption
   - File size or line count (optional context)

**Example Output**:
```
✓ Handoff summary written to: /tmp/spi-1146-handoff-summary.md

Captured:
- Linear issue: SPI-1146 (Claude Code configuration improvements)
- Git state: 4 modified files on branch johnburbridge/spi-1146-*
- Todo list: 7 tasks (3 completed, 1 in progress, 3 pending)
- 5 key decisions documented
- Next step: Complete /write-handoff command implementation

To resume this work in a new session:
  /read-handoff /tmp/spi-1146-handoff-summary.md
```

## Special Cases & Error Handling

### No Git Repository
- If not in a git repository, note this in the handoff
- Skip git-specific sections
- Still capture session context and next steps

### No Linear Issue
- Create handoff based on general session context
- Use timestamp-based filename
- Focus on work completed and next steps
- Note "General development work" as context

### Empty Todo List
- Note "No TodoWrite list active this session"
- Still capture work completed from conversation analysis
- Focus on implicit next steps based on discussion

### Multiple Possible Issues
- If multiple issues detected, ask user to clarify
- Or use most recently mentioned issue
- Document other related issues in "Context References"

### No Recent Activity
- If conversation is minimal, create minimal handoff
- Focus on current state and available context
- Note that session was brief

## Testing Recommendations

After implementing this command, test with:

1. **Active development session**: With Linear issue, git changes, active todos
2. **Minimal session**: Just exploration, no specific issue
3. **Complex session**: Multiple issues discussed, many decisions made
4. **Session with blockers**: Open questions and waiting on user input

Verify that:
- All context is captured accurately
- File is written to correct location
- Content is well-structured and readable
- Next steps are clear and actionable
- Issue references are correct and linked

## Integration with /read-handoff

This command pairs with `/read-handoff` (to be implemented):
- `/write-handoff` creates the summary
- `/read-handoff {filepath}` loads it in a new session
- Together they enable seamless session continuity

The handoff format is designed to be:
- Human-readable (can be reviewed manually)
- Machine-parseable (can be loaded by `/read-handoff`)
- Comprehensive (includes all critical context)
- Actionable (enables immediate work resumption)

## Notes for Claude

When executing this command:

- **Be thorough**: Capture all relevant context, don't skimp on details
- **Be specific**: Use exact paths, names, references
- **Be honest**: Note what's unclear or uncertain
- **Be helpful**: Make resumption as smooth as possible
- **Be structured**: Follow the document format consistently
- **Ask if unsure**: Better to clarify than assume

This command is critical for maintaining continuity across sessions. Execute it with care and completeness.
