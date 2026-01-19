# Example Creation Guidelines

This document provides guidelines and best practices for creating example prompts for RalphLoop. Great examples serve as templates that users can modify, learn from, and build upon.

## What Makes a Great Example

### Core Characteristics

1. **Real-World Usable**: The resulting application should be something you'd actually use, not just a toy project
2. **Balanced Scope**: Challenging enough to demonstrate concepts, but achievable in reasonable time
3. **Clear Structure**: Well-organized sections that are easy to navigate and modify
4. **Comprehensive**: Covers core features, technical requirements, and success criteria
5. **Inspiring**: Sparks ideas for customization and extension

### The "Would Use It" Test

Before finalizing an example, ask:

- Would I install/use this app in my daily life?
- Does it solve a real problem I have?
- Is the UI/UX something I'd be proud to show?
- Does it have enough features to be useful, but not so many it's overwhelming?

## Example Structure Template

Every example prompt should follow this structure:

```markdown
# App Name - One-Line Description

Brief 2-3 paragraph overview explaining what the app does and why it's useful.

## Core Features

### Feature Category 1

- Detailed feature description
- Another feature with context
- User benefit explanation

### Feature Category 2

- Feature that solves specific problem
- Related feature that enhances experience
- Integration feature that connects everything

## Technical Requirements

### Stack

- Technology choices with rationale
- No unnecessary dependencies
- Clear version requirements

### Performance

- Specific metrics (load time, response time)
- Size constraints if important
- Resource usage limits

### Code Quality

- Accessibility requirements
- Security considerations
- Documentation standards

## Example Usage Scenarios

### Scenario 1: Typical User Flow
```

Step-by-step walkthrough
With expected outcomes
Demonstrating key features

```

### Scenario 2: Power User Features
```

Advanced usage
Showing depth of features
Customization options

```

## Success Criteria

- [ ] Specific measurable criteria
- [ ] Quality gates
- [ ] User experience requirements
- [ ] Performance benchmarks

## Bonus Features (if time permits)

- [ ] Stretch goals
- [ ] Advanced integrations
- [ ] Delightful extras
```

## Categories of Examples

### 1. Web Applications

**Characteristics:**

- Single HTML file preferred for learning
- No framework, no build step
- localStorage for persistence
- Responsive, accessible UI

**Good Examples:**

- Todo apps (task management)
- Personal dashboards (finance, habits, analytics)
- Note-taking apps
- Bookmark managers

**Avoid:**

- Complex SPAs with routing
- Backend integration requirements
- Database setup
- Build pipelines

### 2. CLI Tools

**Characteristics:**

- Node.js with npm/npx
- TypeScript optional but recommended
- SQLite for data (preferred over JSON files)
- Interactive TUI mode (bonus)

**Good Examples:**

- File management tools
- API clients
- Developer utilities
- Data processing scripts

**Avoid:**

- Heavy external dependencies
- Complex installation requirements
- GUI-only features

### 3. Mobile-First

**Characteristics:**

- PWA with service workers
- Touch-optimized interactions
- Offline-first design
- Mobile-first responsive design

**Good Examples:**

- Habit trackers
- Expense trackers
- Location-based apps
- Quick-entry tools

**Avoid:**

- Features requiring desktop
- Complex keyboard interactions
- Mouse-specific interactions

## Technology Guidelines

### Recommended Technologies

**Web Apps:**

- Vanilla JavaScript (ES6+)
- Modern CSS (flexbox, grid, custom properties)
- localStorage + IndexedDB
- Chart.js (inline) for visualizations
- jsPDF (inline) for exports

**CLI Tools:**

- Node.js v23.x
- TypeScript with strict mode
- SQLite (better-sqlite3)
- Blessed/Ink for TUI
- Chalk for colors
- Commander.js for CLI parsing

**Avoid:**

- Framework overhead (React, Vue, Angular)
- Build steps (Webpack, Vite, esbuild)
- External CDN dependencies
- Authentication requirements
- Database servers (PostgreSQL, MongoDB)

### No External Dependencies Rule

For web examples:

- All JavaScript inline in the HTML file
- All CSS in `<style>` tags
- No external scripts, fonts, or stylesheets
- Libraries can be included inline if small

For CLI examples:

- Use `npx` for one-off tools
- Minimize production dependencies
- Prefer built-in Node.js modules

## Feature Guidelines

### Core Features (Required)

Every example should include:

1. **CRUD Operations**: Create, read, update, delete
2. **Persistence**: Data survives browser restart / CLI exit
3. **Search/Filter**: Find what you're looking for
4. **Export/Import**: Backup and migration capability
5. **Keyboard Shortcuts**: Power user efficiency
6. **Offline Support**: Works without internet

### User Experience Features

1. **Responsive Design**: Works on mobile and desktop
2. **Accessibility**: WCAG 2.1 AA compliance
3. **Error Handling**: Graceful degradation
4. **Loading States**: Feedback during operations
5. **Empty States**: Helpful when no data exists
6. **Undo/Redo**: Recover from mistakes

### Polish Features

1. **Animations**: Smooth transitions (60fps)
2. **Shortcuts**: Keyboard efficiency
3. **Themes**: Dark/light mode
4. **Customization**: User preferences
5. **Sharing**: Export/sharing capabilities
6. **Statistics**: Usage insights

## Writing Style

### Do

- Use clear, active voice
- Be specific about requirements
- Include concrete examples
- Explain "why" behind choices
- Set realistic expectations
- Celebrate success criteria

### Don't

- Use vague requirements ("fast", "good", "nice")
- Include unnecessary complexity
- Require external services without fallback
- Over-specify implementation details
- Forget edge cases
- Neglect error handling

## Example Categories

### Beginner Examples

**Characteristics:**

- Single feature focus
- Under 50 lines of code
- No external APIs
- Basic persistence

**Examples:**

- Simple counter
- Bookmark manager
- Unit converter
- Password generator

### Intermediate Examples

**Characteristics:**

- Multiple related features
- 100-300 lines of code
- One external API or local database
- Rich UI with interactions

**Examples:**

- Todo app (full-featured)
- Weather CLI
- Expense tracker
- Book collection manager

### Advanced Examples

**Characteristics:**

- Complex feature set
- 300+ lines of code
- Multiple APIs or complex data model
- Professional-grade UI/UX

**Examples:**

- Full finance dashboard
- Media library manager
- Learning management system
- Personal knowledge base

## Naming Conventions

### File Names

Use kebab-case:

```bash
# Good
todo-app-prompt.md
weather-cli-prompt.md
finance-dashboard-prompt.md

# Bad
TodoApp.md
weatherCLI.md
Finance_Dashboard_Prompt.md
```

### App Names

Create memorable, descriptive names:

```markdown
# Good

- "Super Todo" - Modern Task Management Web App
- "TubeMaster" - Pro YouTube Media Suite
- "MoneyWise" - Personal Finance Dashboard
- "BookShelf" - Personal Library Management System

# Avoid

- "Todo List App"
- "YouTube Downloader"
- "Budget Tracker"
- "Book Manager"
```

## Checklist for New Examples

### Before Creating

- [ ] Is there already an example in this category?
- [ ] Is this genuinely useful/interesting?
- [ ] Is the scope achievable?
- [ ] Does it showcase RalphLoop capabilities?

### While Creating

- [ ] Follows the structure template?
- [ ] Includes all required sections?
- [ ] Uses recommended technologies?
- [ ] Balances features and scope?
- [ ] Includes concrete examples?

### Before Submitting

- [ ] Tested the prompt mentally (can you visualize the result)?
- [ ] Checked for clarity and completeness?
- [ ] Verified all links and references?
- [ ] Added bonus features for stretch goals?
- [ ] Included success criteria that are measurable?

## Common Patterns

### Data Models

Always define your data model explicitly:

```typescript
interface Book {
  id: string
  title: string
  authors: string[]
  status: "want" | "reading" | "read"
  rating?: number
  // ... other fields
}
```

### CLI Commands

For CLI tools, show example usage first:

```bash
# Show, don't just describe
$ weather new york
72°F, Sunny, 45% humidity

$ weather --forecast --days 7
7-day forecast for New York...
```

### User Flows

Show actual user scenarios, not feature lists:

```markdown
### Scenario: Adding a New Task

1. User presses `n` (or clicks "+")
2. Quick add modal appears
3. User types "Buy groceries"
4. App auto-suggests category based on keywords
5. User presses Enter to save
6. Task appears at top of list
```

## Anti-Patterns to Avoid

### 1. Feature Creep

**Bad:** "Also include user accounts, social sharing, email notifications, push notifications, SMS reminders, and AI-powered suggestions"

**Good:** Focus on core value first, mention additional features in bonus section

### 2. Vague Requirements

**Bad:** "Make it fast and responsive"

**Good:** "Load under 100ms, 60fps animations"

### 3. Implementation Lock-in

**Bad:** "Use React with Redux for state management, styled-components for styling, and Express for backend"

**Good:** "Modern JavaScript with localStorage persistence, vanilla CSS with custom properties"

### 4. External Dependencies

**Bad:** "Sign up for API key at external-service.com"

**Good:** "Use Open-Meteo API (free, no key required)"

### 5. Missing Edge Cases

**Bad:** "User can create, edit, delete todos"

**Good:** "Handle empty states, duplicate entries, undo deletion, validation errors"

## Inspiration Sources

### Real Applications to Learn From

- Todo apps: Todoist, Things, TickTick
- Finance: YNAB, Monarch Money, Actual
- Books: Goodreads, StoryGraph, LibraryThing
- CLI tools: exa, bat, fzf, eza
- Weather: wttr.in, weather 命令行工具

### Problem Spaces

- Personal productivity
- Data organization
- Media management
- Learning/education
- Health/fitness
- Finance/money
- Creative projects

## Maintenance

### Review Checklist

When reviewing existing examples:

- [ ] Are APIs still available and free?
- [ ] Are performance targets still realistic?
- [ ] Is the tech stack still current?
- [ ] Are there missing features that users request?
- [ ] Is the clarity and quality up to standard?

### Updating Examples

- Keep main structure stable
- Update tech recommendations quarterly
- Add new features to bonus section
- Fix broken links or references
- Incorporate community feedback

## Resources

### Example Templates

See existing examples in this directory for reference:

- `todo-app-prompt.md` - Web app example
- `youtube-cli-prompt.md` - CLI tool example
- `finance-dashboard-prompt.md` - Complex web app
- `weather-cli-prompt.md` - API-integrated CLI
- `book-collection-prompt.md` - Data-rich application

### Further Reading

- RalphLoop main documentation (../AGENTS.md)
- Project structure guidelines
- Best practices for autonomous development
