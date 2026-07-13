# new-novela-multi-hilo.ps1 — Crea un workspace de novela multi-hilo
# Recibe: $Brief (PSObject con los datos del brief, ya validado)
# Requiere: $HubRoot (definido en el dispatcher)

$TargetDir = Join-Path $HubRoot "workspaces\$($Brief.slug)"
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
    New-Item -LiteralPath $TargetDir -ItemType Directory -Force | Out-Null
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

Write-Host "Inyectando pipeline novela-multi-hilo..."
Inject-Pipeline -TargetDir $TargetDir -Escala "novela-multi-hilo"

Write-ConfigJson -TargetDir $TargetDir -Brief $Brief
Write-BriefMd -TargetDir $TargetDir -Brief $Brief
Write-ActosMdMultiHilo -TargetDir $TargetDir -Brief $Brief
Write-AgentsMd -TargetDir $TargetDir -Brief $Brief -Escala "novela-multi-hilo"
Write-MapaMd -TargetDir $TargetDir -Brief $Brief

# Hilos
$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
$opsHilos = New-OperationalHilos -BriefHilos $Brief.hilos -Now $now
Seed-HiloFolders -TargetDir $TargetDir -OperationalHilos $opsHilos -Brief $Brief

# Registrar hilos en config
$config = Get-Content (Join-Path $TargetDir "config.json") -Raw | ConvertFrom-Json
$config | Add-Member -MemberType NoteProperty -Name "hilos" -Value $opsHilos -Force
if ($Brief.PSObject.Properties.Name.Contains("partes") -and $Brief.partes) {
    $config | Add-Member -MemberType NoteProperty -Name "partes" -Value $Brief.partes -Force
}
$config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $TargetDir "config.json") -Encoding UTF8

# Infraestructura
Write-Host "Inicializando Qdrant + Neo4j..."
Initialize-Infra -TargetDir $TargetDir -Brief $Brief

$skillCount = (Get-ChildItem (Join-Path $TargetDir ".opencode\skills") -Directory).Count

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
Write-Host "    opencode --cwd ""workspaces\$($Brief.slug)"""
Write-Host "    /generar"
Write-Host ""
} catch {
    if ($workspaceCreated -and (Test-Path -LiteralPath $TargetDir)) {
        Remove-Item -LiteralPath $TargetDir -Recurse -Force
    }
    throw
}
