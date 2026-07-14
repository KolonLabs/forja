# new-edicion-relato.ps1 -- Deriva una nueva edición corregible de un relato publicado.

param(
    [Parameter(Mandatory = $true)]
    [string]$Origen,
    [Parameter(Mandatory = $true)]
    [string]$Slug,
    [string]$Titulo,
    [string]$Motivo = "Corrección editorial posterior a la publicación."
)

$ErrorActionPreference = "Stop"
$ForjaRoot = Split-Path -Parent $PSScriptRoot
$HubRoot = $ForjaRoot
$WorkspacesRoot = Join-Path $ForjaRoot "workspaces"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

. (Join-Path $PSScriptRoot "lib\common.ps1")

function Assert-KebabSlug {
    param([string]$Value, [string]$Name)

    if ($Value -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        throw "$Name '$Value' invalido. Debe ser un slug kebab-case."
    }
}

Assert-KebabSlug $Origen "Workspace de origen"
Assert-KebabSlug $Slug "Slug de la nueva edición"
if ($Origen -eq $Slug) {
    throw "La nueva edición debe usar un slug distinto del workspace de origen."
}

$sourcePath = Join-Path $WorkspacesRoot $Origen
$targetPath = Join-Path $WorkspacesRoot $Slug
if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    throw "Workspace de origen '$Origen' no encontrado."
}
if (Test-Path -LiteralPath $targetPath) {
    throw "Ya existe un workspace con slug '$Slug': $targetPath"
}

$configPath = Join-Path $sourcePath "config.json"
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Workspace '$Origen' no contiene config.json."
}
try {
    $sourceConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "El config.json de '$Origen' no es válido. $_"
}
if ($sourceConfig.tipo -ne "relato" -or $sourceConfig.escala -ne "relato") {
    throw "'$Origen' no es un relato. La edición derivada solo está disponible para relatos por ahora."
}
if ($sourceConfig.estado -ne "publicado") {
    throw "Workspace '$Origen' está en estado '$($sourceConfig.estado)'. Solo se pueden derivar ediciones de relatos publicados."
}
foreach ($required in @("guion.md", "relato-draft.md", "relato.md", "fichas")) {
    $path = Join-Path $sourcePath $required
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Workspace publicado '$Origen' no contiene '$required'; no se puede abrir una edición corregible."
    }
}
# Una edición no puede inventar la agrupación dramática de una obra antigua.
# Exigimos escenas canónicas; el draft sí puede normalizarse sin tocar prosa.
[void](Get-RelatoGuionEscenas -GuionPath (Join-Path $sourcePath "guion.md"))

$rootSlug = $Origen
$editionNumber = 2
if ($sourceConfig.PSObject.Properties.Name -contains "edicion" -and $sourceConfig.edicion) {
    if ($sourceConfig.edicion.obra_raiz) {
        $rootSlug = $sourceConfig.edicion.obra_raiz
    }
    if ($sourceConfig.edicion.numero) {
        $editionNumber = [int]$sourceConfig.edicion.numero + 1
    }
}
if ([string]::IsNullOrWhiteSpace($Titulo)) {
    $Titulo = $sourceConfig.titulo
}
if ([string]::IsNullOrWhiteSpace($Titulo)) {
    throw "El workspace de origen no tiene título y no se indicó -Titulo."
}

$timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
$operationId = [guid]::NewGuid().ToString("N")
$stagePath = Join-Path $WorkspacesRoot ".${Slug}.edicion-$operationId"
$completed = $false

try {
    New-Item -ItemType Directory -Force -Path $stagePath | Out-Null
    Get-ChildItem -LiteralPath $sourcePath -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $stagePath -Recurse -Force
    }

    # La edición recibe el pipeline vigente, no una copia potencialmente obsoleta del origen.
    $stageOpenCode = Join-Path $stagePath ".opencode"
    if (Test-Path -LiteralPath $stageOpenCode) {
        Remove-Item -LiteralPath $stageOpenCode -Recurse -Force
    }
    foreach ($directory in @("agents", "skills", "commands")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $stageOpenCode $directory) | Out-Null
    }
    Inject-Pipeline -TargetDir $stagePath -Escala "relato" -EstiloBase $sourceConfig.estilo_base -EstiloSecundario $sourceConfig.estilo_secundario

    # Las ediciones derivadas reciben el contrato vigente. Se normalizan solo
    # metadatos de control: headings B y marcadores de escena; nunca la prosa.
    $draftMigration = Convert-RelatoDraftToSceneContract `
        -DraftPath (Join-Path $stagePath "relato-draft.md") `
        -GuionPath (Join-Path $stagePath "guion.md")

    $contextPath = Join-Path $stagePath "contexto_narrativo.md"
    if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) {
        $initialContext = "# Contexto narrativo — $Titulo`n`n## Estado acumulado`n`n- Edición abierta: reconstruir continuidad desde ``relato-edicion-anterior.md``, ``guion.md`` y el draft antes de la primera corrección.`n"
        [System.IO.File]::WriteAllText($contextPath, $initialContext, $utf8NoBom)
    }

    $previousManuscript = Join-Path $stagePath "relato.md"
    $snapshotPath = Join-Path $stagePath "relato-edicion-anterior.md"
    Move-Item -LiteralPath $previousManuscript -Destination $snapshotPath

    $config = Get-Content -LiteralPath (Join-Path $stagePath "config.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $config.slug = $Slug
    $config.titulo = $Titulo
    $config.estado = "correccion"
    $config.creado = $timestamp
    $config.ultima_modificacion = $timestamp
    $config | Add-Member -NotePropertyName "edicion" -NotePropertyValue ([ordered]@{
        numero = $editionNumber
        obra_raiz = $rootSlug
        workspace_origen = $Origen
        motivo = $Motivo
        creada = $timestamp
        manuscrito_origen = "relato-edicion-anterior.md"
        manuscrito_origen_sha256 = (Get-FileHash -LiteralPath $snapshotPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }) -Force
    [System.IO.File]::WriteAllText(
        (Join-Path $stagePath "config.json"),
        ($config | ConvertTo-Json -Depth 12),
        $utf8NoBom
    )
    # No conservamos AGENTS.md ni MAPA.md del origen: son instrucciones de
    # ejecución y podrían describir un contrato anterior al pipeline vigente.
    Write-AgentsMd -TargetDir $stagePath -Brief $config -Escala "relato"
    Write-RelatoEditionMapa -TargetDir $stagePath -Titulo $Titulo -Origen $Origen -Numero $editionNumber

    $editionNote = @"
# Edición $editionNumber — $Titulo

- **Obra raíz:** ``$rootSlug``
- **Workspace de origen:** ``$Origen``
- **Motivo:** $Motivo
- **Creada:** $timestamp
- **Manuscrito de referencia:** ``relato-edicion-anterior.md``

Este workspace deriva de una publicación anterior. El manuscrito de referencia es inmutable: toda corrección se realiza en ``relato-draft.md`` y se valida contra ``guion.md`` y las fichas. Cuando la edición esté lista, ``/publicar`` generará un nuevo ``relato.md`` y dejará el workspace en ``finalizado``.
"@
    [System.IO.File]::WriteAllText((Join-Path $stagePath "EDICION.md"), $editionNote, $utf8NoBom)

    $migrationRows = @()
    if ($draftMigration.headings_migrated) {
        $migrationRows += "| $timestamp | Normalización de draft | Todos los B conservados | Headings heredados convertidos a anclas invisibles |"
    }
    if ($draftMigration.scene_markers_migrated) {
        $migrationRows += "| $timestamp | Normalización de escenas | Todas las E conservadas | Marcadores ESCENA reconstruidos desde el guion sin tocar prosa |"
    }
    $correctionLog = @"
# Registro de correcciones — Edición $editionNumber

| Fecha | Alcance | Beats afectados | Resultado |
|---|---|---|---|
| $timestamp | Apertura de edición | — | Pendiente de corrección |
$($migrationRows -join "`n")

El director añade una fila por cada ejecución de `/corregir`, `/revisar` o `/expandir` realizada durante esta edición.
"@
    [System.IO.File]::WriteAllText((Join-Path $stagePath "correcciones.md"), $correctionLog, $utf8NoBom)

    $editionAgentsNote = @"

## Edición derivada

Este workspace está en ``correccion`` y procede de ``$Origen``. No modifiques ``relato-edicion-anterior.md``: es la referencia publicada. Usa ``/corregir``, ``/revisar`` o ``/expandir`` sobre el draft y termina con ``/publicar`` para llegar a ``finalizado``.
"@
    [System.IO.File]::AppendAllText((Join-Path $stagePath "AGENTS.md"), $editionAgentsNote, $utf8NoBom)

    Move-Item -LiteralPath $stagePath -Destination $targetPath
    $completed = $true

    Write-Host ""
    Write-Host "=== Edición derivada creada: $targetPath ==="
    Write-Host "  Origen:   $Origen (publicado, sin modificar)"
    Write-Host "  Edición:  $editionNumber"
    Write-Host "  Estado:   correccion"
    Write-Host "  Siguiente: opencode --cwd `"workspaces\$Slug`""
    Write-Host "             /corregir completa"
} finally {
    if (-not $completed -and (Test-Path -LiteralPath $stagePath)) {
        Remove-Item -LiteralPath $stagePath -Recurse -Force
    }
}
