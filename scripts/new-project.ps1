# new-project.ps1 — Dispatcher de creacion de workspaces Forja
# Recibe brief JSON por stdin. Delega en el script de la escala correspondiente.
#
# Uso desde el scaffolder (LLM):
#   $briefJson | .\scripts\new-project.ps1
#
# Uso directo:
#   Get-Content brief.json | .\scripts\new-project.ps1

$ErrorActionPreference = "Stop"
$HubRoot = Split-Path -Parent $PSScriptRoot

# Cargar utilidades compartidas
. (Join-Path $PSScriptRoot "lib\common.ps1")

# Leer JSON de stdin
$stdinJson = ($input | Out-String).Trim()
if (-not $stdinJson) { throw "new-project: no se recibio brief por stdin" }

try {
    $Brief = $stdinJson | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "new-project: JSON invalido en stdin. $_"
}

# Validar campos minimos
$requiredRoot = @("slug","titulo","escala","estilo_base")
foreach ($f in $requiredRoot) {
    Test-BriefField $Brief $f "new-project"
}

# Validar escala
$validScales = @("relato", "novela-simple", "novela-multi-hilo")
if ($Brief.escala -notin $validScales) {
    throw "new-project: escala '$($Brief.escala)' no soportada. Valores validos: $($validScales -join ', ')"
}

# Validar estilo_base / estilo_secundario
$validEstilos = @("explicito", "contemporaneo", "erotico", "fantasia", "noir", "romantico", "thriller")
if ($Brief.estilo_base -notin $validEstilos) {
    throw "new-project: estilo_base '$($Brief.estilo_base)' no soportado. Valores validos: $($validEstilos -join ', ')"
}
if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario -and ($Brief.estilo_secundario -notin $validEstilos)) {
    throw "new-project: estilo_secundario '$($Brief.estilo_secundario)' no soportado. Valores validos: $($validEstilos -join ', ')"
}

# Validar explicitud (opcional; si se especifica, debe ser uno de los valores soportados)
$validExplicitud = @("maximo", "alto", "medio", "bajo", "minimo")
if ($Brief.PSObject.Properties.Name.Contains("explicitud") -and $Brief.explicitud -and ($Brief.explicitud -notin $validExplicitud)) {
    throw "new-project: explicitud '$($Brief.explicitud)' no soportada. Valores validos: $($validExplicitud -join ', ')"
}

# Validar slug
if ($Brief.slug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "new-project: slug '$($Brief.slug)' invalido. Debe ser kebab-case (ej. mi-proyecto)"
}

# MAPA.md es parte del contrato entre el briefing y cada workspace.
Test-BriefField $Brief "_mapa" "new-project"
if (-not ($Brief._mapa -is [string]) -or [string]::IsNullOrWhiteSpace($Brief._mapa)) {
    throw "new-project: _mapa debe contener el Markdown inicial de MAPA.md"
}

# Relato nunca usa infraestructura; toda novela la requiere sin excepciones.
if ($Brief.PSObject.Properties.Name.Contains("_no_infra")) {
    throw "new-project: _no_infra ya no es compatible. Relato no inicializa infraestructura y las novelas siempre la requieren."
}

# Validar estructura de hechos
Test-HechosStructure $Brief

# Delegar al script de la escala
$scaleScript = Join-Path $PSScriptRoot "new-$($Brief.escala).ps1"
if (-not (Test-Path -LiteralPath $scaleScript)) {
    throw "new-project: script no encontrado para escala '$($Brief.escala)': $scaleScript"
}

. $scaleScript
