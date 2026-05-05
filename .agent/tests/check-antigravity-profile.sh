#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$AGENT_DIR/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "  [PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "  [FAIL] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

require_file() {
  local path="$1"
  if [ -f "$path" ]; then
    pass "File exists: $path"
  else
    fail "Missing file: $path"
  fi
}

require_absent() {
  local path="$1"
  if [ ! -e "$path" ]; then
    pass "File absent (as expected): $path"
  else
    fail "File should be absent: $path"
  fi
}

echo "========================================"
echo " Antigravity Profile Checks"
echo "========================================"
echo ""

echo "Checking required files..."

required_files=(
  "$AGENT_DIR/AGENTS.md"
  "$AGENT_DIR/INSTALL.md"
  "$AGENT_DIR/task.md"
  "$AGENT_DIR/workflows/brainstorm.md"
  "$AGENT_DIR/workflows/write-plan.md"
  "$AGENT_DIR/workflows/execute-plan.md"
  "$AGENT_DIR/agents/code-reviewer.md"
  "$SCRIPT_DIR/check-antigravity-profile.sh"
  "$SCRIPT_DIR/run-tests.sh"
)

for file in "${required_files[@]}"; do
  require_file "$file"
done

require_absent "$ROOT_DIR/docs/plans/task.md"

required_skills=(
  "brainstorming"
  "executing-plans"
  "finishing-a-development-branch"
  "receiving-code-review"
  "requesting-code-review"
  "systematic-debugging"
  "test-driven-development"
  "using-git-worktrees"
  "using-superpowers"
  "verification-before-completion"
  "writing-plans"
  "writing-skills"
  "single-flow-task-execution"
)

for skill in "${required_skills[@]}"; do
  require_file "$AGENT_DIR/skills/$skill/SKILL.md"
done

# Verify prompt template files for single-flow-task-execution
require_file "$AGENT_DIR/skills/single-flow-task-execution/implementer-prompt.md"
require_file "$AGENT_DIR/skills/single-flow-task-execution/spec-reviewer-prompt.md"
require_file "$AGENT_DIR/skills/single-flow-task-execution/code-quality-reviewer-prompt.md"

echo ""
echo "Checking frontmatter..."

for skill in "${required_skills[@]}"; do
  file="$AGENT_DIR/skills/$skill/SKILL.md"

  if rg -q '^---$' "$file"; then
    pass "$skill has frontmatter delimiters"
  else
    fail "$skill missing frontmatter delimiters"
  fi

  if rg -q '^name:\s*[^[:space:]].*$' "$file"; then
    pass "$skill has name field"
  else
    fail "$skill missing name field"
  fi

  if rg -q '^description:\s*[^[:space:]].*$' "$file"; then
    pass "$skill has description field"
  else
    fail "$skill missing description field"
  fi
done

echo ""
echo "Checking for unsupported legacy instructions..."

legacy_patterns=(
  'Skill tool'
  'Task tool with'
  'Task\("'
  'Dispatch implementer subagent'
  'Dispatch code-reviewer subagent'
  'Create TodoWrite'
  'Mark task complete in TodoWrite'
  'Use TodoWrite'
  'superpowers:'
)

for pattern in "${legacy_patterns[@]}"; do
  if rg -q "$pattern" "$AGENT_DIR/skills"; then
    fail "Legacy pattern found in skills: $pattern"
  else
    pass "Legacy pattern absent: $pattern"
  fi
done

echo ""
echo "Checking AGENTS mapping contract..."

mapping_checks=(
  'Task.*task_boundary'
  'browser_subagent'
  'Skill.*view_file'
  'TodoWrite.*docs/plans/task\.md'
  'run_command'
  'grep_search'
  'find_by_name'
  'mcp_\*'
)

for pattern in "${mapping_checks[@]}"; do
  if rg -q "$pattern" "$AGENT_DIR/AGENTS.md"; then
    pass "AGENTS includes mapping: $pattern"
  else
    fail "AGENTS missing mapping: $pattern"
  fi
done

echo ""
echo "========================================"
echo " Summary"
echo "========================================"
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "STATUS: FAILED"
  exit 1
fi

echo "STATUS: PASSED"
