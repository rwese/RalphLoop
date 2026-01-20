# PromptBuilder - Interactive Prompt Engineering Tool

PromptBuilder helps you transform raw ideas into high-quality, well-structured prompts for RalphLoop autonomous development system.

## Overview

Have an idea but don't know how to write a good prompt? PromptBuilder guides you through defining your project with clarifying questions, then generates a comprehensive prompt ready for RalphLoop.

## Running with RalphLoop

```bash
# Quick-start with PromptBuilder
npx ralphloop quick prompt

# Or using prompt file directly
npx ralphloop --ralph-prompt-file examples/prompt-builder/prompt.md 5
```

## Features

- **Interactive Idea Collection**: Guided questions to extract project details
- **Quality Analysis**: Checks for completeness, clarity, and scope
- **Smart Generation**: Creates structured prompts with all essential sections
- **Multiple Outputs**: Save to file, copy to clipboard, or run directly

## Quick Start

```bash
# Interactive mode
node examples/prompt-builder/bin/prompt-builder.js

# With command-line arguments
node examples/prompt-builder/bin/prompt-builder.js --idea "Build a habit tracker"

# Generate and save
node examples/prompt-builder/bin/prompt-builder.js --output my-prompt.md
```

## Example Output

PromptBuilder transforms:

> "I want to build a habit tracker"

Into a complete prompt:

```markdown
# HabitForge - Personal Habit Tracker

Build a mobile-first habit tracking application designed for busy
professionals who want to build and maintain healthy habits.

## Core Features

- Daily check-ins with configurable reminders
- Streak tracking with visual progress indicators
- Simple, intuitive user interface
- Full offline functionality

## Success Criteria

- [ ] Create and manage habits
- [ ] Receive daily reminders
- [ ] Track streaks over time
- [ ] Works completely offline
- [ ] Mobile-friendly design
```

## Files

- `prompt.md` - Complete project specification for RalphLoop
- `bin/prompt-builder.js` - CLI tool (when built)
- `src/` - Source code (when built)
