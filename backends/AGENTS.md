# Backends Directory Agent Guidance

This directory contains backend configurations for different AI agent runtimes. AI agents working here should understand the backend abstraction layer.

## Directory Structure

```
backends/
├── index.jsonc         # Backend registry and defaults
├── opencode/           # OpenCode backend configuration
│   └── opencode.jsonc  # OpenCode-specific settings
├── claude-code/        # Claude Code backend (placeholder)
├── codex/              # Codex backend (placeholder)
├── kilo/               # Kilo CLI backend (placeholder)
└── mock/               # Mock backend for testing
    ├── mock-opencode   # Mock executable
    └── mock-backend.jsonc
```

## Backend Configuration

### Configuration Schema (index.jsonc)

Each backend must define:

```jsonc
{
  "backend_name": {
    "command": "executable_name", // Command to invoke
    "args": ["arg1", "arg2"], // Default arguments
    "env": { "VAR": "value" }, // Environment variables
    "description": "Purpose", // Human-readable description
  },
}
```

### Supported Backends

| Backend     | Status      | Purpose                         |
| ----------- | ----------- | ------------------------------- |
| opencode    | Primary     | Main autonomous agent runtime   |
| mock        | Testing     | Simulated responses for testing |
| claude-code | Placeholder | Future Claude Code integration  |
| codex       | Placeholder | Future Codex integration        |
| kilo        | Placeholder | Future Kilo CLI integration     |

## Common Tasks

### 1. Adding a New Backend

To add a new backend:

1. Create directory: `backends/<backend-name>/`
2. Add configuration to `index.jsonc`
3. Create backend-specific config if needed
4. Update `load_backend_config()` in `lib/exec.sh` if special handling required
5. Add tests in `tests/integration/`

### 2. Modifying OpenCode Configuration

The OpenCode backend is the primary backend:

- Configuration located in `backends/opencode/opencode.jsonc`
- Supports agent selection via `RALPH_AGENT` environment variable
- Configuration cascade: `RALPH_AGENT` > `index.jsonc` > defaults

### 3. Mock Backend for Testing

The mock backend (`backends/mock/`):

- Returns predefined responses without API calls
- Controlled by environment variables:
  - `RALPH_MOCK_RESPONSE`: "success" or "fail"
  - `RALPH_MOCK_DELAY`: Response delay in seconds
  - `RALPH_MOCK_EXIT_CODE`: Simulated exit code
- Used for testing without incurring API costs

## Key Files to Reference

- **lib/exec.sh**: `load_backend_config()`, `build_opencode_opts()`
- **backends/index.jsonc**: Backend registry
- **tests/integration/test-backends.sh**: Backend integration tests

## Best Practices

1. **Configuration Files**: Use JSONC (JSON with comments) for documentation
2. **Environment Variables**: Document all configurable options
3. **Testing**: Always test with mock backend before using real backends
4. **Placeholders**: Mark unimplemented backends clearly

## Integration Points

- Backend selection happens in `build_opencode_opts()` (`lib/exec.sh`)
- Backend configuration loaded via `load_backend_config()` (`lib/exec.sh`)
- Validation backend can be separate via `RALPH_AGENT_VALIDATION`
