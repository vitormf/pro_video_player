#include "pro_video_player_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>

#define PRO_VIDEO_PLAYER_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), pro_video_player_linux_plugin_get_type(), \
                               ProVideoPlayerLinuxPlugin))

struct _ProVideoPlayerLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(ProVideoPlayerLinuxPlugin, pro_video_player_linux_plugin, g_object_get_type())

static void pro_video_player_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(pro_video_player_linux_plugin_parent_class)->dispose(object);
}

static void pro_video_player_linux_plugin_class_init(ProVideoPlayerLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = pro_video_player_linux_plugin_dispose;
}

static void pro_video_player_linux_plugin_init(ProVideoPlayerLinuxPlugin* self) {}

void pro_video_player_linux_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  ProVideoPlayerLinuxPlugin* plugin = PRO_VIDEO_PLAYER_LINUX_PLUGIN(
      g_object_new(pro_video_player_linux_plugin_get_type(), nullptr));

  // TODO: Register Pigeon API when Linux implementation is complete
  // For now, this is a placeholder plugin with no functionality

  g_object_unref(plugin);
}
