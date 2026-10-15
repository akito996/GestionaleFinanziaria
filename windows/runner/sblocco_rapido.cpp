#include "sblocco_rapido.h"

#include <windows.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Security.Credentials.h>
#include <winrt/Windows.Security.Cryptography.h>
#include <winrt/Windows.Storage.Streams.h>

namespace sblocco_rapido {
namespace {

using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Security::Credentials::KeyCredentialCreationOption;
using winrt::Windows::Security::Credentials::KeyCredentialManager;
using winrt::Windows::Security::Credentials::KeyCredentialStatus;
using winrt::Windows::Security::Cryptography::CryptographicBuffer;

constexpr wchar_t kNome[] =
    L"io.github.akito996.GestionaleFinanziaria.sblocco_rapido";

// Le attese (.get()) non sono ammesse sul thread dell'interfaccia: ogni
// chiamata lavora sul suo thread, in un apartment MTA.
class Apartment {
 public:
  Apartment() { winrt::init_apartment(winrt::apartment_type::multi_threaded); }
  ~Apartment() { winrt::uninit_apartment(); }
  Apartment(const Apartment&) = delete;
  Apartment& operator=(const Apartment&) = delete;
};

// La finestra di Windows Hello a volte si apre dietro l'app: la si porta
// davanti appena compare.
template <typename Operazione>
auto Attendi(Operazione const& operazione) {
  bool davanti = false;
  while (operazione.Status() == AsyncStatus::Started) {
    if (!davanti) {
      HWND dialogo = FindWindowW(L"Credential Dialog Xaml Host", nullptr);
      if (dialogo != nullptr) {
        SetForegroundWindow(dialogo);
        davanti = true;
      }
    }
    Sleep(50);
  }
  return operazione.GetResults();
}

Esito Errore(KeyCredentialStatus stato) {
  Esito esito;
  switch (stato) {
    case KeyCredentialStatus::UserCanceled:
    case KeyCredentialStatus::UserPrefersPassword:
      esito.errore = "annullato";
      break;
    case KeyCredentialStatus::NotFound:
      esito.errore = "invalidata";
      break;
    case KeyCredentialStatus::SecurityDeviceLocked:
      esito.errore = "bloccato";
      break;
    default:
      esito.errore = "errore";
      esito.messaggio =
          "Windows Hello: stato " + std::to_string(static_cast<int>(stato));
      break;
  }
  return esito;
}

}  // namespace

std::string Disponibilita() {
  try {
    Apartment apartment;
    return KeyCredentialManager::IsSupportedAsync().get() ? "pronta"
                                                          : "nessunMetodo";
  } catch (...) {
    return "nonSupportata";
  }
}

Esito Firma(const std::vector<uint8_t>& sfida, bool crea) {
  try {
    Apartment apartment;
    auto apertura =
        crea ? Attendi(KeyCredentialManager::RequestCreateAsync(
                   kNome, KeyCredentialCreationOption::ReplaceExisting))
             : KeyCredentialManager::OpenAsync(kNome).get();
    if (apertura.Status() != KeyCredentialStatus::Success) {
      return Errore(apertura.Status());
    }
    auto dati = CryptographicBuffer::CreateFromByteArray(sfida);
    auto firmato = Attendi(apertura.Credential().RequestSignAsync(dati));
    if (firmato.Status() != KeyCredentialStatus::Success) {
      return Errore(firmato.Status());
    }
    winrt::com_array<uint8_t> byte;
    CryptographicBuffer::CopyToByteArray(firmato.Result(), byte);
    Esito esito;
    esito.firma.assign(byte.begin(), byte.end());
    return esito;
  } catch (winrt::hresult_error const& e) {
    Esito esito;
    esito.errore = "errore";
    esito.messaggio = winrt::to_string(e.message());
    return esito;
  }
}

void Cancella() {
  try {
    Apartment apartment;
    KeyCredentialManager::DeleteAsync(kNome).get();
  } catch (...) {
    // Nessuna chiave da cancellare.
  }
}

}  // namespace sblocco_rapido
