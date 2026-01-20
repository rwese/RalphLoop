# PromptBuilder - Interactive Prompt Engineering Tool

Build an interactive CLI tool that helps users transform raw ideas into high-quality, well-structured prompts for RalphLoop autonomous development system.

## Core Features

### Interactive Idea Collection

- **Welcome Banner**: Display a friendly welcome message explaining the tool's purpose
- **Idea Input**: Prompt the user with "What is your idea you want to have built?"
- **Clarifying Questions**: Ask follow-up questions to gather essential details:
  - What is the primary purpose/goal?
  - Who is the target audience?
  - What platforms/devices should it support?
  - Are there any specific features that are must-haves?
  - Are there any constraints (tech stack, budget, timeline)?
- **Multi-line Input**: Allow pasting or typing longer descriptions
- **Edit Capability**: Let users review and modify their input before proceeding

### Prompt Quality Analysis

- **Completeness Check**: Verify all essential sections are addressed
- **Clarity Assessment**: Flag vague or ambiguous statements
- **Scope Detection**: Identify if the scope is too broad or too narrow
- **Feasibility Check**: Warn about potential complexity issues
- **Suggestions**: Offer specific improvements for weak areas

### Prompt Generation

Transform the user's raw idea into a structured prompt with:

- **Project Title**: Generate a concise, descriptive name
- **Overview**: A compelling summary of what to build
- **Core Features**: Clear list of primary functionality
- **Technical Considerations**: Flexible guidance on implementation
- **Success Criteria**: Measurable outcomes to validate completion
- **Example Scenarios**: Concrete usage examples
- **Bonus Features**: Optional enhancements if time permits

### Output Options

- **Display**: Show the generated prompt in the terminal
- **Save to File**: Write the prompt to a file (default: `prompt.md`)
- **Copy to Clipboard**: Copy the prompt for easy use
- **Direct Execution**: Option to pipe directly to RalphLoop

## User Experience

### Guided Workflow

```
╔══════════════════════════════════════════════════════════════╗
║                   PromptBuilder v1.0                          ║
║        Transform Your Ideas Into Quality Prompts              ║
╚══════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Let's build something great together!

What is your idea you want to have built?
(Press Ctrl+D or Ctrl+C when finished, Ctrl+U to clear line)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
> I want to build a habit tracker app that helps me build better
> habits and track my progress over time. It should be simple to
> use and work offline on my phone.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤔 Great start! Let's gather a few more details...

Target audience? (e.g., busy professionals, students)
> Busy professionals who want to build healthy habits

Must-have features? (comma-separated)
> Daily reminders, streak tracking, simple UI

Any constraints or preferences?
> Offline-first, mobile-friendly, no account required

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ Analyzing your idea...
✓ Scope: Well-defined
✓ Features: 3 core features identified
✓ Clarity: Clear objective

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Generated Prompt:

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

## Example Usage
- User opens app, sees today's habits
- Taps to mark habit as complete
- Views streak history

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
[1] Save to file (prompt.md)
[2] Copy to clipboard
[3] Run with RalphLoop
[4] Edit input
[5] Start over

Choose: _
```

### Non-Interactive Mode

Support CLI arguments for automation:

```bash
# Interactive mode (default)
prompt-builder

# Non-interactive with direct input
prompt-builder --idea "Build a weather app" --audience "hikers" --output prompt.md

# From file
prompt-builder --input ideas.txt --output prompts/

# Generate and run
prompt-builder --idea "Build a todo app" --run
```

### Exit Experience

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Your prompt has been saved to: prompt.md

🚀 Ready to build! Run:
   npx ralphloop -p prompt.md 10

Or start over:
   prompt-builder

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Thank you for using PromptBuilder! 🎉
```

## Technical Implementation

### Stack

- Single HTML file with embedded CSS/JS (web version)
- OR Node.js CLI with inquirer or similar (Node version)
- No external dependencies for core functionality
- localStorage for history/偏好

### File Structure (if Node.js version)

```
prompt-builder/
├── prompt.md
├── README.md
├── package.json
├── bin/
│   └── prompt-builder.js
└── src/
    ├── index.js
    ├── questions.js
    ├── generator.js
    └── output.js
```

## Success Criteria

- **User-Friendly**: Even non-technical users can create quality prompts
- **Quality Output**: Generated prompts produce good results with RalphLoop
- **Flexible**: Handles vague ideas and refines them into clear specifications
- **Fast**: Complete workflow in under 2 minutes
- **Helpful**: Provides useful feedback and suggestions
- **Exportable**: Saves prompts in a format RalphLoop can use directly

## Bonus Features

- **Template Library**: Pre-built prompt templates for common project types
- **History**: Save and revisit previous prompts
- **Import/Export**: Share generated prompts with others
- **AI Enhancement**: Use LLM to further refine prompts (optional)
- **Web Version**: Browser-based UI for users who prefer GUI
- **Template Sharing**: Community templates for common project types
