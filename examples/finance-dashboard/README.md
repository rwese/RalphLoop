# MoneyWise - Personal Finance Dashboard

A beautiful, functional personal finance dashboard that helps users understand their spending, track budgets, and plan for the future.

## Overview

Build a modern fintech-style application with:

- Transaction management and categorization
- Multi-account tracking
- Envelope budgeting system
- Data visualization and reports

## Running with RalphLoop

```bash
# Run with 15 iterations (path is relative to /workspace inside container)
RALPH_PROMPT_FILE=/workspace/examples/finance-dashboard/prompt.md npm run container:run 15

# Or set RALPH_PROMPT directly from the file
RALPH_PROMPT="$(cat examples/finance-dashboard/prompt.md)" npm run container:run 15
```

> **Note:** `RALPH_PROMPT_FILE` paths are relative to `/workspace` inside the container.

## Key Features

### Transaction Management

- Smart transaction entry with receipt photos
- Import from CSV bank exports
- Recurring transactions with smart detection
- Split transactions across categories

### Account Management

- Track multiple account types (checking, savings, credit, investments)
- Balance history and net worth calculation
- Manual or API-based sync

### Budgeting

- Envelope and zero-based budgeting
- Rolling budgets with rollover
- Spending alerts and insights

## Files

- `prompt.md` - Complete project specification for RalphLoop
