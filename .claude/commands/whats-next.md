---
description: Analyze project state and recommend optimal next task
allowed-tools: Bash, mcp__linear__list_issues, mcp__linear__get_issue, Read, Grep
model: sonnet
---

# /whats-next - Smart Task Recommendation

Analyzes project state (test status, git history, Linear issues) and recommends the optimal next task using strategic and tactical factors.

## Workflow

### Step 1: Quality Gate - Test Suite Status

**CRITICAL**: Run first. Quality before all other work.

```bash
bundle exec rspec
```

**If exit code != 0** (tests failing):
- STOP immediately. Do NOT proceed.
- Output failure message with guidance to fix tests first
- Explain why: building on broken foundation compounds issues
- END execution

**If exit code == 0** (tests passing):
- Note: "✓ Test suite passing - proceeding with analysis"
- Continue to Step 2

**Rationale**: Enforces quality-first culture, prevents technical debt, aligns with TDD principles.

### Step 2: Analyze Git State

**Objective**: Understand repository state and recent activity.

**Commands**:
```bash
git rev-parse --abbrev-ref HEAD           # Current branch
git log -10 --oneline --no-decorate       # Recent commits
git status --short                         # Working directory
git diff --name-only                       # Uncommitted changes
```

**Extract**:
- Branch name + extract issue ID if present (pattern: `*/spi-XXXX-*`)
- Recent focus areas from commit messages
- Working directory cleanliness (staged/unstaged/untracked counts)
- Inferred WIP from uncommitted changes

**Output Context**:
```
Git: Branch {name} | Recent: {commit summary} | Status: {clean/dirty} | WIP: {yes/no}
```

### Step 3: Fetch and Analyze Linear Issues

**Fetch all project issues**:
```
mcp__linear__list_issues:
  project: "vagrant-orbstack-provider" (ID: 17cca0c7-f003-4fd8-9be2-327349fb6e15)
  includeArchived: false
  orderBy: "updatedAt"
  limit: 100
```

**Group by workflow state** (using state IDs from CLAUDE.md):
- In Progress: `a433a32b-b815-4e11-af23-a74cb09606aa`
- Todo: `fc814d1f-22b5-4ce6-8b40-87c1312d54ba`
- Backlog: `1e7bd879-6685-4d94-8887-b7709b3ae6e8`
- In Review: `8d617a10-15f3-4e26-ad28-3653215c2f25`
- Done: `3d267fcf-15c0-4f3a-8725-2f1dd717e9e8`

**For each issue determine**:
- Type: Epic/Story/Subtask (from parent/children)
- Priority: Urgent(1), High(2), Normal(3), Low(4)
- Estimate: Story points
- Dependencies: What it depends on, what depends on it
- Blocked status: Dependencies completed?

**Build dependency graph**: Map parent-child relationships, identify blocked vs. ready issues.

**Output Context**:
```
Linear: In Progress {X} | Todo {Y} (ready: {Z}, blocked: {W}) | Backlog {N} | Recent done: {last 3}
```

### Step 4: Analyze Candidate Issues

**For top candidates** in Todo/Backlog:

1. Fetch full details: `mcp__linear__get_issue` → description, acceptance criteria, comments, labels
2. If has parent, fetch parent context
3. Analyze characteristics:
   - Clarity: Requirements clear?
   - Complexity: Based on description/estimate
   - Value: Strategic importance
   - Risk: Technical uncertainty
   - Dependencies: Requires other work?

**Optimize**: Don't fetch all issues in detail. Focus on top candidates based on initial analysis.

### Step 5: Apply Decision Logic ("Ultrathink")

**Strategic Factors** (0-10 points):
- **Epic Priority** (0-3): High-priority epics > nice-to-haves. Check PRD.md.
- **Dependency Impact** (0-3): Unblocks other work > isolated tasks. Critical path items.
- **Value Delivery** (0-2): User value, complete features > partial implementations.
- **Foundation** (0-2): Core infrastructure > advanced features (if foundation incomplete).

**Tactical Factors** (0-10 points):
- **Not Blocked** (+5): Must have no incomplete dependencies. Blocked = 0 points.
- **Clear Requirements** (+2): Well-defined acceptance criteria.
- **Context Match** (+2): Related to recent commits or current branch.
- **Completes WIP** (+1): Finishes in-progress work.

**Scoring**: Total = Strategic + Tactical (max 20). Select highest score.

**Tie-Breaking**:
1. Smaller estimates (velocity)
2. Fewer dependencies
3. More recently updated
4. Stories > Subtasks
5. Ask user if close call

### Step 6: Check Special Conditions

**Before finalizing, check for**:

1. **No Work Available**: Backlog/Todo empty → Suggest creating issues, reviewing roadmap
2. **All Blocked**: Every issue has unmet dependencies → List blockers, recommend resolution
3. **WIP Limit Exceeded**: 3+ issues In Progress → Warn, recommend completing existing work
4. **Dirty Working Directory**: Uncommitted changes → Warn to commit/stash
5. **Orphaned Branch**: Feature branch without matching issue → Warn to resolve

### Step 7: Generate Recommendation

**Output Structure**:

```markdown
# What's Next? Task Recommendation

## Test Suite Status
✓ All tests passing ({X} examples, 0 failures)

## Project State
**Git**: Branch `{name}` | Recent: {summary} | Status: {clean/dirty}
**Linear**: In Progress {X} | Ready {Y} | Blocked {Z} | Recent done: [{issue}]

---

## Recommended Task: [{Issue ID}] {Title}

**Type**: {Epic/Story/Subtask} | **Priority**: {level} | **Estimate**: {points} | **Status**: {state}
**Link**: https://linear.app/spiral-house/issue/{id}

### Why This Task?

{2-3 sentence explanation}

**Strategic Value**: {Epic priority, dependency impact, user value, foundation}
**Tactical Fit**: {Not blocked, clear requirements, context match, completes WIP}

### Context
{IF subtask} **Parent**: [{ID}] {Title} - {status}
{IF dependencies} **Depends On**: [{ID}] {Title} - {status}
{IF blocks others} **Blocks**: [{ID}] {Title}
**Recent Progress**: {Related commits/work}

### Description
{Issue summary}

### Acceptance Criteria
{Key criteria from issue}

---

## Alternatives

{IF other strong candidates}
**Also Consider**:
1. [{ID}] {Title} ({points}pts) - {Why} - {Trade-off vs. recommended}
2. [{ID}] {Title} ({points}pts) - {Why} - {Trade-off vs. recommended}

{IF completing WIP is option}
**Complete Existing**: [{ID}] {Title} - Currently In Progress

---

## Ready to Start?

**{YES/NO}**

{IF YES}
✓ Requirements clear | ✓ No blockers | ✓ Tests passing | ✓ Ready to delegate

**Next Steps**:
1. Run: `/develop {Issue ID}`
2. Review development plan
3. Begin RED-GREEN-REFACTOR cycle

{IF NO}
⚠️ Prerequisites:
- [ ] {Blocker}
- [ ] {Requirement}

**Action**: {What to do before starting}

---
*Analysis completed at {timestamp}*
```

### Step 8: Handle Edge Cases

**Edge Case Outputs** (use structure guidelines, not templates):

**1. Tests Failing** (handled Step 1):
```
Title: "⚠️ Test Suite Failing - Fix Tests First"
Content: Failure count | Why it matters (broken foundation) | Next steps (run rspec, fix, commit) | TDD principle
Format: Block with clear steps
```

**2. No Work Available** (Backlog/Todo empty):
```
Title: "What's Next? No Work Queued"
Content: Test status ✓ | State summary | Warning: No work queued
Actions: 1) Review In Progress, 2) Check completed epics, 3) Create new issues from DESIGN.md, 4) Plan next milestone
```

**3. All Issues Blocked**:
```
Title: "What's Next? Resolve Blockers"
Content: Test status ✓ | State summary | Warning: All blocked
Blockers List: Each blocking issue with status and what blocks
Actions: 1) Address critical blocker, 2) Work on unblocked areas, 3) Escalate if external
```

**4. WIP Limit Exceeded** (3+ In Progress):
```
Title: "What's Next? Complete Existing Work"
Content: Test status ✓ | State summary | Warning: Multiple WIP
In Progress List: Each issue with status since date
Recommendation: Finish before starting | Why: Reduces context switching, delivers faster
Suggested Focus: {Specific issue to complete}
```

**5. Dirty Working Directory**:
```
Title: "What's Next? Commit Your Changes"
Content: Test status ✓ | Git status output | Warning: Uncommitted changes
Actions: 1) Commit changes, 2) Stash changes, 3) Complete current work
Note: Run /whats-next again after cleaning
```

## Quality & Execution Guidelines

**Analysis Rigor**:
- Don't skip steps. Fetch real data, don't assume.
- Be conservative: Prefer finishing > starting, clarity > rushing
- Be strategic: Consider Epic priorities, dependency chains, long-term impact

**Communication**:
- Be clear: Explain reasoning explicitly, show analysis summary
- Be actionable: Provide next steps, include links/commands
- Be honest: If uncertain or multiple equal options, say so

**WIP Discipline**:
- Finishing > starting. Context switching is expensive.
- 3+ In Progress is red flag. Encourage focus and completion.

**Integration**:
- `/whats-next` → `/develop` → agent delegation → `/write-handoff` → `/read-handoff` → `/whats-next`
- Works with baseline-check skill for quality metrics
- Aligns with Engineering Manager role: read-only analysis, strategic decisions, agent coordination

**Test Discipline**:
- Test blocking is non-negotiable
- Never recommend building on broken foundation
- Enforce quality gates strictly

## Notes for Claude

**Execute with**:
- **Quality first**: Test status non-negotiable
- **Strategic thinking**: Don't pick first issue. Consider Epic priorities, PRD goals, dependency chains.
- **Data-driven**: Use real Linear/git data, not assumptions
- **Clear communication**: Explain reasoning, show analysis, provide alternatives
- **WIP respect**: Finishing > starting. Flag multiple In Progress.

This command is the Engineering Manager's strategic planning tool. Execute with rigor and focus on maximum value through optimal task selection.
