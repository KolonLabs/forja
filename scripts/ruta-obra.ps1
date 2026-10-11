# ruta-obra.ps1 -- Devuelve dónde viven las obras y los libros del hub (ADR 0026).
# Sin parámetros imprime la raíz de obras; con -Slug, la ruta de esa obra; con
# -Publicados, la raíz de libros. No comprueba existencia ni crea nada.

param(
    [string]$Slug,
    [switch]$Publicados
)

$ErrorActionPreference = "Stop"
$HubRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\common.ps1")

if ($Publicados) {
    Get-PublicadosRoot
} elseif ([string]::IsNullOrWhiteSpace($Slug)) {
    Get-ObrasRoot
} else {
    if ($Slug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        throw "ruta-obra: slug '$Slug' inválido. Debe ser kebab-case."
    }
    Join-Path (Get-ObrasRoot) $Slug
}
