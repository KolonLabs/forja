# compilar.ps1 -- Compila el manuscrito de esta obra a libro (ADR 0026).
# Lee relato.md o novela.md y escribe publicacion/: Markdown del libro, EPUB y
# PDF opcionales y manifest.json. Solo si todas las salidas se generan asigna
# config.json.estado = "publicado". No modifica el manuscrito ni hace commits.
# En publicacion/ solo sustituye esos archivos; lo demás (borradores, audiolibro
# u otras salidas junto al libro) se conserva (ADR 0041).

param(
    [switch]$Epub,
    [switch]$Pdf,
    [ValidateSet("paperback", "paperback-5x8", "hardcover", "hardcover-9pt", "hardcover-6x9", "hardcover-6x9-9pt")]
    [string]$PdfFormat = "paperback",
    [ValidateSet("auto", "typst", "xelatex", "wkhtmltopdf")]
    [string]$PdfEngine = "auto",
    [string]$Titulo,
    [string]$Autor = "Amaro Alba"
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

. (Join-Path $PSScriptRoot "publicacion-comun.ps1")

$obraConfig = Read-ObraConfig -WorkspaceRoot $WorkspaceRoot
$configPath = $obraConfig.Path
$configRaw = $obraConfig.Raw
$config = $obraConfig.Config

if ($config.estado -notin @("finalizado", "publicado")) {
    throw "compilar: la obra está en estado '$($config.estado)'. Ejecuta /publicar hasta llegar a 'finalizado' antes de compilar."
}
if ($config.tipo -notin @("relato", "novela")) {
    throw "compilar: tipo '$($config.tipo)' no soportado. Debe ser relato o novela."
}
$slug = "$($config.slug)"

$manuscriptName = if ($config.tipo -eq "novela") { "novela.md" } else { "relato.md" }
$manuscriptPath = Join-Path $WorkspaceRoot $manuscriptName
if (-not (Test-Path -LiteralPath $manuscriptPath -PathType Leaf)) {
    throw "compilar: no existe $manuscriptName. Ejecuta /publicar antes de compilar."
}
$manuscript = Get-Content -LiteralPath $manuscriptPath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($manuscript)) {
    throw "compilar: $manuscriptName está vacío."
}

if ([string]::IsNullOrWhiteSpace($Titulo)) {
    $Titulo = if ($config.titulo) { "$($config.titulo)" } else { $slug }
}

$outputDir = Join-Path $WorkspaceRoot "publicacion"
$operationId = [guid]::NewGuid().ToString("N")
$stageDir = Join-Path $WorkspaceRoot ".publicacion-$operationId"
$previousDir = Join-Path $WorkspaceRoot ".publicacion-anterior-$operationId"
$configUpdated = $false
$completed = $false
$retirados = @()
$colocados = @()

try {
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

    # El manuscrito abre con «# <título>». En el libro, título y autor son
    # metadatos (frontmatter YAML), no texto: Pandoc los usa para la portada y los
    # metadatos del EPUB/PDF. Se retira ese primer encabezado para no duplicarlo.
    $body = [regex]::Replace($manuscript.TrimStart([char]0xFEFF), '^\s*# [^\r\n]+\r?\n', "").Trim()
    $bookMarkdown = Join-Path $stageDir "$slug.md"
    $frontMatter = New-FrontMatter (Get-ObraMetadatos -Config $config -Titulo $Titulo -Autor $Autor)
    [System.IO.File]::WriteAllText($bookMarkdown, "$frontMatter`n`n$body`n", $utf8NoBom)

    $artifacts = [ordered]@{
        markdown = [ordered]@{ archivo = "$slug.md"; sha256 = Get-FileSha256 $bookMarkdown }
    }
    # Cubierta del EPUB: imagenes/portada.jpg|png de la obra, si existe.
    $portada = Get-ImagenObra -WorkspaceRoot $WorkspaceRoot -Nombre "portada"
    if ($Epub) {
        $epubPath = Join-Path $stageDir "$slug.epub"
        $epubArgs = @{ InputMarkdown = $bookMarkdown; OutputEpub = $epubPath }
        if ($portada) { $epubArgs.Portada = $portada.Ruta }
        & (Join-Path $PSScriptRoot "build-epub.ps1") @epubArgs
        $artifacts.epub = [ordered]@{ archivo = "$slug.epub"; sha256 = Get-FileSha256 $epubPath }
    }
    if ($Pdf) {
        $pdfPath = Join-Path $stageDir "$slug.pdf"
        & (Join-Path $PSScriptRoot "build-pdf.ps1") -InputMarkdown $bookMarkdown -OutputPdf $pdfPath -PdfFormat $PdfFormat -PdfEngine $PdfEngine
        $artifacts.pdf = [ordered]@{ archivo = "$slug.pdf"; sha256 = Get-FileSha256 $pdfPath; formato = $PdfFormat; motor_solicitado = $PdfEngine }
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    $git = Get-GitEstado -WorkspaceRoot $WorkspaceRoot -Paths @($manuscriptName)
    $manifest = [ordered]@{
        schema_version = 1
        obra = $slug
        titulo = $Titulo
        autor = $Autor
        tipo = "$($config.tipo)"
        compilado = $timestamp
        manuscrito = [ordered]@{
            archivo = $manuscriptName
            sha256 = Get-FileSha256 $manuscriptPath
            commit = $git.commit
            sin_commit = $git.sin_commit
        }
        portada = $(if ($Epub -and $portada) { [ordered]@{ archivo = $portada.Relativa; sha256 = Get-FileSha256 $portada.Ruta } } else { $null })
        artefactos = $artifacts
    }
    [System.IO.File]::WriteAllText((Join-Path $stageDir "manifest.json"), ($manifest | ConvertTo-Json -Depth 12), $utf8NoBom)

    # El estado solo cambia cuando todas las salidas pedidas existen.
    $config.estado = "publicado"
    $config | Add-Member -NotePropertyName "ultima_modificacion" -NotePropertyValue $timestamp -Force
    [System.IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 12), $utf8NoBom)
    $configUpdated = $true

    # En publicacion/ solo se sustituye lo que genera este script, aunque no se
    # haya vuelto a pedir (un EPUB anterior sin -Epub). Lo demás no se mueve: los
    # borradores de revisión (ADR 0028) y lo que otras herramientas dejan junto
    # al libro, como el audiolibro (ADR 0030 y 0041).
    $propios = @("$slug.md", "$slug.epub", "$slug.pdf", "manifest.json")
    $manuscritoAnterior = $null
    $manifiestoAnterior = Join-Path $outputDir "manifest.json"
    if (Test-Path -LiteralPath $manifiestoAnterior -PathType Leaf) {
        try { $manuscritoAnterior = (Get-Content -LiteralPath $manifiestoAnterior -Raw -Encoding UTF8 | ConvertFrom-Json).manuscrito.sha256 } catch { }
    }
    New-Item -ItemType Directory -Force -Path $outputDir, $previousDir | Out-Null
    foreach ($nombre in $propios) {
        $anterior = Join-Path $outputDir $nombre
        if (Test-Path -LiteralPath $anterior) {
            Move-Item -LiteralPath $anterior -Destination (Join-Path $previousDir $nombre)
            $retirados += $nombre
        }
    }
    foreach ($nuevo in @(Get-ChildItem -LiteralPath $stageDir -File)) {
        Move-Item -LiteralPath $nuevo.FullName -Destination (Join-Path $outputDir $nuevo.Name)
        $colocados += $nuevo.Name
    }
    $completed = $true
    Remove-Item -LiteralPath $stageDir, $previousDir -Recurse -Force -ErrorAction SilentlyContinue
    $conservados = @(Get-ChildItem -LiteralPath $outputDir -Force | Where-Object { $_.Name -notin $propios -and $_.Name -ne "borrador" } | ForEach-Object Name)

    Write-Host ""
    Write-Host "=== Obra compilada: $outputDir ==="
    Write-Host "  Markdown:   $(Join-Path $outputDir "$slug.md")"
    if ($Epub) {
        Write-Host "  EPUB:       $(Join-Path $outputDir "$slug.epub")"
        if ($portada) { Write-Host "  Portada:    $($portada.Relativa)" }
        else { Write-Host "  Aviso:      EPUB sin portada; añade imagenes/portada.jpg (o .png) y vuelve a compilar." }
    }
    if ($Pdf) { Write-Host "  PDF:        $(Join-Path $outputDir "$slug.pdf")" }
    Write-Host "  Manifiesto: $(Join-Path $outputDir "manifest.json")"
    if ($conservados.Count -gt 0) {
        Write-Host "  Conservado: $($conservados -join ', ') (no lo genera /compilar)"
        if ($manuscritoAnterior -and $manuscritoAnterior -ne $manifest.manuscrito.sha256) {
            Write-Host "  Aviso:      el manuscrito ha cambiado desde la compilación anterior; lo conservado puede haberse quedado desfasado."
        }
    }
    Write-Host "  Estado:     publicado"
    if ($git.sin_commit) {
        Write-Host "  Aviso:      $manuscriptName tiene cambios sin commitear; el manifiesto no apunta a un commit que lo contenga."
    }
} catch {
    if ($configUpdated -and -not $completed) {
        [System.IO.File]::WriteAllText($configPath, $configRaw, $utf8NoBom)
    }
    throw
} finally {
    if (-not $completed) {
        # Deshace el intercambio: fuera lo colocado y de vuelta lo retirado.
        foreach ($nombre in $colocados) { Remove-Item -LiteralPath (Join-Path $outputDir $nombre) -Force -ErrorAction SilentlyContinue }
        foreach ($nombre in $retirados) { Move-Item -LiteralPath (Join-Path $previousDir $nombre) -Destination (Join-Path $outputDir $nombre) -Force }
        if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
        if (Test-Path -LiteralPath $previousDir) { Remove-Item -LiteralPath $previousDir -Recurse -Force }
    }
}
