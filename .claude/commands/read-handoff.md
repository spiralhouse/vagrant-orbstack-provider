---
description: Resume session from handoff summary file
argument-hint: "[filename]"
model: sonnet
---

# Resume Session from Handoff

You are resuming a development session from a comprehensive handoff summary. The handoff file contains all necessary context to continue work seamlessly.

## Load Handoff Document

@$1

---

## Your Task: Restore Full Session Context

You have just loaded a handoff summary that was created using `/write-handoff`. Your responsibility is to fully internalize this context and prepare to continue the work exactly where it was left off.

### Step 1: Deep Context Analysis

Read the handoff document carefully and extract:

**Issue Context**:
- What Linear issue is being worked on (if any)
- Issue title, description, and acceptance criteria
- Where the issue fits in the hierarchy (Epic → Story → Subtask)
- Current issue status

**Repository State**:
- Current git branch
- Recent commits
- Staged, unstaged, and untracked files
- Overall repository cleanliness

**Work Completed**:
- What features/tasks have been implemented
- What files were created or modified
- What tests were written
- What documentation was updated

**TDD Status**:
- Current TDD phase (RED/GREEN/REFACTOR/Complete)
- Test coverage metrics
- Pending tests
- Technical debt notes from software-architect
- Blockers in TDD cycle

**Todo List State**:
- All completed tasks (✓)
- Current in-progress task (→)
- All pending tasks (☐)
- The exact structure and wording

**Key Decisions**:
- Architecture decisions made
- Technical approach chosen
- Trade-offs considered
- Deferred decisions and why

**Open Questions & Blockers**:
- Unresolved questions
- Active blockers
- Pending user input
- Research needed

**Next Steps**:
- Immediate next task
- Recommended approach
- Prerequisites
- Success criteria

### Step 2: Recreate Todo List

**Critical**: If the handoff includes a todo list, you MUST recreate it using the TodoWrite tool.

**Actions**:
1. Extract the exact todo list from the "Active Todo List" section
2. Preserve all task descriptions exactly as written
3. Set the correct status for each task:
   - Completed tasks: Use the completed status
   - In-progress task: Use the in-progress status with active forms if present
   - Pending tasks: Use the pending status
4. Maintain the same task order
5. Invoke TodoWrite to recreate the list

**Example**:
If handoff shows:
```markdown
### Completed
- [x] Create command structure
- [x] Implement context gathering

### In Progress
- [→] Write handoff document
  - Structure defined
  - Frontmatter complete

### Pending
- [ ] Test command execution
- [ ] Create read-handoff command
```

Then you should use TodoWrite to recreate this exact state.

### Step 3: Verify Current State

Before proceeding, verify the environment matches the handoff:

**Git Branch Check**:
```bash
git rev-parse --abbrev-ref HEAD
```
Compare to the branch listed in the handoff. If different, note this discrepancy.

**Git Status Check**:
```bash
git status --short
```
Compare to the file changes in the handoff. Note any differences.

**File Existence**:
- Spot-check that key files mentioned in "Files Created/Modified" exist
- If files are missing, note this as a potential issue

**Note Discrepancies**: If anything doesn't match, inform the user immediately.

### Step 4: Prepare for Continuation

Based on the handoff, prepare yourself to continue work:

**Review Next Steps**:
- Understand the immediate next task clearly
- Review the recommended approach
- Identify any prerequisites needed
- Know the success criteria

**Load Necessary Context**:
- If specific files are mentioned, prepare to read them
- If documentation is referenced, note which docs are relevant
- If Linear issue is active, be ready to reference it

**Identify Blockers**:
- Note any open questions that need resolution
- Identify any blockers that must be addressed first
- Prepare to ask user about these before proceeding

### Step 5: Communicate with User

Provide a clear, structured summary to the user:

**Format**:
```markdown
# Session Resumed: {Issue ID or General Work}

## Context Restored

**Linear Issue**: [{Issue ID}] {Issue Title} (if applicable)
**Branch**: `{branch name}`
**Status**: {Brief summary of current state}

## Work Completed (Previous Session)

{Summarize 3-5 key accomplishments}

## TDD Status Restored

**Phase**: [RED/GREEN/REFACTOR/Complete]
**Coverage**: [X]% ([Y] examples, [Z] failures)

**Pending Tests**:
[List from handoff]

**Technical Debt**:
[List from handoff]

**Next TDD Action**: [What phase to continue from]

## Current Todo List

{Show the recreated todo list with current status}

## What's Next

**Immediate Task**: {Description of next task}

**Approach**:
{1-3 sentence summary of how to tackle it}

**Prerequisites**:
{Any blockers or questions that need resolution}

## Questions for You

{If any open questions or blockers exist, list them}
{If state verification found discrepancies, ask about them}
{Otherwise, ask: "Ready to proceed with {next task}?"}
```

**Communication Guidelines**:
- Be concise but complete
- Highlight any blockers or open questions prominently
- Make it easy for user to confirm you have the right context
- Express readiness to continue or need for clarification
- Don't assume—if anything is unclear, ask

### Step 6: Ready for Action

Once you've communicated your understanding:

**If everything is clear**:
- Wait for user confirmation to proceed
- Be ready to execute the next steps immediately
- Have relevant files and context at hand

**If there are questions**:
- Don't proceed until questions are resolved
- Be specific about what you need to know
- Offer options or suggested approaches where appropriate

**If state mismatches**:
- Ask user if environment has changed
- Confirm whether to proceed despite differences
- Suggest corrective actions if needed

---

## Special Cases

### No Todo List in Handoff
If the handoff has no active todo list:
- Note this in your summary
- Focus on the "Next Steps" section
- Offer to create a new todo list based on remaining work

### No Linear Issue
If this is general development work:
- Note "General development session (no Linear issue)"
- Focus on work completed and next steps
- Continue based on session context

### Handoff from Different User
If the handoff might be from a different developer:
- Review their decisions carefully
- Note any questions about approach
- Respect their context and rationale

### Stale Handoff
If the handoff timestamp is old (days/weeks):
- Note the timestamp to user
- Suggest checking if context is still valid
- Ask if any changes have occurred since then

### Blockers Present
If handoff lists blockers:
- Highlight these prominently in your summary
- Ask user if blockers have been resolved
- Don't proceed to blocked work without confirmation

---

## Error Handling

### File Not Found
If the handoff file doesn't exist:
- Provide a clear error message
- Check if user provided correct path
- Suggest using `ls /tmp/` to find handoff files

### Malformed Handoff
If the handoff is missing critical sections:
- Load what context you can
- Note which sections are missing
- Ask user if this is the correct file

### Git State Mismatch
If current state significantly differs from handoff:
- Don't assume the environment is correct
- Present the differences clearly
- Ask user which state is correct

---

## Quality Standards

When resuming a session, ensure you:

- [ ] Load and read the entire handoff document
- [ ] Extract all critical context accurately
- [ ] Recreate the todo list if present
- [ ] Verify current environment state
- [ ] Identify and highlight any blockers
- [ ] Provide clear summary to user
- [ ] Ask clarifying questions if anything is unclear
- [ ] Wait for user confirmation before proceeding
- [ ] Express readiness to continue work

---

## Think Deeply

Take your time to fully absorb the handoff context. This is critical for maintaining work quality and continuity across sessions.

**Consider**:
- What was the developer's mental model?
- What decisions were made and why?
- What's the natural next step in the workflow?
- What questions or blockers need resolution?
- How can you minimize context loss?

The goal is seamless continuation—the user should feel like there was no session break at all.

---

## Integration with /write-handoff

These commands form a complete handoff cycle:

```bash
# End of session
/write-handoff
# Output: /tmp/spi-1146-handoff-summary.md

# New session (hours/days later)
/read-handoff /tmp/spi-1146-handoff-summary.md
# Result: Full context restored, ready to continue
```

Your successful execution of this command ensures zero knowledge loss across sessions and enables productive work resumption.
