# build-epub.ps1 -- Markdown a EPUB con Pandoc (ADR 0038). Título, autor y demás
# metadatos salen del frontmatter YAML del Markdown (compilar.ps1, borrador.ps1,
# crear-libro.ps1); -Titulo y -Autor solo los sobrescriben. Un Markdown sin
# frontmatter, con la cabecera «# Título» + «## Autor» de antes, sigue siendo válido.
# -Portada es la imagen de cubierta del EPUB (imagenes/portada.jpg de la obra).
param(
    [Parameter(Mandatory = $true)]
    [string]$InputMarkdown,
    [Parameter(Mandatory = $true)]
    [string]$OutputEpub,
    [string]$Titulo,
    [string]$Autor,
    [string]$Portada
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "publicacion-comun.ps1")

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
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$OutputEpub = [System.IO.Path]::GetFullPath($OutputEpub)
$libro = Read-MarkdownLibro $InputMarkdown
$cuerpo = $libro.Cuerpo

# Cambio de escena: cada `---` del texto (párrafo propio) pasa a «* * *» centrado,
# como en el PDF; la línea fina de <hr> apenas se ve en un lector, y en modo
# oscuro desaparece. Estilo y sangría del párrafo siguiente: .separador en build.css.
$separador = "::: {.separador role=`"separator`"}`n\* \* \*`n:::"
$cuerpo = [regex]::Replace($cuerpo, '(?<=\A|\n[ \t]*\r?\n)---[ \t]*(?=\r?\n[ \t]*\r?\n|\s*\z)', $separador.Replace('$', '$$'))

# Pandoc abre cada capítulo del EPUB con un encabezado de nivel 1; si el texto no
# empieza con uno (un relato), inserta el título de la obra como encabezado visible
# justo después de la portada. Se pone uno propio con el título, oculto por la
# clase `titulo-oculto` de build.css: da nombre a la entrada del índice de
# navegación y el texto empieza con la prosa.
if ($cuerpo -notmatch '^#[ \t]+\S') {
    # Ojo: PowerShell no distingue mayúsculas; no reutilizar el nombre $Titulo.
    $tituloCapitulo = if (-not [string]::IsNullOrWhiteSpace($Titulo)) { $Titulo } else { $libro.Campos["title"] }
    if ([string]::IsNullOrWhiteSpace($tituloCapitulo)) { $tituloCapitulo = "Texto" }
    $tituloCapitulo = [regex]::Replace($tituloCapitulo, '([\\`*_{}\[\]<>#])', '\$1')
    $cuerpo = "# $tituloCapitulo {.unnumbered .titulo-oculto}`n`n$cuerpo"
}
$sourceText = if ($libro.FrontMatter) { "$($libro.FrontMatter)`n`n$cuerpo`n" } else { "$cuerpo`n" }

$preparedInput = Join-Path (Split-Path -Parent $OutputEpub) (".{0}.epub-source.md" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputEpub))
try {
    [System.IO.File]::WriteAllText($preparedInput, $sourceText, $utf8NoBom)

    $arguments = @(
        $preparedInput,
        "--from", "markdown",
        "--to", "epub",
        "-o", $OutputEpub
    )
    if (Test-LibroConCapitulos $libro.Cuerpo) { $arguments += "--toc", "--toc-depth=1" }
    if (-not [string]::IsNullOrWhiteSpace($Portada)) {
        if (-not (Test-Path -LiteralPath $Portada -PathType Leaf)) {
            throw "build-epub: no existe la imagen de portada: $Portada"
        }
        $arguments += "--epub-cover-image", (Resolve-Path -LiteralPath $Portada).Path
        # Las tiendas rechazan cubiertas pequeñas (imagenes/LEEME.md): se avisa, no se impide.
        $dimensiones = Get-DimensionesImagen $Portada
        if (-not $dimensiones) {
            Write-Host "Aviso: la portada no es un PNG o JPEG reconocible: $Portada"
        } elseif ($dimensiones.Ancho -lt 1000) {
            Write-Host "Aviso: la portada mide $($dimensiones.Ancho) × $($dimensiones.Alto) px; algunas tiendas rechazan menos de 1000 px de ancho (recomendado 1600 × 2560)."
        }
    }
    $arguments += @(Get-MetadatosPandoc -Libro $libro -Titulo $Titulo -Autor $Autor)
    $cssPath = Join-Path $PSScriptRoot "build.css"
    if (Test-Path -LiteralPath $cssPath -PathType Leaf) {
        $arguments += "--css", $cssPath
    }

    Write-Host "Generando EPUB..."
    $output = & $pandoc @arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputEpub -PathType Leaf)) {
        $logPath = Join-Path (Split-Path -Parent $OutputEpub) ("{0}.epub-build-error.log" -f [System.IO.Path]::GetFileNameWithoutExtension($OutputEpub))
        [System.IO.File]::WriteAllText($logPath, $output, $utf8NoBom)
        throw "build-epub: Pandoc no pudo generar el EPUB. Revisa $logPath"
    }
} finally {
    if (Test-Path -LiteralPath $preparedInput -PathType Leaf) {
        Remove-Item -LiteralPath $preparedInput -Force
    }
}
