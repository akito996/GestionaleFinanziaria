"""Peso delle build, per la CI: scrive una tabella nel riepilogo
dell'esecuzione (GITHUB_STEP_SUMMARY) e un avviso con il totale.

Uso: python tool/dimensioni.py <cartella build Windows | file .apk> ...
"""
import io
import os
import sys
import zipfile


def mb(n):
    return f'{n / 1048576:.1f} MB'


def cartella(percorso):
    file = []
    for radice, _, nomi in os.walk(percorso):
        for nome in nomi:
            p = os.path.join(radice, nome)
            file.append((os.path.relpath(p, percorso), os.path.getsize(p)))
    totale = sum(d for _, d in file)
    # Quanto pesa da scaricare: zip con la compressione massima (come l'MSI).
    memoria = io.BytesIO()
    with zipfile.ZipFile(memoria, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for nome, _ in file:
            z.write(os.path.join(percorso, nome), nome)
    compresso = memoria.getbuffer().nbytes
    righe = [
        f'### Windows: {mb(compresso)} da scaricare, {mb(totale)} installata',
        '',
        '| File | Peso |',
        '|---|---|',
    ]
    for nome, d in sorted(file, key=lambda x: -x[1]):
        if d >= 100 * 1024:
            righe.append(f'| `{nome}` | {mb(d)} |')
    return righe, f'Windows: {mb(compresso)} da scaricare, {mb(totale)} installata'


def apk(percorso):
    peso = os.path.getsize(percorso)
    nome = os.path.basename(percorso)
    righe = [
        f'### {nome}: {mb(peso)}',
        '',
        '| Contenuto | Nel file | Installato |',
        '|---|---|---|',
    ]
    with zipfile.ZipFile(percorso) as z:
        voci = z.infolist()
        librerie = [v for v in voci if v.filename.endswith('.so')]
        for v in sorted(librerie, key=lambda x: -x.file_size):
            righe.append(
                f'| `{v.filename}` | {mb(v.compress_size)} | {mb(v.file_size)} |'
            )
        resto = [v for v in voci if not v.filename.endswith('.so')]
        righe.append(
            f'| altro (codice Android, risorse) | '
            f'{mb(sum(v.compress_size for v in resto))} | '
            f'{mb(sum(v.file_size for v in resto))} |'
        )
    return righe, f'{nome}: {mb(peso)}'


def main():
    tabelle = ['## Peso delle build', '']
    avvisi = []
    for arg in sys.argv[1:]:
        if os.path.isdir(arg):
            righe, avviso = cartella(arg)
        elif arg.endswith('.apk') and os.path.isfile(arg):
            righe, avviso = apk(arg)
        else:
            continue
        tabelle += righe + ['']
        avvisi.append(avviso)
    testo = '\n'.join(tabelle) + '\n'
    print(testo)
    riepilogo = os.environ.get('GITHUB_STEP_SUMMARY')
    if riepilogo:
        with open(riepilogo, 'a', encoding='utf-8') as f:
            f.write(testo)
    if avvisi:
        print('::notice title=Peso delle build::' + ' · '.join(avvisi))


if __name__ == '__main__':
    main()
