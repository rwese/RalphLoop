# Simple Todo CLI

A simple Todo List CLI application built with Node.js to demonstrate autonomous development capabilities with RalphLoop.

## Features

- Add new tasks to your todo list
- List all tasks with completion status
- Mark tasks as completed
- Remove tasks from the list
- Persistent storage (tasks saved to JSON file)

## Installation

```bash
# Navigate to the project directory
cd examples/simple-todo-cli

# Run the application
node src/index.js add "Your first task"
```

## Usage

### Add a Task

```bash
node src/index.js add "Buy groceries"
node src/index.js add "Walk the dog"
node src/index.js add "Finish project report"
```

### List All Tasks

```bash
node src/index.js list
```

### Mark a Task as Completed

```bash
node src/index.js complete 1  # Mark first task as completed
```

### Remove a Task

```bash
node src/index.js remove 2  # Remove second task
```

### Show Help

```bash
node src/index.js help
```

## Project Structure

```
simple-todo-cli/
├── README.md           # This file
├── package.json        # NPM package configuration
├── todos.json          # Data storage (auto-generated)
└── src/
    └── index.js        # Main application code
```

## Technologies Used

- **Node.js**: JavaScript runtime environment (v16.0.0+)
- **Native Modules**: `fs` and `path` for file operations
- **No external dependencies**: Pure Node.js implementation

## Development

This project was created using [RalphLoop](https://github.com/rwese/RalphLoop), an autonomous development system that demonstrates self-sustaining development processes.

### RalphLoop Workflow

1. **Analyze** - Understand project requirements
2. **Plan** - Break down into manageable tasks
3. **Execute** - Implement features
4. **Verify** - Run tests and validation
5. **Document** - Update progress and commit changes

## License

MIT License

## Contributing

This is an example project for demonstrating RalphLoop's capabilities. Feel free to use it as a template for your own projects.
