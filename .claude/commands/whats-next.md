---
description: Analyze project state and recommend optimal next task
allowed-tools: Bash, mcp__linear__list_issues, mcp__linear__get_issue, Read, Grep
model: sonnet
---

# /whats-next - Smart Task Recommendation Engine

This command analyzes the complete project state and recommends the optimal next task to work on. It combines test status, git history, Linear issue priorities, and strategic factors to provide intelligent task selection.

## What This Command Does

When you run `/whats-next`, Claude will:

1. **Quality Gate**: Run test suite and block if tests are failing
2. **Git Analysis**: Examine current branch, recent commits, working directory status
3. **Linear Analysis**: Fetch all project issues, group by status, analyze priorities
4. **Decision Logic**: Apply strategic and tactical factors to recommend the best next task
5. **Structured Output**: Present recommendation with rationale, context, and alternatives

## Workflow Instructions

Follow these steps in exact order. This is a quality-first, data-driven workflow.

### Step 1: Quality Gate - Test Suite Status

**CRITICAL**: This must be the FIRST step. Quality comes before all other work.

**Objective**: Verify that the test suite is passing before recommending new work.

**Actions**:
1. Run the test suite:
   ```bash
   bundle exec rspec
   ```

2. Capture the exit code

3. **Decision Point**:

   **IF exit code != 0 (tests failing)**:
   - STOP immediately
   - DO NOT proceed with analysis
   - Output the following message:

   ```markdown
   # ⚠️  Test Suite Failing - Fix Tests First

   The test suite has failing tests. You must fix these before starting new work.

   **Why This Matters**:
   Test failures indicate existing functionality is broken. Adding new work on top of
   a broken foundation leads to compounding issues and makes debugging harder.

   **Next Steps**:
   1. Run `bundle exec rspec` to see detailed test failures
   2. Fix the failing tests
   3. Commit the fixes
   4. Then run `/whats-next` again

   **TDD Principle**: Always maintain a green test suite. Never build on a red foundation.
   ```

   - END execution here

   **IF exit code == 0 (all tests passing)**:
   - Note: "✓ Test suite passing - proceeding with analysis"
   - Continue to Step 2

**Why This Step Is First**:
- Enforces quality-first culture
- Prevents compounding technical debt
- Ensures new work builds on solid foundation
- Aligns with TDD principles (maintain green suite)
- Forces discipline in development workflow

### Step 2: Analyze Git State

**Objective**: Understand current repository state and recent development activity.

**Actions**:

1. **Get current branch**:
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```
   - Capture branch name
   - Determine if on `main` or feature branch
   - Extract issue ID if present in branch name (pattern: `*/spi-XXXX-*`)

2. **Get recent commit history** (last 10 commits):
   ```bash
   git log -10 --oneline --no-decorate
   ```
   - Analyze commit messages for patterns
   - Identify which features were recently completed
   - Look for issue references (SPI-XXX format)
   - Detect focus areas (what's been worked on recently)

3. **Check working directory status**:
   ```bash
   git status --short
   ```
   - Count staged files
   - Count unstaged changes
   - Count untracked files
   - Determine overall cleanliness

4. **Analyze uncommitted changes**:
   ```bash
   git diff --name-only
   ```
   - Identify which files have changes
   - Infer what work is in progress
   - Detect potential WIP (work in progress)

**Extract Intelligence**:
- **Recent Focus**: What areas have been active (provider, actions, tests, docs)?
- **Work Pattern**: Frequent commits or long gaps?
- **Current Context**: Is there work in progress?
- **Branch Status**: Clean main or active feature branch?

**Output Context**:
```
Git Analysis:
- Branch: {branch name}
- Recent Activity: {summary of last 10 commits}
- Working Directory: {clean | X modified, Y staged, Z untracked}
- Inferred WIP: {yes/no - what work appears in progress}
```

### Step 3: Fetch and Analyze Linear Issues

**Objective**: Get complete view of all project work items and their current state.

**Actions**:

1. **Fetch all issues for the vagrant-orbstack-provider project**:
   ```
   Use mcp__linear__list_issues with filters:
   - Project: "vagrant-orbstack-provider" (ID: 17cca0c7-f003-4fd8-9be2-327349fb6e15)
   - Include all states
   - Fetch: id, identifier, title, description, state, priority, estimate,
           parent (for hierarchy), children (for dependencies)
   ```

2. **Group issues by workflow state**:
   - **In Progress** (state ID: `a433a32b-b815-4e11-af23-a74cb09606aa`)
   - **Todo** (state ID: `fc814d1f-22b5-4ce6-8b40-87c1312d54ba`)
   - **Backlog** (state ID: `1e7bd879-6685-4d94-8887-b7709b3ae6e8`)
   - **In Review** (state ID: `8d617a10-15f3-4e26-ad28-3653215c2f25`)
   - **Done** (state ID: `3d267fcf-15c0-4f3a-8725-2f1dd717e9e8`)
   - **Canceled/Duplicate** (ignore these)

3. **For each issue, determine**:
   - **Type**: Epic, Story, or Subtask (based on parent/children relationships)
   - **Priority**: Urgent (1), High (2), Normal (3), Low (4), or unset
   - **Estimate**: Story points if set
   - **Dependencies**: What it depends on, what depends on it
   - **Hierarchy**: Parent issue (if any)
   - **Blocked Status**: Are dependencies completed?

4. **Build dependency graph**:
   - Map parent-child relationships
   - Identify which issues are blocked by others
   - Find issues that are ready to start (no blockers)

**Edge Cases**:
- **No issues in Backlog/Todo**: Flag this condition
- **All issues in Done/Canceled**: Flag this condition
- **Multiple issues In Progress**: Note as potential WIP limit violation

**Output Context**:
```
Linear Analysis:
- In Progress: X issues
- Todo: Y issues (Z ready to start, W blocked)
- Backlog: N issues
- Recent completions: [list last 3 Done]
```

### Step 4: Analyze Individual Issue Details

**Objective**: Deep-dive on candidate issues to inform decision.

**For each issue in "Todo" or "Backlog" states**:

1. **Fetch full issue details** using `mcp__linear__get_issue`:
   - Full description
   - Acceptance criteria
   - Comments (for additional context)
   - Labels/tags
   - Creation date
   - Last updated

2. **If issue has a parent, fetch parent**:
   - Understand Epic or Story context
   - Check parent status (is parent in progress?)
   - Check if parent is blocked

3. **Analyze issue characteristics**:
   - **Clarity**: Are requirements clear or vague?
   - **Complexity**: Estimate based on description (if no estimate set)
   - **Value**: Strategic importance (based on Epic/Story)
   - **Risk**: Technical uncertainty or complexity
   - **Dependencies**: Requires other work first?

**Optimization**:
- Don't fetch all issues in detail (would be slow)
- Focus on top candidates based on initial analysis
- Fetch details only for issues being seriously considered

### Step 5: Apply Decision Logic ("Ultrathink" Analysis)

**Objective**: Select the optimal next task using strategic and tactical factors.

**Strategic Factors** (What SHOULD we work on?):

1. **Epic Priority**:
   - Prefer issues from higher-priority Epics
   - Core features > Nice-to-haves
   - User-facing > Internal tooling
   - Check PRD.md for product priorities

2. **Dependency Chain**:
   - Prefer issues that unblock other work
   - Look for critical path items
   - Avoid issues blocked by others

3. **Value Delivery**:
   - Prefer issues that deliver user value
   - Stories > Subtasks (unless Story is blocked)
   - Complete features > partial implementations

4. **Technical Foundation**:
   - Prefer infrastructure/foundation over features (if foundation incomplete)
   - Core Provider > Advanced features
   - Testing framework > individual tests (if framework missing)

**Tactical Factors** (What CAN we work on?):

1. **Blocker Status**:
   - Issue must not be blocked by incomplete dependencies
   - Parent Story/Epic must not be canceled or blocked
   - External dependencies must be available

2. **WIP Limits**:
   - If multiple issues "In Progress", consider completing those first
   - Warn if too much concurrent work
   - Prefer finishing over starting

3. **Clarity**:
   - Requirements must be clear enough to start
   - Acceptance criteria should be defined
   - If vague, may need refinement first

4. **Context Switching**:
   - If on feature branch, prefer related work
   - If recent commits in area X, prefer continuing in area X
   - Minimize cognitive load

5. **Quick Wins**:
   - Small tasks (1-2 points) can build momentum
   - Documentation tasks when mentally fatigued
   - Bug fixes when waiting on decisions

**Decision Matrix**:

```
For each candidate issue, score:

Strategic Score (0-10):
- Epic priority: 0-3 points
- Dependency impact: 0-3 points
- Value delivery: 0-2 points
- Foundation importance: 0-2 points

Tactical Score (0-10):
- Not blocked: +5 points, Blocked: 0 points
- Clear requirements: +2 points
- Matches current context: +2 points
- Completes in-progress work: +1 point

Total Score = Strategic + Tactical (max 20)

Select highest-scoring issue.
```

**Tie-Breaking**:
1. Prefer smaller estimates (velocity)
2. Prefer issues with fewer dependencies
3. Prefer issues updated more recently
4. Prefer Stories over Subtasks
5. Ask user to choose between top 2-3

### Step 6: Check for Special Conditions

**Before finalizing recommendation, check**:

1. **No Work Available**:
   - If Backlog and Todo are empty, report this
   - Suggest creating new issues or checking priorities

2. **All Issues Blocked**:
   - If every issue has unmet dependencies, report this
   - List the blockers
   - Suggest addressing blockers first

3. **Too Much WIP**:
   - If 3+ issues "In Progress", warn about WIP limits
   - Recommend completing existing work first
   - Exception: Different developers working in parallel

4. **Dirty Working Directory**:
   - If uncommitted changes exist, warn
   - Recommend committing or stashing
   - Suggest completing current work first

5. **Tests Failing** (already handled in Step 1):
   - Should never reach here if tests failed
   - But double-check as safety

6. **Feature Branch Without Issue**:
   - If on feature branch but can't match to issue
   - Warn about orphaned branch
   - Suggest resolving before new work

### Step 7: Generate Recommendation Output

**Objective**: Present analysis results in clear, actionable format.

**Output Structure**:

```markdown
# What's Next? Task Recommendation

## Test Suite Status
✓ All tests passing ([X] examples, 0 failures)

## Project State Summary

**Git**:
- Branch: `{branch name}`
- Recent work: {summary of last commits}
- Working directory: {clean | has changes}

**Linear**:
- In Progress: {X} issues
- Ready to Start: {Y} issues
- Blocked: {Z} issues
- Recent completions: [{last done issue}]

---

## Recommended Task

**[{Issue ID}] {Issue Title}**

- **Type**: {Epic | Story | Subtask}
- **Priority**: {Urgent | High | Normal | Low}
- **Estimate**: {X points} (~{hours/days})
- **Status**: {Backlog | Todo}
- **Link**: https://linear.app/spiral-house/issue/{issue-id}

### Why This Task?

{2-3 sentence explanation of why this is the best choice}

**Strategic Value**:
- {Reason 1: Epic priority, dependency impact, etc.}
- {Reason 2: User value, foundation importance, etc.}

**Tactical Fit**:
- {Reason 1: Not blocked, clear requirements, etc.}
- {Reason 2: Context match, completes WIP, etc.}

### Context

{IF subtask with parent:}
**Parent Story**: [{Parent ID}] {Parent Title}
- Story Status: {status}
- Story Goal: {brief description}

{IF has dependencies:}
**Depends On**: [{Issue ID}] {Issue Title} - {status}

{IF blocks other work:}
**Blocks**: [{Issue ID}] {Issue Title}

**Recent Progress**:
{Summary of related recent commits or work}

### Description

{Issue description summary}

### Acceptance Criteria

{List key acceptance criteria from issue}

---

## Alternative Considerations

{IF other strong candidates exist:}

**Also Consider**:
1. **[{Issue ID}] {Issue Title}** ({points} pts)
   - Why: {brief rationale}
   - Trade-off: {why recommended task is better}

2. **[{Issue ID}] {Issue Title}** ({points} pts)
   - Why: {brief rationale}
   - Trade-off: {why recommended task is better}

{IF completing in-progress work is an option:}

**Complete Existing WIP**:
- [{Issue ID}] {Issue Title} - Currently In Progress
- Consider finishing this before starting new work

---

## Ready to Start?

**{YES | NO}**

{IF YES:}
✓ Requirements clear
✓ No blockers
✓ Tests passing
✓ Ready to delegate to agents

**Next Steps**:
1. Run: `/develop {Issue ID}`
2. Review development plan
3. Begin RED-GREEN-REFACTOR cycle

{IF NO:}
⚠️  Prerequisites needed:
- [ ] {Blocker or requirement}
- [ ] {Blocker or requirement}

**Recommended Action**:
{What to do before starting this task}

---

*Analysis completed at {timestamp}*
```

### Step 8: Handle Edge Cases with Specific Outputs

**Edge Case 1: Tests Failing**

Already handled in Step 1 - execution stops immediately.

**Edge Case 2: No Work Available**

```markdown
# What's Next? No Work Queued

## Test Suite Status
✓ All tests passing

## Project State Summary

**Linear**:
- In Progress: {X} issues
- Todo: 0 issues
- Backlog: 0 issues

⚠️  **No work is queued in Backlog or Todo.**

### Recommended Actions

1. **Review In Progress issues**:
   {List issues In Progress}
   - Consider completing these first

2. **Check for completed Epics**:
   - All planned work may be complete
   - Review PRD.md for next phase planning

3. **Create new issues**:
   - Review DESIGN.md for planned features
   - Break down Epics into Stories/Subtasks
   - Prioritize and add to Backlog

4. **Project planning needed**:
   - Consult with stakeholders
   - Define next milestone
   - Update Linear roadmap

---

**Status**: No actionable tasks available
**Recommendation**: Review project planning and create new issues
```

**Edge Case 3: All Issues Blocked**

```markdown
# What's Next? Resolve Blockers

## Test Suite Status
✓ All tests passing

## Project State Summary

**Linear**:
- Todo: {X} issues (all blocked)
- Blocked by: {Y} issues

⚠️  **All queued tasks are blocked by incomplete dependencies.**

### Blockers Analysis

{FOR each blocking issue:}

**Blocker**: [{Issue ID}] {Issue Title}
- **Status**: {current status}
- **Blocks**: {X} other issues
- **Action**: {what needs to happen}

### Recommended Actions

**Priority**: Resolve blockers to unblock work

1. **Address critical blocker**: [{Issue ID}] {Title}
   - {Why this is critical}
   - {What to do}

2. **Alternative**: Work on unblocked areas
   - {Suggest creating issues in unblocked areas}

3. **Escalate**:
   - {If blockers are external or need decisions}

---

**Status**: Work is blocked
**Recommendation**: {Focus on specific blocker}
```

**Edge Case 4: WIP Limit Exceeded**

```markdown
# What's Next? Complete Existing Work

## Test Suite Status
✓ All tests passing

## Project State Summary

**Linear**:
- In Progress: {X} issues ⚠️  (WIP limit concern)
- Todo: {Y} issues

⚠️  **Multiple issues are In Progress. Consider completing existing work before starting new tasks.**

### In Progress Issues

{FOR each issue In Progress:}

1. **[{Issue ID}] {Issue Title}**
   - Status: In Progress since {date}
   - Estimate: {points}
   - {Brief status summary}

### Recommendation: Finish What You Started

**Why**:
- Reduces context switching
- Delivers value faster
- Maintains focus
- Prevents WIP buildup

**Next Steps**:
1. Choose one In Progress issue to complete
2. Focus on that until Done
3. Then return to `/whats-next` for next task

**Suggested Focus**: [{Issue ID}] {Title}
- {Why this one specifically}

---

{IF there's a compelling reason to start new work:}

**Alternative**: If In Progress issues are waiting on external factors:

**[{Issue ID}] {New Task Title}**
- {Brief justification for starting new work}

---

**Status**: WIP limit concern
**Recommendation**: Complete In Progress work first
```

**Edge Case 5: Dirty Working Directory**

```markdown
# What's Next? Commit Your Changes

## Test Suite Status
✓ All tests passing

## Git State

**Branch**: `{branch}`
**Working Directory**: ⚠️  Uncommitted changes

```
{output of git status --short}
```

⚠️  **You have uncommitted changes. Commit or stash before starting new work.**

### Recommended Actions

**Option 1: Commit changes**
```bash
git add {files}
git commit -m "{appropriate commit message}"
```

**Option 2: Stash changes**
```bash
git stash save "WIP: {description}"
```

**Option 3: Complete current work**
- Finish what you're working on
- Commit as complete feature
- Then run `/whats-next`

### Once Clean

After committing/stashing, run `/whats-next` again for task recommendation.

---

**Status**: Uncommitted changes
**Recommendation**: Clean working directory first
```

## Quality Guidelines

### Analysis Rigor

**Be Thorough**:
- Don't skip steps
- Fetch real data, don't assume
- Consider all factors
- Think through implications

**Be Conservative**:
- Prefer finishing over starting
- Prefer unblocking over new work
- Prefer clarity over rushing
- Respect WIP limits

**Be Strategic**:
- Look at bigger picture
- Consider Epic priorities
- Think about dependency chains
- Balance short-term and long-term

### Communication Standards

**Be Clear**:
- Explain reasoning explicitly
- Show your work (analysis summary)
- Use specific examples
- Avoid ambiguity

**Be Actionable**:
- Provide next steps
- Include links to Linear issues
- Give commands when helpful
- Make it easy to act

**Be Honest**:
- If multiple options are equal, say so
- If analysis is uncertain, note it
- If data is missing, acknowledge it
- If you'd ask user, do it

## Integration with Other Commands

**Workflow Pattern**:

```bash
# 1. Check what to work on
/whats-next
# Output: Recommends SPI-1234

# 2. Analyze and plan the work
/develop SPI-1234
# Output: Creates development plan, posts to Linear

# 3. Execute the work
# (Delegate to agents: test-engineer, ruby-developer, etc.)

# 4. End of session
/write-handoff
# Output: Saves state to /tmp/spi-1234-handoff-summary.md

# 5. New session - resume
/read-handoff /tmp/spi-1234-handoff-summary.md
# Output: Restores context

# 6. Check next task
/whats-next
# Output: Might recommend continuing SPI-1234 or new task
```

**Command Synergies**:

- `/whats-next` → `/develop`: Natural flow from selection to planning
- `/write-handoff` → `/read-handoff` → `/whats-next`: Session resumption flow
- `baseline-check` (skill) → `/whats-next`: Quality metrics inform recommendations
- `/whats-next` → agent delegation: Recommendation drives agent coordination

## Notes for Claude

When executing this command:

**Prioritize Quality**:
- Test suite status is non-negotiable
- Never recommend building on broken foundation
- Enforce quality gates strictly

**Think Strategically**:
- Don't just pick the first issue
- Consider Epic priorities and PRD goals
- Balance quick wins with strategic work
- Think about dependency chains

**Be Data-Driven**:
- Use real Linear data, not assumptions
- Analyze git history for context
- Look at actual estimates and priorities
- Base recommendations on evidence

**Communicate Clearly**:
- Explain your reasoning
- Show the analysis process
- Make it easy to understand why
- Provide alternatives when close call

**Respect WIP Limits**:
- Finishing is better than starting
- Context switching is expensive
- Multiple In Progress is a red flag
- Encourage focus and completion

**Be Helpful**:
- Provide next steps
- Include links and commands
- Handle edge cases gracefully
- Make it actionable

This command is the Engineering Manager's strategic planning tool. Execute it with rigor, thoughtfulness, and a focus on delivering maximum value through optimal task selection.
