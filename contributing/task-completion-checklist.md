# Task Completion Checklist

Before moving any task from "In Progress" to "Completed" in ROADMAP.md, verify ALL items below:

## 1. `make format quick-check` passes without errors

Run from project root:

```bash
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
make format quick-check
```

This runs:
- Code formatting (dart format)
- Dart analyze
- Kotlin compilation check
- iOS/macOS Swift compilation check
- Format verification
- Shared links verification
- Logging verification (no direct print/Log statements in library code)
- Code duplication check (≤2.5% threshold)

If this fails, the task is NOT complete. Fix all errors and run again until it passes.

## 2. All tests pass (unit, widget, integration, native)

- [ ] All Dart tests pass (`make test`)
- [ ] All native tests pass (`make test-native`)
  - [ ] iOS native tests
  - [ ] Android native tests
  - [ ] macOS native tests
- [ ] E2E/integration tests pass if applicable (`make test-e2e`)
- [ ] No tests skipped without explicit user permission
- [ ] Failing tests fixed (implementation bugs corrected, not test adjusted to match broken behavior)

## 3. The code follows the architecture guidelines

Reference: contributing/architecture.md

- [ ] State management patterns followed correctly
- [ ] File size limits respected
- [ ] Refactoring guidelines applied
- [ ] DRY principle followed - no code duplication
  - [ ] Similar code extracted to functions/shared modules
  - [ ] Shared code patterns used (MethodChannelBase, iOS/macOS Swift links)
- [ ] Code sharing utilized where appropriate
  - [ ] iOS/macOS share Swift via shared_apple_sources/
  - [ ] Platform implementations use consistent patterns
- [ ] Single responsibility principle - each class/function does one thing
- [ ] Library independence maintained - library packages never reference example app code

## 4. The tests follow the testing guidelines

Reference: contributing/testing-guide.md

- [ ] TDD followed strictly - tests written BEFORE implementation
- [ ] Red → Green → Refactor cycle used
- [ ] Established test patterns from testing-guide.md reused
- [ ] No reinvented solutions - documented patterns used
- [ ] Test structure patterns followed:
  - [ ] Proper mock setup
  - [ ] Correct async delays
  - [ ] Widget testing best practices
- [ ] Any new testing patterns/solutions documented in contributing/testing-guide.md

## 5. Code coverage is compliant

- [ ] Dart code: 95% line coverage per file (target)
- [ ] Native code: 80% line coverage (target)
- [ ] Global minimum: 80% line coverage overall (mandatory)
- [ ] Coverage verified via `make coverage`

## 6. There is no more opportunity for code improvements

- [ ] Code is clean and maintainable
- [ ] No obvious refactoring opportunities remain
- [ ] API design follows video_player compatibility philosophy
  - [ ] Method/property names match video_player patterns where applicable
  - [ ] API feels like natural extension of video_player
  - [ ] Smooth migration path for video_player users
- [ ] No lint ignore lines added without explicit user permission
- [ ] All public APIs have dartdoc comments (`///`)
- [ ] Verbose logging requirements followed:
  - [ ] All logging uses verbose functions (verboseLog, ProVideoPlayerLogger.log)
  - [ ] No direct print/Log/console.log in library code
- [ ] Documentation updated:
  - [ ] docs/ updated for user-facing changes
  - [ ] contributing/ updated for new developer patterns
  - [ ] README.md updated if main features changed
- [ ] Platform consistency maintained:
  - [ ] Primary platforms (iOS, Android, macOS, Web) have feature parity
  - [ ] Shared code updated consistently
- [ ] Copyright compliance verified for any new test fixtures/media
  - [ ] Public domain, permissively licensed, or self-created
  - [ ] Proper attribution included

## 7. There is no more opportunity for testing improvements

- [ ] Test coverage comprehensive for new functionality
- [ ] Edge cases covered
- [ ] Error conditions tested
- [ ] Platform-specific behavior tested appropriately
- [ ] Integration between components tested
- [ ] No obvious gaps in test scenarios

## ROADMAP.md Updates

- [ ] All task checkboxes in ROADMAP.md ticked
- [ ] Task ready to move to "Completed" with condensed summary:
  - [ ] Implementation details removed
  - [ ] Test coverage numbers removed
  - [ ] Sub-bullet explanations removed
  - [ ] Only "what was accomplished" remains

---

**CRITICAL: Only after ALL these criteria are met can the task be moved to "Completed".**

**Remember**: Quality over speed. Seek the BEST solution, not the fastest.
