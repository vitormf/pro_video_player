#ifndef FLUTTER_PLUGIN_PRO_VIDEO_PLAYER_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_PRO_VIDEO_PLAYER_WINDOWS_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace pro_video_player_windows {

class ProVideoPlayerWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ProVideoPlayerWindowsPlugin();

  virtual ~ProVideoPlayerWindowsPlugin();

  // Disallow copy and assign.
  ProVideoPlayerWindowsPlugin(const ProVideoPlayerWindowsPlugin&) = delete;
  ProVideoPlayerWindowsPlugin& operator=(const ProVideoPlayerWindowsPlugin&) = delete;
};

}  // namespace pro_video_player_windows

#endif  // FLUTTER_PLUGIN_PRO_VIDEO_PLAYER_WINDOWS_PLUGIN_H_
