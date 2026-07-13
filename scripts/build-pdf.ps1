param(
    [Parameter(Mandatory = $true)]
    [string]$InputMarkdown,
    [Parameter(Mandatory = $true)]
    [string]$OutputPdf,
    [Parameter(Mandatory = $true)]
    [string]$Titulo,
    [Parameter(Mandatory = $true)]
    [string]$Autor,
    [ValidateSet("paperback", "paperback-5x8", "hardcover", "hardcover-9pt", "hardcover-6x9", "hardcover-6x9-9pt")]
    [string]$PdfFormat = "paperback",
    [ValidateSet("auto", "typst", "xelatex", "wkhtmltopdf")]
    [string]$PdfEngine = "auto"
)

$ErrorActionPreference = "Stop"

function Find-Executable {
    param([string]$Name, [string[]]$Candidates = @())

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        if ($command.Path) { return $command.Path }
        if ($command.Source) { return $command.Source }
    }

    foreach ($candidate in $Candidates) {
        $resolved = Resolve-Path -LiteralPath $candidate -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.Path }
    }

    return $null
}

function Convert-InchesToMillimeters {
    param([string]$Value)

    $inches = [double]($Value -replace "in$", "")
    return [math]::Round($inches * 25.4, 2).ToString([System.Globalization.CultureInfo]::InvariantCulture)
}

if (-not (Test-Path -LiteralPath $InputMarkdown -PathType Leaf)) {
    throw "build-pdf: no existe el Markdown de entrada: $InputMarkdown"
}

$InputMarkdown = (Resolve-Path -LiteralPath $InputMarkdown).Path
$OutputPdf = [System.IO.Path]::GetFullPath($OutputPdf)
$OutputDir = Split-Path -Parent $OutputPdf
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$pandoc = Find-Executable "pandoc" @(
    $env:PANDOC_PATH,
    $env:PANDOC,
    "C:\Program Files\Pandoc\pandoc.exe",
    "C:\Program Files (x86)\Pandoc\pandoc.exe",
    "$env:LOCALAPPDATA\Programs\Pandoc\pandoc.exe",
    "$env:LOCALAPPDATA\Pandoc\pandoc.exe",
    "C:\ProgramData\chocolatey\bin\pandoc.exe",
    "$env:USERPROFILE\scoop\shims\pandoc.exe"
)
if (-not $pandoc) {
    throw "build-pdf: no se encontro Pandoc. Instala Pandoc o define PANDOC_PATH."
}

$engines = [ordered]@{
    typst = Find-Executable "typst" @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\typst.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Typst.Typst_Microsoft.Winget.Source_8wekyb3d8bbwe\typst.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Typst.Typst_Microsoft.Winget.Source_8wekyb3d8bbwe\typst-x86_64-pc-windows-msvc\typst.exe",
        "$env:ProgramFiles\typst\typst.exe"
    )
    xelatex = Find-Executable "xelatex" @(
        "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64\xelatex.exe",
        "C:\Program Files\MiKTeX\miktex\bin\x64\xelatex.exe",
        "C:\Program Files (x86)\MiKTeX\miktex\bin\xelatex.exe"
    )
    wkhtmltopdf = Find-Executable "wkhtmltopdf" @(
        "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe",
        "C:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe",
        "$env:LOCALAPPDATA\Programs\wkhtmltopdf\bin\wkhtmltopdf.exe"
    )
}

if ($PdfEngine -eq "auto") {
    # Mantener el orden de preferencia de Canida: Typst, wkhtmltopdf, XeLaTeX.
    $PdfEngine = @("typst", "wkhtmltopdf", "xelatex") | Where-Object { $engines[$_] } | Select-Object -First 1
}
if (-not $PdfEngine -or -not $engines[$PdfEngine]) {
    throw "build-pdf: no se encontro un motor PDF compatible. Instala Typst, MiKTeX/XeLaTeX o wkhtmltopdf."
}
$PdfEnginePath = $engines[$PdfEngine]

$formats = @{
    paperback = @{ Width = "6in"; Height = "9in"; Inner = "0.875in"; Outer = "0.5in"; Top = "0.5in"; Bottom = "0.5in"; FontSize = "9.5pt" }
    "paperback-5x8" = @{ Width = "5in"; Height = "8in"; Inner = "1in"; Outer = "0.375in"; Top = "0.35in"; Bottom = "0.45in"; FontSize = "10pt" }
    hardcover = @{ Width = "7in"; Height = "10in"; Inner = "1in"; Outer = "0.625in"; Top = "0.75in"; Bottom = "0.875in"; FontSize = "10pt" }
    "hardcover-9pt" = @{ Width = "7in"; Height = "10in"; Inner = "1in"; Outer = "0.625in"; Top = "0.75in"; Bottom = "0.875in"; FontSize = "9pt" }
    "hardcover-6x9" = @{ Width = "6in"; Height = "9in"; Inner = "1in"; Outer = "0.625in"; Top = "0.625in"; Bottom = "0.75in"; FontSize = "10pt" }
    "hardcover-6x9-9pt" = @{ Width = "6in"; Height = "9in"; Inner = "1in"; Outer = "0.625in"; Top = "0.625in"; Bottom = "0.75in"; FontSize = "9pt" }
}
$format = $formats[$PdfFormat]

# El Markdown combinado incluye título y autor para la lectura directa. La
# plantilla PDF genera su propia portada, así que se eliminan esos encabezados.
$sourceText = Get-Content -LiteralPath $InputMarkdown -Raw -Encoding UTF8
$sourceText = [regex]::Replace($sourceText, "^\\s*# [^\\r\\n]+\\r?\\n(?:\\r?\\n)*## [^\\r\\n]+\\r?\\n(?:\\r?\\n)*", "")
$preparedInput = Join-Path $OutputDir (".{0}.pdf-source.md" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputPdf))
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

try {
    [System.IO.File]::WriteAllText($preparedInput, $sourceText, $utf8NoBom)

    $pandocArgs = @(
        $preparedInput,
        "--from", "markdown",
        "--metadata", "title=$Titulo",
        "--metadata", "author=$Autor",
        "--metadata", "lang=es",
        "--toc", "--toc-depth=1",
        "-o", $OutputPdf
    )

    switch ($PdfEngine) {
        "typst" {
            $template = Join-Path $PSScriptRoot "templates\forja-kdp.typ"
            if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
                throw "build-pdf: falta la plantilla Typst: $template"
            }
            $pandocArgs += @(
                "--pdf-engine=$PdfEnginePath",
                "--template", $template,
                "-V", "page-width=$($format.Width)",
                "-V", "page-height=$($format.Height)",
                "-V", "inner-margin=$($format.Inner)",
                "-V", "outer-margin=$($format.Outer)",
                "-V", "top-margin=$($format.Top)",
                "-V", "bottom-margin=$($format.Bottom)",
                "-V", "font-size=$($format.FontSize)"
            )
        }
        "xelatex" {
            $pandocArgs += @(
                "--pdf-engine=$PdfEnginePath",
                "-V", "documentclass:book",
                "-V", "classoption:twoside,openright",
                "-V", "geometry:paperwidth=$($format.Width),paperheight=$($format.Height),top=$($format.Top),bottom=$($format.Bottom),inner=$($format.Inner),outer=$($format.Outer)",
                "-V", "fontsize=$($format.FontSize)",
                "-V", "mainfont=Georgia",
                "-V", "sansfont=Arial",
                "-V", "monofont=Courier New",
                "-V", "linestretch=1.25"
            )
        }
        "wkhtmltopdf" {
            $pandocArgs += @(
                "--pdf-engine=$PdfEnginePath",
                "--standalone",
                "--pdf-engine-opt=--page-width", "--pdf-engine-opt=$((Convert-InchesToMillimeters $format.Width) + 'mm')",
                "--pdf-engine-opt=--page-height", "--pdf-engine-opt=$((Convert-InchesToMillimeters $format.Height) + 'mm')",
                "--pdf-engine-opt=--margin-top", "--pdf-engine-opt=$((Convert-InchesToMillimeters $format.Top) + 'mm')",
                "--pdf-engine-opt=--margin-bottom", "--pdf-engine-opt=$((Convert-InchesToMillimeters $format.Bottom) + 'mm')",
                "--pdf-engine-opt=--margin-left", "--pdf-engine-opt=$((Convert-InchesToMillimeters $format.Inner) + 'mm')",
                "--pdf-engine-opt=--margin-right", "--pdf-engine-opt=$((Convert-InchesToMillimeters $format.Outer) + 'mm')",
                "--pdf-engine-opt=--enable-local-file-access"
            )
        }
    }

    Write-Host "Generando PDF ($PdfFormat, motor $PdfEngine)..."
    $output = & $pandoc @pandocArgs 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPdf -PathType Leaf)) {
        $logPath = Join-Path $OutputDir ("{0}.pdf-build-error.log" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputPdf))
        [System.IO.File]::WriteAllText($logPath, $output, $utf8NoBom)
        throw "build-pdf: Pandoc/$PdfEngine fallo. Revisa $logPath"
    }

    Write-Host "PDF generado: $OutputPdf"
} finally {
    if (Test-Path -LiteralPath $preparedInput -PathType Leaf) {
        Remove-Item -LiteralPath $preparedInput -Force
    }
}
