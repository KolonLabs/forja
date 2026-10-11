# crear-libro.ps1 -- Ensambla antologias de relatos finalizados (ADR 0026).
# Una obra unica se compila dentro de la obra con /compilar.

param(
    [Parameter(Mandatory = $true)]
    [string]$Libro,
    [Parameter(Mandatory = $true)]
    [string[]]$Fuentes,
    [string]$Titulo = $Libro,
    [string]$Autor = "Amaro Alba",
    [switch]$Epub,
    [switch]$Pdf,
    [ValidateSet("paperback", "paperback-5x8", "hardcover", "hardcover-9pt", "hardcover-6x9", "hardcover-6x9-9pt")]
    [string]$PdfFormat = "paperback",
    [ValidateSet("auto", "typst", "xelatex", "wkhtmltopdf")]
    [string]$PdfEngine = "auto"
)

$ErrorActionPreference = "Stop"
$HubRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\common.ps1")
$WorkspacesRoot = Get-ObrasRoot
$PublicadosRoot = Get-PublicadosRoot
$BuildScripts = Join-Path $HubRoot "shared\scripts"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Assert-KebabSlug {
    param([string]$Value, [string]$Name)

    if ($Value -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        throw "$Name '$Value' invalido. Debe ser un slug kebab-case."
    }
}

function Get-FileSha256 {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

Assert-KebabSlug $Libro "Libro"
# Una obra unica se compila dentro de la obra con /compilar (ADR 0026). El hub
# solo ensambla antologias de varios relatos.
if (-not $Fuentes -or $Fuentes.Count -lt 2) {
    throw "Una antologia requiere al menos dos relatos. Para compilar una sola obra usa /compilar dentro de ella."
}
foreach ($source in $Fuentes) {
    Assert-KebabSlug $source "Workspace"
}
if (($Fuentes | Sort-Object -Unique).Count -ne $Fuentes.Count) {
    throw "No puedes incluir el mismo workspace mas de una vez."
}

$sources = @()
foreach ($source in $Fuentes) {
    $workspacePath = Join-Path $WorkspacesRoot $source
    if (-not (Test-Path -LiteralPath $workspacePath -PathType Container)) {
        throw "Workspace '$source' no encontrado en $WorkspacesRoot."
    }

    $configPath = Join-Path $workspacePath "config.json"
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Workspace '$source' no contiene config.json."
    }

    $configRaw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    try {
        $config = $configRaw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Workspace '$source' tiene un config.json invalido. $_"
    }

    if ($config.estado -ne "finalizado") {
        throw "Workspace '$source' esta en estado '$($config.estado)'. /crear-libro solo admite fuentes finalizadas."
    }
    if ($config.tipo -ne "relato") {
        throw "Workspace '$source' tiene tipo '$($config.tipo)'. Una antologia solo admite relatos; una novela se compila con /compilar dentro de la obra."
    }

    $manuscriptName = "relato.md"
    $manuscriptPath = Join-Path $workspacePath $manuscriptName
    if (-not (Test-Path -LiteralPath $manuscriptPath -PathType Leaf)) {
        throw "Workspace '$source' no contiene $manuscriptName. Ejecuta /publicar antes de compilar."
    }

    $sources += [PSCustomObject]@{
        Slug = $source
        Config = $config
        ConfigPath = $configPath
        ConfigRaw = $configRaw
        ManuscriptPath = $manuscriptPath
        ManuscriptSha256 = Get-FileSha256 $manuscriptPath
        Title = if ($config.titulo) { $config.titulo } else { $source }
    }
}

New-Item -ItemType Directory -Force -Path $PublicadosRoot | Out-Null
$outputDir = Join-Path $PublicadosRoot $Libro
if (Test-Path -LiteralPath $outputDir) {
    throw "El libro '$Libro' ya existe en $outputDir. Usa recompilar-libro.ps1 para añadir o regenerar formatos."
}
$operationId = [guid]::NewGuid().ToString("N")
$stageDir = Join-Path $PublicadosRoot ".${Libro}.staging-$operationId"
$backupDir = Join-Path $PublicadosRoot ".${Libro}.backup-$operationId"
$updatedSources = @()
$published = $false

try {
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
    $bookMarkdown = Join-Path $stageDir "$Libro.md"
    $content = [System.Text.StringBuilder]::new()
    $content.Append("# $Titulo`n`n") | Out-Null
    $content.Append("## $Autor`n`n") | Out-Null

    foreach ($source in $sources) {
        Write-Host "Incluyendo: $($source.Title)"
        $content.Append((Get-Content -LiteralPath $source.ManuscriptPath -Raw -Encoding UTF8).Trim()) | Out-Null
        $content.Append("`n`n") | Out-Null
    }
    [System.IO.File]::WriteAllText($bookMarkdown, $content.ToString(), $utf8NoBom)

    if ($Epub) {
        & (Join-Path $BuildScripts "build-epub.ps1") -InputMarkdown $bookMarkdown -OutputEpub (Join-Path $stageDir "$Libro.epub") -Titulo $Titulo -Autor $Autor
    }
    if ($Pdf) {
        & (Join-Path $BuildScripts "build-pdf.ps1") -InputMarkdown $bookMarkdown -OutputPdf (Join-Path $stageDir "$Libro.pdf") -Titulo $Titulo -Autor $Autor -PdfFormat $PdfFormat -PdfEngine $PdfEngine
    }

    $artifacts = [ordered]@{
        markdown = [ordered]@{
            archivo = "$Libro.md"
            sha256 = Get-FileSha256 $bookMarkdown
        }
    }
    if ($Epub) {
        $epubPath = Join-Path $stageDir "$Libro.epub"
        $artifacts.epub = [ordered]@{
            archivo = "$Libro.epub"
            sha256 = Get-FileSha256 $epubPath
        }
    }
    if ($Pdf) {
        $pdfPath = Join-Path $stageDir "$Libro.pdf"
        $artifacts.pdf = [ordered]@{
            archivo = "$Libro.pdf"
            sha256 = Get-FileSha256 $pdfPath
            formato = $PdfFormat
            motor_solicitado = $PdfEngine
        }
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    $manifest = [ordered]@{
        schema_version = 1
        libro = $Libro
        titulo = $Titulo
        autor = $Autor
        tipo = "relato"
        creado = $timestamp
        actualizado = $timestamp
        fuentes = @(
            $sources | ForEach-Object {
                [ordered]@{
                    workspace = $_.Slug
                    manuscrito = [System.IO.Path]::GetFileName($_.ManuscriptPath)
                    sha256 = $_.ManuscriptSha256
                }
            }
        )
        artefactos = $artifacts
        historial_formatos = @(
            [ordered]@{
                fecha = $timestamp
                accion = "crear"
                formatos = @($artifacts.Keys)
            }
        )
    }
    [System.IO.File]::WriteAllText(
        (Join-Path $stageDir "manifest.json"),
        ($manifest | ConvertTo-Json -Depth 12),
        $utf8NoBom
    )

    # Update source states only after all requested artifacts have built successfully.
    foreach ($source in $sources) {
        $source.Config.estado = "publicado"
        $source.Config | Add-Member -NotePropertyName "ultima_modificacion" -NotePropertyValue $timestamp -Force
        Set-Content -LiteralPath $source.ConfigPath -Value ($source.Config | ConvertTo-Json -Depth 12) -Encoding UTF8
        $updatedSources += $source
    }

    if (Test-Path -LiteralPath $outputDir) {
        Move-Item -LiteralPath $outputDir -Destination $backupDir
    }
    try {
        Move-Item -LiteralPath $stageDir -Destination $outputDir
    } catch {
        if (Test-Path -LiteralPath $backupDir) {
            Move-Item -LiteralPath $backupDir -Destination $outputDir
        }
        throw
    }

    if (Test-Path -LiteralPath $backupDir) {
        try {
            Remove-Item -LiteralPath $backupDir -Recurse -Force
        } catch {
            Write-Warning "No se pudo eliminar la copia de seguridad temporal: $backupDir"
        }
    }
    $published = $true

    Write-Host ""
    Write-Host "=== Libro creado: $outputDir ==="
    Write-Host "  Markdown: $(Join-Path $outputDir "$Libro.md")"
    if ($Epub) { Write-Host "  EPUB:     $(Join-Path $outputDir "$Libro.epub")" }
    if ($Pdf) { Write-Host "  PDF:      $(Join-Path $outputDir "$Libro.pdf")" }
    Write-Host "  Manifiesto: $(Join-Path $outputDir "manifest.json")"
} catch {
    foreach ($source in $updatedSources) {
        Set-Content -LiteralPath $source.ConfigPath -Value $source.ConfigRaw -Encoding UTF8
    }
    throw
} finally {
    if (-not $published -and (Test-Path -LiteralPath $stageDir)) {
        Remove-Item -LiteralPath $stageDir -Recurse -Force
    }
    if (-not $published -and (Test-Path -LiteralPath $backupDir) -and -not (Test-Path -LiteralPath $outputDir)) {
        Move-Item -LiteralPath $backupDir -Destination $outputDir
    }
}
