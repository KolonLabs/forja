# recompilar-libro.ps1 -- Regenera formatos desde un libro ya publicado.

param(
    [Parameter(Mandatory = $true)]
    [string]$Libro,
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
$PublicadosRoot = Get-PublicadosRoot
$BuildScripts = Join-Path $HubRoot "shared\scripts"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Assert-KebabSlug {
    param([string]$Value)

    if ($Value -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        throw "Libro '$Value' invalido. Debe ser un slug kebab-case."
    }
}

function Get-FileSha256 {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

Assert-KebabSlug $Libro
if (-not $Epub -and -not $Pdf) {
    throw "Indica al menos una salida: -Epub y/o -Pdf."
}

$outputDir = Join-Path $PublicadosRoot $Libro
$manifestPath = Join-Path $outputDir "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "No existe manifest.json para '$Libro'. Solo se pueden recompilar libros creados por /crear-libro."
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "El manifiesto de '$Libro' no es valido. $_"
}
if ($manifest.libro -ne $Libro -or -not $manifest.titulo -or -not $manifest.autor -or -not $manifest.artefactos -or -not $manifest.artefactos.markdown -or -not $manifest.historial_formatos) {
    throw "El manifiesto de '$Libro' no contiene los metadatos requeridos."
}

$markdownPath = Join-Path $outputDir "$Libro.md"
if (-not (Test-Path -LiteralPath $markdownPath -PathType Leaf)) {
    throw "El libro '$Libro' no contiene su Markdown congelado: $markdownPath"
}
if (-not $manifest.artefactos.markdown.sha256 -or (Get-FileSha256 $markdownPath) -ne $manifest.artefactos.markdown.sha256) {
    throw "El Markdown congelado de '$Libro' no coincide con el hash del manifiesto. Crea una nueva edición; no recompiles una fuente modificada."
}

$operationId = [guid]::NewGuid().ToString("N")
$stageDir = Join-Path $PublicadosRoot ".${Libro}.recompilando-$operationId"
$backupDir = Join-Path $PublicadosRoot ".${Libro}.backup-$operationId"
$completed = $false

try {
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
    Get-ChildItem -LiteralPath $outputDir -Force | Copy-Item -Destination $stageDir -Recurse -Force
    $stageMarkdown = Join-Path $stageDir "$Libro.md"

    if ($Epub) {
        $epubPath = Join-Path $stageDir "$Libro.epub"
        & (Join-Path $BuildScripts "build-epub.ps1") -InputMarkdown $stageMarkdown -OutputEpub $epubPath -Titulo $manifest.titulo -Autor $manifest.autor
        $manifest.artefactos | Add-Member -NotePropertyName "epub" -NotePropertyValue ([ordered]@{
            archivo = "$Libro.epub"
            sha256 = Get-FileSha256 $epubPath
        }) -Force
    }
    if ($Pdf) {
        $pdfPath = Join-Path $stageDir "$Libro.pdf"
        & (Join-Path $BuildScripts "build-pdf.ps1") -InputMarkdown $stageMarkdown -OutputPdf $pdfPath -Titulo $manifest.titulo -Autor $manifest.autor -PdfFormat $PdfFormat -PdfEngine $PdfEngine
        $manifest.artefactos | Add-Member -NotePropertyName "pdf" -NotePropertyValue ([ordered]@{
            archivo = "$Libro.pdf"
            sha256 = Get-FileSha256 $pdfPath
            formato = $PdfFormat
            motor_solicitado = $PdfEngine
        }) -Force
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    $formats = @()
    if ($Epub) { $formats += "epub" }
    if ($Pdf) { $formats += "pdf" }
    $history = @($manifest.historial_formatos)
    $history += [PSCustomObject]@{
        fecha = $timestamp
        accion = "recompilar"
        formatos = $formats
    }
    $manifest.actualizado = $timestamp
    $manifest.historial_formatos = $history
    [System.IO.File]::WriteAllText(
        (Join-Path $stageDir "manifest.json"),
        ($manifest | ConvertTo-Json -Depth 12),
        $utf8NoBom
    )

    Move-Item -LiteralPath $outputDir -Destination $backupDir
    try {
        Move-Item -LiteralPath $stageDir -Destination $outputDir
    } catch {
        if (Test-Path -LiteralPath $backupDir) {
            Move-Item -LiteralPath $backupDir -Destination $outputDir
        }
        throw
    }
    if (Test-Path -LiteralPath $backupDir) {
        Remove-Item -LiteralPath $backupDir -Recurse -Force
    }
    $completed = $true

    Write-Host ""
    Write-Host "=== Libro recompilado: $outputDir ==="
    if ($Epub) { Write-Host "  EPUB: $(Join-Path $outputDir "$Libro.epub")" }
    if ($Pdf) { Write-Host "  PDF:  $(Join-Path $outputDir "$Libro.pdf")" }
} finally {
    if (-not $completed -and (Test-Path -LiteralPath $stageDir)) {
        Remove-Item -LiteralPath $stageDir -Recurse -Force
    }
    if (-not $completed -and (Test-Path -LiteralPath $backupDir) -and -not (Test-Path -LiteralPath $outputDir)) {
        Move-Item -LiteralPath $backupDir -Destination $outputDir
    }
}
