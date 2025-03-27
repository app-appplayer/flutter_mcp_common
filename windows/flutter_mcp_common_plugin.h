#ifndef FLUTTER_PLUGIN_FLUTTER_MCP_COMMON_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_MCP_COMMON_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_mcp_common {

class FlutterMcpCommonPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterMcpCommonPlugin();

  virtual ~FlutterMcpCommonPlugin();

  // Disallow copy and assign.
  FlutterMcpCommonPlugin(const FlutterMcpCommonPlugin&) = delete;
  FlutterMcpCommonPlugin& operator=(const FlutterMcpCommonPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_mcp_common

#endif  // FLUTTER_PLUGIN_FLUTTER_MCP_COMMON_PLUGIN_H_
