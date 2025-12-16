#include "pro_video_player_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define PRO_VIDEO_PLAYER_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), pro_video_player_linux_plugin_get_type(), \
                               ProVideoPlayerLinuxPlugin))

struct _ProVideoPlayerLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(ProVideoPlayerLinuxPlugin, pro_video_player_linux_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void pro_video_player_linux_plugin_handle_method_call(
    ProVideoPlayerLinuxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "create") == 0) {
    // TODO: Implement video player creation with GStreamer
    response = FL_METHOD_RESPONSE(fl_method_error_response_new("UNIMPLEMENTED",
                                                                "Native Linux implementation needed",
                                                                nullptr));
  } else if (strcmp(method, "dispose") == 0) {
    // TODO: Implement player disposal
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "play") == 0) {
    // TODO: Implement play
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "pause") == 0) {
    // TODO: Implement pause
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "stop") == 0) {
    // TODO: Implement stop
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "seekTo") == 0) {
    // TODO: Implement seekTo
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "setPlaybackSpeed") == 0) {
    // TODO: Implement setPlaybackSpeed
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "setVolume") == 0) {
    // TODO: Implement setVolume
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "setLooping") == 0) {
    // TODO: Implement setLooping
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "getPosition") == 0) {
    // TODO: Implement getPosition
    g_autoptr(FlValue) result = fl_value_new_int(0);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "getDuration") == 0) {
    // TODO: Implement getDuration
    g_autoptr(FlValue) result = fl_value_new_int(0);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "enterFullscreen") == 0) {
    // TODO: Implement fullscreen
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "exitFullscreen") == 0) {
    // TODO: Implement exit fullscreen
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void pro_video_player_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(pro_video_player_linux_plugin_parent_class)->dispose(object);
}

static void pro_video_player_linux_plugin_class_init(ProVideoPlayerLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = pro_video_player_linux_plugin_dispose;
}

static void pro_video_player_linux_plugin_init(ProVideoPlayerLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                            gpointer user_data) {
  ProVideoPlayerLinuxPlugin* plugin = PRO_VIDEO_PLAYER_LINUX_PLUGIN(user_data);
  pro_video_player_linux_plugin_handle_method_call(plugin, method_call);
}

void pro_video_player_linux_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  ProVideoPlayerLinuxPlugin* plugin = PRO_VIDEO_PLAYER_LINUX_PLUGIN(
      g_object_new(pro_video_player_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "dev.pro_video_player.linux/methods",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                              g_object_ref(plugin),
                                              g_object_unref);

  g_object_unref(plugin);
}
