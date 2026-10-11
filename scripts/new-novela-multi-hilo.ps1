# new-novela-multi-hilo.ps1 — Crea un workspace de novela multi-hilo
# Recibe: $Brief (PSObject con los datos del brief, ya validado)
# Requiere: $HubRoot (definido en el dispatcher)

# Las obras viven fuera del hub, cada una con su propio git (ADR 0026).
$TargetDir = Join-Path (Get-ObrasRoot) $Brief.slug
if (Test-Path -LiteralPath $TargetDir) {
    throw "Ya existe un workspace con slug '$($Brief.slug)': $TargetDir"
}

$required = @("slug","titulo","escala","estilo_base","logline","hechos","hilos")
foreach ($f in $required) {
    Test-BriefField $Brief $f "new-novela-multi-hilo"
}

Write-Host "Creando workspace (novela-multi-hilo): $TargetDir"

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

Write-Host "Inyectando pipeline novela-multi-hilo..."
Inject-Pipeline -TargetDir $TargetDir -Escala "novela-multi-hilo" -EstiloBase $Brief.estilo_base -EstiloSecundario $Brief.estilo_secundario

Write-ConfigJson -TargetDir $TargetDir -Brief $Brief
Write-BriefMd -TargetDir $TargetDir -Brief $Brief
Write-ActosMdMultiHilo -TargetDir $TargetDir -Brief $Brief
Write-AgentsMd -TargetDir $TargetDir -Brief $Brief -Escala "novela-multi-hilo"
Write-MapaMd -TargetDir $TargetDir -Brief $Brief

# Hilos
$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
$opsHilos = New-OperationalHilos -BriefHilos $Brief.hilos -Now $now
Seed-HiloFolders -TargetDir $TargetDir -OperationalHilos $opsHilos -Brief $Brief

# Artefactos globales. El guionista (modo trenzado) rellena la tabla y el
# director mantiene contexto.md; el pipeline los referencia desde FASE 0.
Write-NovelaGlobalScaffold -TargetDir $TargetDir -Brief $Brief -OperationalHilos $opsHilos

# Registrar hilos en config
$config = Get-Content (Join-Path $TargetDir "config.json") -Raw | ConvertFrom-Json
$config | Add-Member -MemberType NoteProperty -Name "hilos" -Value $opsHilos -Force
$config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $TargetDir "config.json") -Encoding UTF8

# Infraestructura
Write-Host "Inicializando Qdrant + Neo4j..."
Initialize-Infra -TargetDir $TargetDir -Brief $Brief

# Repositorio propio de la obra, sin commits (ADR 0026).
Initialize-ObraGit -TargetDir $TargetDir

$skillCount = (Get-ChildItem (Join-Path $TargetDir ".claude\skills") -Directory).Count

Write-Host ""
Write-Host "============================================"
Write-Host "  Workspace creado [novela-multi-hilo]"
Write-Host "============================================"
Write-Host "  Ruta:      $TargetDir"
Write-Host "  Escala:    novela-multi-hilo (8 fases)"
Write-Host "  Estilo:    $($Brief.estilo_base)"
Write-Host "  Skills:    $skillCount activos"
Write-Host "  Hilos:     $($opsHilos.Count)"
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
