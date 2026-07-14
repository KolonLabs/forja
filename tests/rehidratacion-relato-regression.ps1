# rehidratacion-relato-regression.ps1 — Prueba aislada del reinicio desde semilla.
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
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared") -Destination (Join-Path $hub "shared") -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $hub "scripts\lib") | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\new-relato.ps1") -Destination (Join-Path $hub "scripts\new-relato.ps1") -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\lib\common.ps1") -Destination (Join-Path $hub "scripts\lib\common.ps1") -Force

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

    $reflexion = @{ fortalezas = @("Semilla legible"); riesgos = @("Recurrencia que revisar en diseño"); decisiones_usuario = @("Reiniciar desde backup") } | ConvertTo-Json -Compress
    & (Join-Path $RepoRoot "scripts\rehidratar-relato.ps1") -Origen "origen" -Destino "origen-reinicio" -Actos backup -Crear -ReflexionJson $reflexion -ForjaRootOverride $hub | Out-Null

    Assert-True (Test-Path -LiteralPath $target) "crea el destino"
    $config = Get-Content -LiteralPath (Join-Path $target "config.json") -Raw | ConvertFrom-Json
    Assert-True ($config.estado -eq "diseno") "reinicia en diseño"
    Assert-True ($config.ultimo_hecho_seq -eq 2 -and $config.ultimo_beat_seq -eq 0 -and $config.ultimo_escena_seq -eq 0) "reconstruye contadores canónicos"
    $actos = Get-Content -LiteralPath (Join-Path $target "_actos.md") -Raw
    Assert-True ($actos -match "H_0001" -and $actos -match "H_0002" -and $actos -notmatch "\[D" -and $actos -notmatch "H_0001–H_0002") "asigna IDs H y normaliza la marca [D] legada"
    Assert-True ((Get-Content -LiteralPath (Join-Path $target "MAPA.md") -Raw) -match "E_XXXX") "regenera el mapa con el contrato por escenas"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $target "relato.md"))) "no hereda manuscrito"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $target "guion.md"))) "no hereda guion"
    Assert-True (Test-Path -LiteralPath (Join-Path $target "scripts\relato-transaccion.ps1")) "inyecta el helper vigente"
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $source "_actos_backup_20260714.md") -Algorithm SHA256).Hash -eq $sourceHash) "no modifica la semilla del origen"
    Assert-True ((Get-Content -LiteralPath (Join-Path $source "relato.md") -Raw) -match "no debe heredarse") "no modifica la prosa del origen"
    Assert-Throws { & (Join-Path $RepoRoot "scripts\rehidratar-relato.ps1") -Origen "origen" -Destino "origen-reinicio" -Actos backup -Crear -ReflexionJson $reflexion -ForjaRootOverride $hub | Out-Null } "no sobreescribe un destino existente"

    Write-Host "OK: regresión de rehidratación de relato superada."
} finally {
    if (Test-Path -LiteralPath $RunRoot) {
        Remove-Item -LiteralPath $RunRoot -Recurse -Force
    }
}
