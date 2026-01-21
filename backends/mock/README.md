# Mock Backend for RalphLoop

A mock backend for testing RalphLoop without requiring actual OpenCode API calls or expensive AI model invocations. This backend simulates agent responses for development, debugging, and CI/CD testing.

## Quick Start

### 1. Setup the Mock Backend

```bash
# Make the mock-opencode script executable
chmod +x backends/mock/bin/mock-opencode

# Add to your PATH (optional, for convenience)
export PATH="$(pwd)/backends/mock/bin:$PATH"

# Or create an alias
alias opencode="mock-opencode"
```

### 2. Use with RalphLoop

```bash
# Option 1: Use alias (simple)
alias opencode="mock-opencode"
./ralph 3

# Option 2: Use PATH prepend
PATH="$(pwd)/backends/mock/bin:$PATH" ./ralph 3

# Option 3: Create a wrapper script
```

### 3. Test Different Scenarios

```bash
# Quick success scenario
RALPH_MOCK_RESPONSE=success ./ralph 1

# Test validation failure
RALPH_MOCK_RESPONSE=fail ./ralph 1

# Simulate slow processing (3 second delay)
RALPH_MOCK_DELAY=3 RALPH_MOCK_RESPONSE=progress ./ralph 1

# Test timeout handling
RALPH_MOCK_EXIT_CODE=124 ./ralph 1

# Empty output scenario
RALPH_MOCK_RESPONSE=empty ./ralph 1
```

## Environment Variables

| Variable               | Default    | Description                                            |
| ---------------------- | ---------- | ------------------------------------------------------ |
| `RALPH_MOCK_RESPONSE`  | `complete` | Response type: `complete`, `fail`, `progress`, `empty` |
| `RALPH_MOCK_DELAY`     | `0`        | Artificial delay in seconds before responding          |
| `RALPH_MOCK_EXIT_CODE` | `0`        | Exit code to return (0=success, 124=timeout)           |

## Test Scenarios

The mock backend supports several test scenarios for different use cases:

### 1. Quick Success (`success`)

- Agent immediately marks task as complete
- No delay
- Exit code: 0
- Use case: Fast iteration testing

```bash
RALPH_MOCK_RESPONSE=success ./ralph 1
```

### 2. Validation Failure (`fail`)

- Agent completes but validation fails
- Useful for testing error handling flow
- Exit code: 0

```bash
RALPH_MOCK_RESPONSE=fail ./ralph 1
```

### 3. Progress Simulation (`progress`)

- Agent simulates ongoing work
- Adds delays to test real-time output streaming
- Returns partial completion

```bash
RALPH_MOCK_DELAY=2 RALPH_MOCK_RESPONSE=progress ./ralph 1
```

### 4. Timeout Simulation (`timeout`)

- Simulates command timeout
- Exit code: 124
- Tests timeout error handling

```bash
RALPH_MOCK_EXIT_CODE=124 ./ralph 1
```

### 5. Empty Output (`empty`)

- Returns no output
- Tests empty response handling

```bash
RALPH_MOCK_RESPONSE=empty ./ralph 1
```

## Direct Mock CLI Usage

The mock-opencode CLI can be used directly for testing:

```bash
# Show help
backends/mock/bin/mock-opencode --help

# Run with default settings
backends/mock/bin/mock-opencode run --agent AGENT_RALPH

# Run with progress simulation
RALPH_MOCK_DELAY=2 backends/mock/bin/mock-opencode run --agent AGENT_RALPH

# Run validation simulation
backends/mock/bin/mock-opencode validate

# Run specific test scenario
backends/mock/bin/mock-opencode test success
backends/mock/bin/mock-opencode test fail
backends/mock/bin/mock-opencode test progress
backends/mock/bin/mock-opencode test timeout
```

## Testing RalphLoop Changes

The mock backend is particularly useful for:

1. **Output Streaming Tests**

   ```bash
   # Test that output appears in real-time
   RALPH_MOCK_DELAY=1 RALPH_MOCK_RESPONSE=progress ./ralph 1
   ```

2. **Error Handling Tests**

   ```bash
   # Test timeout handling
   RALPH_MOCK_EXIT_CODE=124 ./ralph 1

   # Test error output
   RALPH_MOCK_EXIT_CODE=1 ./ralph 1
   ```

3. **Validation Flow Tests**

   ```bash
   # Test successful validation
   RALPH_MOCK_RESPONSE=success ./ralph 1

   # Test failed validation
   RALPH_MOCK_RESPONSE=fail ./ralph 1
   ```

4. **Performance Tests**
   ```bash
   # Test with various delays
   for delay in 0 1 3 5; do
       echo "Testing with ${delay}s delay"
       RALPH_MOCK_DELAY=$delay ./ralph 1
   done
   ```

## CI/CD Integration

Use in CI/CD pipelines for fast, deterministic testing:

```yaml
# .github/workflows/test-ralphloop.yml
- name: Test RalphLoop with Mock Backend
  run: |
    chmod +x backends/mock/bin/mock-opencode
    PATH="$(pwd)/backends/mock/bin:$PATH" ./ralph 3

- name: Test Timeout Handling
  run: |
    chmod +x backends/mock/bin/mock-opencode
    RALPH_MOCK_EXIT_CODE=124 ./ralph 1 || echo "Expected exit code 124"
```

## Troubleshooting

### Issue: Command not found

```bash
# Make sure the script is executable
chmod +x backends/mock/bin/mock-opencode

# Check PATH includes the mock directory
echo $PATH | grep -q "backends/mock/bin" || echo "Add to PATH"
```

### Issue: Wrong response type

```bash
# Verify environment variables are set
echo "RALPH_MOCK_RESPONSE=$RALPH_MOCK_RESPONSE"
echo "RALPH_MOCK_DELAY=$RALPH_MOCK_DELAY"

# Set explicitly
export RALPH_MOCK_RESPONSE=progress
export RALPH_MOCK_DELAY=2
```

### Issue: Alias conflicts

```bash
# If you have an alias for opencode, use command prefix
command opencode run --agent AGENT_RALPH

# Or temporarily unalias
unalias opencode 2>/dev/null
```

## Advanced Configuration

### Custom Response Templates

You can customize responses by modifying the mock-opencode script:

```bash
# Edit the generate_completion_response function
nano backends/mock/bin/mock-opencode

# Look for:
# - generate_completion_response()
# - generate_progress_response()
```

### Multiple Mock Instances

For parallel testing, use different response files:

```bash
# Create custom response files
cat > /tmp/mock-complete.txt << 'EOF'
<promise>COMPLETE</promise>
Custom complete response
EOF

# Use with custom script
cp backends/mock/bin/mock-opencode /tmp/my-mock
# Modify /tmp/my-mock to use custom response
```

## Best Practices

1. **Always clean up environment variables** after testing:

   ```bash
   (
     export RALPH_MOCK_DELAY=5
     ./ralph 1
   )
   # RALPH_MOCK_DELAY not affected outside subshell
   ```

2. **Use subshells for isolation**:

   ```bash
   (RALPH_MOCK_RESPONSE=fail ./ralph 1)
   ```

3. **Test the full workflow**:

   ```bash
   # Test complete flow
   RALPH_MOCK_DELAY=1 ./ralph 3 && echo "Workflow succeeded"
   ```

4. **Check exit codes**:
   ```bash
   RALPH_MOCK_EXIT_CODE=124 ./ralph 1
   echo "Exit code: $? (expected: 124)"
   ```

## Contributing

To add new test scenarios:

1. Add the scenario case in `run_scenario()` function
2. Update the `Test Scenarios` section in this README
3. Add environment variable documentation
4. Test your new scenario:
   ```bash
   backends/mock/bin/mock-opencode test your-new-scenario
   ```

## License

Part of RalphLoop project. See LICENSE file for details.
