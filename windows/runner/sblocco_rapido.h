#ifndef RUNNER_SBLOCCO_RAPIDO_H_
#define RUNNER_SBLOCCO_RAPIDO_H_

#include <cstdint>
#include <string>
#include <vector>

// Sblocco con Windows Hello (ADR-016). La chiave privata resta nel chip di
// sicurezza del PC (TPM) o nel provider di Windows e firma la "sfida" solo
// dopo PIN, viso o impronta: la firma (sempre uguale per la stessa sfida)
// diventa, nell'app, la chiave che apre l'archivio.
//
// Tutte le funzioni sono bloccanti: vanno chiamate fuori dal thread
// dell'interfaccia.
namespace sblocco_rapido {

// "pronta", "nessunMetodo" (Windows Hello non configurato) o "nonSupportata".
std::string Disponibilita();

struct Esito {
  std::vector<uint8_t> firma;
  // Vuoto se riuscito, altrimenti "annullato", "invalidata", "bloccato" o
  // "errore" (con il dettaglio in [messaggio]).
  std::string errore;
  std::string messaggio;
};

// Firma [sfida] con la chiave di Windows Hello. [crea]: prima crea una chiave
// nuova, al posto di quella vecchia.
Esito Firma(const std::vector<uint8_t>& sfida, bool crea);

// Cancella la chiave (sblocco rapido spento).
void Cancella();

}  // namespace sblocco_rapido

#endif  // RUNNER_SBLOCCO_RAPIDO_H_
