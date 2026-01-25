# Bin Directory Agent Guidance

This directory contains CLI entry points and executable tools for RalphLoop. AI agents working in this directory should follow these guidelines.

## Directory Structure

```
bin/
├── ralph              # Main autonomous loop entry point
├── ralph-config       # Configuration management tool
├── ralph-status       # Status and monitoring tool
├── ralph-trigger      # Trigger and execution tool
└── json-query.cjs     # JSON query utility (Node.js)
```

## Common Tasks

### 1. Modifying CLI Arguments

When working on CLI argument parsing in `args.sh` or `bin/ralph`:

- Use `lib/args.sh` for argument parsing logic
- Follow the configuration cascade defined in root AGENTS.md
- Maintain backward compatibility with existing flags
- Update help text when adding new options

### 2. Entry Point Changes

The main entry points (`ralph`, `ralph-config`, `ralph-status`, `ralph-trigger`):

- Should be minimal and delegate to `lib/` modules
- `bin/ralph` sources `lib.sh` and calls `run_pipeline()`
- Any new entry points should follow the same pattern
- Ensure executable permissions (`chmod +x`)

### 3. Node.js Tools

The `json-query.cjs` file is a Node.js utility:

- Used for JSON configuration querying
- Can be called from shell scripts via command substitution
- Dependencies: Node.js 18+ required

## Key Files to Reference

- **lib/args.sh**: Core argument parsing functions
- **lib/core.sh**: Configuration and utilities
- **pipeline.yaml**: Pipeline configuration schema

## Best Practices

1. **Shell Scripts**: Use `bash -n` to verify syntax before committing
2. **Error Handling**: Include proper error messages and exit codes
3. **Documentation**: Update help text when adding features
4. **Testing**: Add unit tests in `tests/unit/` for new functions

## Integration Points

- Arguments flow through `parse_cli_args()` in `lib/args.sh`
- Configuration is managed in `lib/core.sh`
- Pipeline execution starts from `bin/ralph`
