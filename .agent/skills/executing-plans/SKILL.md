---
name: executing-plans
description: Use when you have a written implementation plan and need to execute it in Antigravity single-flow mode
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.
**Entrypoint principle:** This is the standard execution entrypoint. Do not offer alternate execution modes.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan

1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: follow the single-flow execution model from `.agent/skills/single-flow-task-execution/SKILL.md`
5. Update `<project-root>/docs/plans/task.md` (table-only tracker) and proceed

### Step 2: Execute Batch

**Default: First 3 tasks**

For each task:

1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report

When batch complete:

- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue

Based on feedback:

- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:

- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SKILL:** Use `.agent/skills/finishing-a-development-branch/SKILL.md`
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**

- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**

- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
- Use `task_boundary` for coding tasks; use `browser_subagent` only for browser tasks

## Integration

**Required workflow skills:**

- **`.agent/skills/using-git-worktrees/SKILL.md`** - REQUIRED: Set up isolated workspace before starting
- **`.agent/skills/writing-plans/SKILL.md`** - Creates the plan this skill executes
- **`.agent/skills/single-flow-task-execution/SKILL.md`** - REQUIRED: Enforce single-flow execution with two-stage review
- **`.agent/skills/finishing-a-development-branch/SKILL.md`** - Complete development after all tasks
