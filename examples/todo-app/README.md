# Super Todo - Modern Task Management Web App

A feature-rich, production-ready todo application built with vanilla HTML/CSS/JS.

## Overview

Build a todo app that feels like a mini-product, not just a coding exercise. This example demonstrates a complex single-page application with:

- Nested projects and smart lists
- Keyboard shortcuts and drag-and-drop
- Offline support with PWA
- Rich task management features

## Running with RalphLoop

```bash
# Run with 10 iterations (path is relative to /workspace inside container)
RALPH_PROMPT_FILE=/workspace/examples/todo-app/prompt.md npm run container:run 10

# Or set RALPH_PROMPT directly from the file
RALPH_PROMPT="$(cat examples/todo-app/prompt.md)" npm run container:run 10
```

> **Note:** `RALPH_PROMPT_FILE` paths are relative to `/workspace` inside the container.

## Key Features

### Task Management

- Smart task creation with rich descriptions
- Inline editing and bulk operations
- Task templates for recurring work

### Organization

- Unlimited nested folders/projects
- Tags, priorities, and due dates
- Smart lists: Today, This Week, Overdue

### Technical Stack

- Single HTML file (no build step)
- Vanilla ES6+ JavaScript
- localStorage + IndexedDB
- PWA with offline support

## Files

- `prompt.md` - Complete project specification for RalphLoop
- `index.html` - When built, contains the complete application
