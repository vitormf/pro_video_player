# Pigeon Architecture Decision

## Decision: Per-Platform Pigeon Implementation (Option 1)

**Date:** 2024-12-15
**Status:** Approved ✅

### Summary

After careful analysis of Pigeon's compatibility requirements, we've chosen to implement Pigeon separately in each platform package rather than using a centralized approach.

## The Problem

Pigeon's documentation explicitly warns against splitting generated code across packages:

> "Pigeon-generated code **should not** be split across packages. For example, putting the generated Dart code in a platform interface package and the generated host-language code in a platform implementation package is very likely to cause crashes for some plugin clients after updates."

**Why this matters:**
- Both Dart and native code must be generated with the **exact same Pigeon version**
- In federated plugins, packages can be updated independently
- Version mismatch = undefined behavior and crashes
- Pigeon's message format is an internal implementation detail that changes between versions

## Evaluated Options

### ❌ Option 0: Centralized Pigeon (Initial Approach - REJECTED)

```
pro_video_player_platform_interface/
  └── pigeons/video_player_api.dart  ← Single source
      ↓ generates →
  - Dart → platform_interface
  - Kotlin → android
  - Swift → ios/macos
  - C++ → windows
```

**Why Rejected:**
- Violates Pigeon's explicit compatibility guidelines
- Risk of crashes when packages updated independently
- Users might update `pro_video_player_android` but not `platform_interface`
- Production stability risk unacceptable

### ❌ Option 2: Monorepo with Synchronized Versions

Keep centralized Pigeon but enforce strict version synchronization across all packages.

**Why Rejected:**
- Still violates Pigeon guidelines
- Relies on perfect coordination (easy to break)
- Users can still install mismatched versions via dependency resolution
- Higher maintenance burden

### ✅ Option 1: Per-Platform Pigeon (CHOSEN)

Each platform package contains its own:
- Pigeon definitions (`pigeons/messages.dart`)
- Generated Dart code (`lib/src/pigeon_generated/`)
- Generated native code (Kotlin/Swift/C++)
- Pigeon dev_dependency

```
pro_video_player_android/
  ├── pigeons/messages.dart
  ├── lib/src/pigeon_generated/messages.g.dart
  └── android/.../PigeonMessages.kt

pro_video_player_ios/
  ├── pigeons/messages.dart (same API definitions)
  ├── lib/src/pigeon_generated/messages.g.dart
  └── ios/Classes/PigeonMessages.swift
```

## Advantages of Per-Platform Approach

### ✅ Safety & Stability
- **Follows Pigeon best practices** - No risk of version mismatch crashes
- **Self-contained packages** - Each platform package is fully independent
- **Version isolation** - Pigeon version controlled within each package
- **Production-ready** - Pattern used by official Flutter plugins

### ✅ Flexibility
- Each platform can upgrade Pigeon independently
- No coordination needed for Pigeon updates
- Easier to test changes in isolation
- Clear boundaries for platform-specific needs

### ✅ Maintainability
- Generated code stays close to implementation
- Easier to understand what each package needs
- No cross-package dependencies for Pigeon
- Simpler CI/CD pipeline per package

## Disadvantages & Mitigation

### ⚠️ API Definition Duplication

**Problem:** Same API definitions exist in multiple `pigeons/messages.dart` files

**Mitigation Strategy:**
1. **Master copy** in `pro_video_player_platform_interface/pigeons/` (not compiled, reference only)
2. **Automated sync script** to copy changes to all platform packages
3. **CI validation** to ensure all platform Pigeon files are identical
4. **Documentation** explaining the sync process

### ⚠️ Manual Synchronization Required

**Problem:** Changes must be copied to all platforms

**Mitigation Strategy:**
1. Script: `./scripts/sync-pigeon-definitions.sh` copies from master to all platforms
2. Pre-commit hook validates synchronization
3. CI check fails if platforms are out of sync
4. Clear documentation on workflow

## Implementation Strategy

### Phase 1: Android (First Platform)
1. Copy `pigeons/messages.dart` to `pro_video_player_android/pigeons/`
2. Update `@ConfigurePigeon` to generate only Dart + Kotlin locally
3. Add `pigeon: ^22.7.4` to `pro_video_player_android/pubspec.yaml`
4. Generate code: `dart run pigeon --input pigeons/messages.dart`
5. Implement `ProVideoPlayerHostApi` in Kotlin
6. Export generated Dart code from package

### Phase 2: iOS & macOS
1. Copy `pigeons/messages.dart` to each package
2. Update `@ConfigurePigeon` for Dart + Swift
3. Generate code and implement handlers
4. Share Swift implementation via hard links

### Phase 3: Cleanup
1. Remove Pigeon from `platform_interface`
2. Keep master copy for reference
3. Document sync workflow
4. Add CI validation

### Phase 4: Automation
1. Create sync script
2. Add pre-commit hooks
3. CI validation
4. Documentation

## Sync Workflow

When updating Pigeon API definitions:

```bash
# 1. Edit master copy (reference only)
vim pro_video_player_platform_interface/pigeons/messages.dart

# 2. Sync to all platforms
./scripts/sync-pigeon-definitions.sh

# 3. Regenerate code for each platform
cd pro_video_player_android && dart run pigeon --input pigeons/messages.dart
cd ../pro_video_player_ios && dart run pigeon --input pigeons/messages.dart
cd ../pro_video_player_macos && dart run pigeon --input pigeons/messages.dart
# etc.

# 4. CI automatically validates sync
```

## Comparison with Flutter's video_player

The official Flutter `video_player` plugin uses this **same per-platform approach**:

- `video_player_android` has `pigeon: ^26.1.0` as dev_dependency
- Each platform package has its own `pigeons/` directory
- Generated code stays within package boundaries
- ✅ Follows Pigeon compatibility guidelines

**Sources:**
- [video_player_android pubspec.yaml](https://github.com/flutter/packages/blob/main/packages/video_player/video_player_android/pubspec.yaml)
- [Pigeon documentation](https://pub.dev/packages/pigeon)

## Decision Rationale

While per-platform Pigeon requires API definition duplication, the **safety benefits outweigh the maintenance cost**:

1. **Zero risk of version-mismatch crashes** (Pigeon's #1 concern)
2. **Battle-tested pattern** (used by official Flutter plugins)
3. **Production stability** (critical for a video player library)
4. **Mitigation is straightforward** (sync script + CI validation)

The alternative (centralized Pigeon) violates explicit Pigeon warnings and could cause crashes in production. This risk is unacceptable for a library that will be used in production apps.

## References

- [Pigeon Inter-version Compatibility](https://pub.dev/packages/pigeon#inter-version-compatibility)
- [Flutter packages: video_player structure](https://github.com/flutter/packages/tree/main/packages/video_player)
- [Migrating Flutter Plugins to Pigeon: Lessons Learned](https://invertase.io/blog/migrating-flutter-plugins-to-pigeon-lessons-learned)

---

**Next Steps:**
See `PIGEON_MIGRATION.md` for implementation progress and technical details.
