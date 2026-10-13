# borrador.ps1 -- Versión limpia de revisión del trabajo en curso (ADR 0028, 0036 y 0037).
# Prosa: relato completo desde relato-draft.md; en novela, un único capítulo (el
# indicado o el capítulo en curso), solo con sus escenas completas. Escribe en
# publicacion/borrador/prosa/.
# Guion (-Guion): los beats para revisión humana, con su etiqueta visual y su acción;
# -Anotado añade tono, extensión y notas. Relato completo; en novela, un capítulo (en
# multi-hilo, de capitulos/ o de un hilo con -Hilo). Escribe en publicacion/borrador/guion/.
# Nunca cambia el estado ni toca draft, guion o manuscrito.

param(
    [string]$Capitulo,
    [switch]$Guion,
    [switch]$Anotado,
    [string]$Hilo,
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

$Id = '[A-Za-z0-9][A-Za-z0-9_-]*'
# Estados de beat del guion: ✅ cerrado, ⬜ pendiente, 🔄 en curso.
$beatCerrado = [string][char]0x2705
$estadosBeat = (@($beatCerrado, [string][char]0x2B1C, [char]::ConvertFromUtf32(0x1F504)) | ForEach-Object { [regex]::Escape($_) }) -join '|'

function Read-Texto {
    param([string]$Path)
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8).TrimStart([char]0xFEFF) -replace "`r`n", "`n"
}

function Format-Prosa {
    # Retira lo que no es prosa y normaliza los saltos de párrafo.
    param([string]$Texto)

    # Un comentario que ocupa su línea se va con ella; si no, partiría el párrafo.
    $Texto = [regex]::Replace($Texto, '(?m)^[ \t]*<!--[^\n]*?-->[ \t]*(\n|$)', '')
    $Texto = [regex]::Replace($Texto, '(?s)<!--.*?-->', '')
    $Texto = [regex]::Replace($Texto, '[ \t]+\n', "`n")
    $Texto = [regex]::Replace($Texto, '\n{3,}', "`n`n")
    return $Texto.Trim()
}

function Get-RelatoBorrador {
    $draftPath = Join-Path $WorkspaceRoot "relato-draft.md"
    if (-not (Test-Path -LiteralPath $draftPath -PathType Leaf)) {
        throw "borrador: no existe relato-draft.md; todavía no hay prosa."
    }
    $draft = Read-Texto $draftPath
    $marcas = [regex]::Matches($draft, '(?m)^<!--\s*ESCENA\s+(E_\d{4})\s*:\s*(.*?)\s*\|\s*salida:\s*(continua|separador)\s*-->[ \t]*$')
    if ($marcas.Count -eq 0) {
        throw "borrador: relato-draft.md todavía no tiene escenas escritas."
    }

    $total = $null
    $guionPath = Join-Path $WorkspaceRoot "guion.md"
    if (Test-Path -LiteralPath $guionPath -PathType Leaf) {
        $total = [regex]::Matches((Read-Texto $guionPath), '(?m)^###\s+E_\d{4}\b').Count
    }

    # La salida describe cómo termina la escena: `separador` añade un corte tras
    # ella, salvo en la última incluida (mismo criterio que /publicar).
    $partes = @()
    for ($i = 0; $i -lt $marcas.Count; $i++) {
        $inicio = $marcas[$i].Index + $marcas[$i].Length
        $fin = if ($i + 1 -lt $marcas.Count) { $marcas[$i + 1].Index } else { $draft.Length }
        $cuerpo = $draft.Substring($inicio, $fin - $inicio)
        $cuerpo = [regex]::Replace($cuerpo, '(?m)^##\s+B_\d{4}\b.*$', '')
        $partes += Format-Prosa $cuerpo
        if ($marcas[$i].Groups[3].Value -eq "separador" -and $i -lt $marcas.Count - 1) {
            $partes += "---"
        }
    }

    $cobertura = if ($total) { "escenas escritas: $($marcas.Count) de $total" } else { "escenas escritas: $($marcas.Count)" }
    return [pscustomobject]@{
        Base = "$slug-borrador"
        Encabezado = ""
        Cuerpo = ($partes -join "`n`n")
        Cobertura = $cobertura
        Alcance = [ordered]@{
            escenas_incluidas = @($marcas | ForEach-Object { $_.Groups[1].Value })
            escenas_total = $total
        }
        Fuentes = @("relato-draft.md", "guion.md") | Where-Object { Test-Path -LiteralPath (Join-Path $WorkspaceRoot $_) }
    }
}

function Get-CapituloEstado {
    param([System.IO.DirectoryInfo]$Dir)

    $guionPath = Join-Path $Dir.FullName "guion.md"
    if (-not (Test-Path -LiteralPath $guionPath -PathType Leaf)) { return $null }
    $guion = Read-Texto $guionPath

    $nombre = $Dir.Name
    $titulo = [regex]::Match($guion, '(?m)^#\s+Cap[ií]tulo\s+\S+\s+[—-]\s+(.+?)\s*$')
    if ($titulo.Success) { $nombre = $titulo.Groups[1].Value }
    $numero = [int]([regex]::Match($Dir.Name, '^cap-(\d+)').Groups[1].Value)

    # Escenas del guion en orden; cada beat pertenece a la última escena declarada.
    $escenas = [System.Collections.Generic.List[object]]::new()
    $actual = $null
    $pendientes = $false
    foreach ($linea in $guion -split "`n") {
        $marca = [regex]::Match($linea, "^<!--\s*ESCENA\s+($Id)\s*:\s*([^|<>]+?)\s*(?:\|\s*hilo:\s*$Id\s*)?-->")
        if ($marca.Success) {
            $actual = [pscustomobject]@{ Id = $marca.Groups[1].Value; Nombre = $marca.Groups[2].Value.Trim(); Beats = 0; Cerrados = 0 }
            $escenas.Add($actual)
            continue
        }
        $beat = [regex]::Match($linea, "^(?:[-*]\s+)?($estadosBeat)\s+(?:B_\d+\s*$([char]0x00B7)\s*)?$Id\s+\[\d+\]")
        if ($beat.Success) {
            if ($beat.Groups[1].Value -ne $beatCerrado) { $pendientes = $true }
            if ($actual) {
                $actual.Beats++
                if ($beat.Groups[1].Value -eq $beatCerrado) { $actual.Cerrados++ }
            }
        }
    }

    # Prosa de cada escena presente en el draft.
    $prosa = @{}
    $draftPath = Join-Path $Dir.FullName "draft.md"
    if (Test-Path -LiteralPath $draftPath -PathType Leaf) {
        $draft = Read-Texto $draftPath
        $marcas = [regex]::Matches($draft, "(?m)^<!--\s*ESCENA\s+($Id)\s*:[^\n]*-->[ \t]*$")
        for ($i = 0; $i -lt $marcas.Count; $i++) {
            $inicio = $marcas[$i].Index + $marcas[$i].Length
            $fin = if ($i + 1 -lt $marcas.Count) { $marcas[$i + 1].Index } else { $draft.Length }
            $prosa[$marcas[$i].Groups[1].Value] = $draft.Substring($inicio, $fin - $inicio)
        }
    }

    $completas = @($escenas | Where-Object { $_.Beats -gt 0 -and $_.Cerrados -eq $_.Beats -and $prosa.ContainsKey($_.Id) })
    return [pscustomobject]@{
        Dir = $Dir
        Numero = $numero
        Nombre = $nombre
        Escenas = $escenas
        Prosa = $prosa
        Completas = $completas
        Pendientes = $pendientes
    }
}

function Format-EscenaNovela {
    param([string]$Texto)

    # Notas del escritor: bloque con encabezado propio o línea en cursiva.
    $Texto = [regex]::Replace($Texto, '(?ms)^#{2,4}[ \t]+Notas?[ \t]+del[ \t]+escritor\b.*?(?=^##[ \t]|\z)', '')
    $Texto = [regex]::Replace($Texto, '(?m)^\*Notas?[ \t]+del[ \t]+escritor:.*\*[ \t]*$', '')
    $Texto = [regex]::Replace($Texto, "(?m)^##[ \t]+$Id[ \t]+\[\d+\].*$", '')
    return Format-Prosa $Texto
}

function Get-NovelaBorrador {
    $capitulosDir = Join-Path $WorkspaceRoot "capitulos"
    if (-not (Test-Path -LiteralPath $capitulosDir -PathType Container)) {
        throw "borrador: no existe capitulos/; todavía no hay capítulos."
    }
    $capitulos = @(Get-ChildItem -LiteralPath $capitulosDir -Directory |
        Where-Object { $_.Name -match '^cap-\d+' } |
        Sort-Object { [int]([regex]::Match($_.Name, '^cap-(\d+)').Groups[1].Value) })

    if ([string]::IsNullOrWhiteSpace($Capitulo)) {
        # Capítulo en curso: el primero con beats pendientes y alguna escena
        # completa; si todos los que tienen escenas completas están cerrados, el último.
        $estados = @($capitulos | ForEach-Object { Get-CapituloEstado $_ } | Where-Object { $_ -and $_.Completas.Count -gt 0 })
        if ($estados.Count -eq 0) {
            throw "borrador: ningún capítulo tiene todavía escenas completas."
        }
        $estado = $estados | Where-Object { $_.Pendientes } | Select-Object -First 1
        if (-not $estado) { $estado = $estados[-1] }
    } else {
        $patron = if ($Capitulo -match '^\d+$') { "^cap-0*$([int]$Capitulo)(-|$)" } else { "^$([regex]::Escape($Capitulo))(-|$)" }
        $coincidencias = @($capitulos | Where-Object { $_.Name -match $patron })
        if ($coincidencias.Count -ne 1) {
            throw "borrador: '$Capitulo' no identifica un único capítulo en capitulos/."
        }
        $estado = Get-CapituloEstado $coincidencias[0]
        if (-not $estado) { throw "borrador: $($coincidencias[0].Name) no tiene guion.md." }
        if ($estado.Completas.Count -eq 0) {
            throw "borrador: $($estado.Dir.Name) no tiene escenas completas (0 de $($estado.Escenas.Count))."
        }
    }

    # Escenas completas en orden; un hueco anterior a la última incluida se señala.
    $ids = @($estado.Completas | ForEach-Object { $_.Id })
    $ultima = -1
    for ($i = 0; $i -lt $estado.Escenas.Count; $i++) { if ($ids -contains $estado.Escenas[$i].Id) { $ultima = $i } }
    $partes = @()
    $huecos = @()
    for ($i = 0; $i -le $ultima; $i++) {
        $escena = $estado.Escenas[$i]
        if ($ids -contains $escena.Id) {
            $partes += Format-EscenaNovela $estado.Prosa[$escena.Id]
        } else {
            $partes += "*[Escena pendiente: $($escena.Nombre)]*"
            $huecos += $escena.Id
        }
    }

    $relDir = "capitulos/$($estado.Dir.Name)"
    return [pscustomobject]@{
        Base = "$slug-cap-$('{0:D2}' -f $estado.Numero)-borrador"
        Encabezado = "# Capítulo $($estado.Numero) — $($estado.Nombre)"
        Cuerpo = ($partes -join "`n`n")
        Cobertura = "Capítulo $($estado.Numero) — $($estado.Nombre) · escenas completas: $($ids.Count) de $($estado.Escenas.Count)"
        Alcance = [ordered]@{
            capitulo = $estado.Dir.Name
            escenas_incluidas = $ids
            escenas_pendientes_intermedias = $huecos
            escenas_total = $estado.Escenas.Count
        }
        Fuentes = @("$relDir/draft.md", "$relDir/guion.md")
    }
}

function ConvertTo-GuionEscenas {
    # Escenas y beats de un guion, en orden. Una escena empieza con su marcador
    # <!-- ESCENA … --> (novela) o con su encabezado ### E_NNNN — Nombre (relato).
    param([string]$Texto)

    $escenas = [System.Collections.Generic.List[object]]::new()
    $actual = $null
    $soloMarcador = $false
    foreach ($linea in $Texto -split "`n") {
        $marca = [regex]::Match($linea, "^<!--\s*ESCENA\s+($Id)\s*:\s*([^|<>]+?)\s*(?:\|[^>]*)?-->")
        if ($marca.Success) {
            $actual = [pscustomobject]@{ Etiqueta = $null; Nombre = $marca.Groups[2].Value.Trim(); Datos = [System.Collections.Generic.List[string]]::new(); Beats = [System.Collections.Generic.List[object]]::new() }
            $escenas.Add($actual)
            $soloMarcador = $true
            continue
        }
        $cabecera = [regex]::Match($linea, '^###\s+(E_\d{4,})\s*[—-]\s*(.+?)\s*$')
        if ($cabecera.Success) {
            if ($actual -and $soloMarcador -and $actual.Beats.Count -eq 0) {
                $actual.Etiqueta = $cabecera.Groups[1].Value
                $actual.Nombre = $cabecera.Groups[2].Value
            } else {
                $actual = [pscustomobject]@{ Etiqueta = $cabecera.Groups[1].Value; Nombre = $cabecera.Groups[2].Value; Datos = [System.Collections.Generic.List[string]]::new(); Beats = [System.Collections.Generic.List[object]]::new() }
                $escenas.Add($actual)
            }
            $soloMarcador = $false
            continue
        }
        if (-not $actual) { continue }
        $beat = [regex]::Match($linea, "^\s*(?:[-*]\s+)?($estadosBeat)\s*(?:(B_\d{4,})(?:\s*$([char]0x00B7)\s*$Id)?|$Id)(?:\s+\[\d+\])?\s+[—-]\s+(.+?)\s*$")
        if ($beat.Success) {
            $actual.Beats.Add((ConvertTo-GuionBeat -Estado $beat.Groups[1].Value -Etiqueta $beat.Groups[2].Value -Resto $beat.Groups[3].Value))
            continue
        }
        # Datos de la escena (- Ubicación: …, **Objetivo:** …) antes de su primer beat.
        if ($actual.Beats.Count -eq 0 -and $linea -match '^\s*(?:-\s+[^:\n]{1,40}:\s+\S|\*\*[^*\n]{1,40}:?\*\*:?\s*\S)') {
            $actual.Datos.Add(($linea.Trim() -replace '^-\s+', ''))
        }
    }
    return $escenas
}

function ConvertTo-GuionBeat {
    # Separa la acción del beat de sus anotaciones: las etiquetas finales entre
    # corchetes (tono, personajes, zona, hilos, [elipsis]) y la literalidad ⚡.
    param([string]$Estado, [string]$Etiqueta, [string]$Resto)

    $etiquetas = [System.Collections.Generic.List[string]]::new()
    $accion = $Resto
    while ($true) {
        $final = [regex]::Match($accion, '\s*`?(\[[^\[\]]*\])`?\s*$')
        if (-not $final.Success -or $final.Index -eq 0) { break }
        $etiquetas.Insert(0, $final.Groups[1].Value)
        $accion = $accion.Substring(0, $final.Index)
    }
    $literal = "\s*$([char]0x26A1)\s*(?:`"[^`"]*`"|$([char]0x00AB)[^$([char]0x00BB)]*$([char]0x00BB)|$([char]0x201C)[^$([char]0x201D)]*$([char]0x201D))"
    return [pscustomobject]@{
        Cerrado = ($Estado -eq $beatCerrado)
        Etiqueta = $Etiqueta
        Accion = ([regex]::Replace($accion, $literal, '')).Trim()
        AccionLiteral = $accion.Trim()
        Etiquetas = $etiquetas.ToArray()
    }
}

function Format-GuionEscenas {
    param([object[]]$Escenas)

    $partes = @()
    foreach ($escena in $Escenas) {
        $partes += if ($escena.Etiqueta) { "## $($escena.Etiqueta) — $($escena.Nombre)" } else { "## $($escena.Nombre)" }
        if ($Anotado -and $escena.Datos.Count -gt 0) {
            $partes += (($escena.Datos | ForEach-Object { "*$($_ -replace '\*', '')*" }) -join "  `n")
        }
        foreach ($beat in $escena.Beats) {
            $texto = if ($Anotado) { $beat.AccionLiteral } else { $beat.Accion }
            if ($Anotado -and $beat.Etiquetas.Count -gt 0) { $texto += " · " + ($beat.Etiquetas -join " ") }
            $partes += if ($beat.Etiqueta) { "**$($beat.Etiqueta)** $texto" } else { $texto }
        }
    }
    return ($partes -join "`n`n")
}

function Get-GuionResumen {
    param([object[]]$Escenas)
    $beats = @($Escenas | ForEach-Object { $_.Beats } | Where-Object { $_ })
    return [pscustomobject]@{
        Escenas = $Escenas.Count
        Beats = $beats.Count
        Cerrados = @($beats | Where-Object { $_.Cerrado }).Count
        SinEtiqueta = @($beats | Where-Object { -not $_.Etiqueta }).Count
    }
}

function Get-CapitulosConGuion {
    param([string]$Raiz)
    if (-not (Test-Path -LiteralPath $Raiz -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $Raiz -Directory | Where-Object {
        $_.Name -match '^cap-\d+' -and (Test-Path -LiteralPath (Join-Path $_.FullName "guion.md") -PathType Leaf)
    } | Sort-Object { [int]([regex]::Match($_.Name, '^cap-(\d+)').Groups[1].Value) })
}

function Get-RelatoGuionBorrador {
    $guionPath = Join-Path $WorkspaceRoot "guion.md"
    if (-not (Test-Path -LiteralPath $guionPath -PathType Leaf)) {
        throw "borrador: no existe guion.md; todavía no hay guion."
    }
    $escenas = @(ConvertTo-GuionEscenas (Read-Texto $guionPath) | Where-Object { $_.Beats.Count -gt 0 })
    if ($escenas.Count -eq 0) { throw "borrador: guion.md todavía no tiene beats." }
    $resumen = Get-GuionResumen $escenas
    return [pscustomobject]@{
        Base = "$slug-guion$sufijoAnotado-borrador"
        Encabezado = ""
        Cuerpo = Format-GuionEscenas $escenas
        Cobertura = "guion completo · escenas: $($resumen.Escenas) · beats: $($resumen.Beats)"
        Alcance = [ordered]@{ escenas = $resumen.Escenas; beats = $resumen.Beats; beats_cerrados = $resumen.Cerrados; anotado = [bool]$Anotado }
        Fuentes = @("guion.md")
        SinEtiqueta = $resumen.SinEtiqueta
    }
}

function Get-NovelaGuionBorrador {
    # Capítulos con guion: los de capitulos/ o, en multi-hilo, los de un hilo.
    $capitulosDir = Join-Path $WorkspaceRoot "capitulos"
    $hilosDir = Join-Path $WorkspaceRoot "hilos"
    $hiloNombre = $null
    if (-not [string]::IsNullOrWhiteSpace($Hilo)) {
        $hiloNombre = if ($Hilo -like "hilo-*") { $Hilo } else { "hilo-$Hilo" }
        if (-not (Test-Path -LiteralPath (Join-Path $hilosDir $hiloNombre) -PathType Container)) { throw "borrador: no existe hilos/$hiloNombre." }
    } elseif ($esMultiHilo -and (Get-CapitulosConGuion $capitulosDir).Count -eq 0) {
        # Antes de ensamblar, los guiones viven en cada hilo.
        $hilos = @(if (Test-Path -LiteralPath $hilosDir -PathType Container) {
            Get-ChildItem -LiteralPath $hilosDir -Directory | Where-Object { (Get-CapitulosConGuion $_.FullName).Count -gt 0 } | Sort-Object Name
        })
        if ($hilos.Count -gt 1) {
            throw "borrador: los capítulos aún no están ensamblados; indica el hilo con --hilo ($(($hilos | ForEach-Object { $_.Name -replace '^hilo-', '' }) -join ', '))."
        }
        if ($hilos.Count -eq 1) { $hiloNombre = $hilos[0].Name }
    }
    $raiz = if ($hiloNombre) { Join-Path $hilosDir $hiloNombre } else { $capitulosDir }
    $relBase = if ($hiloNombre) { "hilos/$hiloNombre" } else { "capitulos" }
    $capitulos = Get-CapitulosConGuion $raiz
    if ($capitulos.Count -eq 0) { throw "borrador: ningún capítulo de $relBase/ tiene todavía guion.md." }

    if ([string]::IsNullOrWhiteSpace($Capitulo)) {
        # Capítulo en curso: el primero con beats pendientes; si todos están cerrados, el último.
        $pendiente = "(?m)^\s*(?:[-*]\s+)?(?:$([regex]::Escape([string][char]0x2B1C))|$([regex]::Escape([char]::ConvertFromUtf32(0x1F504))))"
        $elegido = $capitulos | Where-Object { (Read-Texto (Join-Path $_.FullName "guion.md")) -match $pendiente } | Select-Object -First 1
        if (-not $elegido) { $elegido = $capitulos[-1] }
    } else {
        $patron = if ($Capitulo -match '^\d+$') { "^cap-0*$([int]$Capitulo)(-|$)" } else { "^$([regex]::Escape($Capitulo))(-|$)" }
        $todos = @(if (Test-Path -LiteralPath $raiz -PathType Container) { Get-ChildItem -LiteralPath $raiz -Directory | Where-Object { $_.Name -match $patron } })
        if ($todos.Count -ne 1) { throw "borrador: '$Capitulo' no identifica un único capítulo en $relBase/." }
        $elegido = $capitulos | Where-Object { $_.FullName -eq $todos[0].FullName } | Select-Object -First 1
        if (-not $elegido) { throw "borrador: $relBase/$($todos[0].Name) no tiene guion.md." }
    }

    $texto = Read-Texto (Join-Path $elegido.FullName "guion.md")
    $numero = [int]([regex]::Match($elegido.Name, '^cap-(\d+)').Groups[1].Value)
    if ($hiloNombre) {
        $h1 = [regex]::Match($texto, '(?m)^#\s+(.+?)\s*$')
        $encabezado = "# $(if ($h1.Success) { $h1.Groups[1].Value } else { "$hiloNombre · $($elegido.Name)" })"
    } else {
        $titulo = [regex]::Match($texto, '(?m)^#\s+Cap[ií]tulo\s+\S+\s+[—-]\s+(.+?)\s*$')
        $encabezado = "# Capítulo $numero — $(if ($titulo.Success) { $titulo.Groups[1].Value } else { $elegido.Name })"
    }
    $escenas = @(ConvertTo-GuionEscenas $texto | Where-Object { $_.Beats.Count -gt 0 })
    if ($escenas.Count -eq 0) { throw "borrador: $relBase/$($elegido.Name) todavía no tiene beats." }
    $resumen = Get-GuionResumen $escenas
    $prefijo = if ($hiloNombre) { "$slug-$($hiloNombre -replace '^hilo-', '')" } else { $slug }
    return [pscustomobject]@{
        Base = "$prefijo-cap-$('{0:D2}' -f $numero)-guion$sufijoAnotado-borrador"
        Encabezado = $encabezado
        Cuerpo = Format-GuionEscenas $escenas
        Cobertura = "guion · $($encabezado.Substring(2)) · escenas: $($resumen.Escenas) · beats: $($resumen.Beats), $($resumen.Cerrados) escritos"
        Alcance = [ordered]@{ capitulo = $elegido.Name; hilo = $hiloNombre; escenas = $resumen.Escenas; beats = $resumen.Beats; beats_cerrados = $resumen.Cerrados; anotado = [bool]$Anotado }
        Fuentes = @("$relBase/$($elegido.Name)/guion.md")
        SinEtiqueta = $resumen.SinEtiqueta
    }
}

$obra = Read-ObraConfig -WorkspaceRoot $WorkspaceRoot
$config = $obra.Config
$slug = "$($config.slug)"
if ($config.tipo -notin @("relato", "novela")) {
    throw "borrador: tipo '$($config.tipo)' no soportado. Debe ser relato o novela."
}
$esMultiHilo = "$($config.escala)" -eq "novela-multi-hilo"
if (-not $Guion -and ($Anotado -or -not [string]::IsNullOrWhiteSpace($Hilo))) {
    throw "borrador: --anotado y --hilo solo se usan con --guion."
}
if (-not [string]::IsNullOrWhiteSpace($Hilo) -and -not $esMultiHilo) {
    throw "borrador: --hilo solo existe en novela multi-hilo."
}
if ($config.tipo -eq "relato" -and -not [string]::IsNullOrWhiteSpace($Capitulo)) {
    throw "borrador: un relato no tiene capítulos; ejecuta /borrador sin capítulo."
}
$sufijoAnotado = if ($Anotado) { "-anotado" } else { "" }
if ($Guion) {
    $borrador = if ($config.tipo -eq "novela") { Get-NovelaGuionBorrador } else { Get-RelatoGuionBorrador }
} else {
    $borrador = if ($config.tipo -eq "novela") { Get-NovelaBorrador } else { Get-RelatoBorrador }
}
if ([string]::IsNullOrWhiteSpace($Titulo)) {
    $Titulo = if ($config.titulo) { "$($config.titulo)" } else { $slug }
}

$fecha = (Get-Date).ToString("yyyy-MM-dd HH:mm")
$marca = if ($Guion) { "guion, borrador" } else { "borrador" }
$nota = "*Borrador del $fecha · $($borrador.Cobertura). No es el texto final.*"
$markdown = "# $Titulo ($marca)`n`n## $Autor`n`n$nota`n`n"
if ($borrador.Encabezado) { $markdown += "$($borrador.Encabezado)`n`n" }
$markdown += "$($borrador.Cuerpo)`n"

$borradorRoot = Join-Path $WorkspaceRoot "publicacion\borrador"
$outputDir = Join-Path $borradorRoot $(if ($Guion) { "guion" } else { "prosa" })
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$stageDir = Join-Path $outputDir (".tmp-" + [guid]::NewGuid().ToString("N"))
$base = $borrador.Base
try {
    New-Item -ItemType Directory -Path $stageDir | Out-Null
    $mdPath = Join-Path $stageDir "$base.md"
    [System.IO.File]::WriteAllText($mdPath, $markdown, $utf8NoBom)
    $artifacts = [ordered]@{ markdown = [ordered]@{ archivo = "$base.md"; sha256 = Get-FileSha256 $mdPath } }
    if ($Epub) {
        $epubPath = Join-Path $stageDir "$base.epub"
        & (Join-Path $PSScriptRoot "build-epub.ps1") -InputMarkdown $mdPath -OutputEpub $epubPath -Titulo "$Titulo ($marca)" -Autor $Autor
        $artifacts.epub = [ordered]@{ archivo = "$base.epub"; sha256 = Get-FileSha256 $epubPath }
    }
    if ($Pdf) {
        $pdfPath = Join-Path $stageDir "$base.pdf"
        & (Join-Path $PSScriptRoot "build-pdf.ps1") -InputMarkdown $mdPath -OutputPdf $pdfPath -Titulo "$Titulo ($marca)" -Autor $Autor -PdfFormat $PdfFormat -PdfEngine $PdfEngine
        $artifacts.pdf = [ordered]@{ archivo = "$base.pdf"; sha256 = Get-FileSha256 $pdfPath; formato = $PdfFormat; motor_solicitado = $PdfEngine }
    }

    $git = Get-GitEstado -WorkspaceRoot $WorkspaceRoot -Paths $borrador.Fuentes
    $manifest = [ordered]@{
        schema_version = 1
        tipo = $(if ($Guion) { "borrador-guion" } else { "borrador" })
        obra = $slug
        titulo = $Titulo
        generado = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        alcance = $borrador.Alcance
        fuentes = @($borrador.Fuentes | ForEach-Object { [ordered]@{ archivo = $_; sha256 = Get-FileSha256 (Join-Path $WorkspaceRoot $_) } })
        commit = $git.commit
        fuentes_sin_commit = $git.sin_commit
        artefactos = $artifacts
    }
    [System.IO.File]::WriteAllText((Join-Path $stageDir "$base.manifest.json"), ($manifest | ConvertTo-Json -Depth 12), $utf8NoBom)

    # El borrador anterior de este mismo alcance se sustituye entero: no quedan
    # formatos viejos junto a los nuevos.
    # También la versión suelta en publicacion/borrador/, anterior a la carpeta prosa/.
    foreach ($dir in @($outputDir, $borradorRoot)) {
        foreach ($ext in @("md", "epub", "pdf", "manifest.json")) {
            $previo = Join-Path $dir "$base.$ext"
            if (Test-Path -LiteralPath $previo) { Remove-Item -LiteralPath $previo -Force }
        }
    }
    # El .md es la fuente del EPUB/PDF: se conserva siempre. Con -Epub o -Pdf el
    # manifest es un fichero de trabajo y se elimina; sin ellos, se conserva.
    $soloFormatos = $Epub -or $Pdf
    Get-ChildItem -LiteralPath $stageDir -File | Where-Object {
        -not ($soloFormatos -and $_.Name -like "*.manifest.json")
    } | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $outputDir $_.Name)
    }

    Write-Host ""
    Write-Host "=== Borrador generado: $outputDir ==="
    Write-Host "  Alcance:  $($borrador.Cobertura)"
    Write-Host "  Markdown: $(Join-Path $outputDir "$base.md")"
    if ($Epub) { Write-Host "  EPUB:     $(Join-Path $outputDir "$base.epub")" }
    if ($Pdf) { Write-Host "  PDF:      $(Join-Path $outputDir "$base.pdf")" }
    if ($Guion -and $borrador.SinEtiqueta -gt 0) {
        Write-Host "  Aviso:    $($borrador.SinEtiqueta) beats sin etiqueta visual; ejecuta python -X utf8 scripts/etiquetas-guion.py"
    }
    Write-Host "  Estado:   sin cambios ($($config.estado))"
} finally {
    if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
}
