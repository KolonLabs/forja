# publicacion-regression.ps1 — Metadatos, portada e identificador de libros, borradores y antologías (ADR 0038 y 0040).
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-publicacion-regression-" + [guid]::NewGuid().ToString("N"))
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Scripts = Join-Path $RepoRoot "shared\scripts"

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message, [string]$Pattern)
    try { & $Action } catch {
        if ($Pattern -and $_.Exception.Message -notmatch $Pattern) { throw "ASSERT: $Message (mensaje inesperado: $($_.Exception.Message))" }
        return
    }
    throw "ASSERT: $Message"
}

function Read-EpubEntrada {
    # Texto de una entrada del EPUB (un zip), buscada por el final de su ruta.
    param([string]$Epub, [string]$Sufijo)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Epub)
    try {
        $entradas = @($zip.Entries | Where-Object { $_.FullName -like "*$Sufijo" })
        $textos = foreach ($entrada in $entradas) {
            $lector = [System.IO.StreamReader]::new($entrada.Open())
            try { $lector.ReadToEnd() } finally { $lector.Dispose() }
        }
        return ($textos -join "`n")
    } finally { $zip.Dispose() }
}

$variables = @("FORJA_RESULTADOS", "FORJA_OBRAS", "FORJA_PUBLICADOS")
$entornoPrevio = @{}
foreach ($v in $variables) { $entornoPrevio[$v] = [Environment]::GetEnvironmentVariable($v) }

try {
    New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null
    . (Join-Path $Scripts "publicacion-comun.ps1")

    # Frontmatter: valores entrecomillados en una línea, escapados, sin campos vacíos.
    $fm = New-FrontMatter ([ordered]@{ title = "El «tío» `"Vicente`" \ I"; subtitle = $null; author = "Amaro`nAlba"; lang = "es" })
    Assert-True ($fm -ceq "---`ntitle: `"El «tío» \`"Vicente\`" \\ I`"`nauthor: `"Amaro Alba`"`nlang: `"es`"`n---") "New-FrontMatter escapa comillas y barras, une líneas y omite vacíos"

    $conFm = Join-Path $RunRoot "con-frontmatter.md"
    Write-Utf8 $conFm "$fm`n`nPrimer párrafo.`n"
    $libro = Read-MarkdownLibro $conFm
    Assert-True ($libro.FrontMatter -ceq $fm -and $libro.Campos["title"] -ceq "El «tío» `"Vicente`" \ I" -and $libro.Cuerpo -ceq "Primer párrafo.") "Read-MarkdownLibro separa el frontmatter y desescapa sus valores"
    $args1 = @(Get-MetadatosPandoc -Libro $libro)
    Assert-True ($args1.Count -eq 0) "con frontmatter e idioma, no hacen falta --metadata"
    $args2 = @(Get-MetadatosPandoc -Libro $libro -Titulo "Otro")
    Assert-True (($args2 -join "|") -ceq "--metadata|title=Otro") "-Titulo sobrescribe el título"

    $legado = Join-Path $RunRoot "legado.md"
    Write-Utf8 $legado "# Antología`n`n## Amaro Alba`n`n# Uno`n`nTexto uno.`n`n# Dos`n`nTexto dos.`n"
    $libroLegado = Read-MarkdownLibro $legado
    Assert-True (-not $libroLegado.FrontMatter -and $libroLegado.Campos["title"] -ceq "Antología" -and $libroLegado.Campos["author"] -ceq "Amaro Alba" -and $libroLegado.Cuerpo.StartsWith("# Uno")) "la cabecera antigua «# Título / ## Autor» pasa a metadatos y sale del cuerpo"
    Assert-True ((@(Get-MetadatosPandoc -Libro $libroLegado) -join "|") -ceq "--metadata|title=Antología|--metadata|author=Amaro Alba|--metadata|lang=es") "sin frontmatter: título, autor e idioma por --metadata"
    Assert-True ((Test-LibroConCapitulos $libroLegado.Cuerpo) -and -not (Test-LibroConCapitulos "# Capítulo 1`n`nTexto.") -and -not (Test-LibroConCapitulos "Texto.")) "índice solo con dos o más capítulos"

    # Identificador estable (UUID v5, espacio URL; valores de referencia de Python uuid.uuid5) y subtítulo de la obra (ADR 0040).
    Assert-True ((New-IdentificadorObra "forja:obra:relato-prueba") -ceq "urn:uuid:e951ba97-8172-589b-91da-fe87b4bf4663" -and (New-IdentificadorObra "forja:libro:antologia") -ceq "urn:uuid:fb36b4db-d265-5a47-b766-bd206211425f") "New-IdentificadorObra es un UUID v5 estable"
    $configObra = [pscustomobject]@{ slug = "relato-prueba"; genero = "Erótica"; subgenero = "Drama"; subtitulo = "Primera entrega" }
    $meta = Get-ObraMetadatos -Config $configObra -Titulo "Relato" -Autor "Amaro Alba"
    Assert-True ($meta.subtitle -ceq "Primera entrega" -and $meta.identifier -ceq "urn:uuid:e951ba97-8172-589b-91da-fe87b4bf4663") "Get-ObraMetadatos toma config.json.subtitulo y el identificador de la obra"
    Assert-True ([string]::IsNullOrWhiteSpace((Get-ObraMetadatos -Config ([pscustomobject]@{ slug = "x" }) -Titulo "T" -Autor "A").subtitle)) "sin subtitulo en config.json no hay subtítulo"

    # Portada de prueba: PNG válido de 1 × 1 px (pequeño a propósito, para el aviso de tamaño).
    $portadaPng = Join-Path $RunRoot "portada.png"
    [System.IO.File]::WriteAllBytes($portadaPng, [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
    $dim = Get-DimensionesImagen $portadaPng
    Assert-True ($dim.Ancho -eq 1 -and $dim.Alto -eq 1) "Get-DimensionesImagen lee un PNG"
    Assert-True ($null -eq (Get-DimensionesImagen $conFm)) "Get-DimensionesImagen no reconoce lo que no es imagen"

    # Antología del hub: frontmatter y un capítulo por relato, en raíces temporales.
    $env:FORJA_RESULTADOS = Join-Path $RunRoot "resultados"
    $env:FORJA_OBRAS = Join-Path $env:FORJA_RESULTADOS "Obras"
    $env:FORJA_PUBLICADOS = Join-Path $env:FORJA_RESULTADOS "Publicados"
    foreach ($r in @(@{ slug = "uno"; titulo = "Uno"; genero = "Erótica" }, @{ slug = "dos"; titulo = "Dos"; genero = "Erótica" })) {
        $obra = Join-Path $env:FORJA_OBRAS $r.slug
        Write-Utf8 (Join-Path $obra "config.json") (@{ slug = $r.slug; titulo = $r.titulo; tipo = "relato"; escala = "relato"; estado = "finalizado"; genero = $r.genero } | ConvertTo-Json)
        Write-Utf8 (Join-Path $obra "relato.md") "# $($r.titulo)`n`nTexto de $($r.slug).`n"
    }
    $salidaLibro = & (Join-Path $RepoRoot "scripts\crear-libro.ps1") -Libro "antologia" -Fuentes @("uno", "dos") -Titulo "Antología de prueba" -Epub -Portada $portadaPng 6>&1 | Out-String
    $libroDir = Join-Path $env:FORJA_PUBLICADOS "antologia"
    $antologiaMd = Join-Path $libroDir "antologia.md"
    $antologia = (Get-Content -LiteralPath $antologiaMd -Raw -Encoding UTF8) -replace "`r`n", "`n"
    Assert-True ($antologia -match '^---\ntitle: "Antología de prueba"\nauthor: "Amaro Alba"\nlang: "es"\ndate: "\d{4}-\d{2}-\d{2}"\nsubject: "Erótica"\nidentifier: "urn:uuid:fb36b4db-d265-5a47-b766-bd206211425f"\n---\n\n# Uno\n\nTexto de uno\.\n\n# Dos\n') "crear-libro abre con frontmatter, identificador estable y un capítulo por relato"
    Assert-True ($antologia -notmatch '(?m)^## Amaro Alba') "crear-libro no pone el autor en el texto"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $env:FORJA_OBRAS "uno\config.json") | ConvertFrom-Json).estado -eq "publicado") "crear-libro publica las fuentes"

    # Portada de la antología: congelada en el libro con su hash, en el EPUB y con aviso por tamaño.
    $manifiestoLibro = Get-Content -Raw -LiteralPath (Join-Path $libroDir "manifest.json") | ConvertFrom-Json
    Assert-True ($manifiestoLibro.portada.archivo -eq "portada.png" -and $manifiestoLibro.portada.sha256 -eq (Get-FileSha256 (Join-Path $libroDir "portada.png"))) "crear-libro congela la portada y su hash"
    Assert-True ((Read-EpubEntrada (Join-Path $libroDir "antologia.epub") "content.opf") -match 'cover-image' -and (Read-EpubEntrada (Join-Path $libroDir "antologia.epub") "content.opf") -match 'urn:uuid:fb36b4db-d265-5a47-b766-bd206211425f') "EPUB de antología: cubierta e identificador estable"
    Assert-True ($salidaLibro -match 'Aviso: la portada mide 1 × 1 px') "build-epub avisa de una portada pequeña"
    $salidaRecompilar = & (Join-Path $RepoRoot "scripts\recompilar-libro.ps1") -Libro "antologia" -Epub 6>&1 | Out-String
    Assert-True ((Read-EpubEntrada (Join-Path $libroDir "antologia.epub") "content.opf") -match 'cover-image' -and $salidaRecompilar -match 'Portada:') "recompilar-libro reutiliza la portada congelada"
    Assert-Throws { & (Join-Path $RepoRoot "scripts\recompilar-libro.ps1") -Libro "antologia" -Pdf -Portada $portadaPng | Out-Null } "recompilar-libro exige -Epub para cambiar la portada" "exige regenerar el EPUB"
    [System.IO.File]::WriteAllBytes((Join-Path $libroDir "portada.png"), [byte[]](1, 2, 3))
    Assert-Throws { & (Join-Path $RepoRoot "scripts\recompilar-libro.ps1") -Libro "antologia" -Epub | Out-Null } "recompilar-libro rechaza una portada congelada alterada" "no coincide con el hash"
    & (Join-Path $RepoRoot "scripts\recompilar-libro.ps1") -Libro "antologia" -Epub -Portada $portadaPng 6>&1 | Out-Null
    $manifiestoLibro = Get-Content -Raw -LiteralPath (Join-Path $libroDir "manifest.json") | ConvertFrom-Json
    Assert-True ($manifiestoLibro.portada.sha256 -eq (Get-FileSha256 $portadaPng) -and (Get-FileSha256 (Join-Path $libroDir "portada.png")) -eq (Get-FileSha256 $portadaPng)) "recompilar-libro -Portada sustituye la portada y su hash"

    # EPUB de un relato: metadatos del frontmatter, título oculto que nombra la entrada del índice, sin índice visible.
    $relatoMd = Join-Path $RunRoot "relato.md"
    Write-Utf8 $relatoMd ((New-FrontMatter (Get-ObraMetadatos -Config ([pscustomobject]@{ slug = "relato-prueba"; genero = "Erótica"; subgenero = "Drama" }) -Titulo "Relato (borrador)" -Autor "Amaro Alba")) + "`n`nPrimer párrafo.`n`n---`n`n—Réplica —dice.`n")
    $relatoEpub = Join-Path $RunRoot "relato.epub"
    & (Join-Path $Scripts "build-epub.ps1") -InputMarkdown $relatoMd -OutputEpub $relatoEpub | Out-Null
    $opf = Read-EpubEntrada $relatoEpub "content.opf"
    Assert-True ($opf -match '<dc:title[^>]*>Relato \(borrador\)</dc:title>' -and $opf -match '<dc:language>es</dc:language>' -and $opf -match '<dc:creator[^>]*>Amaro Alba</dc:creator>' -and $opf -match 'Erótica · Drama') "EPUB de relato: título, idioma, autor y tema desde el frontmatter"
    $capitulos = Read-EpubEntrada $relatoEpub "ch001.xhtml"
    Assert-True ($capitulos -match '<h1[^>]*class="[^"]*titulo-oculto[^"]*"[^>]*>Relato \(borrador\)</h1>') "EPUB de relato: título oculto al inicio del texto"
    Assert-True ($capitulos -match '<div class="separador" role="separator">\s*<p>\* \* \*</p>' -and $capitulos -notmatch '<hr') "EPUB de relato: el cambio de escena es «* * *», no una línea <hr>"
    Assert-True ($opf -match 'urn:uuid:e951ba97-8172-589b-91da-fe87b4bf4663' -and $opf -notmatch 'cover-image') "EPUB de relato: identificador estable y sin cubierta si no se pide"
    Assert-True ((Read-EpubEntrada $relatoEpub "build.css") + (Read-EpubEntrada $relatoEpub "stylesheet1.css") -match 'h1\.titulo-oculto\s*\{\s*display:\s*none') "EPUB de relato: build.css oculta ese título"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $RunRoot ".relato.epub-source.md"))) "build-epub no deja su Markdown de trabajo"

    # EPUB de una antología congelada sin frontmatter: la cabecera antigua va a los metadatos, no al texto.
    $legadoEpub = Join-Path $RunRoot "legado.epub"
    & (Join-Path $Scripts "build-epub.ps1") -InputMarkdown $legado -OutputEpub $legadoEpub | Out-Null
    $opfLegado = Read-EpubEntrada $legadoEpub "content.opf"
    Assert-True ($opfLegado -match '<dc:title[^>]*>Antología</dc:title>' -and $opfLegado -match '<dc:creator[^>]*>Amaro Alba</dc:creator>' -and $opfLegado -match '<dc:language>es</dc:language>') "EPUB sin frontmatter: título, autor e idioma por defecto"
    $textoLegado = Read-EpubEntrada $legadoEpub ".xhtml"
    Assert-True ($textoLegado -notmatch '<h2[^>]*>Amaro Alba</h2>' -and $textoLegado -notmatch 'titulo-oculto">') "EPUB sin frontmatter: sin cabecera antigua en el texto ni título oculto"
    Assert-True ((Read-EpubEntrada $legadoEpub "nav.xhtml") -match '>Uno<' -and (Read-EpubEntrada $legadoEpub "nav.xhtml") -match '>Dos<') "EPUB de antología: un capítulo por relato en el índice"

    Write-Host "OK: publicacion-regression"
} finally {
    foreach ($v in $variables) { [Environment]::SetEnvironmentVariable($v, $entornoPrevio[$v]) }
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
