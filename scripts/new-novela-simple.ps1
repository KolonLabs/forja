# new-novela-simple.ps1 — Crea un workspace de novela simple
# Recibe: $Brief (PSObject con los datos del brief, ya validado)
# Requiere: $HubRoot (definido en el dispatcher)

# Las obras viven fuera del hub, cada una con su propio git (ADR 0026).
$TargetDir = Join-Path (Get-ObrasRoot) $Brief.slug
if (Test-Path -LiteralPath $TargetDir) {
    throw "Ya existe un workspace con slug '$($Brief.slug)': $TargetDir"
}

$required = @("slug","titulo","escala","estilo_base","logline","hechos","capitulos_estimados")
foreach ($f in $required) {
    Test-BriefField $Brief $f "new-novela-simple"
}

Write-Host "Creando workspace (novela-simple): $TargetDir"

$workspaceCreated = $false
try {
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
    $workspaceCreated = $true

    # 1. Crear estructura de directorios
    $dirs = @(
        "$TargetDir\.opencode\agents",
        "$TargetDir\.claude\skills",
        "$TargetDir\.opencode\commands",
        "$TargetDir\fichas",
        "$TargetDir\capitulos",
        "$TargetDir\referencias"
    )
    foreach ($d in $dirs) { New-Item -Force -ItemType Directory $d | Out-Null }

# 2. Escribir opencode.json (aislado del hub)
Write-OpencodeConfig -TargetDir $TargetDir

Write-Host "Inyectando pipeline novela-simple..."
Inject-Pipeline -TargetDir $TargetDir -Escala "novela-simple" -EstiloBase $Brief.estilo_base -EstiloSecundario $Brief.estilo_secundario

Write-ConfigJson -TargetDir $TargetDir -Brief $Brief
Write-BriefMd -TargetDir $TargetDir -Brief $Brief
Write-ActosMd -TargetDir $TargetDir -Brief $Brief
Write-AgentsMd -TargetDir $TargetDir -Brief $Brief -Escala "novela-simple"
Write-MapaMd -TargetDir $TargetDir -Brief $Brief

# Artefactos globales que el pipeline referencia desde FASE 0.
Write-NovelaGlobalScaffold -TargetDir $TargetDir -Brief $Brief

# Infraestructura
Write-Host "Inicializando Qdrant + Neo4j..."
Initialize-Infra -TargetDir $TargetDir -Brief $Brief

# Repositorio propio de la obra, sin commits (ADR 0026).
Initialize-ObraGit -TargetDir $TargetDir

$skillCount = (Get-ChildItem (Join-Path $TargetDir ".claude\skills") -Directory).Count

Write-Host ""
Write-Host "============================================"
Write-Host "  Workspace creado [novela-simple]"
Write-Host "============================================"
Write-Host "  Ruta:      $TargetDir"
Write-Host "  Escala:    novela-simple (4 fases)"
Write-Host "  Estilo:    $($Brief.estilo_base)"
Write-Host "  Skills:    $skillCount activos"
Write-Host "  Caps:      $($Brief.capitulos_estimados) estimados"
Write-Host ""
Write-Host "  Para comenzar:"
Write-Host "    opencode --cwd ""$TargetDir"""
Write-Host "    o, en Claude Code, abre una sesión en esa carpeta (agente principal: director)"
Write-Host "    /generar"
Write-Host ""
} catch {
    if ($workspaceCreated -and (Test-Path -LiteralPath $TargetDir)) {
        Remove-Item -LiteralPath $TargetDir -Recurse -Force
    }
    throw
}
