# crear-libro.ps1 -- Ensambla libros desde workspaces publicados de Forja.

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
$ForjaRoot = Split-Path -Parent $PSScriptRoot
$WorkspacesRoot = Join-Path $ForjaRoot "workspaces"
$PublicadosRoot = Join-Path $ForjaRoot "publicados"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Assert-KebabSlug {
    param([string]$Value, [string]$Name)

    if ($Value -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        throw "$Name '$Value' invalido. Debe ser un slug kebab-case."
    }
}

function Find-Pandoc {
    $command = Get-Command pandoc -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        if ($command.Path) { return $command.Path }
        if ($command.Source) { return $command.Source }
    }

    foreach ($candidate in @(
        $env:PANDOC_PATH,
        $env:PANDOC,
        "C:\Program Files\Pandoc\pandoc.exe",
        "C:\Program Files (x86)\Pandoc\pandoc.exe",
        "$env:LOCALAPPDATA\Programs\Pandoc\pandoc.exe",
        "$env:LOCALAPPDATA\Pandoc\pandoc.exe",
        "C:\ProgramData\chocolatey\bin\pandoc.exe",
        "$env:USERPROFILE\scoop\shims\pandoc.exe"
    )) {
        if (-not $candidate) { continue }
        $resolved = Resolve-Path -LiteralPath $candidate -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.Path }
    }

    throw "No se encontro Pandoc. Instala Pandoc o define PANDOC_PATH."
}

function Invoke-EpubBuild {
    param([string]$InputPath, [string]$OutputPath)

    $pandoc = Find-Pandoc
    $arguments = @(
        $InputPath,
        "--from", "markdown",
        "--to", "epub",
        "--metadata", "title=$Titulo",
        "--metadata", "author=$Autor",
        "--metadata", "lang=es",
        "--toc", "--toc-depth=1",
        "-o", $OutputPath
    )
    $cssPath = Join-Path $PSScriptRoot "build.css"
    if (Test-Path -LiteralPath $cssPath -PathType Leaf) {
        $arguments += "--css", $cssPath
    }

    Write-Host "Generando EPUB..."
    $output = & $pandoc @arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
        $logPath = Join-Path (Split-Path -Parent $OutputPath) ("{0}.epub-build-error.log" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputPath))
        [System.IO.File]::WriteAllText($logPath, $output, $utf8NoBom)
        throw "Pandoc no pudo generar el EPUB. Revisa $logPath"
    }
}

Assert-KebabSlug $Libro "Libro"
if (-not $Fuentes -or $Fuentes.Count -eq 0) {
    throw "Debes indicar al menos un workspace fuente."
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
        throw "Workspace '$source' no encontrado."
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

    if ($config.estado -notin @("publicacion", "publicado")) {
        throw "Workspace '$source' esta en estado '$($config.estado)'. Ejecuta /publicar antes de compilar."
    }
    if ($config.tipo -notin @("relato", "novela")) {
        throw "Workspace '$source' tiene tipo '$($config.tipo)' no soportado. Debe ser relato o novela."
    }

    $manuscriptName = if ($config.tipo -eq "novela") { "novela.md" } else { "relato.md" }
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
        Title = if ($config.titulo) { $config.titulo } else { $source }
    }
}

$sourceTypes = @($sources | ForEach-Object { $_.Config.tipo } | Sort-Object -Unique)
if ($sourceTypes.Count -ne 1) {
    throw "No puedes mezclar relatos y novelas en el mismo libro."
}
if ($sourceTypes[0] -eq "novela" -and $sources.Count -ne 1) {
    throw "Un libro de novela requiere exactamente un workspace fuente. Para una antologia usa solo relatos."
}

New-Item -ItemType Directory -Force -Path $PublicadosRoot | Out-Null
$outputDir = Join-Path $PublicadosRoot $Libro
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
        Invoke-EpubBuild -InputPath $bookMarkdown -OutputPath (Join-Path $stageDir "$Libro.epub")
    }
    if ($Pdf) {
        & (Join-Path $PSScriptRoot "build-pdf.ps1") -InputMarkdown $bookMarkdown -OutputPdf (Join-Path $stageDir "$Libro.pdf") -Titulo $Titulo -Autor $Autor -PdfFormat $PdfFormat -PdfEngine $PdfEngine
    }

    # Update source states only after all requested artifacts have built successfully.
    foreach ($source in $sources) {
        if ($source.Config.estado -eq "publicacion") {
            $source.Config.estado = "publicado"
            $source.Config.ultima_modificacion = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            Set-Content -LiteralPath $source.ConfigPath -Value ($source.Config | ConvertTo-Json -Depth 12) -Encoding UTF8
            $updatedSources += $source
        }
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
