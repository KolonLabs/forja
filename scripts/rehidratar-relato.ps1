# rehidratar-relato.ps1 — reconstruye un relato legado como un scaffold vigente.
# Lee exclusivamente la semilla editorial de un workspace existente y crea otro
# workspace en estado `diseno`. Nunca modifica ni copia prosa, guion, fichas o
# memoria del origen.

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Origen,

    [Parameter(Mandatory)]
    [string]$Destino,

    [ValidateSet("actual", "backup")]
    [string]$Actos = "actual",

    [string]$ReflexionJson,

    [switch]$Crear,

    # Solo para regresiones aisladas. La operación normal siempre parte del hub.
    [string]$ForjaRootOverride
)

$ErrorActionPreference = "Stop"

function Get-RelatoRehidratacionPremisa {
    param([string]$BriefPath)

    if (-not (Test-Path -LiteralPath $BriefPath -PathType Leaf)) { return $null }
    $brief = Get-Content -LiteralPath $BriefPath -Raw -Encoding UTF8
    $match = [regex]::Match($brief, '(?ms)^##\s+Premisa\s*\r?\n(.*?)(?=^##\s+|\z)')
    if (-not $match.Success) { return $null }
    $premisa = $match.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($premisa) -or $premisa -eq "---") { return $null }
    return $premisa
}

function Get-RelatoRehidratacionActos {
    param([string]$ActosPath)

    $actos = @()
    $actual = $null
    $enHechos = $false

    foreach ($line in (Get-Content -LiteralPath $ActosPath -Encoding UTF8)) {
        if ($line -match '^##\s+(.+?)\s*$') {
            $titulo = $matches[1].Trim()
            if ($titulo -match '^Notas del director\b') { break }
            $actual = [ordered]@{
                acto = $titulo
                objetivo = $null
                efecto_lector = $null
                tension = $null
                hechos = @()
            }
            $actos += $actual
            $enHechos = $false
            continue
        }
        if ($null -eq $actual) { continue }

        if ($line -match '^\*\*Objetivo narrativo:\*\*\s*(.+?)\s*$') {
            $actual.objetivo = $matches[1].Trim()
            continue
        }
        if ($line -match '^\*\*Que debe sentir el lector:\*\*\s*(.+?)\s*$') {
            $actual.efecto_lector = $matches[1].Trim()
            continue
        }
        if ($line -match '^\*\*Tension:\*\*\s*(.+?)\s*$') {
            $actual.tension = $matches[1].Trim()
            continue
        }
        if ($line -match '^###\s+Hechos\s*$') {
            $enHechos = $true
            continue
        }
        if ($line -match '^###\s+') {
            $enHechos = $false
            continue
        }
        if ($enHechos -and $line -match '^-\s+(.+?)\s*$') {
            $texto = $matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($texto)) {
                $actual.hechos += $texto
            }
        }
    }

    if ($actos.Count -eq 0) {
        throw "El archivo de hechos no contiene actos reconocibles: $ActosPath"
    }
    foreach ($acto in $actos) {
        if ($acto.hechos.Count -eq 0) {
            throw "El acto '$($acto.acto)' no contiene hechos; no es una semilla válida."
        }
    }

    return @($actos | ForEach-Object { [pscustomobject]$_ })
}

function New-RelatoRehidratacionMapa {
    param(
        [string]$Titulo,
        [string]$Origen,
        [string]$FuenteActos
    )

    $lineas = @(
        "# MAPA — $Titulo",
        "",
        '## Jerarquía narrativa',
        "",
        '```text',
        '_actos.md (H_XXXX)',
        '  → guion.md (B_XXXX agrupados en E_XXXX)',
        '  → relato-draft.md (prosa por escena; anclas invisibles B_XXXX)',
        '  → relato.md (manuscrito limpio)',
        '```',
        "",
        '## Estado inicial',
        "",
        "Este workspace se ha rehidratado desde la semilla editorial de ``$Origen`` usando sus actos ``$FuenteActos``. Se inicia en ``diseno``: no hereda guion, prosa, fichas, contexto ni estado de publicación del origen.",
        "",
        '## Archivos',
        "",
        '| Archivo | Estado inicial | Función |',
        '|---|---|---|',
        '| `BRIEF.md` | creado | Contrato editorial recuperado. |',
        '| `_actos.md` | creado | Hechos canónicos H_XXXX. |',
        '| `guion.md` | pendiente | Beats globales y escenas operativas. |',
        '| `fichas/` | vacío | Entidades derivadas del guion. |',
        '| `relato-draft.md` | pendiente | Prosa por escena. |',
        '| `contexto_narrativo.md` | pendiente | Memoria local durante la escritura. |',
        '| `relato.md` | pendiente | Salida limpia al finalizar. |',
        "",
        '## Flujo',
        "",
        '`diseno → fichas → escritura → finalizado → publicado (hub)`'
    )
    return ($lineas -join "`n")
}

function ConvertFrom-RelatoRehidratacionReflexion {
    param([string]$Json)

    if ([string]::IsNullOrWhiteSpace($Json)) {
        throw "-Crear requiere -ReflexionJson con la reflexión editorial confirmada."
    }
    try {
        $reflexion = $Json | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "-ReflexionJson no es JSON válido. $_"
    }
    foreach ($campo in @("fortalezas", "riesgos", "decisiones_usuario")) {
        if (-not $reflexion.PSObject.Properties.Name.Contains($campo) -or $null -eq $reflexion.$campo) {
            throw "-ReflexionJson requiere '$campo'."
        }
    }
    return $reflexion
}

if ($Origen -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "Origen '$Origen' inválido. Debe ser el slug de un workspace."
}
if ($Destino -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "Destino '$Destino' inválido. Debe usar kebab-case."
}
if ($Origen -eq $Destino) {
    throw "El destino debe ser distinto del origen: la rehidratación nunca modifica el workspace legado."
}

$HubRoot = if ([string]::IsNullOrWhiteSpace($ForjaRootOverride)) {
    Split-Path -Parent $PSScriptRoot
} else {
    (Resolve-Path -LiteralPath $ForjaRootOverride -ErrorAction Stop).Path
}
$WorkspacesRoot = Join-Path $HubRoot "workspaces"
$sourcePath = Join-Path $WorkspacesRoot $Origen
$targetPath = Join-Path $WorkspacesRoot $Destino

if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    throw "No existe el workspace de origen: $sourcePath"
}
if (Test-Path -LiteralPath $targetPath) {
    throw "Ya existe el workspace destino: $targetPath"
}

$configPath = Join-Path $sourcePath "config.json"
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "El origen no contiene config.json."
}
try {
    $sourceConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "El config.json de '$Origen' no es válido. $_"
}
if ($sourceConfig.tipo -ne "relato" -or $sourceConfig.escala -ne "relato") {
    throw "'$Origen' no es un relato; la rehidratación solo admite relatos."
}
if ([string]::IsNullOrWhiteSpace($sourceConfig.titulo) -or [string]::IsNullOrWhiteSpace($sourceConfig.estilo_base)) {
    throw "El origen debe conservar titulo y estilo_base en config.json."
}

$actosPath = if ($Actos -eq "actual") {
    Join-Path $sourcePath "_actos.md"
} else {
    $backups = @(Get-ChildItem -LiteralPath $sourcePath -File -Filter "_actos_backup_*.md" | Sort-Object Name)
    if ($backups.Count -eq 0) {
        throw "'$Origen' no tiene un _actos_backup_*.md; no se puede usar -Actos backup."
    }
    if ($backups.Count -gt 1) {
        $nombres = $backups.Name -join ", "
        throw "'$Origen' tiene varios backups de actos ($nombres). Selecciona uno manualmente antes de rehidratar."
    }
    $backups[0].FullName
}
if (-not (Test-Path -LiteralPath $actosPath -PathType Leaf)) {
    throw "No existe la semilla de actos: $actosPath"
}

$hechos = Get-RelatoRehidratacionActos -ActosPath $actosPath
$premisa = Get-RelatoRehidratacionPremisa -BriefPath (Join-Path $sourcePath "BRIEF.md")
$reflexion = if ($Crear) {
    ConvertFrom-RelatoRehidratacionReflexion -Json $ReflexionJson
} elseif ($sourceConfig.PSObject.Properties.Name.Contains("reflexion_agente")) {
    $sourceConfig.reflexion_agente
} else {
    $null
}

$brief = [ordered]@{
    slug = $Destino
    titulo = $sourceConfig.titulo
    escala = "relato"
    estilo_base = $sourceConfig.estilo_base
    estilo_secundario = if ($sourceConfig.PSObject.Properties.Name.Contains("estilo_secundario")) { $sourceConfig.estilo_secundario } else { $null }
    logline = $sourceConfig.logline
    premisa = $premisa
    genero = $sourceConfig.genero
    subgenero = if ($sourceConfig.PSObject.Properties.Name.Contains("subgenero")) { $sourceConfig.subgenero } else { $null }
    tono = $sourceConfig.tono
    atmosfera = if ($sourceConfig.PSObject.Properties.Name.Contains("atmosfera")) { $sourceConfig.atmosfera } else { $null }
    explicitud = $sourceConfig.explicitud
    pov = $sourceConfig.pov
    extension_estimada = $sourceConfig.extension_estimada
    protagonistas = $sourceConfig.protagonistas
    personajes_clave = $sourceConfig.personajes_clave
    antagonista_o_conflicto = if ($sourceConfig.PSObject.Properties.Name.Contains("antagonista_o_conflicto")) { $sourceConfig.antagonista_o_conflicto } else { $null }
    setting = $sourceConfig.setting
    temas = $sourceConfig.temas
    referencias = if ($sourceConfig.PSObject.Properties.Name.Contains("referencias")) { $sourceConfig.referencias } else { $null }
    restricciones = $sourceConfig.restricciones
    puntos_conexion = if ($sourceConfig.PSObject.Properties.Name.Contains("puntos_conexion")) { $sourceConfig.puntos_conexion } else { $null }
    hechos = $hechos
    _mapa = New-RelatoRehidratacionMapa -Titulo $sourceConfig.titulo -Origen $Origen -FuenteActos $Actos
    reflexion_agente = $reflexion
}
$briefObject = [pscustomobject]$brief

if (-not $Crear) {
    $briefObject | ConvertTo-Json -Depth 16
    return
}

# Reutiliza el creador canónico para que el destino reciba exactamente la misma
# inyección y los mismos contadores que un relato creado hoy desde el hub.
. (Join-Path $HubRoot "scripts\lib\common.ps1")
$Brief = $briefObject
. (Join-Path $HubRoot "scripts\new-relato.ps1")

Write-Host ""
Write-Host "=== Relato rehidratado: $targetPath ==="
Write-Host "  Origen:       $Origen (sin modificar)"
Write-Host "  Actos usados: $Actos"
Write-Host "  Estado:       diseno"
Write-Host "  Siguiente:    opencode --cwd `"workspaces\$Destino`""
Write-Host "                /validar-hechos"
