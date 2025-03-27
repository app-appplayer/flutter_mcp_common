#include "include/flutter_mcp_common/flutter_mcp_common_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_mcp_common_plugin.h"

void FlutterMcpCommonPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_mcp_common::FlutterMcpCommonPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
