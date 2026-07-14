# rehidratacion-relato-regression.ps1 — Prueba aislada de extracción de evidencia.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-rehidratacion-regression-" + [guid]::NewGuid().ToString("N"))
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
    $hub = Join-Path $RunRoot "hub"
    $source = Join-Path $hub "workspaces\origen"
    $target = Join-Path $hub "workspaces\origen-reinicio"
    New-Item -ItemType Directory -Force -Path $source | Out-Null

    $legacyConfig = [ordered]@{
        titulo = "Origen legado"
        slug = "origen"
        tipo = "relato"
        escala = "relato"
        estado = "publicado"
        estilo_base = "contemporaneo"
        estilo_secundario = $null
        creado = "2026-01-01T00:00:00"
        ultima_modificacion = "2026-01-02T00:00:00"
        ultimo_hecho_global = "H_0000"
        ultimo_beat_global = "B_0099"
        logline = "Una llamada rompe una rutina aparentemente segura."
        genero = "drama"
        tono = "tenso"
        explicitud = "medio"
        pov = "3ª limitada"
        extension_estimada = "8000"
        protagonistas = @(@{ nombre = "Ana"; deseo = "Entender la llamada"; obstaculo = "El miedo"; arco = "De evitar a decidir" })
        personajes_clave = @("Marcos — la voz desconocida")
        setting = "Madrid actual"
        temas = @("miedo", "decisión")
        restricciones = @("Sin violencia sexual")
        reflexion_agente = @{ fortalezas = @("Un conflicto claro"); riesgos = @("Ritmo irregular"); decisiones_usuario = @("Final abierto") }
    }
    Write-Utf8 -Path (Join-Path $source "config.json") -Content ($legacyConfig | ConvertTo-Json -Depth 12)
    Write-Utf8 -Path (Join-Path $source "BRIEF.md") -Content @'
# Brief — Origen legado

## Premisa

Ana recibe una llamada y debe decidir si abandona su rutina.
'@
    Write-Utf8 -Path (Join-Path $source "_actos.md") -Content @'
# Actos — Origen legado

## Acto I — Deriva

**Objetivo narrativo:** Llevar a Ana fuera de casa.

**Que debe sentir el lector:** Inquietud.

**Tension:** La llamada no admite espera.

### Hechos

- H_99: Ana recibe una llamada y decide esconderla.
'@
    Write-Utf8 -Path (Join-Path $source "_actos_backup_20260714.md") -Content @'
# Actos — Origen legado

## Acto I — La llamada

**Objetivo narrativo:** Romper la rutina de Ana.

**Que debe sentir el lector:** Inquietud.

**Tension:** Ignorar la llamada puede tener consecuencias.

### Hechos

- H_01: Ana recibe una llamada que transforma su mañana.
- H_02 [D · H_01–H_02]: La inquietud crece mientras decide si responder.
'@
    Write-Utf8 -Path (Join-Path $source "relato.md") -Content "# Prosa que no debe heredarse`n"
    $sourceHash = (Get-FileHash -LiteralPath (Join-Path $source "_actos_backup_20260714.md") -Algorithm SHA256).Hash

    $evidencia = & (Join-Path $RepoRoot "scripts\rehidratar-relato.ps1") -Origen "origen" -Destino "origen-reinicio" -Actos backup -ForjaRootOverride $hub | ConvertFrom-Json

    Assert-True ($evidencia.esquema -eq "rehidratacion-relato-evidencia-v2") "devuelve el esquema de evidencia vigente"
    Assert-True ($evidencia.origen -eq "origen" -and $evidencia.destino_sugerido -eq "origen-reinicio") "identifica origen y destino sugerido"
    Assert-True ($evidencia.semilla.premisa -match "abandona su rutina") "recupera la premisa como evidencia"
    $hechos = @($evidencia.semilla.actos[0].hechos)
    Assert-True ($hechos.Count -eq 2 -and $hechos[0] -match "Ana recibe" -and $hechos[1] -notmatch "\[D" -and $hechos[1] -notmatch "H_0001–H_0002") "normaliza controles legados sin convertirlos en hechos finales"
    Assert-True (@($evidencia.normalizaciones).Count -eq 2) "declara las normalizaciones aplicadas"
    Assert-True ($evidencia.criterio_de_reconstruccion -match "situación o detonante" -and $evidencia.criterio_de_reconstruccion -match "consecuencia visible") "expone la regla de entidad de los hechos"
    Assert-True (-not (Test-Path -LiteralPath $target)) "la vista previa no crea el destino"
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $source "_actos_backup_20260714.md") -Algorithm SHA256).Hash -eq $sourceHash) "no modifica la semilla del origen"
    Assert-True ((Get-Content -LiteralPath (Join-Path $source "relato.md") -Raw) -match "no debe heredarse") "no modifica la prosa del origen"

    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Assert-Throws { & (Join-Path $RepoRoot "scripts\rehidratar-relato.ps1") -Origen "origen" -Destino "origen-reinicio" -Actos backup -ForjaRootOverride $hub | Out-Null } "no permite un destino existente"

    Write-Host "OK: regresión de rehidratación de relato superada."
} finally {
    if (Test-Path -LiteralPath $RunRoot) {
        Remove-Item -LiteralPath $RunRoot -Recurse -Force
    }
}
