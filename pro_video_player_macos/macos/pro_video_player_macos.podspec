Pod::Spec.new do |s|
  s.name = 'pro_video_player_macos'
  s.version          = '0.0.1'
  s.summary          = 'macOS implementation of pro_video_player.'
  s.description      = <<-DESC
macOS implementation of the pro_video_player plugin.
                       DESC
  s.homepage         = 'https://github.com/user/pro_video_player'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'

  # Automatically create symlinks to shared Swift sources before build
  # This eliminates the need for manual setup while maintaining code sharing
  s.prepare_command = <<-CMD
    mkdir -p Classes/Shared
    SHARED_DIR="$(cd ../../shared_apple_sources && pwd)"
    for file in "$SHARED_DIR"/*.swift; do
      if [ -f "$file" ]; then
        filename=$(basename "$file")
        ln -sf "$file" "Classes/Shared/$filename"
      fi
    done
  CMD

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.12'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
