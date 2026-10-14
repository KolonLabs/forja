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
    # El subtítulo es config.json.subtitulo (opcional): debe coincidir con la
    # cubierta, porque las tiendas comparan ambos.
    param($Config, [string]$Titulo, [string]$Autor)

    $temas = @("$($Config.genero)", "$($Config.subgenero)") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    return [ordered]@{
        title = $Titulo
        subtitle = "$($Config.subtitulo)"
        author = $Autor
        lang = "es"
        date = (Get-Date).ToString("yyyy-MM-dd")
        subject = ($temas -join " · ")
        identifier = New-IdentificadorObra "forja:obra:$($Config.slug)"
    }
}

function New-IdentificadorObra {
    # URN estable (UUID v5 de RFC 4122, espacio URL) derivado de una clave fija: el
    # slug de la obra o el alcance de un borrador. Pandoc genera un UUID aleatorio en
    # cada EPUB y el lector tomaría cada recompilación por un libro distinto.
    param([string]$Clave)

    $ns = ([guid]"6ba7b811-9dad-11d1-80b4-00c04fd430c8").ToByteArray()
    # Guid.ToByteArray invierte los tres primeros campos; RFC 4122 usa orden de red.
    [Array]::Reverse($ns, 0, 4); [Array]::Reverse($ns, 4, 2); [Array]::Reverse($ns, 6, 2)
    $hash = [System.Security.Cryptography.SHA1]::HashData([byte[]]($ns + [System.Text.Encoding]::UTF8.GetBytes($Clave)))
    $b = [byte[]]$hash[0..15]
    $b[6] = ($b[6] -band 0x0F) -bor 0x50
    $b[8] = ($b[8] -band 0x3F) -bor 0x80
    $hex = -join ($b | ForEach-Object { $_.ToString("x2") })
    return "urn:uuid:{0}-{1}-{2}-{3}-{4}" -f $hex.Substring(0, 8), $hex.Substring(8, 4), $hex.Substring(12, 4), $hex.Substring(16, 4), $hex.Substring(20, 12)
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

function Get-ImagenObra {
    # Imagen de la obra en imagenes/ (portada, contraportada…) en JPG o PNG: ruta
    # absoluta y relativa, o $null si no existe. imagenes/ se versiona con la obra;
    # publicacion/ no, porque su libro se regenera en cada compilación.
    param([string]$WorkspaceRoot, [string]$Nombre)

    foreach ($ext in @("jpg", "jpeg", "png")) {
        $relativa = "imagenes/$Nombre.$ext"
        $ruta = Join-Path $WorkspaceRoot $relativa
        if (Test-Path -LiteralPath $ruta -PathType Leaf) {
            return [pscustomobject]@{ Ruta = (Resolve-Path -LiteralPath $ruta).Path; Relativa = $relativa }
        }
    }
    return $null
}

function Get-DimensionesImagen {
    # Ancho y alto en píxeles de un PNG (cabecera IHDR) o un JPEG (primer marcador
    # SOF), sin dependencias; $null si no reconoce el formato.
    param([string]$Path)

    $b = [System.IO.File]::ReadAllBytes($Path)
    if ($b.Length -ge 24 -and $b[0] -eq 0x89 -and $b[1] -eq 0x50 -and $b[2] -eq 0x4E -and $b[3] -eq 0x47) {
        $ancho = ([int]$b[16] -shl 24) -bor ([int]$b[17] -shl 16) -bor ([int]$b[18] -shl 8) -bor [int]$b[19]
        $alto = ([int]$b[20] -shl 24) -bor ([int]$b[21] -shl 16) -bor ([int]$b[22] -shl 8) -bor [int]$b[23]
        return [pscustomobject]@{ Ancho = $ancho; Alto = $alto }
    }
    if ($b.Length -ge 4 -and $b[0] -eq 0xFF -and $b[1] -eq 0xD8) {
        $i = 2
        while ($i + 9 -lt $b.Length) {
            if ($b[$i] -ne 0xFF) { $i++; continue }
            $marca = $b[$i + 1]
            if ($marca -eq 0xFF) { $i++; continue }
            # SOF0–SOF15, salvo DHT (C4), JPG (C8) y DAC (CC): alto y ancho del fotograma.
            if ($marca -ge 0xC0 -and $marca -le 0xCF -and $marca -notin @(0xC4, 0xC8, 0xCC)) {
                return [pscustomobject]@{ Ancho = ([int]$b[$i + 7] -shl 8) -bor [int]$b[$i + 8]; Alto = ([int]$b[$i + 5] -shl 8) -bor [int]$b[$i + 6] }
            }
            if ($marca -eq 0xD8 -or $marca -eq 0x01 -or ($marca -ge 0xD0 -and $marca -le 0xD7)) { $i += 2; continue }
            $i += 2 + (([int]$b[$i + 2] -shl 8) -bor [int]$b[$i + 3])
        }
    }
    return $null
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
