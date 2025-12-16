#include "pro_video_player_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace pro_video_player_windows {

// static
void ProVideoPlayerWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "dev.pro_video_player.windows/methods",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ProVideoPlayerWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ProVideoPlayerWindowsPlugin::ProVideoPlayerWindowsPlugin() {}

ProVideoPlayerWindowsPlugin::~ProVideoPlayerWindowsPlugin() {}

void ProVideoPlayerWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string &method = method_call.method_name();

  if (method.compare("create") == 0) {
    // TODO: Implement video player creation with Media Foundation
    result->Error("UNIMPLEMENTED", "Native Windows implementation needed");
  } else if (method.compare("dispose") == 0) {
    // TODO: Implement player disposal
    result->Success(flutter::EncodableValue());
  } else if (method.compare("play") == 0) {
    // TODO: Implement play
    result->Success(flutter::EncodableValue());
  } else if (method.compare("pause") == 0) {
    // TODO: Implement pause
    result->Success(flutter::EncodableValue());
  } else if (method.compare("stop") == 0) {
    // TODO: Implement stop
    result->Success(flutter::EncodableValue());
  } else if (method.compare("seekTo") == 0) {
    // TODO: Implement seekTo
    result->Success(flutter::EncodableValue());
  } else if (method.compare("setPlaybackSpeed") == 0) {
    // TODO: Implement setPlaybackSpeed
    result->Success(flutter::EncodableValue());
  } else if (method.compare("setVolume") == 0) {
    // TODO: Implement setVolume
    result->Success(flutter::EncodableValue());
  } else if (method.compare("setLooping") == 0) {
    // TODO: Implement setLooping
    result->Success(flutter::EncodableValue());
  } else if (method.compare("getPosition") == 0) {
    // TODO: Implement getPosition
    result->Success(flutter::EncodableValue(0));
  } else if (method.compare("getDuration") == 0) {
    // TODO: Implement getDuration
    result->Success(flutter::EncodableValue(0));
  } else if (method.compare("enterFullscreen") == 0) {
    // TODO: Implement fullscreen
    result->Success(flutter::EncodableValue(false));
  } else if (method.compare("exitFullscreen") == 0) {
    // TODO: Implement exit fullscreen
    result->Success(flutter::EncodableValue());
  } else {
    result->NotImplemented();
  }
}

}  // namespace pro_video_player_windows
