# PromptBuilder - Interactive Prompt Engineering Tool

PromptBuilder helps you transform raw ideas into high-quality, well-structured prompts for RalphLoop autonomous development system.

## Overview

Have an idea but don't know how to write a good prompt? PromptBuilder guides you through defining your project with clarifying questions, then generates a comprehensive prompt ready for RalphLoop.

## Running with RalphLoop

```bash
# Quick-start with PromptBuilder (interactive)
npx ralphloop quick prompt

# Non-interactive mode with IDEA environment variable
IDEA="Build a habit tracker for busy professionals" npx ralphloop quick prompt

# Or using prompt file directly
npx ralphloop --ralph-prompt-file examples/prompt-builder/prompt.md 5
```

## Interactive vs Non-Interactive

### Interactive Mode

Just run without parameters and the tool will ask you questions:

```bash
npx ralphloop quick prompt
# 💡 What is your idea you want to have built?
# > Build a weather app
```

### Non-Interactive Mode

Pass the idea via environment variable:

```bash
# Using IDEA environment variable
IDEA="Build a REST API for user authentication" npx ralphloop quick prompt

# The tool generates a complete prompt and can save it to a file
```

## Features

- **Interactive Idea Collection**: Guided questions to extract project details
- **Quality Analysis**: Checks for completeness, clarity, and scope
- **Smart Generation**: Creates structured prompts with all essential sections
- **Multiple Outputs**: Save to file, copy to clipboard, or run directly

## CLI Options

When running the built tool directly:

```bash
prompt-builder --help

Options:
  --idea, -i <text>      Your idea (non-interactive mode)
  --output, -o <file>    Output file (default: prompt.md)
  --audience, -a <text>  Target audience
  --features, -f <list>  Comma-separated must-have features
  --constraints, -c <text>  Constraints or preferences
  --help                 Show this help
```

## Example Usage

```bash
# Interactive
prompt-builder

# Non-interactive with parameters
prompt-builder --idea "Build a habit tracker" \
  --audience "busy professionals" \
  --features "daily reminders, streak tracking" \
  --constraints "offline-first, no account required"

# With RalphLoop environment variable
IDEA="Build a weather CLI tool with forecasts and alerts" \
  npx ralphloop quick prompt
```

## Example Output

PromptBuilder transforms:

> "Build a habit tracker for busy professionals"

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
