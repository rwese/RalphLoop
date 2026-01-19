# Todo App - Web Application

Build a clean, modern todo web application with the following requirements:

## Core Features

### Todo Management

- Create new todos with title and optional description
- Edit todo title and description inline
- Delete todos with confirmation
- Mark todos as complete/incomplete with checkbox
- Restore recently deleted todos (keep for 7 days)

### Organization

- Organize todos into projects or lists (e.g., "Personal", "Work")
- Add due dates to todos
- Set priority levels (low, medium, high)
- Add tags/labels to todos for filtering
- Filter todos by status (all, active, completed)
- Search todos by title or description

### User Experience

- Clean, minimalist UI design
- Responsive layout (mobile and desktop)
- Smooth animations for add/edit/complete actions
- Keyboard shortcuts (n=new, e=edit, del=delete, c=complete)
- Auto-save to localStorage
- Bulk actions: mark all complete, clear completed

## Technical Requirements

### Stack

- Single HTML file with embedded CSS and JavaScript (no framework)
- Use localStorage for data persistence
- Modern CSS with CSS custom properties (variables)
- Vanilla JavaScript (ES6+)
- No external dependencies

### Performance

- Page load under 200ms
- Smooth 60fps animations
- Work offline (service worker optional)

### Code Quality

- Semantic HTML structure
- Accessible (WCAG 2.1 AA)
- Clean, readable code with comments
- Mobile-first responsive design

## Example Usage

```
1. User clicks "Add Todo" button or presses "n"
2. Enters "Buy groceries" with description "Milk, Eggs, Bread"
3. Sets due date to today, priority to high
4. Adds tags: ["shopping", "urgent"]
5. Todo appears in "Personal" list with high priority indicator
6. User clicks checkbox to mark complete
7. Todo shows as completed with strikethrough animation
8. User filters to "Completed" to see all done items
```

## Success Criteria

- [ ] Clean, professional UI with no external CSS/JS
- [ ] All CRUD operations work smoothly
- [ ] Filtering and search function correctly
- [ ] Data persists across browser sessions
- [ ] Mobile-responsive layout
- [ ] Keyboard shortcuts functional
- [ ] No console errors
- [ ] Fast performance and smooth animations
