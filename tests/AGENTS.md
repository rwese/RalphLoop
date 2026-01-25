# Tests Directory Agent Guidance

This directory contains the complete test suite for RalphLoop. AI agents working here should follow testing best practices and maintain test coverage.

## Directory Structure

```
tests/
├── run-tests.sh           # Main test runner (all tests)
├── run-resume-tests.sh    # Pipeline resume tests
├── common.sh              # Test utilities and helpers
├── README.md              # Testing documentation
├── package.json           # Node.js test dependencies
├── fixtures/              # Test fixture files
├── unit/                  # Unit tests
│   ├── test-functions.sh  # Function-level tests
│   ├── test-pipeline.sh   # Pipeline tests
│   ├── test-validation.sh # Validation tests
│   └── ...
├── integration/           # Integration tests
│   └── test-backends.sh   # Backend integration
├── e2e/                   # End-to-end tests
│   └── test-workflows.sh  # Workflow tests
└── mock/                  # Mock backend tests
    └── test-mock-backend.sh
```

## Test Categories

### Unit Tests (`tests/unit/`)

Test individual functions in isolation:

- **test-functions.sh**: Core function tests
- **test-pipeline.sh**: Pipeline stage tests
- **test-validation.sh**: Validation logic tests

Run with: `./tests/run-tests.sh --unit`

### Integration Tests (`tests/integration/`)

Test component interactions:

- **test-backends.sh**: Backend loading and configuration

Run with: `./tests/run-tests.sh --integration`

### End-to-End Tests (`tests/e2e/`)

Test complete workflows:

- **test-workflows.sh**: Full pipeline execution

Run with: `./tests/run-tests.sh --e2e`

### Mock Tests (`tests/mock/`)

Test with mock backend:

- **test-mock-backend.sh**: Mock behavior validation

Run with: `./tests/run-tests.sh --mock`

## Common Tasks

### 1. Writing Unit Tests

When adding tests for new functions:

1. Source the module containing the function
2. Use `assert_*` functions from `common.sh`
3. Test success and failure cases
4. Clean up any temporary files

Example structure:

```bash
#!/bin/bash
source "../common.sh"
source "../lib.sh"

test_function_name() {
    local result
    result=$(function_name "arg1" "arg2")
    assertEquals "expected_output" "$result"
}
```

### 2. Running Tests

```bash
# All tests
./tests/run-tests.sh --all

# Specific categories
./tests/run-tests.sh --unit --integration --e2e --mock

# Quick smoke tests
./tests/run-tests.sh --quick

# CI mode (fail fast)
./tests/run-tests.sh --ci

# Resume-specific tests
./tests/run-resume-tests.sh
```

### 3. Adding Test Fixtures

Place fixtures in `tests/fixtures/`:

- Configuration files (`.yaml`, `.jsonc`)
- Mock data files
- Expected output files

Reference fixtures with relative paths from test scripts.

## Test Utilities (`tests/common.sh`)

Key functions available in tests:

| Function        | Purpose                               |
| --------------- | ------------------------------------- |
| `assertEquals`  | Assert two values are equal           |
| `assertTrue`    | Assert command returns 0              |
| `assertFalse`   | Assert command returns non-zero       |
| `assertNotNull` | Assert variable is not empty          |
| `setup()`       | Setup function (override per test)    |
| `teardown()`    | Teardown function (override per test) |
| `RALPH_SCRIPT`  | Path to main script                   |
| `RALPH_LIB`     | Path to lib directory                 |

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Clean State**: Remove temporary files in teardown
3. **Descriptive Names**: Test functions should describe what they test
4. **Coverage**: Aim for 100% coverage on new functions
5. **Mocking**: Use mock backend for API-dependent tests

## Key Files to Reference

- **tests/common.sh**: Test utilities and assertions
- **tests/run-tests.sh**: Test runner with all options
- **lib.sh**: Module loader (sourced in tests)

## Integration Points

- Tests source `tests/common.sh` for utilities
- Tests source `lib.sh` to load modules
- Pipeline tests use `tests/unit/test-pipeline.sh` as template
- Backend tests use `tests/integration/test-backends.sh` as template
