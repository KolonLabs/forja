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

# Validar slug
if ($Brief.slug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "new-project: slug '$($Brief.slug)' invalido. Debe ser kebab-case (ej. mi-proyecto)"
}

# Validar estructura de hechos
Test-HechosStructure $Brief

# Delegar al script de la escala
$scaleScript = Join-Path $PSScriptRoot "new-$($Brief.escala).ps1"
if (-not (Test-Path -LiteralPath $scaleScript)) {
    throw "new-project: script no encontrado para escala '$($Brief.escala)': $scaleScript"
}

. $scaleScript
