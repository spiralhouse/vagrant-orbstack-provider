---
description: Analyze Linear issue and create comprehensive development plan
argument-hint: "[SPI-xxx]"
allowed-tools: mcp__linear__get_issue, mcp__linear__update_issue, mcp__linear__create_comment, Grep, Read, WebFetch, Glob
model: sonnet
---

# /develop - Engineering Manager Workflow

This command implements the Engineering Manager workflow for analyzing Linear issues and creating comprehensive development plans. It's the centerpiece of our development workflow automation.

## What This Command Does

When you run `/develop SPI-xxx`, Claude will:

1. Fetch the complete Linear issue hierarchy (subtask → story → epic)
2. Search and analyze relevant project documentation
3. Perform deep analysis of scope, complexity, and technical approach
4. Determine agent delegation strategy
5. Ask clarifying questions if needed
6. Update the Linear issue status and post the development plan
7. Present a comprehensive development plan with next steps

## Workflow Instructions

Follow these steps in order. Be thorough but respect YAGNI principles.

### Step 1: Fetch Linear Issue Hierarchy

**Objective**: Build complete context from the issue and all its parents.

**Actions**:
1. Use `mcp__linear__get_issue` to fetch the issue `$1` (the Linear issue ID argument)
2. Examine the response for the `parent` field
3. If a parent exists, recursively fetch it:
   - Subtask → fetch parent Story
   - Story → fetch parent Epic
   - Continue until reaching top-level Epic or no more parents
4. Build a complete hierarchy map showing relationships

**Important**:
- Handle cases where issues have no parents gracefully
- Handle issues that are already top-level epics
- Be defensive against circular references (shouldn't happen, but check)

**Example Output Structure**:
```
Epic: [SPI-1132] Core Provider Implementation
  └─ Story: [SPI-1140] Implement SSH Integration
      └─ Subtask: [SPI-1146] Create SSH Info Action
```

### Step 2: Search Related Documentation

**Objective**: Find and analyze relevant project documentation to inform the plan.

**Actions**:
1. Search `docs/` directory for relevant documentation:
   - Always check: `docs/PRD.md` (product requirements)
   - Always check: `docs/DESIGN.md` (technical design)
   - Search for other docs based on issue keywords
2. Use `Grep` to search for:
   - Feature names mentioned in the issue
   - Technical terms from issue description
   - Component names (e.g., "Provider", "SSH", "Action")
   - Related class or module names
3. Use `Read` to review relevant sections of found documents
4. Build a knowledge base of:
   - Existing design decisions
   - Architecture constraints
   - Related features
   - Technical patterns to follow

**Search Strategy**:
- Start with exact phrase matches
- Then try individual keywords
- Check both file names and content
- Prioritize design docs over examples

**If No Documentation Found**:
- Note this in the analysis
- Flag that design documentation may need to be created
- Proceed with plan based on issue description and project conventions

### Step 3: Deep Analysis ("Ultrathink")

**Objective**: Comprehensively analyze the work to create an informed development plan.

**Perform Analysis On**:

#### Scope & Complexity
- What exactly needs to be built/changed?
- What is explicitly in scope?
- What is explicitly out of scope?
- How does this fit into the larger feature/epic?
- What is the estimated complexity? (Use Fibonacci: 1, 2, 3, 5, 8, 13, 21)
  - 1 point: Trivial (< 1 hour)
  - 2 points: Simple (1-2 hours)
  - 3 points: Small (2-4 hours)
  - 5 points: Medium (4-8 hours)
  - 8 points: Large (1-2 days)
  - 13 points: Very large (2-3 days)
  - 21 points: Too large - needs breakdown

#### Technical Approach
- What is the high-level implementation strategy?
- Which existing components will be modified?
- Which new components need to be created?
- What are the key technical decisions needed?
- Are there multiple viable approaches? (compare if so)
- What patterns from existing code should be followed?

#### YAGNI Assessment
**Critical**: Apply "You Ain't Gonna Need It" principles:
- Are we building only what's needed NOW?
- Are we avoiding over-engineering?
- Are we designing for current requirements, not hypothetical futures?
- Can we simplify the approach?
- What's the minimum viable implementation?

#### Design Document Assessment
Determine if a technical design document is needed:

**Create Design Doc IF**:
- Architectural changes required
- New major components/systems
- Complex integrations
- Significant API changes
- Multiple implementation approaches to compare
- High technical risk

**Skip Design Doc IF**:
- Small feature additions
- Bug fixes
- Documentation updates
- Simple, straightforward implementations
- Well-established patterns being followed

#### Testing Requirements
- What are the critical paths that must be tested?
- Unit tests needed?
- Integration tests needed?
- Manual testing scenarios?
- Edge cases to cover?
- Performance considerations?

#### Documentation Updates
- README changes needed?
- API documentation?
- User guides?
- Examples?
- Code comments?

#### Technical Risks & Mitigation
- What could go wrong?
- Dependencies on external systems?
- Compatibility concerns?
- Performance risks?
- How to mitigate each risk?

### Step 4: Agent Delegation Strategy

**Objective**: Determine the sequence of agent handoffs to complete the work.

**Available Agents**:
- **ruby-developer**: Ruby code implementation (provider, actions, config)
- **test-engineer**: Test writing and execution
- **documentation-writer**: Documentation and examples
- **code-reviewer**: Code quality and architecture review
- **release-engineer**: Gem packaging and release

**Determine Delegation Sequence**:

For typical feature work:
1. **ruby-developer** - Implement core functionality
2. **test-engineer** - Write and verify tests
3. **documentation-writer** - Update relevant docs
4. **code-reviewer** - Review before merge

For documentation work:
1. **documentation-writer** - Create/update docs
2. **code-reviewer** - Review for accuracy

For bug fixes:
1. **ruby-developer** - Fix the issue
2. **test-engineer** - Add regression tests
3. **code-reviewer** - Review fix

**Provide Clear Context for Each Agent**:
- What they need to build/test/document
- Relevant design decisions
- Constraints and requirements
- Success criteria
- Files they'll likely need to modify

### Step 5: Identify Clarifying Questions

**Objective**: Surface any ambiguities or decisions needed before starting work.

**Check For**:
- Unclear requirements in the issue description
- Multiple valid implementation approaches
- Missing acceptance criteria
- Scope boundary questions
- Technical decision points requiring input
- Priority trade-offs

**If Questions Exist**:
- List them clearly in the development plan
- Explain why each question matters
- Suggest default approaches if applicable
- Note that work should not proceed until questions are answered

**Don't Ask Questions About**:
- Things clearly documented in PRD/DESIGN
- Standard patterns established in the codebase
- Decisions already made in parent Epic/Story
- Over-engineering concerns (apply YAGNI instead)

### Step 6: Check for Subtask/Issue Needs

**Objective**: Identify if the work should be broken down further.

**Consider Creating New Issues IF**:
- Story is > 13 points (too large for 2-week sprint)
- Multiple distinct technical components involved
- Work can be parallelized across multiple developers
- Clear separation of concerns exists
- Dependencies can be completed independently

**DO NOT Create Issues Automatically**:
- Flag the recommendation in the plan
- Explain rationale for breakdown
- Suggest issue titles and scope
- Ask user to approve before creating

### Step 7: Update Linear Issue

**Objective**: Move the issue to "In Progress" and post the development plan.

**Actions**:
1. Use `mcp__linear__update_issue` to transition the issue:
   - Issue ID: `$1`
   - State ID: `a433a32b-b815-4e11-af23-a74cb09606aa` (In Progress)
2. Use `mcp__linear__create_comment` to post the development plan:
   - Issue ID: `$1`
   - Body: The formatted development plan (see Step 8 format)

**Error Handling**:
- If update fails, note this but continue with presenting the plan
- If comment posting fails, provide the plan text for manual posting

### Step 8: Present Development Plan

**Objective**: Create a comprehensive, actionable development plan.

**Plan Format**:

```markdown
# Development Plan: [Issue Title]

## Executive Summary
[2-3 sentence overview of what needs to be done and why]

## Issue Hierarchy
[Show the full hierarchy: Epic → Story → Subtask]

Epic: [SPI-xxx] [Epic Title]
  └─ Story: [SPI-xxx] [Story Title]
      └─ Subtask: [SPI-xxx] [Subtask Title] ← **This Issue**

## Scope Analysis

### In Scope
- [Specific deliverable 1]
- [Specific deliverable 2]
- [Specific deliverable 3]

### Out of Scope
- [What we're NOT doing]
- [What's deferred to future work]

### YAGNI Notes
[What we're explicitly NOT over-engineering and why]

## Technical Approach

### High-Level Strategy
[Describe the implementation approach in 1-2 paragraphs]

### Components to Modify
- `path/to/file.rb` - [What changes]
- `path/to/test.rb` - [What tests]

### Components to Create
- `path/to/new_file.rb` - [What it does]

### Key Design Decisions
1. [Decision 1]: [Rationale]
2. [Decision 2]: [Rationale]

### Design Document Needed?
[YES/NO] - [Rationale]

## TDD Workflow

This feature will be developed following RED-GREEN-REFACTOR cycle:

### RED Phase (test-engineer)
- Write failing tests for [specific functionality]
- Verify tests fail with clear messages
- Test files: [list expected test files]
- Success: Tests exist and fail with informative error messages

### GREEN Phase (ruby-developer)
- Implement minimal solution to pass tests
- Don't refactor yet - just make it work
- Implementation files: [list files]
- Success: All tests pass (new + existing)

### REFACTOR Phase
1. **software-architect**: Analyze for patterns, duplication, design improvements
   - Review implementation and tests
   - Identify code smells or design issues
   - Provide refactoring strategy with rationale
   - Success: Clear refactoring strategy provided

2. **ruby-developer**: Implement refactoring strategy
   - Execute software-architect's strategy
   - Maintain passing tests throughout
   - Success: Improved code, all tests green

3. **test-engineer**: Verify all tests still pass
   - Run complete test suite
   - Confirm no regressions
   - Success: Green test suite after refactoring

### Test Coverage Target
- Unit tests: [specific scenarios]
- Integration tests: [if applicable]
- Expected coverage: [%]

## Agent Delegation Plan

### Sequence
1. **test-engineer** (RED phase)
   - Task: Write failing tests for [feature]
   - Files: spec/unit/[feature]_spec.rb
   - Success: Tests fail with clear messages

2. **ruby-developer** (GREEN phase)
   - Task: Implement [feature] to pass tests
   - Files: lib/vagrant-orbstack/[feature].rb
   - Success: All tests pass

3. **software-architect** (REFACTOR analysis)
   - Task: Analyze implementation for patterns and improvements
   - Focus: DRY, SOLID, design patterns
   - Success: Clear refactoring strategy provided

4. **ruby-developer** (REFACTOR execution)
   - Task: Implement refactoring strategy
   - Constraint: Maintain passing tests
   - Success: Improved code, all tests green

5. **test-engineer** (REFACTOR verification)
   - Task: Confirm all tests still pass
   - Success: Green test suite

6. **documentation-writer**
   - Task: [Specific documentation task]
   - Context: [What needs documenting]
   - Files: [Docs to update]
   - Success: [Definition of done]

7. **code-reviewer**
   - Task: Final review (quality, security, tests, approval)
   - Focus: [Specific review areas]
   - Success: Approval for merge

## Testing Requirements

### Unit Tests
- [Test case 1]
- [Test case 2]

### Integration Tests
- [Integration scenario 1]

### Manual Testing
- [Manual test scenario]

## Documentation Updates

### Required Updates
- [ ] README.md - [What section]
- [ ] docs/DESIGN.md - [What section]
- [ ] Examples - [What example]
- [ ] Code comments - [What needs documenting]

## Success Criteria

**Definition of Done**:
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] Tests passing
- [ ] Documentation updated
- [ ] Code reviewed and approved

## Risks & Mitigation

### Technical Risks
1. **Risk**: [Potential technical issue]
   - **Likelihood**: High/Medium/Low
   - **Impact**: High/Medium/Low
   - **Mitigation**: [How to address]

### Dependencies
- [External dependency 1]: [How it affects us]

## Complexity Estimate

**Story Points**: [X points]
**Rationale**: [Why this estimate]
**Duration**: [Estimated time based on points]

## Clarifying Questions

[If any questions were identified in Step 5]

1. **Question**: [The question]
   - **Why It Matters**: [Rationale]
   - **Suggested Default**: [If applicable]

[If no questions: "No clarifying questions - requirements are clear."]

## Recommended Issue Breakdown

[If subtask creation is recommended from Step 6]

**Recommendation**: Break this issue into [N] subtasks:

1. **[Subtask Title 1]** ([X] points)
   - Scope: [What it covers]

2. **[Subtask Title 2]** ([X] points)
   - Scope: [What it covers]

**Rationale**: [Why breakdown is recommended]

[If no breakdown needed: "No breakdown needed - issue is appropriately scoped."]

## Next Steps

1. [Immediate next action]
2. [Second action]
3. [Third action]

---

**Status**: Development plan complete. Issue transitioned to "In Progress" in Linear.
**Ready to Start**: [YES/NO - explain if no]
```

## Quality Guidelines

### Balance Quality with YAGNI

From CLAUDE.md: "We will always prioritize quality above expedience, but we also abide by YAGNI principles and stay within scope."

**Apply This By**:
- Being thorough in analysis, but not perfectionist
- Designing for current needs, not hypothetical futures
- Implementing tests for critical paths, not every edge case
- Documenting what users need, not everything possible
- Choosing simple solutions over clever ones
- Avoiding premature optimization

### Scope Discipline

**Stay Within Scope**:
- Respect the issue description boundaries
- Don't expand scope without explicit approval
- Flag scope creep if detected
- Defer nice-to-haves to future issues

**If Scope is Unclear**:
- Ask clarifying questions
- Reference parent Story/Epic for context
- Consult PRD.md for product intent
- Make conservative assumptions

### Technical Excellence

**Follow Project Conventions**:
- Ruby style guide (2-space indentation, snake_case, etc.)
- YARD comments for public methods
- Trunk-based development (short-lived branches)
- Conventional commits (feat:, fix:, docs:, etc.)
- Test coverage for critical paths

**Reference Documentation**:
- Check DESIGN.md for architecture patterns
- Follow existing code patterns
- Maintain consistency with established approaches

## Example Usage

```bash
/develop SPI-1146
```

This will:
1. Fetch SPI-1146 and its parents (SPI-1140, SPI-1132)
2. Search docs for SSH-related content
3. Analyze the SSH Info Action implementation needs
4. Create delegation plan for ruby-developer → test-engineer → documentation-writer
5. Update SPI-1146 to "In Progress"
6. Post comprehensive plan to Linear
7. Present plan with next steps

## Example Output

For a subtask like "Create SSH Info Action":

```
# Development Plan: Create SSH Info Action

## Executive Summary
Implement the SSHInfo action class that provides SSH connection information to Vagrant
for connecting to OrbStack machines. This is part of the SSH integration story and
enables `vagrant ssh` functionality.

## Issue Hierarchy
Epic: [SPI-1132] Core Provider Implementation
  └─ Story: [SPI-1140] Implement SSH Integration
      └─ Subtask: [SPI-1146] Create SSH Info Action ← **This Issue**

## Scope Analysis

### In Scope
- Create `lib/vagrant-orbstack/action/ssh_info.rb`
- Implement SSH connection info retrieval from OrbStack CLI
- Return host, port, username, private_key_path in expected format
- Unit tests for SSH info action
- Integration with provider action builder

### Out of Scope
- SSH key generation (using OrbStack's default)
- SSH config file management
- Port forwarding configuration
- ProxyCommand setup

### YAGNI Notes
Not implementing custom SSH key management - OrbStack provides this by default. Not
adding SSH config customization - can be added later if users request it.

## Technical Approach

### High-Level Strategy
Create an action middleware class that shells out to `orb info <machine-name>` to get
SSH connection details. Parse the JSON response and return it in Vagrant's expected
format (hash with :host, :port, :username, :private_key_path keys).

### Components to Create
- `lib/vagrant-orbstack/action/ssh_info.rb` - Main action class
- `spec/unit/action/ssh_info_spec.rb` - Unit tests

### Key Design Decisions
1. **CLI Parsing**: Use `orb info` command rather than trying to discover SSH details
2. **Error Handling**: Return nil if machine doesn't exist (Vagrant convention)
3. **Username**: Default to 'vagrant' for consistency with Vagrant expectations

### Design Document Needed?
NO - This is straightforward action implementation following established patterns in
the Vagrant ecosystem. The approach is well-documented in DESIGN.md.

[... rest of plan ...]

## Next Steps

1. Delegate to ruby-developer: Implement SSHInfo action class
2. Delegate to test-engineer: Write unit and integration tests
3. Delegate to code-reviewer: Review implementation
4. Update Linear issue to Done when complete

---

**Status**: Development plan complete. Issue transitioned to "In Progress" in Linear.
**Ready to Start**: YES - All requirements clear, no blockers.
```

## Notes for Claude

When executing this command:

- **Be thorough but efficient**: Don't over-analyze, but don't skip steps
- **Use all available context**: Issue hierarchy + docs + project conventions
- **Think critically**: Apply YAGNI, question scope, identify risks
- **Communicate clearly**: The plan should be actionable by specialized agents
- **Be specific**: Exact file paths, class names, method signatures when possible
- **Ask when uncertain**: Better to clarify than assume
- **Update Linear reliably**: The issue status and comment are important artifacts

This command is the Engineering Manager's primary tool for coordinating development work. Execute it with the rigor and thoroughness expected of a senior engineering leader.
