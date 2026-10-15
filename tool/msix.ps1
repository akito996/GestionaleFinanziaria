# Pacchetto MSIX per il Microsoft Store (ADR-017), con lo strumento ufficiale
# di Microsoft (makeappx, nel Windows SDK). Il pacchetto non è firmato:
# lo firma Microsoft quando lo pubblica nello Store.
#
# Senza i dati dello Store si usa un'identità di prova: il pacchetto serve
# solo a controllare che si costruisca (non si può caricare nello Store).
param(
  # Cartella della build di Windows (Release).
  [Parameter(Mandatory)] [string] $Build,
  # File .msix da creare.
  [Parameter(Mandatory)] [string] $Uscita,
  # Quattro numeri, l'ultimo 0 (regola dello Store), es. 0.1.37.0.
  [Parameter(Mandatory)] [string] $Versione,
  [string] $Nome = 'GestionaleFinanziaria.Prova',
  [string] $Editore = 'CN=GestionaleFinanziaria-Prova',
  [string] $NomeEditore = 'GestionaleFinanziaria (prova)'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if ($Versione -notmatch '^\d{1,5}\.\d{1,5}\.\d{1,5}\.0$') {
  throw "Versione non valida per lo Store: $Versione"
}
$radice = Split-Path $PSScriptRoot -Parent
$layout = Join-Path ([IO.Path]::GetTempPath()) "msix-$([guid]::NewGuid())"
Copy-Item -Path $Build -Destination $layout -Recurse
$cartellaLoghi = Join-Path $layout 'Assets'
New-Item -ItemType Directory -Path $cartellaLoghi | Out-Null

# Loghi dall'icona dell'app, centrati su fondo trasparente.
$icona = New-Object System.Drawing.Icon(
  (Join-Path $radice 'windows/runner/resources/app_icon.ico'), 256, 256)
$sorgente = $icona.ToBitmap()
function Scrivi-Logo([string] $nome, [int] $larghezza, [int] $altezza) {
  $immagine = New-Object System.Drawing.Bitmap($larghezza, $altezza)
  $grafica = [System.Drawing.Graphics]::FromImage($immagine)
  $grafica.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $grafica.Clear([System.Drawing.Color]::Transparent)
  $lato = [int]([Math]::Min($larghezza, $altezza) * 0.8)
  $x = [int](($larghezza - $lato) / 2)
  $y = [int](($altezza - $lato) / 2)
  $grafica.DrawImage($sorgente, $x, $y, $lato, $lato)
  $immagine.Save((Join-Path $cartellaLoghi $nome), [System.Drawing.Imaging.ImageFormat]::Png)
  $grafica.Dispose()
  $immagine.Dispose()
}
Scrivi-Logo 'Square44x44Logo.png' 44 44
Scrivi-Logo 'Square150x150Logo.png' 150 150
Scrivi-Logo 'Wide310x150Logo.png' 310 150
Scrivi-Logo 'StoreLogo.png' 50 50

# Manifesto con i dati dello Store (testo XML protetto).
$valori = @{
  '{{NOME}}' = $Nome
  '{{EDITORE}}' = $Editore
  '{{NOME_EDITORE}}' = $NomeEditore
  '{{VERSIONE}}' = $Versione
}
$manifesto = Get-Content (Join-Path $radice 'windows/msix/AppxManifest.xml') -Raw
foreach ($voce in $valori.GetEnumerator()) {
  $manifesto = $manifesto.Replace($voce.Key, [Security.SecurityElement]::Escape($voce.Value))
}
Set-Content -Path (Join-Path $layout 'AppxManifest.xml') -Value $manifesto -Encoding utf8

$makeappx = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\makeappx.exe' |
  Sort-Object FullName | Select-Object -Last 1
if (-not $makeappx) {
  throw 'makeappx non trovato: serve il Windows SDK.'
}
& $makeappx.FullName pack /d $layout /p $Uscita /o
if ($LASTEXITCODE -ne 0) {
  throw "makeappx ha restituito $LASTEXITCODE"
}
Remove-Item -Recurse -Force $layout
Write-Output "Pacchetto: $Uscita ($Versione, $Nome)"
