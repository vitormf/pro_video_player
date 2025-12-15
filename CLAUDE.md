# CLAUDE.md

Instructions for Claude Code when working with this codebase.

## CRITICAL: Follow Strictly

This document MUST be followed strictly. All instructions are mandatory requirements, not suggestions.

1. Read this entire document at start of each session
2. Follow TDD strictly - Write tests BEFORE implementation, no exceptions
3. Verify compliance before completing any task
4. Ask if unsure rather than making assumptions
5. Seek the BEST solution - Prioritize correctness, maintainability, quality over speed

### Core Philosophy: Best Solution, Not Fastest

Always seek the best solution, not the easiest or fastest. Choose cleaner, more maintainable code. Invest time in proper architecture. Don't cut corners. Quality and correctness are paramount; development speed is secondary.

## After Making Changes - Run Quick Check

MANDATORY after any code changes (Dart, Kotlin, Swift), run from project root:

```bash
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
make quick-check
```

IMPORTANT: Always run from project root, NOT from subdirectories.

Runs all checks in parallel (~17 sec): Dart analyze, Kotlin compile, iOS/macOS Swift compile, format check, shared links verification, logging verification, code duplication.

Do NOT consider task complete until `make quick-check` passes. If fails: fix errors, run again, repeat until passes.

## Copyright and Legal Compliance

CRITICAL: All test fixtures, example media, assets MUST be copyright-compliant for open source distribution.

Allowed:
- Public domain content
- Open source licensed files with attribution (MIT, Apache 2.0, CC-BY-SA)
- W3C specification examples
- Simple non-creative test data
- Self-created test files

Never commit:
- Copyrighted movies, TV shows, commercial video clips
- Copyrighted music or audio
- Copyrighted images (stock photos, movie posters)
- Subtitle files extracted from commercial media (Netflix, Disney+)
- Any content without proper licensing or attribution

Before adding test fixtures/media, verify:
1. Content is public domain, permissively licensed, or self-created?
2. License permits open source redistribution?
3. Proper attribution included in comments?
4. No copyrighted characters, logos, trademarks?
5. Comfortable defending this in court?

If "no" to ANY question above, DO NOT add the file.

See contributing/copyright-compliance.md for detailed attribution requirements and current compliance status.

## Quick Commands

All make commands run from project root.

- `make quick-check` - Run after every change. Fast parallel compile check (Dart+Kotlin+Swift). MUST run from root
- `/pr-ready` - Full PR readiness check (tests, coverage, analysis)
- `/tdd FeatureName` - Start TDD cycle for a new feature
- `/coverage` - Show test coverage report for all packages
- `/test-native [platform]` - Run native tests (ios, android, macos, or all)
- `/fix` - Auto-fix code issues (format + dart fix + analyze)
- `/e2e [platform]` - Run E2E UI tests on device/simulator
- `/review [files]` - Review code for quality, bugs, test coverage

Subagents (via Task tool):
- `code-reviewer` - Reviews code for bugs, security, test coverage, platform consistency
- `security-auditor` - Scans for security vulnerabilities
- `doc-checker` - Scans for missing dartdoc on public APIs
- `test-gap-finder` - Identifies untested public methods and coverage gaps
- `doc-sync-checker` - Verifies markdown docs and dartdoc match implementation

Keep subagent list in sync with `.claude/agents/`.

## Project Priorities

1. Functional & Bug-Free - Reliability paramount. Must work correctly across all platforms
2. Simple & Easy to Use - Intuitive API, minimal integration effort
3. Well-Tested - Comprehensive coverage ensures stability
4. Well-Documented - All public APIs must have dartdoc

## Code Philosophy

Core Principles:
- Short, focused code - Prefer concise over verbose
- Consistent patterns - Same approach for similar problems
- Single responsibility - Each class/function does one thing well
- Share code - Avoid duplication across packages/platforms (iOS/macOS share Swift, MethodChannelBase pattern)
- Dart-first - Implement in Dart when possible without 3rd party deps; only use native for platform APIs
- Design for testing - Dependency injection, interfaces, mockable components
- Library independence - Library packages MUST be completely self-sufficient and NEVER reference example app code, classes, resources, or package names under ANY circumstance. Library must work standalone without example apps present.

Shared Apple Sources (iOS/macOS): Swift code shared via `shared_apple_sources/` with hard links. Always run `make setup` after cloning to create hard links. Pre-commit hooks verify sync.

See contributing/architecture.md for details on code sharing, state management patterns, refactoring guidelines.

## API Design Philosophy

Inspired by video_player Flutter library: API should feel familiar to existing video_player users while providing enhanced functionality. Design principles:
- Maintain compatible naming conventions - Method/property names should match video_player patterns where functionality overlaps (e.g., `initialize()`, `play()`, `pause()`, `seekTo()`, `setVolume()`, `value`, `position`, `duration`, `isPlaying`)
- Compatible even when extended - New/incompatible APIs should still feel like natural extensions of video_player patterns rather than completely different paradigms
- Smooth migration path - Users migrating from video_player should find API intuitive with minimal learning curve
- Preserve Flutter ecosystem familiarity - Follow established Flutter plugin conventions that video_player exemplifies

Reference implementation: https://pub.dev/packages/video_player

Note: See ROADMAP.md for high priority API refactoring task to align current implementation with this philosophy.

Coverage Targets:
- Dart code: 95% line coverage per file (target)
- Native code: 80% line coverage (target)
- Global minimum: 80% line coverage overall (mandatory)

Code Duplication:
- Threshold: ≤2.5% code duplication (mandatory)
- Detected duplication should be refactored when feasible
- Use shared base classes, utilities, or helper functions
- Checked automatically via `make quick-check` using jscpd
- Detection thresholds: min 10 lines, min 50 tokens

Documentation:
- All public APIs documented - Every public class, method, property needs dartdoc (`///`)
- README completeness - Document main usage scenarios and features requiring extra configuration

See contributing/developer-guide.md for API documentation requirements, developer configurability options, file creation policies.

## Project Structure

Federated Flutter plugin:

```
pro_video_player/
├── pro_video_player/                    # Main package (user-facing API)
├── pro_video_player_platform_interface/ # Abstract interfaces, DTOs, method_channel_base.dart
├── pro_video_player_android/            # ExoPlayer implementation
├── pro_video_player_ios/                # AVPlayer (extends MethodChannelBase)
├── pro_video_player_web/                # HTML5 VideoElement
├── pro_video_player_macos/              # AVPlayer (extends MethodChannelBase)
├── pro_video_player_windows/            # libmpv (requires Windows VM)
├── pro_video_player_linux/              # libmpv (requires Linux VM)
├── example-showcase/                         # Full-featured demo app
└── example-simple-player/                    # Minimal file/URL player
```

Key Features: Native video player per platform, Background playback, PiP, Fullscreen, Subtitles (SRT/VTT/SSA/ASS/TTML/CEA-608/708/embedded), Track selection, Adaptive streaming (HLS/DASH), Playlists (M3U/PLS/XSPF), Cross-platform Flutter controls.

Example apps: example-showcase must showcase ALL library features; example-simple-player is minimal file/URL player.

## Dependency Philosophy

Minimize external dependencies: Only add when absolutely necessary. Prefer native Dart/Flutter solutions. Keep dependency tree shallow.

Allowed: plugin_platform_interface (required for federated plugin), flutter_test/integration_test (testing), mocktail (mocking).

Avoided: Heavy utility packages, large dependency trees, unmaintained packages.

## Test-Driven Development

Strict TDD practices:
1. Write tests first - failing tests before implementation
2. Red → Green → Refactor cycle
3. Test categories: unit (mocked deps), widget, integration, platform channel

CRITICAL: Before writing ANY tests, consult contributing/testing-guide.md for established patterns, mock setup, async delays, common pitfalls, and helper functions. Do NOT reinvent solutions - use documented patterns.

CRITICAL: Do NOT skip tests without explicit user permission.

All tests must run and pass. If test failing:
1. Fix the test or code to make it pass
2. If skipping truly necessary (e.g., platform limitations), ask user first
3. Document why skip is necessary when approved

When Tests Fail: Failing tests often reveal implementation bugs, not test bugs - this is exactly what tests should do! Before assuming test is wrong, thoroughly examine implementation code it's testing. Example bugs caught: missing state updates, incomplete logic, forgotten cleanup. Fix root causes - If implementation incomplete, fix it; don't adjust tests to match broken behavior.

Testing Commands:
- `make test` - All Dart tests
- `make test-interface` - platform_interface only
- `make test-main` - main package only
- `make test-web` - web package (Chrome)
- `make test-e2e` - E2E UI tests (auto-detect)
- `make test-native` - All native tests
- `make coverage` - Full Dart + Native coverage with summary

Comprehensive testing guidance in contributing/testing-guide.md: test structure patterns (mock setup, widget testing, async delays), common pitfalls, E2E cross-platform guidelines, Android native coverage (unit vs instrumented vs combined), helper functions.

CRITICAL: When you discover and fix architectural testing challenges (e.g., desktop wrapper intercepting taps, timer cleanup issues, event stream broadcasting, async timing problems), you MUST document the solution in contributing/testing-guide.md. Add it to the appropriate section: "Test Structure Patterns", "Common Test Pitfalls", or create a new section if needed. Include the problem description, root cause, and solution with code examples. This prevents future developers from having to rediscover the same solutions.

## Verbose Logging Requirements

All logging in library code must be guarded by verbose mode. Prevents debug output from polluting production apps.

Logging functions:
- Kotlin: ProVideoPlayerPlugin.verboseLog(message, tag) - checks isVerboseLoggingEnabled
- Swift: verboseLog(message, tag:) - checks VerboseLogger.shared.isEnabled
- Dart: ProVideoPlayerLogger.log(message, tag:) - checks isVerboseLoggingEnabled
- Web: verboseLog(message, tag:) - checks isVerboseLoggingEnabled

Forbidden in library code:
- Kotlin: Log.d(), Log.e(), Log.w(), Log.i(), Log.v(), println()
- Swift: print(), NSLog()
- Dart: print(), debugPrint() (except in logger implementation)
- Web: console.log(), console.warn(), console.error()

Exception: Example app can use direct logging for demo/debug purposes.

`make quick-check` automatically verifies this. Manual check: `./makefiles/scripts/check-verbose-logging.sh`

## Code Style

Follows Effective Dart (https://dart.dev/effective-dart):
- Line length: 120 characters
- Prefer single quotes
- Relative imports within packages
- Always declare return types
- Document all public APIs
- Use flutter_lints

Commands: `dart format . -l 120`, `dart analyze`, `dart fix --apply`

Shared analysis_options.yaml at root. Excluded: *.g.dart, *.freezed.dart, *.mocks.dart

Lint Ignore Lines: CRITICAL - Do NOT add lint ignore lines (`// ignore:`, `// ignore_for_file:`) without explicit user permission. All code should pass strict analysis. If analyzer raises issue: 1) Fix underlying problem first, 2) If fix not possible/appropriate, ask user before adding ignore, 3) Document why ignore necessary when approved. Existing ignores are for specific cases (deprecated API migrations, legitimate async BuildContext patterns). New ignores require justification.

## Platform Priority

- Primary (equal): iOS, Android, macOS, Web - feature parity, sync implementations
- Secondary: Windows, Linux - defer until primary complete

See contributing/platform-notes.md for platform-specific details (iOS/macOS shared Swift, Windows/Linux shared C++, platform capabilities).

## Build Commands

- `make` - Interactive fzf task selector
- `make setup` - FVM + install dependencies + create hard links
- `make install` - Dependencies only
- `make clean` - Clean all packages
- `make run` - Run example app
- `make all` - Full rebuild with checks
- `make help` - All commands

## FVM

```bash
dart pub global activate fvm
fvm install
fvm flutter pub get
fvm flutter test
```

Flutter version in .fvmrc. Always prefix commands with fvm.

## Pull Request Guidelines

- Ensure all tests pass
- Include tests for new functionality (TDD)
- Update documentation if needed
- Follow conventional commit messages

## Project Roadmap

See ROADMAP.md for complete feature tracking and status.

When starting work on roadmap item:
1. Move item from current section to "In Progress" section
2. Check off completed sub-tasks immediately as you complete each one (don't batch updates)
3. Before marking item as "Completed", verify compliance with:
   - contributing/architecture.md - State management patterns, refactoring guidelines, file size limits
   - contributing/developer-guide.md - API documentation requirements, configurability patterns
   - contributing/testing-guide.md - Test patterns, TDD practices, documented solutions
   - Code coverage expectations - 95% Dart per file, 80% native, 80% global minimum
4. Move item to "Completed" only after verification passes
5. When moving to "Completed": Condense the item to brief summary format
   - Remove implementation details, test coverage numbers, sub-bullet explanations
   - Keep only "what was accomplished" without "how it was implemented"
   - Pending tasks should remain detailed; completed tasks should be concise
   - Details preserved in git history and documentation if needed later

## Documentation Structure

This project separates user documentation from developer/contributor documentation.

User Documentation (docs/): Help library users integrate and use the video player. Linked from README.md. Audience: App developers using this library.

```
docs/
├── setup/ (android.md, ios.md)
├── features/ (pip.md, background-playback.md, subtitles.md, fullscreen.md, casting.md)
└── troubleshooting.md
```

Update when: Adding new features, changing public APIs, updating setup instructions that affect library users.

Developer Documentation (contributing/): Guide contributors working on library itself. Linked from CLAUDE.md (this file). Audience: Contributors, maintainers, AI assistants.

```
contributing/
├── architecture.md (state management patterns, refactoring guidelines)
├── testing-guide.md (test patterns, TDD practices, coverage requirements)
├── developer-guide.md (API docs requirements, VideoPlayerOptions reference)
├── platform-notes.md (platform capabilities, shared code, format support)
└── copyright-compliance.md (attribution requirements, compliance status)
```

Update when: Discovering new patterns, updating testing practices, changing architecture, documenting developer workflows.

Important Guidelines:
- DO: Update docs/ when changing user-facing features or setup
- DO: Update contributing/ when discovering new development patterns or practices
- DO: Keep CLAUDE.md focused on critical instructions (currently ~12k chars, target <40k)
- DO: Move detailed reference material to appropriate contributing/ files
- DON'T: Add user-facing setup guides to contributing/
- DON'T: Add internal development patterns to docs/
- DON'T: Inline lengthy reference material into CLAUDE.md
- DON'T: Create random markdown files outside these two directories

Note: This file is optimized for Claude Code reading, not human reading. Prioritize clarity and information density over visual formatting. No need for decorative elements, tables with excessive spacing, or emoji. Compact, clear text is sufficient.

## Developer Documentation Reference

- contributing/architecture.md - State management, architectural patterns, refactoring guidelines, code sharing
- contributing/testing-guide.md - Test structure patterns, best practices, E2E guidelines, coverage details
- contributing/developer-guide.md - API documentation requirements, developer configurability, file creation policies
- contributing/platform-notes.md - Platform-specific implementation details and capabilities
- contributing/copyright-compliance.md - Attribution requirements and compliance status
