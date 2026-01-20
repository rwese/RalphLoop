# Super Todo - Modern Task Management Web App

Build a feature-rich, production-ready todo application that you would actually want to use daily. This should feel like a mini-product, not just a coding exercise.

## Core Features

### Task Management

- **Smart Task Creation**: Create tasks with title, rich description (markdown support), due dates, times, and priority
- **Quick Add**: Press `n` to open quick add modal, type task, press Enter to save
- **Inline Editing**: Click any task field to edit directly - no modal needed
- **Smart Delete**: Soft delete with trash bin, permanent delete, and restore within 30 days
- **Bulk Operations**: Select multiple tasks (shift+click or checkbox), bulk delete, bulk complete, bulk move
- **Task Templates**: Create templates for recurring task types (e.g., "Weekly Review", "Meeting Prep")

### Organization System

- **Nested Projects**: Unlimited folder/project hierarchy (Work/Projects/Backend, Personal/Hobbies)
- **Smart Lists**: "Today", "This Week", "Overdue", "Flagged", "All Tasks"
- **Tags & Labels**: Multi-colored tags with drag-and-drop assignment
- **Priorities**: 4 levels (urgent, high, medium, low) with visual indicators
- **Due Dates & Reminders**: Set due dates with times, get browser notifications
- **Recurring Tasks**: Daily, weekly, monthly, yearly, or custom intervals (e.g., "every 3 days")
- **Task Dependencies**: Mark tasks as blocked by other tasks

### Collaboration & Sharing

- **Share Lists**: Generate shareable links for read-only or edit access
- **Team Tasks**: Assign tasks to "people" (simple name entries)
- **Comments**: Add comments/discussions on tasks
- **Activity History**: See who did what and when

### Progress & Insights

- **Visual Progress**: Completion rings, progress bars per project
- **Productivity Stats**: Tasks completed today/week/month, current streak
- **Burndown Charts**: Simple visualization for project completion over time
- **Heatmap**: Calendar view showing activity intensity (like GitHub contributions)

### User Experience

- **Dark/Light Mode**: System preference detection, manual toggle
- **Offline First**: Works completely offline with service workers, auto-sync when online
- **Keyboard Shortcuts**:
  - `n` = New task
  - `e` = Edit selected task
  - `space` = Toggle complete
  - `del` = Soft delete
  - `f` = Focus search
  - `p` = Switch to previous project
  - `1-9` = Quick filter shortcuts
  - `?` = Show all shortcuts
- **Drag & Drop**: Reorder tasks within list, move between projects
- **Auto-save**: Instant persistence to localStorage with conflict resolution
- **Data Export**: Export all data as JSON for backup or migration
- **Data Import**: Import from JSON, Todoist CSV, Wunderlist export
- **Undo/Redo**: Full action history with undo (Ctrl+Z) and redo (Ctrl+Y)

## Technical Requirements

### Stack

- Single HTML file with embedded CSS and JavaScript (no framework, no build step)
- **CSS**: Modern CSS with custom properties, flexbox/grid, animations
- **JS**: Vanilla ES6+ with modules (import/export from same file via data: URLs)
- **No external dependencies**: No CDN links, no npm packages, everything inline
- **Storage**: localStorage with IndexedDB for larger data (attachments, history)
- **PWA**: manifest.json and service worker for installability and offline use

### Performance

- **Load Time**: Under 100KB initial bundle, load in under 100ms
- **Interaction**: All interactions under 100ms response
- **Animations**: Smooth 60fps CSS animations, no jank
- **Storage**: Efficient localStorage usage with compression (LZ-String or similar inline)
- **Memory**: Works on devices with < 256MB RAM

### Code Quality

- **Accessibility**: WCAG 2.1 AA compliant, full keyboard navigation, screen reader support
- **Semantic HTML**: Proper landmarks, ARIA labels, focus management
- **Responsive**: Mobile-first, works from 320px to 4K screens
- **Error Handling**: Graceful degradation, error boundaries, meaningful error messages
- **Testing**: Include simple test suite (can run in browser console)

### Security

- **XSS Prevention**: All user input sanitized, CSP headers inline
- **Data Validation**: Input validation on client side
- **Privacy**: All data stays local, no analytics, no tracking

## Example Usage Scenarios

### Scenario 1: Daily Planning

```
1. Open app, automatically filtered to "Today" view
2. Review yesterday's incomplete tasks (shown at top)
3. Press `n`, type "Review emails", set due today, priority medium, add to "Work"
4. Create 3-4 more tasks for the day
5. See progress ring update as tasks are completed
6. At end of day, export weekly report
```

### Scenario 2: Project Management

```
1. Create project "Website Redesign"
2. Add tasks: "Design mockups", "Set up repo", "Implement header", "Test on mobile"
3. Set "Design mockups" as prerequisite for "Implement header"
4. Set due dates: mockups (3 days), repo (1 day), header (5 days), test (7 days)
5. See blocked tasks dimmed until prerequisite complete
6. Share project link with team for read-only view
```

### Scenario 3: Habit Tracking

```
1. Create recurring task "Exercise" with recurrence "daily"
2. Add to "Health" project with high priority
3. Complete task daily, watch streak counter grow
4. View heatmap to see consistency over months
5. Get browser notification at 7 AM daily (if due today and incomplete)
```

## Success Criteria

- [ ] **Functional**: All CRUD operations work smoothly without bugs
- [ ] **Fast**: Sub-100ms interactions, instant load
- [ ] **Beautiful**: Modern UI that looks professional, not like a tutorial project
- [ ] **Accessible**: Fully usable with keyboard only, screen reader compatible
- [ ] **Offline**: Install as PWA, works completely offline
- [ ] **Data Safe**: Auto-save, undo/redo, export/import
- [ ] **Mobile**: Works great on phone with touch interactions
- [ ] **Keyboard Pro**: Power user keyboard shortcuts that feel natural
- [ ] **No Errors**: Zero console errors, graceful error handling
- [ ] **Documented**: Inline code comments, keyboard shortcut reference in-app

## Bonus Features (if time permits)

- [ ] **Themes**: Multiple color themes (blue, green, purple, etc.)
- [ ] **Emoji Support**: Add emoji to task titles
- [ ] **Natural Language Parsing**: Parse "buy milk tomorrow at 5pm" into task + date + time
- [ ] **Focus Mode**: Hide everything except current task
- [ ] **Timer**: Pomodoro timer built into task view
- [ ] **Email Tasks**: Forward email to generate task (requires backend)
- [ ] **API**: Expose local API for other tools to interact
