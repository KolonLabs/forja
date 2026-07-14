# rehidratar-relato.ps1 — extrae evidencia editorial de un relato legado.
# Lee exclusivamente una semilla editorial. No crea, modifica ni copia un
# workspace: el scaffolder reconstruye después un brief nuevo y lo entrega al
# dispatcher canónico `new-project.ps1` tras confirmación humana.

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Origen,

    [Parameter(Mandatory)]
    [string]$Destino,

    [ValidateSet("actual", "backup")]
    [string]$Actos = "actual",

    # Solo para regresiones aisladas. La operación normal siempre parte del hub.
    [string]$ForjaRootOverride
)

$ErrorActionPreference = "Stop"

function Get-RelatoRehidratacionCampo {
    param(
        [object]$Objeto,
        [string]$Nombre
    )

    if ($Objeto.PSObject.Properties.Name -contains $Nombre) {
        return $Objeto.$Nombre
    }
    return $null
}

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

function ConvertTo-RelatoRehidratacionHecho {
    param([string]$Texto)

    # Los ID H y las marcas [D] son control técnico legado, no contenido
    # editorial. La salida es solo una semilla normalizada: el scaffolder debe
    # reformularla, ampliarla, dividirla o reordenarla si lo requiere el arco.
    $normalizado = [regex]::Replace($Texto.Trim(), '^H_\d{1,4}\s*(?:[—:]\s*)?', '')
    $normalizado = [regex]::Replace($normalizado, '^\[D(?:\s*·\s*H_\d{1,4}\s*[–-]\s*H_\d{1,4})?\]\s*[:—-]?\s*', '')
    if ([string]::IsNullOrWhiteSpace($normalizado)) {
        throw "Un hecho legado queda vacío después de retirar sus marcas de control: '$Texto'"
    }
    return $normalizado
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
            $texto = ConvertTo-RelatoRehidratacionHecho -Texto $matches[1]
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
$actosOriginales = Get-Content -LiteralPath $actosPath -Raw -Encoding UTF8
$normalizaciones = @()
if ($actosOriginales -match '(?m)^\s*-\s+H_\d{1,4}\b') {
    $normalizaciones += "Se retiraron los ID H legados: el destino asignará identificadores nuevos."
}
if ($actosOriginales -match '\[D(?:\s*·\s*H_\d{1,4}\s*[–-]\s*H_\d{1,4})?\]') {
    $normalizaciones += "Se retiraron las marcas [D] y sus rangos: en relato los patrones se reformulan como contexto causal del hecho, sin pauta técnica."
}

$semilla = [ordered]@{
    titulo = $sourceConfig.titulo
    escala = "relato"
    estilo_base = $sourceConfig.estilo_base
    estilo_secundario = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "estilo_secundario"
    logline = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "logline"
    premisa = $premisa
    genero = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "genero"
    subgenero = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "subgenero"
    tono = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "tono"
    atmosfera = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "atmosfera"
    explicitud = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "explicitud"
    pov = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "pov"
    extension_estimada = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "extension_estimada"
    protagonistas = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "protagonistas"
    personajes_clave = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "personajes_clave"
    antagonista_o_conflicto = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "antagonista_o_conflicto"
    setting = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "setting"
    temas = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "temas"
    referencias = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "referencias"
    restricciones = Get-RelatoRehidratacionCampo -Objeto $sourceConfig -Nombre "restricciones"
    actos = $hechos
}

$evidencia = [ordered]@{
    esquema = "rehidratacion-relato-evidencia-v2"
    origen = $Origen
    destino_sugerido = $Destino
    fuente_actos = $Actos
    semilla = [pscustomobject]$semilla
    normalizaciones = $normalizaciones
    limites = @(
        "Esta salida es evidencia editorial, no un brief final ni un contrato de hechos.",
        "El destino debe reconstruirse con hechos nuevos y suficientemente contextualizados; puede añadir, fusionar, dividir, reordenar o descartar elementos de la semilla.",
        "No se ha leído ni debe usarse guion, prosa, fichas, memoria, cola ni instrucciones antiguas del origen."
    )
    criterio_de_reconstruccion = "Conserva solo los no negociables confirmados. Cada hecho final debe ofrecer situación o detonante, agencia y presión concreta, cambio causal y consecuencia visible; los patrones añaden contexto de rutina, variación y progresión, sin convertirse en beats, escenas ni prosa."
}

[pscustomobject]$evidencia | ConvertTo-Json -Depth 16
