# publicacion-comun.ps1 -- Utilidades de compilar.ps1, borrador.ps1 y build-*.ps1
# (ADR 0026, 0028 y 0038): configuración, hashes, estado git y frontmatter de
# metadatos. Se carga con dot-sourcing; no se ejecuta por sí solo.

function Get-FileSha256 {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-ObraConfig {
    param([string]$WorkspaceRoot)

    $path = Join-Path $WorkspaceRoot "config.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Falta config.json en $WorkspaceRoot."
    }
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    try {
        $config = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "config.json no es válido. $_"
    }
    if ("$($config.slug)" -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        throw "config.json.slug '$($config.slug)' no es un slug kebab-case."
    }
    return [pscustomobject]@{ Path = $path; Raw = $raw; Config = $config }
}

function Get-ObraMetadatos {
    # Propiedades de la obra para el frontmatter del libro o del borrador. Los
    # campos son los que Pandoc usa en la portada y los metadatos del EPUB/PDF.
    param($Config, [string]$Titulo, [string]$Autor)

    $temas = @("$($Config.genero)", "$($Config.subgenero)") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    return [ordered]@{
        title = $Titulo
        subtitle = $null
        author = $Autor
        lang = "es"
        date = (Get-Date).ToString("yyyy-MM-dd")
        subject = ($temas -join " · ")
    }
}

function New-FrontMatter {
    # Bloque YAML al inicio del Markdown: Pandoc lo lee como metadatos (portada,
    # metadatos del EPUB/PDF) y los editores Markdown como propiedades, así que
    # título y autor no entran en el texto. Omite los campos vacíos.
    param([System.Collections.IDictionary]$Campos)

    $lineas = @("---")
    foreach ($clave in $Campos.Keys) {
        $valor = "$($Campos[$clave])"
        if ([string]::IsNullOrWhiteSpace($valor)) { continue }
        # Un salto de línea rompería el escalar: el valor va en una sola línea.
        $escapado = ($valor.Trim() -replace '\s+', ' ') -replace '\\', '\\' -replace '"', '\"'
        $lineas += "${clave}: `"$escapado`""
    }
    $lineas += "---"
    return ($lineas -join "`n")
}

function Read-MarkdownLibro {
    # Markdown de entrada de build-epub.ps1 y build-pdf.ps1: separa el frontmatter
    # del cuerpo y lee sus campos escalares. Sin frontmatter, reconoce la cabecera
    # «# Título» + «## Autor» de los libros anteriores al ADR 0038 (antologías ya
    # congeladas) y la retira del cuerpo para tratarla como metadatos.
    param([string]$Path)

    $texto = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8).TrimStart([char]0xFEFF)
    $campos = @{}
    $frontMatter = [regex]::Match($texto, '^---[ \t]*\r?\n(?s:.*?)\r?\n(?:---|\.\.\.)[ \t]*(?:\r?\n|$)')
    if ($frontMatter.Success) {
        foreach ($linea in [regex]::Matches($frontMatter.Value, '(?m)^([A-Za-z][\w-]*):[ \t]*(.*?)[ \t]*\r?$')) {
            $valor = $linea.Groups[2].Value
            $citado = [regex]::Match($valor, '^"((?:[^"\\]|\\.)*)"$')
            if ($citado.Success) { $valor = $citado.Groups[1].Value -replace '\\(.)', '$1' }
            $campos[$linea.Groups[1].Value] = $valor
        }
        return [pscustomobject]@{ FrontMatter = $frontMatter.Value.TrimEnd(); Campos = $campos; Cuerpo = $texto.Substring($frontMatter.Length).Trim() }
    }
    $cabecera = [regex]::Match($texto, '^\s*# ([^\r\n]+)\r?\n(?:[ \t]*\r?\n)*## ([^\r\n]+)\r?\n')
    if ($cabecera.Success) {
        $campos.title = $cabecera.Groups[1].Value.Trim()
        $campos.author = $cabecera.Groups[2].Value.Trim()
        return [pscustomobject]@{ FrontMatter = $null; Campos = $campos; Cuerpo = $texto.Substring($cabecera.Length).Trim() }
    }
    return [pscustomobject]@{ FrontMatter = $null; Campos = $campos; Cuerpo = $texto.Trim() }
}

function Get-MetadatosPandoc {
    # Argumentos --metadata de Pandoc, que prevalecen sobre el frontmatter: los
    # campos de una cabecera antigua, el idioma si el Markdown no lo declara (todo
    # Forja escribe en español) y las sobrescrituras -Titulo y -Autor.
    param($Libro, [string]$Titulo, [string]$Autor)

    $meta = [ordered]@{}
    if (-not $Libro.FrontMatter) {
        foreach ($clave in @("title", "author")) { if ($Libro.Campos[$clave]) { $meta[$clave] = $Libro.Campos[$clave] } }
    }
    if ([string]::IsNullOrWhiteSpace($Libro.Campos["lang"])) { $meta.lang = "es" }
    if (-not [string]::IsNullOrWhiteSpace($Titulo)) { $meta.title = $Titulo }
    if (-not [string]::IsNullOrWhiteSpace($Autor)) { $meta.author = $Autor }

    $argumentos = @()
    foreach ($clave in $meta.Keys) { $argumentos += "--metadata", "$clave=$($meta[$clave])" }
    return $argumentos
}

function Test-LibroConCapitulos {
    # El índice solo tiene sentido con dos o más capítulos (encabezados de nivel 1):
    # en un relato o en el borrador de un único capítulo sería una página de relleno.
    param([string]$Cuerpo)
    return ([regex]::Matches($Cuerpo, '(?m)^#[ \t]+\S').Count -ge 2)
}

function Get-GitEstado {
    # Commit de la obra y si alguno de los archivos indicados tiene cambios sin
    # commitear. Sin git o sin commits devuelve nulos: compilar no depende del historial.
    param([string]$WorkspaceRoot, [string[]]$Paths)

    $estado = [ordered]@{ commit = $null; sin_commit = $null }
    if (-not (Test-Path -LiteralPath (Join-Path $WorkspaceRoot ".git"))) { return $estado }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $estado }

    $commit = & git -C $WorkspaceRoot rev-parse --verify --quiet HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) { return $estado }
    $estado.commit = "$commit".Trim()
    $cambios = & git -C $WorkspaceRoot status --porcelain -- @Paths 2>$null
    $estado.sin_commit = -not [string]::IsNullOrWhiteSpace(($cambios | Out-String))
    return $estado
}
