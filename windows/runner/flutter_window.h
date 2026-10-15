#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Sblocco con Windows Hello (canale "gestionale/sblocco_rapido").
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      sblocco_rapido_;
  void GestisciSbloccoRapido(
      const flutter::MethodCall<flutter::EncodableValue>& chiamata,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
          risultato);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
