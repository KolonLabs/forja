# new-relato.ps1 — Crea un workspace de relato
# Recibe: $Brief (PSObject con los datos del brief, ya validado)
# Requiere: $HubRoot (definido en el dispatcher)

$TargetDir = Join-Path $HubRoot "workspaces\$($Brief.slug)"
if (Test-Path -LiteralPath $TargetDir) {
    throw "Ya existe un workspace con slug '$($Brief.slug)': $TargetDir"
}

# Validar campos requeridos
$required = @("slug","titulo","escala","estilo_base","logline","hechos")
foreach ($f in $required) {
    Test-BriefField $Brief $f "new-relato"
}

Write-Host "Creando workspace (relato): $TargetDir"

$workspaceCreated = $false
try {
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
    $workspaceCreated = $true

    # 1. Crear estructura de directorios
    $dirs = @(
        "$TargetDir\.opencode\agents",
        "$TargetDir\.opencode\skills",
        "$TargetDir\.opencode\commands",
        "$TargetDir\fichas"
    )
    foreach ($d in $dirs) { New-Item -Force -ItemType Directory $d | Out-Null }

# 2. Escribir opencode.json
@"
{
  "`$schema": "https://opencode.ai/config.json",
  "default_agent": "director"
}
"@ | Set-Content -LiteralPath (Join-Path $TargetDir "opencode.json") -Encoding UTF8

# 2. Inyectar pipeline
Write-Host "Inyectando pipeline relato..."
Inject-Pipeline -TargetDir $TargetDir -Escala "relato" -EstiloBase $Brief.estilo_base -EstiloSecundario $Brief.estilo_secundario

# 3. Escribir archivos del workspace
Write-ConfigJson -TargetDir $TargetDir -Brief $Brief
Write-BriefMd -TargetDir $TargetDir -Brief $Brief
Write-ActosMd -TargetDir $TargetDir -Brief $Brief -AsignarIdsGlobales
Write-AgentsMd -TargetDir $TargetDir -Brief $Brief -Escala "relato"
Write-MapaMd -TargetDir $TargetDir -Brief $Brief

# 4. Confirmación
$skillCount = (Get-ChildItem (Join-Path $TargetDir ".opencode\skills") -Directory).Count

Write-Host ""
Write-Host "============================================"
Write-Host "  Workspace creado [relato]"
Write-Host "============================================"
Write-Host "  Ruta:      $TargetDir"
Write-Host "  Escala:    relato (4 fases)"
Write-Host "  Estilo:    $($Brief.estilo_base)"
Write-Host "  Skills:    $skillCount activos"
Write-Host ""
Write-Host "  Para comenzar:"
Write-Host "    opencode --cwd ""workspaces\$($Brief.slug)"""
Write-Host "    /generar"
Write-Host ""
} catch {
    if ($workspaceCreated -and (Test-Path -LiteralPath $TargetDir)) {
        Remove-Item -LiteralPath $TargetDir -Recurse -Force
    }
    throw
}
