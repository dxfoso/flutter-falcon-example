//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_falcon_linux_flatpak/flutter_falcon_linux_flatpak_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_falcon_linux_flatpak_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterFalconLinuxFlatpakPlugin");
  flutter_falcon_linux_flatpak_plugin_register_with_registrar(flutter_falcon_linux_flatpak_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
}
