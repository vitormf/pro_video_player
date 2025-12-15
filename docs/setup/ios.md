# iOS Setup

This guide covers iOS-specific configuration required for pro_video_player features.

## Basic Setup

No additional configuration required for basic video playback.

## Feature-Specific Configuration

### Background Playback

To enable background audio playback, add to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

Or in Xcode: Target > Signing & Capabilities > + Capability > Background Modes > Audio, AirPlay, and Picture in Picture

### Picture-in-Picture

PiP requires iOS 14.0+ and specific entitlements:

1. **Info.plist** - Add background mode:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
   </array>
   ```

2. **Xcode Capability** - Enable "Picture in Picture" under Background Modes

3. **Minimum Deployment Target** - iOS 14.0 or higher in your Podfile:
   ```ruby
   platform :ios, '14.0'
   ```

## Podfile Configuration

### Minimum iOS Version

```ruby
platform :ios, '12.0'  # Minimum supported
# platform :ios, '14.0'  # Required for PiP
```

### Post-Install Hook

If you encounter build issues, add to your Podfile:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

## Troubleshooting

See [Troubleshooting Guide](../troubleshooting.md#ios) for common iOS issues.
