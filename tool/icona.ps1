# Icona dell'app, scelta dell'utente "5A": portafoglio con barre che salgono,
# nei tre blu della prima versione di prova. Disegnata da geometria (unità
# 512, come la bozza), così Android, Windows e Store nascono da un solo
# sorgente. Rigenerare con: pwsh tool/icona.ps1
param(
  # Cartella in più dove salvare un'anteprima da 1024 px (facoltativa).
  [string] $Anteprima
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$radice = Split-Path $PSScriptRoot -Parent

function Colore([string] $esadecimale) {
  [System.Drawing.ColorTranslator]::FromHtml($esadecimale)
}
$chiaro = Colore '#54C5F8'
$medio = Colore '#29B6F6'
$scuro = Colore '#01579B'
$bordo = Colore '#D6E4EF'
$bianco = [System.Drawing.Color]::White

function Arrotondato([float] $x, [float] $y, [float] $l, [float] $a, [float] $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = 2 * $r
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $l - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $l - $d, $y + $a - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $a - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  $p
}

function Riempi($g, [System.Drawing.Color] $colore, $forma) {
  $pennello = New-Object System.Drawing.SolidBrush($colore)
  $g.FillPath($pennello, $forma)
  $pennello.Dispose()
}

function Cerchio([float] $cx, [float] $cy, [float] $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddEllipse($cx - $r, $cy - $r, 2 * $r, 2 * $r)
  $p
}

# Il portafoglio (unità 512, già centrato: bozza 5A spostata di 24 in alto).
# [monocromatica]: sagoma piena con barre e chiusura "bucate" (icona a tema
# di Android 13+).
function Portafoglio($g, [bool] $monocromatica) {
  $carta = Arrotondato 130 126 220 80 16
  $corpo = Arrotondato 96 176 300 210 40
  $linguetta = Arrotondato 300 238 120 86 24
  $buchi = @(
    (Cerchio 340 281 14),
    (Arrotondato 136 316 36 40 8),
    (Arrotondato 186 282 36 74 8),
    (Arrotondato 236 244 36 112 8)
  )
  if ($monocromatica) {
    Riempi $g $scuro $carta
    Riempi $g $scuro $corpo
    Riempi $g $scuro $linguetta
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    foreach ($b in $buchi) { Riempi $g ([System.Drawing.Color]::Transparent) $b }
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
  } else {
    Riempi $g $chiaro $carta
    Riempi $g $scuro $corpo
    Riempi $g $medio $linguetta
    foreach ($b in $buchi) { Riempi $g $bianco $b }
  }
}

function Nuova([int] $lato) {
  $immagine = New-Object System.Drawing.Bitmap($lato, $lato,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($immagine)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)
  @{ Immagine = $immagine; Grafica = $g }
}

function Salva($tela, [string] $percorso) {
  New-Item -ItemType Directory -Force -Path (Split-Path $percorso) | Out-Null
  $tela.Grafica.Dispose()
  $tela.Immagine.Save($percorso, [System.Drawing.Imaging.ImageFormat]::Png)
  $tela.Immagine.Dispose()
}

# Icona completa: quadrato bianco arrotondato con il portafoglio.
function Completa([int] $lato) {
  $tela = Nuova $lato
  $g = $tela.Grafica
  $g.ScaleTransform($lato / 512, $lato / 512)
  $fondo = Arrotondato 4 4 504 504 112
  Riempi $g $bianco $fondo
  if ($lato -ge 64) {
    $penna = New-Object System.Drawing.Pen($bordo, 6)
    $g.DrawPath($penna, $fondo)
    $penna.Dispose()
  }
  Portafoglio $g $false
  $tela
}

# Livello in primo piano dell'icona adattiva di Android (tela da 108 dp):
# il disegno sta nel cerchio sicuro da 66 dp, qualunque forma usi il telefono.
function PrimoPiano([int] $lato, [bool] $monocromatica) {
  $tela = Nuova $lato
  $g = $tela.Grafica
  $raggioSicuro = $lato * 33 / 108 * 0.92
  $scala = $raggioSicuro / 207.5   # metà diagonale del portafoglio (unità 512)
  $g.TranslateTransform($lato / 2, $lato / 2)
  $g.ScaleTransform($scala, $scala)
  $g.TranslateTransform(-258, -256)
  Portafoglio $g $monocromatica
  $tela
}

# Android: icona classica (fino ad Android 7.1) e adattiva (da Android 8).
$res = Join-Path $radice 'android/app/src/main/res'
$densita = [ordered]@{ mdpi = 1; hdpi = 1.5; xhdpi = 2; xxhdpi = 3; xxxhdpi = 4 }
foreach ($voce in $densita.GetEnumerator()) {
  $cartella = Join-Path $res "mipmap-$($voce.Key)"
  Salva (Completa ([int](48 * $voce.Value))) (Join-Path $cartella 'ic_launcher.png')
  $adattiva = [int](108 * $voce.Value)
  Salva (PrimoPiano $adattiva $false) (Join-Path $cartella 'ic_launcher_foreground.png')
  Salva (PrimoPiano $adattiva $true) (Join-Path $cartella 'ic_launcher_monochrome.png')
}

# Windows: .ico con più misure (immagini PNG dentro l'icona).
$misure = 16, 20, 24, 32, 40, 48, 64, 128, 256
$immagini = foreach ($m in $misure) {
  $tela = Completa $m
  $flusso = New-Object System.IO.MemoryStream
  $tela.Grafica.Dispose()
  $tela.Immagine.Save($flusso, [System.Drawing.Imaging.ImageFormat]::Png)
  $tela.Immagine.Dispose()
  , $flusso.ToArray()
}
$ico = New-Object System.IO.MemoryStream
$scrittore = New-Object System.IO.BinaryWriter($ico)
$scrittore.Write([UInt16]0)
$scrittore.Write([UInt16]1)
$scrittore.Write([UInt16]$misure.Count)
$posizione = 6 + 16 * $misure.Count
for ($i = 0; $i -lt $misure.Count; $i++) {
  $lato = if ($misure[$i] -ge 256) { 0 } else { $misure[$i] }
  $scrittore.Write([byte]$lato)
  $scrittore.Write([byte]$lato)
  $scrittore.Write([byte]0)
  $scrittore.Write([byte]0)
  $scrittore.Write([UInt16]1)
  $scrittore.Write([UInt16]32)
  $scrittore.Write([UInt32]$immagini[$i].Length)
  $scrittore.Write([UInt32]$posizione)
  $posizione += $immagini[$i].Length
}
foreach ($dati in $immagini) { $scrittore.Write($dati) }
$scrittore.Flush()
[System.IO.File]::WriteAllBytes(
  (Join-Path $radice 'windows/runner/resources/app_icon.ico'), $ico.ToArray())
$scrittore.Dispose()

# Microsoft Store: sorgente dei loghi del pacchetto e logo della scheda.
Salva (Completa 1024) (Join-Path $radice 'windows/msix/icona.png')

if ($Anteprima) {
  Salva (Completa 1024) (Join-Path $Anteprima 'icona-1024.png')
  Salva (PrimoPiano 432 $false) (Join-Path $Anteprima 'icona-adattiva.png')
  Salva (PrimoPiano 432 $true) (Join-Path $Anteprima 'icona-monocromatica.png')
}
Write-Output 'Icona rigenerata: Android, Windows (.ico) e Store.'
