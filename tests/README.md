# RalphLoop Test Suite

Comprehensive testing framework for RalphLoop autonomous development system.

## Quick Start

```bash
# Run all tests
./tests/run-tests.sh --all

# Run specific test categories
./tests/run-tests.sh --unit           # Unit tests
./tests/run-tests.sh --integration    # Integration tests
./tests/run-tests.sh --e2e           # End-to-end tests
./tests/run-tests.sh --mock          # Mock backend tests

# Quick smoke tests
./tests/run-tests.sh --quick

# With verbose output
./tests/run-tests.sh --all --verbose
```

## Test Structure

```
tests/
├── run-tests.sh           # Main test runner
├── common.sh              # Shared utilities and assertions
├── package.json           # NPM scripts for testing
├── unit/                  # Unit tests
│   ├── test-functions.sh  # Script function tests
│   └── test-validation.sh # Validation function tests
├── integration/           # Integration tests
│   └── test-backends.sh   # Backend configuration tests
├── e2e/                   # End-to-end tests
│   └── test-workflows.sh  # Complete workflow tests
├── mock/                  # Mock backend tests
│   └── test-mock-backend.sh
└── fixtures/              # Test fixtures and test data
```

## Test Categories

### Unit Tests (`--unit`)

Tests for individual functions in the ralph script:

- `get_prompt()` - Prompt source detection
- `sanitize_for_heredoc()` - Content sanitization
- `get_validation_status()` - Status extraction
- `validate_max_rounds()` - Input validation
- Configuration display functions

**Run:** `./tests/run-tests.sh --unit`

### Integration Tests (`--integration`)

Tests for backend integrations:

- Backend directory structure
- Mock backend configuration
- Mock opencode CLI commands
- Backend with RalphLoop integration
- Configuration parsing

**Run:** `./tests/run-tests.sh --integration`

### End-to-End Tests (`--e2e`)

Tests for complete workflows:

- Single iteration workflow
- Multiple iterations workflow
- Completion and validation flow
- Failed validation handling
- Progress tracking
- Git integration
- Custom environment variables
- Error handling

**Run:** `./tests/run-tests.sh --e2e`

### Mock Backend Tests (`--mock`)

Tests for the mock backend:

- Basic run commands
- Response modes (complete, fail, progress, empty)
- Delay functionality
- Exit codes
- Validation modes
- Test scenarios
- Error handling

**Run:** `./tests/run-tests.sh --mock`

### Quick Tests (`--quick`)

Smoke tests for rapid validation:

- Core functionality tests
- Mock backend tests
- Basic workflows

**Run:** `./tests/run-tests.sh --quick`

## Using the Mock Backend

The mock backend allows testing RalphLoop without actual OpenCode API calls:

```bash
# Quick success scenario
RALPH_MOCK_RESPONSE=success ./ralph 1

# Test validation failure
RALPH_MOCK_RESPONSE=fail ./ralph 1

# Simulate slow processing
RALPH_MOCK_DELAY=3 ./ralph 1

# Test timeout handling
RALPH_MOCK_EXIT_CODE=124 ./ralph 1

# Direct mock CLI usage
backends/mock/bin/mock-opencode --help
backends/mock/bin/mock-opencode test success
```

### Mock Environment Variables

| Variable               | Default    | Description                |
| ---------------------- | ---------- | -------------------------- |
| `RALPH_MOCK_RESPONSE`  | `complete` | Response type              |
| `RALPH_MOCK_DELAY`     | `0`        | Artificial delay (seconds) |
| `RALPH_MOCK_EXIT_CODE` | `0`        | Exit code to return        |

### Mock Scenarios

```bash
# Success - Immediate completion
backends/mock/bin/mock-opencode test success

# Fail - Completion with issues
backends/mock/bin/mock-opencode test fail

# Progress - Simulates ongoing work
backends/mock/bin/mock-opencode test progress

# Timeout - Simulates timeout
backends/mock/bin/mock-opencode test timeout

# Empty - Returns no output
backends/mock/bin/mock-opencode test empty

# Error - Returns error
backends/mock/bin/mock-opencode test error
```

## Writing Tests

### Adding Unit Tests

Add new test functions to `tests/unit/test-functions.sh`:

```bash
test_my_function() {
    print_section "Test: My function"

    # Test assertions
    assert_success 0 "Should succeed"
    assert_contains "$output" "expected" "Should contain expected text"
    assert_equal "value" "$result" "Should equal expected value"
}
```

### Adding Integration Tests

Add integration tests to `tests/integration/test-backends.sh`:

```bash
test_my_integration() {
    print_section "Test: My integration"

    # Setup
    setup_test_environment

    # Test
    local output=$(some_command)
    assert_contains "$output" "expected" "Should work"

    # Teardown (automatic via trap)
}
```

### Using Assertions

Available assertions in `common.sh`:

```bash
# File/directory
assert_file_exists "/path/file" "description"
assert_dir_exists "/path/dir" "description"

# Content
assert_contains "$content" "pattern" "description"
assert_not_contains "$content" "pattern" "description"

# Exit codes
assert_success 0 "description"
assert_failure 1 "description"
assert_exit_code "expected" "actual" "description"

# Values
assert_equal "expected" "actual" "description"
assert_match "$value" "regex" "description"
assert_empty "$value" "description"
assert_not_empty "$value" "description"
```

## CI/CD Integration

### GitHub Actions

The test suite runs automatically on:

- Every push to main/master/develop
- Every pull request
- Weekly scheduled run

Configuration: `.github/workflows/tests.yml`

### Running in CI Mode

```bash
# Non-interactive mode
./tests/run-tests.sh --all --ci

# Exit with error code on failure
if ! ./tests/run-tests.sh --ci; then
    echo "Tests failed!"
    exit 1
fi
```

### Environment Variables for CI

```bash
export CI_MODE=true           # Non-interactive mode
export VERBOSE=false          # Minimal output
export RALPH_MOCK_RESPONSE=success
export RALPH_MOCK_DELAY=0
```

## Test Output

### Passing Tests

```
========================================
Unit Tests - Script Functions
========================================

[TEST] Test description
✓ PASS: Test passed
```

### Failing Tests

```
[TEST] Test description
✗ FAIL: Test failed (expected: X, got: Y)
```

### Test Summary

```
========================================
Test Summary
========================================

  Tests Run:    15
  Tests Passed: 14
  Tests Failed: 1
  Tests Skipped: 0

❌ Some tests failed!
```

## Troubleshooting

### Tests not running

```bash
# Make scripts executable
chmod +x tests/run-tests.sh
chmod +x backends/mock/bin/mock-opencode

# Check bash version
bash --version  # Should be >= 4.0
```

### Permission errors

```bash
# Fix permissions
chmod +x tests/**/*.sh
chmod +x ralph
```

### Timeout issues

```bash
# Increase timeout for slow tests
export RALPH_TIMEOUT=300

# Or test with mock backend
RALPH_MOCK_DELAY=0 ./tests/run-tests.sh --quick
```

### Missing dependencies

```bash
# Check required tools
which bash
which grep
which sed
```

## Performance Testing

Run performance tests to measure test execution time:

```bash
# Time the test suite
time ./tests/run-tests.sh --all

# Profile individual tests
time ./tests/run-tests.sh --unit
time ./tests/run-tests.sh --integration
time ./tests/run-tests.sh --e2e
```

## Best Practices

1. **Run quick tests before committing**:

   ```bash
   ./tests/run-tests.sh --quick
   ```

2. **Run full tests before push**:

   ```bash
   ./tests/run-tests.sh --all
   ```

3. **Use mock backend for development**:

   ```bash
   RALPH_MOCK_RESPONSE=success ./ralph 5
   ```

4. **Add tests for new features**:
   - Add unit tests to `tests/unit/`
   - Add integration tests to `tests/integration/`
   - Add E2E tests to `tests/e2e/`

5. **Keep tests fast**:
   - Use mock backend for unit tests
   - Minimize delays in mock responses
   - Use quick tests for CI

## Contributing

1. Ensure all tests pass before submitting PR
2. Add tests for new functionality
3. Update documentation for new features
4. Follow test naming conventions:
   - `test_function_name()` for unit tests
   - `test_*_workflow()` for E2E tests
   - `test_*_integration()` for integration tests
