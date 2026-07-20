$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot 'whitepaper\whitepaper-ejecutivo.html'
$outputPath = Join-Path $repoRoot 'assets\whitepaper-ejecutivo.pdf'
$localCopyPath = Join-Path $repoRoot 'Whitepaper ejecutivo.pdf'
$temporaryPdfPath = Join-Path $env:TEMP "interdato-whitepaper-$PID.pdf"
$browserProfilePath = Join-Path $env:TEMP "interdato-whitepaper-browser-$PID"

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
  throw "El navegador terminó con código $($process.ExitCode) al generar el whitepaper."
}

if (-not (Test-Path -LiteralPath $temporaryPdfPath)) {
  throw 'El PDF no fue generado.'
}

Copy-Item -LiteralPath $temporaryPdfPath -Destination $outputPath -Force
Copy-Item -LiteralPath $temporaryPdfPath -Destination $localCopyPath -Force

Write-Output "Whitepaper generado: $outputPath"
Write-Output "Copia local actualizada: $localCopyPath"
