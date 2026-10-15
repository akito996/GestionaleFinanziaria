#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <thread>

#include "flutter/generated_plugin_registrant.h"
#include "sblocco_rapido.h"

namespace {

// Le risposte a Flutter partono dal thread della finestra: i lavori finiti
// sugli altri thread aspettano qui e arrivano con questo messaggio.
constexpr UINT kLavoroPronto = WM_APP + 1;
std::mutex lavori_mutex;
std::deque<std::function<void()>> lavori;

void SulThreadDellaFinestra(HWND finestra, std::function<void()> lavoro) {
  {
    std::lock_guard<std::mutex> blocco(lavori_mutex);
    lavori.push_back(std::move(lavoro));
  }
  PostMessage(finestra, kLavoroPronto, 0, 0);
}

void EseguiLavoriPronti() {
  std::deque<std::function<void()>> pronti;
  {
    std::lock_guard<std::mutex> blocco(lavori_mutex);
    pronti.swap(lavori);
  }
  for (auto& lavoro : pronti) {
    lavoro();
  }
}

std::vector<uint8_t> Byte(const flutter::EncodableValue* argomenti,
                          const char* nome) {
  const auto* mappa = std::get_if<flutter::EncodableMap>(argomenti);
  if (mappa == nullptr) {
    return {};
  }
  auto voce = mappa->find(flutter::EncodableValue(nome));
  if (voce == mappa->end()) {
    return {};
  }
  const auto* byte = std::get_if<std::vector<uint8_t>>(&voce->second);
  return byte == nullptr ? std::vector<uint8_t>() : *byte;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  sblocco_rapido_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "gestionale/sblocco_rapido",
          &flutter::StandardMethodCodec::GetInstance());
  sblocco_rapido_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& chiamata,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 risultato) {
        GestisciSbloccoRapido(chiamata, std::move(risultato));
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  sblocco_rapido_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

// Windows Hello: ogni richiesta lavora su un thread suo (le finestre di
// verifica aspettano l'utente) e risponde dal thread della finestra.
void FlutterWindow::GestisciSbloccoRapido(
    const flutter::MethodCall<flutter::EncodableValue>& chiamata,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
        risultato) {
  const std::string metodo = chiamata.method_name();
  if (metodo != "disponibilita" && metodo != "attiva" && metodo != "leggi" &&
      metodo != "disattiva") {
    risultato->NotImplemented();
    return;
  }
  std::vector<uint8_t> sfida = Byte(chiamata.arguments(), "sfida");
  std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> risposta(
      std::move(risultato));
  HWND finestra = GetHandle();
  std::thread([metodo, sfida, risposta, finestra]() {
    std::function<void()> fine;
    if (metodo == "disponibilita") {
      std::string stato = sblocco_rapido::Disponibilita();
      fine = [risposta, stato]() {
        risposta->Success(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("stato"), flutter::EncodableValue(stato)},
            {flutter::EncodableValue("pin"), flutter::EncodableValue(true)},
        }));
      };
    } else if (metodo == "disattiva") {
      sblocco_rapido::Cancella();
      fine = [risposta]() { risposta->Success(); };
    } else {
      sblocco_rapido::Esito esito =
          sblocco_rapido::Firma(sfida, metodo == "attiva");
      fine = [risposta, esito]() {
        if (!esito.errore.empty()) {
          risposta->Error(esito.errore, esito.messaggio);
          return;
        }
        risposta->Success(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("materiale"),
             flutter::EncodableValue(esito.firma)},
            {flutter::EncodableValue("dati"),
             flutter::EncodableValue(std::vector<uint8_t>())},
        }));
      };
    }
    SulThreadDellaFinestra(finestra, std::move(fine));
  }).detach();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == kLavoroPronto) {
    EseguiLavoriPronti();
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
