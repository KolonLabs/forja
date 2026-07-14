# importacion-proyecto-regression.ps1 — Prueba aislada del empaquetado de fuentes libres.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-importacion-proyecto-regression-" + [guid]::NewGuid().ToString("N"))
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    try { & $Action } catch { return }
    throw "ASSERT: $Message"
}

try {
    $fuentes = Join-Path $RunRoot "ideas"
    $segundaFuente = Join-Path $RunRoot "otra-ruta"
    $salida = Join-Path $RunRoot "paquete.md"
    Write-Utf8 -Path (Join-Path $fuentes "nota.md") -Content "Una mujer recibe una carta que no reconoce.`nLa voz es íntima y melancólica."
    Write-Utf8 -Path (Join-Path $fuentes "sub\escaleta.txt") -Content "El hermano oculta la carta.`nEl conflicto escala en una cena familiar."
    Write-Utf8 -Path (Join-Path $fuentes "duplicada.markdown") -Content "Una mujer recibe una carta que no reconoce.`nLa voz es íntima y melancólica."
    Write-Utf8 -Path (Join-Path $fuentes "node_modules\ignorar.md") -Content "Este contenido no puede entrar en el paquete."
    Write-Utf8 -Path (Join-Path $fuentes "referencia.docx") -Content "Formato no admitido."
    Write-Utf8 -Path (Join-Path $segundaFuente "mundo.txt") -Content "La ciudad está vacía cuando llega el amanecer."
    $sourceHash = (Get-FileHash -LiteralPath (Join-Path $fuentes "nota.md") -Algorithm SHA256).Hash

    $resultado = & (Join-Path $RepoRoot "scripts\preparar-importacion-proyecto.ps1") -Fuente @($fuentes, $segundaFuente) -Salida $salida | ConvertFrom-Json
    Assert-True ($resultado.fuentes_canonicas -eq 3) "incluye fuentes canónicas de varias rutas"
    Assert-True ($resultado.duplicados -eq 1) "deduplica por hash"
    Assert-True ($resultado.omitidos -ge 2) "registra directorios y formatos excluidos"
    $paquete = Get-Content -LiteralPath $resultado.paquete -Raw
    Assert-True ($paquete -match "F_001" -and $paquete -match "0001 \| Una mujer recibe una carta" -and $paquete -match "La ciudad está vacía") "conserva evidencia con líneas"
    Assert-True ($paquete -notmatch "Este contenido no puede entrar") "no lee dependencias excluidas"
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $fuentes "nota.md") -Algorithm SHA256).Hash -eq $sourceHash) "no modifica fuentes"
    Assert-True (Test-Path -LiteralPath $resultado.manifiesto) "emite manifiesto separado"
    Assert-Throws { & (Join-Path $RepoRoot "scripts\preparar-importacion-proyecto.ps1") -Fuente @($fuentes, $segundaFuente) -Salida (Join-Path $RunRoot "demasiado-grande.md") -MaxCaracteres 10 | Out-Null } "no trunca fuentes al superar el límite"

    Write-Host "OK: regresión de importación de proyecto superada."
} finally {
    if (Test-Path -LiteralPath $RunRoot) {
        Remove-Item -LiteralPath $RunRoot -Recurse -Force
    }
}
