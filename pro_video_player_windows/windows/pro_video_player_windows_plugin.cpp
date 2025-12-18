#include "pro_video_player_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace pro_video_player_windows {

// static
void ProVideoPlayerWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<ProVideoPlayerWindowsPlugin>();

  // TODO: Register Pigeon API when Windows implementation is complete
  // For now, this is a placeholder plugin with no functionality

  registrar->AddPlugin(std::move(plugin));
}

ProVideoPlayerWindowsPlugin::ProVideoPlayerWindowsPlugin() {}

ProVideoPlayerWindowsPlugin::~ProVideoPlayerWindowsPlugin() {}

}  // namespace pro_video_player_windows
