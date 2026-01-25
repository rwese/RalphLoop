# Examples Directory Agent Guidance

This directory contains example projects demonstrating RalphLoop usage patterns. AI agents can use these as reference implementations.

## Directory Structure

```
examples/
├── README.md              # Examples overview
├── todo-app/              # Task management PWA
├── simple-todo-cli/       # CLI todo application
├── book-collection/       # Library management system
├── finance-dashboard/     # Personal finance tracker
├── weather-cli/           # CLI weather tool
├── youtube-cli/           # YouTube download tool
├── prompt-builder/        # Interactive prompt tool
└── pipeline/              # Pipeline configuration examples
    └── iterative-refactor.yaml
```

## Example Categories

### Complete Applications

These examples provide full project structure:

| Example           | Type    | Complexity | Purpose                   |
| ----------------- | ------- | ---------- | ------------------------- |
| todo-app          | PWA     | Medium     | Task management web app   |
| simple-todo-cli   | CLI     | Low        | Basic todo CLI            |
| book-collection   | CLI/API | Medium     | Library book management   |
| finance-dashboard | Web App | High       | Personal finance tracking |

### Utility Tools

Smaller, focused utilities:

| Example        | Type | Purpose                       |
| -------------- | ---- | ----------------------------- |
| weather-cli    | CLI  | Fetch weather data            |
| youtube-cli    | CLI  | YouTube video/audio downloads |
| prompt-builder | CLI  | Interactive prompt creation   |

### Configuration Examples

Specialized configuration demonstrations:

| Example   | Purpose                        |
| --------- | ------------------------------ |
| pipeline/ | Custom pipeline configurations |

## Using Examples

### Running with Examples

```bash
# Using npx with example prompt
npx ralphloop -p examples/todo-app/prompt.md 10

# Using environment variable
RALPH_PROMPT_FILE=/workspace/examples/todo-app/prompt.md ./ralph 10

# Quick-start specific example
npx ralphloop quick todo  # Starts todo-app example
```

### Example Structure

Each example typically contains:

```
example-name/
├── prompt.md       # Example objectives
├── progress.md     # Example progress tracking
└── ...             # Project-specific files
```

## Common Tasks

### 1. Creating a New Example

To create a new example project:

1. Create directory: `examples/<example-name>/`
2. Add `prompt.md` with example objectives
3. Add `progress.md` (can be empty)
4. Add project files demonstrating the concept
5. Update `examples/README.md` with description
6. Update root AGENTS.md examples table

### 2. Modifying Existing Examples

When updating examples:

- Keep `prompt.md` focused on demonstrating specific features
- Ensure `progress.md` shows realistic iteration progression
- Maintain working project files
- Test the example still runs correctly

### 3. Pipeline Examples

The `pipeline/` directory contains pipeline configuration examples:

- **iterative-refactor.yaml**: Custom 5-stage pipeline
  - analyze → implement → test → review → deploy
  - Demonstrates conditional transitions
  - Shows AI validation hooks

## Key Files to Reference

- **examples/README.md**: Catalog of all examples
- **examples/todo-app/prompt.md**: Standard example format
- **pipeline.yaml**: Default pipeline configuration
- **examples/pipeline/iterative-refactor.yaml**: Custom pipeline example

## Best Practices

1. **Focused Scope**: Each example should demonstrate 1-2 concepts
2. **Working Code**: Examples should be functional
3. **Clear Prompts**: `prompt.md` should define clear objectives
4. **Documentation**: Include README if example is complex

## Integration Points

- Examples use RalphLoop to self-implement
- Pipeline examples demonstrate custom workflow configuration
- Each example can have its own `pipeline.yaml` override
- Examples test RalphLoop's ability to work in different domains
