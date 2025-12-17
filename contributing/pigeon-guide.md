# Pigeon Platform Channel Code Generation

This project uses [Pigeon](https://pub.dev/packages/pigeon) for type-safe platform channel communication between Dart and native code (Kotlin, Swift, C++).

## Critical Requirements

### Inter-Version Compatibility

**CRITICAL:** Pigeon-generated message channel code is an internal implementation detail that can change without warning. To prevent crashes:

1. **Same Pigeon Version Required**: Both Dart and host-language code MUST be generated with the **same version** of Pigeon. Mismatched versions cause undefined behavior and crashes.

2. **Do NOT Split Across Packages**: Pigeon-generated code must remain unified. According to Pigeon documentation:
   > "Pigeon-generated code should **NOT** be split across packages (such as one package for the Dart code and another for the host language code). That arrangement is very likely to cause crashes for some plugin clients after updates."

3. **Version Synchronization**: When updating Pigeon:
   - Update the Pigeon version in ALL platform packages simultaneously
   - Regenerate ALL Pigeon code (Dart + Kotlin + Swift + C++) in one operation
   - Never publish packages with mismatched Pigeon-generated code

### Current Architecture

This project maintains Pigeon source files in each platform package but ensures consistency through:

1. **Identical Source Files**: All `pigeons/messages.dart` files are kept identical across:
   - `pro_video_player_android/pigeons/messages.dart`
   - `pro_video_player_ios/pigeons/messages.dart`
   - `pro_video_player_macos/pigeons/messages.dart`

2. **Consistent Package Names**: All configurations specify:
   ```dart
   dartPackageName: 'pro_video_player_platform_interface'
   ```
   This ensures all platforms generate channel names with the same prefix, enabling communication.

3. **Coordinated Generation**: The `make pigeon-generate` command regenerates ALL platforms together.

## Configuration Files

### Full Configuration (Android/iOS)

Used by Android and iOS packages to generate code for ALL platforms:

```dart
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon_generated/messages.g.dart',
    dartTestOut: 'test/pigeon_generated/test_messages.g.dart',
    dartPackageName: 'pro_video_player_platform_interface',  // CRITICAL: Must match across all platforms
    kotlinOut: '../pro_video_player_android/android/src/main/kotlin/dev/pro_video_player/pro_video_player_android/PigeonMessages.kt',
    kotlinOptions: KotlinOptions(package: 'dev.pro_video_player.pro_video_player_android'),
    swiftOut: '../pro_video_player_ios/ios/Classes/PigeonMessages.swift',
    cppOptions: CppOptions(namespace: 'pro_video_player'),
    cppHeaderOut: '../pro_video_player_windows/windows/pigeon_messages.h',
    cppSourceOut: '../pro_video_player_windows/windows/pigeon_messages.cpp',
    copyrightHeader: 'pigeons/copyright_header.txt',
  ),
)
```

### Single-Language Configuration (macOS)

Used by macOS package to generate only Swift code:

```dart
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'pro_video_player_platform_interface',  // CRITICAL: Must match across all platforms
    swiftOut: 'macos/Classes/PigeonMessages.swift',
    copyrightHeader: 'pigeons/copyright_header.txt',
    oneLanguage: true,
  ),
)
```

## Regenerating Pigeon Code

**IMPORTANT:** Always regenerate from the project root using the Makefile:

```bash
cd /path/to/pro_video_player
make pigeon-generate
```

This command:
1. Verifies development tools are installed
2. Regenerates Pigeon code for Android, iOS, and macOS
3. Ensures all platforms use the same Pigeon version
4. Maintains consistent channel names across platforms

**Never** run `dart run pigeon` manually in individual packages - this can create version mismatches.

## Modifying Pigeon Definitions

When changing platform channel APIs:

1. **Edit the Source**: Modify ONE of the `pigeons/messages.dart` files (preferably Android or iOS)
2. **Sync to Other Platforms**: Copy the changes to the other platform packages' `pigeons/messages.dart` files
3. **Regenerate Everything**: Run `make pigeon-generate` from project root
4. **Verify Consistency**: Check that channel names match:
   ```bash
   # Should all show the same channel prefix
   grep "ProVideoPlayerHostApi.create" pro_video_player_ios/ios/Classes/PigeonMessages.swift
   grep "ProVideoPlayerHostApi.create" pro_video_player_platform_interface/lib/src/pigeon_generated/messages.g.dart
   ```

## Channel Name Format

With `dartPackageName: 'pro_video_player_platform_interface'`, channels follow this pattern:

```
dev.flutter.pigeon.pro_video_player_platform_interface.ProVideoPlayerHostApi.{methodName}
```

Example channel names:
- `dev.flutter.pigeon.pro_video_player_platform_interface.ProVideoPlayerHostApi.create`
- `dev.flutter.pigeon.pro_video_player_platform_interface.ProVideoPlayerHostApi.play`
- `dev.flutter.pigeon.pro_video_player_platform_interface.ProVideoPlayerHostApi.pause`

## Troubleshooting

### "Unable to establish connection on channel" Error

**Symptoms**: Platform channel fails with error like:
```
PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.pro_video_player_platform_interface.ProVideoPlayerHostApi.create"., null, null)
```

**Causes**:
1. Channel name mismatch between Dart and native code
2. Pigeon code generated with different `dartPackageName` values
3. Pigeon code not regenerated after configuration changes
4. Platform package not properly linked in example app

**Solutions**:
1. Verify all `pigeons/messages.dart` files have identical `dartPackageName`
2. Regenerate all Pigeon code: `make pigeon-generate`
3. Clean and rebuild: `cd example-showcase && flutter clean && flutter pub get`
4. Check channel names match (see "Verify Consistency" above)

### Pigeon Version Mismatch

**Symptoms**: Crashes, undefined behavior, serialization errors

**Solutions**:
1. Check Pigeon version in all `pubspec.yaml` files under `dev_dependencies`
2. Ensure all platform packages use the same version
3. Run `make pigeon-generate` to regenerate with consistent version
4. Never mix Pigeon-generated code from different Pigeon versions

## References

- [Pigeon Documentation](https://pub.dev/packages/pigeon)
- [Pigeon Inter-Version Compatibility](https://pub.dev/packages/pigeon#inter-version-compatibility)
- [PigeonOptions API](https://pub.dev/documentation/pigeon/latest/pigeon/PigeonOptions-class.html)
