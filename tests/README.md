# Makefile Tests

This directory contains BATS (Bash Automated Testing System) tests for the project's makefiles.

## Prerequisites

Install BATS:
```bash
# macOS
brew install bats-core

# Linux
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

## Running Tests

Run all tests:
```bash
make test-makefiles
```

Run specific test file:
```bash
bats tests/makefiles/config_test.bats
```

Run with verbose output:
```bash
bats -t tests/makefiles/
```

## Test Structure

```
tests/
├── test_helper.bash              # Common test utilities
├── README.md                     # This file
└── makefiles/
    ├── config_test.bats          # Tests for makefiles/config.mk
    ├── package_targets_test.bats # Tests for makefiles/package-targets.mk
    ├── test_mk_test.bats         # Tests for makefiles/test.mk
    ├── setup_test.bats           # Tests for makefiles/setup.mk
    ├── verify_test.bats          # Tests for makefiles/verify.mk
    ├── coverage_test.bats        # Tests for makefiles/coverage.mk
    ├── development_test.bats     # Tests for makefiles/development.mk
    ├── selector_test.bats        # Tests for makefiles/selector.mk
    └── makefile_test.bats        # Tests for main Makefile
```

## What We Test

### config.mk
- Variable definitions (PACKAGES, FVM, FLUTTER, DART)
- FVM detection logic
- VERBOSE mode handling
- Helper functions (print-%, run-parallel-packages)

### package-targets.mk
- Per-package target generation (test-*, coverage-*, analyze-*, etc.)
- Package name mappings (PKG_interface, PKG_main, etc.)
- Template functions (define-test-target, define-coverage-target, etc.)
- Special handling for web platform (--platform chrome)

### test.mk
- Test execution targets (test, test-coverage, analyze)
- DRY principle compliance (targets use run-parallel-packages)
- Quick-check functionality
- Platform-specific tests (test-interface, test-main, test-web)

### setup.mk
- Setup and installation targets
- Code formatting (format, format-check)
- Shared links management
- Git hooks configuration

### Makefile (main)
- Include structure
- Default goal
- Help documentation
- Overall integration
- DRY compliance

### verify.mk
- Tool verification targets (verify-tools, verify-setup)
- FVM version checking and installation
- Flutter version validation
- Tool detection (_check-fvm, _check-flutter, _check-fzf, _check-lcov)
- Shared links verification
- Git hooks configuration
- Error messaging and user guidance

### coverage.mk
- Coverage workflow targets (coverage, coverage-html, coverage-summary)
- Path fixing with sed (SF: pattern transformations)
- lcov combining logic for multiple packages
- Dependency on native coverage targets
- HTML report generation
- Script integration (coverage-summary.sh)
- Graceful handling of missing coverage files

### development.mk
- Developer workflow targets (run, run-simple, pigeon-generate)
- DEVICE_ID parameter handling
- Conditional device selection
- Pigeon code generation from platform_interface
- Swift file copying to macOS
- Example app directory validation
- Progress messaging and feedback

### selector.mk
- Interactive task selector target (select)
- fzf dependency checking
- Script integration (task-selector.sh)
- Variable passing (FLUTTER, IOS_SIMULATOR_ID)
- Default goal configuration
- Script file validation

## Writing New Tests

1. Create a new `.bats` file in `tests/makefiles/`
2. Load the test helper: `load ../test_helper`
3. Write test cases using `@test` decorator
4. Use helper functions from `test_helper.bash`

Example:
```bash
#!/usr/bin/env bats
load ../test_helper

@test "my feature: does something" {
  run bash -c "cd '$PROJECT_ROOT' && make my-target"
  assert_success
  assert_output --regexp "expected output"
}
```

## Test Helpers

Available from `test_helper.bash`:
- `setup()` - Runs before each test
- `teardown()` - Runs after each test
- `run_make()` - Run make with error handling
- `target_exists()` - Check if makefile target exists
- `get_packages()` - Get list of packages
- `count_makefile_lines()` - Count lines in makefile
- `using_fvm()` - Check if FVM is configured
- `require_command()` - Skip test if command not available

## CI Integration

These tests should be run in CI to catch makefile regressions:
```yaml
- name: Test makefiles
  run: make test-makefiles
```

## Debugging Tests

Run with verbose output:
```bash
bats -t tests/makefiles/config_test.bats
```

Run single test by line number:
```bash
bats tests/makefiles/config_test.bats:10
```

Print values during test:
```bash
@test "debug example" {
  echo "Debug: $PROJECT_ROOT" >&3
  run make help
  echo "Output: $output" >&3
}
```
