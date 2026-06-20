# ============================================================================
# CliniCore — Robot Framework Test Runner
# ============================================================================
# USO:
#   .\run_tests.ps1                          <- todos los tests + todos los reportes
#   .\run_tests.ps1 -Tags smoke              <- solo smoke tests
#   .\run_tests.ps1 -Tags e2e -Informe       <- E2E + abrir reporte al terminar
#   .\run_tests.ps1 -Suite tests/01_auth     <- suite específica
#   .\run_tests.ps1 -Parallel               <- ejecución en paralelo (pabot)
# ============================================================================

param(
    [string]$Suite    = "tests",
    [string]$Tags     = "",
    [switch]$Parallel = $false,
    [switch]$Informe  = $false,
    [string]$Output   = "results"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Write-Step { param($msg) Write-Host "`n  $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  AVS $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "  ERR $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  CliniCore - Robot Framework Test Suite" -ForegroundColor Magenta
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# ── 1. Localizar ejecutables Python ──────────────────────────────────────────
Write-Step "Localizando herramientas..."

$UserScripts = python -c "import site,os; s=site.getusersitepackages(); print(os.path.join(os.path.dirname(s),'Scripts'))"
$RobotMetricsExe = Join-Path $UserScripts "robotmetrics.exe"
$PabotExe        = Join-Path $UserScripts "pabot.exe"

if (-not (Test-Path $RobotMetricsExe)) {
    Write-Warn "robotmetrics.exe no encontrado en $UserScripts"
    Write-Warn "Reinstalando: pip install --user robotframework-metrics"
    python -m pip install -q --user robotframework-metrics
}
Write-OK "Robot Framework listo"
Write-OK "robotmetrics: $RobotMetricsExe"

# ── 2. Preparar carpeta de resultados ────────────────────────────────────────
Write-Step "Preparando carpeta de resultados..."
$ResultDir = Join-Path $PSScriptRoot $Output
if (-not (Test-Path $ResultDir)) { New-Item -ItemType Directory -Path $ResultDir | Out-Null }
Get-ChildItem $ResultDir -Filter "*.xml"  | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem $ResultDir -Filter "*.html" | Remove-Item -Force -ErrorAction SilentlyContinue
Write-OK "Carpeta limpia: $ResultDir"

# ── 3. Construir argumentos de robot ─────────────────────────────────────────
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$RFArgs = @(
    "--outputdir",      $ResultDir,
    "--output",         "output.xml",
    "--report",         "report.html",
    "--log",            "log.html",
    "--loglevel",       "INFO",
    "--reporttitle",    "CliniCore — Reporte de Pruebas",
    "--logtitle",       "CliniCore — Log Detallado",
    "--metadata",       "Proyecto:CliniCore TFM",
    "--metadata",       "Ejecutado:$Timestamp",
    "--metadata",       "Entorno:localhost"
)
if ($Tags) { $RFArgs += "--include"; $RFArgs += $Tags }

# ── 4. Ejecutar tests ─────────────────────────────────────────────────────────
Write-Step "Ejecutando tests$(if ($Tags) { " [tag: $Tags]" })..."
if ($Parallel) {
    Write-Host "     Modo paralelo — pabot 4 procesos" -ForegroundColor Gray
    & $PabotExe --processes 4 @RFArgs $Suite
} else {
    python -m robot @RFArgs $Suite
}
$RFExitCode = $LASTEXITCODE

# ── 5. Generar RobotMetrics Dashboard ────────────────────────────────────────
Write-Step "Generando RobotMetrics Dashboard (graficos y estadisticas)..."
& $RobotMetricsExe `
    -I  $ResultDir `
    -O  "output.xml" `
    -L  "log.html" `
    -skt True `
    -t   True `
    -d   True
if ($LASTEXITCODE -eq 0) {
    Write-OK "Dashboard generado"
} else {
    Write-Warn "robotmetrics tuvo un error (revisa output.xml)"
}

# ── 6. Resumen de archivos generados ─────────────────────────────────────────
Write-Host ""
Write-Host "  REPORTES GENERADOS" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────────────────────────────"

$archivos = @(
    @{ Nombre = "report.html";        Desc = "Resumen ejecutivo con estadisticas y grafico de pass/fail" },
    @{ Nombre = "log.html";           Desc = "Log detallado paso a paso de cada keyword" },
    @{ Nombre = "RobotMetrics.html";  Desc = "Dashboard con graficos de dona, barras y tiempos" },
    @{ Nombre = "output.xml";         Desc = "XML fuente (util para rebot o integracion CI/CD)" }
)
foreach ($a in $archivos) {
    $ruta = Join-Path $ResultDir $a.Nombre
    if (Test-Path $ruta) {
        Write-Host "  [OK] $($a.Nombre)" -ForegroundColor Green
        Write-Host "       $($a.Desc)"
        Write-Host "       $ruta"
    }
}

# ── 7. Abrir reporte en el navegador ─────────────────────────────────────────
if ($Informe) {
    $principal = Join-Path $ResultDir "RobotMetrics.html"
    if (-not (Test-Path $principal)) { $principal = Join-Path $ResultDir "report.html" }
    Write-Step "Abriendo reporte en el navegador..."
    Start-Process $principal
}

Write-Host ""
if ($RFExitCode -eq 0) {
    Write-Host "  RESULTADO: TODOS LOS TESTS PASARON" -ForegroundColor Green
} else {
    Write-Host "  RESULTADO: ALGUNOS TESTS FALLARON (codigo $RFExitCode)" -ForegroundColor Yellow
    Write-Host "  Revisa log.html para ver el detalle de los fallos." -ForegroundColor Yellow
}
Write-Host ""
exit $RFExitCode
