# publicacion-regression.ps1 — Metadatos en frontmatter para libros, borradores y antologías (ADR 0038).
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

    # Antología del hub: frontmatter y un capítulo por relato, en raíces temporales.
    $env:FORJA_RESULTADOS = Join-Path $RunRoot "resultados"
    $env:FORJA_OBRAS = Join-Path $env:FORJA_RESULTADOS "Obras"
    $env:FORJA_PUBLICADOS = Join-Path $env:FORJA_RESULTADOS "Publicados"
    foreach ($r in @(@{ slug = "uno"; titulo = "Uno"; genero = "Erótica" }, @{ slug = "dos"; titulo = "Dos"; genero = "Erótica" })) {
        $obra = Join-Path $env:FORJA_OBRAS $r.slug
        Write-Utf8 (Join-Path $obra "config.json") (@{ slug = $r.slug; titulo = $r.titulo; tipo = "relato"; escala = "relato"; estado = "finalizado"; genero = $r.genero } | ConvertTo-Json)
        Write-Utf8 (Join-Path $obra "relato.md") "# $($r.titulo)`n`nTexto de $($r.slug).`n"
    }
    & (Join-Path $RepoRoot "scripts\crear-libro.ps1") -Libro "antologia" -Fuentes @("uno", "dos") -Titulo "Antología de prueba" | Out-Null
    $antologiaMd = Join-Path $env:FORJA_PUBLICADOS "antologia\antologia.md"
    $antologia = (Get-Content -LiteralPath $antologiaMd -Raw -Encoding UTF8) -replace "`r`n", "`n"
    Assert-True ($antologia -match '^---\ntitle: "Antología de prueba"\nauthor: "Amaro Alba"\nlang: "es"\ndate: "\d{4}-\d{2}-\d{2}"\nsubject: "Erótica"\n---\n\n# Uno\n\nTexto de uno\.\n\n# Dos\n') "crear-libro abre con frontmatter y cada relato es un capítulo"
    Assert-True ($antologia -notmatch '(?m)^## Amaro Alba') "crear-libro no pone el autor en el texto"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $env:FORJA_OBRAS "uno\config.json") | ConvertFrom-Json).estado -eq "publicado") "crear-libro publica las fuentes"

    # EPUB de un relato: metadatos del frontmatter, título oculto que nombra la entrada del índice, sin índice visible.
    $relatoMd = Join-Path $RunRoot "relato.md"
    Write-Utf8 $relatoMd ((New-FrontMatter (Get-ObraMetadatos -Config ([pscustomobject]@{ genero = "Erótica"; subgenero = "Drama" }) -Titulo "Relato (borrador)" -Autor "Amaro Alba")) + "`n`nPrimer párrafo.`n`n—Réplica —dice.`n")
    $relatoEpub = Join-Path $RunRoot "relato.epub"
    & (Join-Path $Scripts "build-epub.ps1") -InputMarkdown $relatoMd -OutputEpub $relatoEpub | Out-Null
    $opf = Read-EpubEntrada $relatoEpub "content.opf"
    Assert-True ($opf -match '<dc:title[^>]*>Relato \(borrador\)</dc:title>' -and $opf -match '<dc:language>es</dc:language>' -and $opf -match '<dc:creator[^>]*>Amaro Alba</dc:creator>' -and $opf -match 'Erótica · Drama') "EPUB de relato: título, idioma, autor y tema desde el frontmatter"
    $capitulos = Read-EpubEntrada $relatoEpub "ch001.xhtml"
    Assert-True ($capitulos -match '<h1[^>]*class="[^"]*titulo-oculto[^"]*"[^>]*>Relato \(borrador\)</h1>') "EPUB de relato: título oculto al inicio del texto"
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
