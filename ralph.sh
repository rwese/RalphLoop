#!/usr/bin/env bash

# ralph.sh - RalphLoop Autonomous Development Agent
# Usage: ./ralph.sh <iterations>

set -e -u -o pipefail

# Configuration
MAX_ROUNDS=${1:-100}
PROGRESS_FILE="progress.md"
PROMPT_FILE="prompt.md"

# Ensure prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE file must exist" >&2
    exit 1
fi

# Ensure progress file exists
if [ ! -f "$PROGRESS_FILE" ]; then
    touch "$PROGRESS_FILE"
fi

# Main loop
for ((i = 1; i <= MAX_ROUNDS; i++)); do
    echo "========================================"
    echo "🔄 RalphLoop Iteration $i of $MAX_ROUNDS"
    echo "========================================"

    # Read current progress for context
    PROGRESS_CONTENT=$(cat "$PROGRESS_FILE")
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")

    # Run OpenCode agent with current context
    result=$(
        opencode run --share --agent yolo << EOF
# Goals and Resources

## Project plan

${PROMPT_CONTENT}

## Current Progress

${PROGRESS_CONTENT}

## Your Priorities

1. [ ] Analyze current state and decide highest goal next step
2. [ ] Work on the next goal
3. [ ] Update progress.md with what was accomplished and which goals are left to reach our project plan
4. [ ] Create git commit with changes
5. [ ] Identify new improvements or features to add to achieve our goal

## Constraints

- [ ] Only work on ONE goal per iteration

## Success Criteria

The loop succeeds when:

- [ ] Git history shows regular commits
- [ ] Progress tracking is up to date
- [ ] We made progress towards our goal

If the current goal is complete, output <promise>COMPLETE</promise>.
EOF
    )

    echo "$result" | tee /dev/stderr

    # Check for completion
    if echo "$result" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "🎉 RalphLoop mission complete!"
        echo "========================================"
        exit 0
    fi

    echo ""
    echo "✅ Iteration $i complete. Continuing..."
    echo ""
done

echo "========================================"
echo "🏁 Max iterations ($MAX_ROUNDS) reached."
echo "   RalphLoop will rest for now."
echo "========================================"
