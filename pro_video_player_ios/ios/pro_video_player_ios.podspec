Pod::Spec.new do |s|
  s.name = 'pro_video_player_ios'
  s.version          = '0.0.1'
  s.summary          = 'iOS implementation of pro_video_player.'
  s.description      = <<-DESC
iOS implementation of pro_video_player, using AVPlayer for native video playback.
                       DESC
  s.homepage         = 'https://github.com/user/pro_video_player'
  s.license          = { :type => 'MIT' }
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

  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version       = '5.0'
end
