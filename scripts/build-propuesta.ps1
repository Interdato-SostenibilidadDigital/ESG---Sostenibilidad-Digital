$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot 'propuesta\propuesta-sostenibilidad-digital.html'
$outputPath = Join-Path $repoRoot 'assets\propuesta-sostenibilidad-digital.pdf'
$temporaryPdfPath = Join-Path $env:TEMP "interdato-propuesta-$PID.pdf"
$browserProfilePath = Join-Path $env:TEMP "interdato-propuesta-browser-$PID"

$browserCandidates = @(
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
)

$browser = $browserCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $browser) {
  throw 'No se encontró Microsoft Edge o Google Chrome para generar el PDF.'
}

$source = Get-Item -LiteralPath $sourcePath
$sourceUri = [System.Uri]::new($source.FullName).AbsoluteUri

$arguments = @(
  '--headless=new',
  '--disable-gpu',
  '--no-pdf-header-footer',
  '--print-to-pdf-no-header',
  "--user-data-dir=`"$browserProfilePath`"",
  "--print-to-pdf=`"$temporaryPdfPath`"",
  "`"$sourceUri`""
)

$process = Start-Process `
  -FilePath $browser `
  -ArgumentList $arguments `
  -Wait `
  -PassThru `
  -WindowStyle Hidden

if ($process.ExitCode -ne 0) {
  throw "El navegador terminó con código $($process.ExitCode) al generar la propuesta."
}

if (-not (Test-Path -LiteralPath $temporaryPdfPath)) {
  throw 'El PDF no fue generado.'
}

Copy-Item -LiteralPath $temporaryPdfPath -Destination $outputPath -Force

Remove-Item -LiteralPath $temporaryPdfPath -Force
if (Test-Path -LiteralPath $browserProfilePath) {
  Remove-Item -LiteralPath $browserProfilePath -Recurse -Force
}

Write-Output "Propuesta generada: $outputPath"
