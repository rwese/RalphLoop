#!/usr/bin/env node

/**
 * Simple Todo List CLI Application
 * Demonstrates autonomous development with RalphLoop
 */

const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '..', 'todos.json');

class TodoApp {
  constructor() {
    this.todos = this.loadTodos();
  }

  loadTodos() {
    try {
      if (fs.existsSync(DATA_FILE)) {
        const data = fs.readFileSync(DATA_FILE, 'utf8');
        return JSON.parse(data);
      }
    } catch (error) {
      console.error('Error loading todos:', error.message);
    }
    return [];
  }

  saveTodos() {
    try {
      fs.writeFileSync(DATA_FILE, JSON.stringify(this.todos, null, 2));
    } catch (error) {
      console.error('Error saving todos:', error.message);
    }
  }

  add(task) {
    if (!task || task.trim() === '') {
      console.error('Error: Task cannot be empty');
      process.exit(1);
    }

    const todo = {
      id: Date.now(),
      task: task.trim(),
      completed: false,
      createdAt: new Date().toISOString()
    };

    this.todos.push(todo);
    this.saveTodos();
    console.log(`Added: "${task}"`);
  }

  list() {
    if (this.todos.length === 0) {
      console.log('No todos found. Add some tasks!');
      return;
    }

    console.log('\nTodo List:');
    console.log('==========');

    this.todos.forEach((todo, index) => {
      const status = todo.completed ? '[x]' : '[ ]';
      console.log(`${index + 1}. ${status} ${todo.task}`);
    });

    console.log(`\nTotal: ${this.todos.length} tasks (${this.todos.filter(t => t.completed).length} completed)`);
  }

  complete(id) {
    const index = id - 1;

    if (index < 0 || index >= this.todos.length) {
      console.error(`Error: Invalid task number ${id}`);
      process.exit(1);
    }

    this.todos[index].completed = true;
    this.saveTodos();
    console.log(`Completed: "${this.todos[index].task}"`);
  }

  remove(id) {
    const index = id - 1;

    if (index < 0 || index >= this.todos.length) {
      console.error(`Error: Invalid task number ${id}`);
      process.exit(1);
    }

    const removed = this.todos.splice(index, 1)[0];
    this.saveTodos();
    console.log(`Removed: "${removed.task}"`);
  }

  help() {
    console.log(`
Todo App - Simple Task Manager
==============================

Usage:
  node src/index.js <command> [options]

Commands:
  add <task>      Add a new task
  list            List all tasks
  complete <id>   Mark a task as completed
  remove <id>     Remove a task
  help            Show this help message

Examples:
  node src/index.js add "Buy groceries"
  node src/index.js list
  node src/index.js complete 1
  node src/index.js remove 2
`);
  }
}

// Main CLI logic
function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'help';

  const app = new TodoApp();

  switch (command) {
    case 'add': {
      if (args.length < 2) {
        console.error('Error: Missing task. Usage: node src/index.js add "task description"');
        process.exit(1);
      }
      app.add(args.slice(1).join(' '));
      break;
    }

    case 'list':
      app.list();
      break;

    case 'complete': {
      const completeId = parseInt(args[1]);
      if (isNaN(completeId)) {
        console.error('Error: Invalid ID. Usage: node src/index.js complete <id>');
        process.exit(1);
      }
      app.complete(completeId);
      break;
    }

    case 'remove': {
      const removeId = parseInt(args[1]);
      if (isNaN(removeId)) {
        console.error('Error: Invalid ID. Usage: node src/index.js remove <id>');
        process.exit(1);
      }
      app.remove(removeId);
      break;
    }

    case 'help':
    default:
      app.help();
      break;
  }
}

main();
