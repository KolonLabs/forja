param(
    [Parameter(Mandatory = $true)]
    [string]$InputMarkdown,
    [Parameter(Mandatory = $true)]
    [string]$OutputEpub,
    [Parameter(Mandatory = $true)]
    [string]$Titulo,
    [Parameter(Mandatory = $true)]
    [string]$Autor
)

$ErrorActionPreference = "Stop"

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

    throw "build-epub: no se encontro Pandoc. Instala Pandoc o define PANDOC_PATH."
}

if (-not (Test-Path -LiteralPath $InputMarkdown -PathType Leaf)) {
    throw "build-epub: no existe el Markdown de entrada: $InputMarkdown"
}

$pandoc = Find-Pandoc
$arguments = @(
    $InputMarkdown,
    "--from", "markdown",
    "--to", "epub",
    "--metadata", "title=$Titulo",
    "--metadata", "author=$Autor",
    "--metadata", "lang=es",
    "--toc", "--toc-depth=1",
    "-o", $OutputEpub
)
$cssPath = Join-Path $PSScriptRoot "build.css"
if (Test-Path -LiteralPath $cssPath -PathType Leaf) {
    $arguments += "--css", $cssPath
}

Write-Host "Generando EPUB..."
$output = & $pandoc @arguments 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputEpub -PathType Leaf)) {
    $logPath = Join-Path (Split-Path -Parent $OutputEpub) ("{0}.epub-build-error.log" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputEpub))
    [System.IO.File]::WriteAllText($logPath, $output, [System.Text.UTF8Encoding]::new($false))
    throw "build-epub: Pandoc no pudo generar el EPUB. Revisa $logPath"
}
