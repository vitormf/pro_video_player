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
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.12'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
