# borrador-regression.ps1 — Borradores de revisión de relato y novela, de prosa y de guion (ADR 0028, 0036 y 0038).
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-borrador-regression-" + [guid]::NewGuid().ToString("N"))
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Ok = [string][char]0x2705
$Pend = [string][char]0x2B1C

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

function New-Obra {
    param([string]$Nombre, [hashtable]$Config)
    $dir = Join-Path $RunRoot $Nombre
    New-Item -ItemType Directory -Force -Path (Join-Path $dir "scripts") | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot "shared\scripts\*") -Destination (Join-Path $dir "scripts") -Recurse
    Write-Utf8 -Path (Join-Path $dir "config.json") -Content ($Config | ConvertTo-Json)
    return $dir
}

function Get-Cuerpo {
    # El texto tras el frontmatter de metadatos (ADR 0038).
    param([string]$Path)
    $texto = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8) -replace "`r`n", "`n"
    if ($texto -notmatch '^---\n') { throw "ASSERT: $Path no abre con frontmatter" }
    return ($texto -replace '(?s)^---\n.*?\n---\n', '').Trim()
}

function Get-Campo {
    # Valor de un campo del frontmatter (todos van entrecomillados).
    param([string]$Path, [string]$Campo)
    $m = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), "(?m)^${Campo}: `"(.*)`"\r?$")
    if ($m.Success) { return $m.Groups[1].Value } else { return $null }
}

try {
    # Relato: toda la prosa confirmada; `separador` corta tras la escena salvo la última.
    $relato = New-Obra "relato" @{ slug = "relato-prueba"; titulo = "Relato de prueba"; tipo = "relato"; escala = "relato"; estado = "escritura" }
    Write-Utf8 -Path (Join-Path $relato "guion.md") -Content "# Guion`n`n### E_0001 — Uno`n`n### E_0002 — Dos`n`n### E_0003 — Tres`n`n### E_0004 — Cuatro`n"
    Write-Utf8 -Path (Join-Path $relato "relato-draft.md") -Content @'
# Draft — Relato de prueba

<!-- ESCENA E_0001: Uno | salida: continua -->
<!-- B_0001 -->
Ana abre la puerta.
<!-- B_0002 -->
Sale a la calle.
<!-- ESCENA E_0002: Dos | salida: separador -->
<!-- B_0003 -->
La calle está vacía.
<!-- ESCENA E_0003: Tres | salida: separador -->
<!-- B_0004 -->
Vuelve a casa.
'@
    & (Join-Path $relato "scripts\borrador.ps1") | Out-Null
    $relatoMd = Join-Path $relato "publicacion\borrador\prosa\relato-prueba-borrador.md"
    $cuerpo = Get-Cuerpo $relatoMd
    Assert-True ($cuerpo -ceq "Ana abre la puerta.`nSale a la calle.`n`nLa calle está vacía.`n`n---`n`nVuelve a casa.") "relato: limpia anclas, une escenas y corta tras separador salvo al final"
    Assert-True ((Get-Campo $relatoMd "subtitle") -match "^Borrador del .* · escenas escritas: 3 de 4 · no es el texto final$") "relato: el subtítulo declara fecha y cobertura"
    Assert-True ((Get-Campo $relatoMd "title") -ceq "Relato de prueba (borrador)" -and (Get-Campo $relatoMd "author") -ceq "Amaro Alba" -and (Get-Campo $relatoMd "lang") -ceq "es") "relato: título con la marca, autor e idioma en el frontmatter"
    Assert-True ((Get-Content -Raw -LiteralPath $relatoMd) -notmatch "(?m)^#{1,2} (Relato de prueba|Amaro Alba)") "relato: título y autor no entran en el texto"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $relato "config.json") | ConvertFrom-Json).estado -eq "escritura") "relato: no cambia el estado"
    Assert-Throws { & (Join-Path $relato "scripts\borrador.ps1") -Capitulo 1 | Out-Null } "relato: rechaza un capítulo" "no tiene capítulos"

    # /compilar conserva los borradores al sustituir publicacion/.
    Write-Utf8 -Path (Join-Path $relato "relato.md") -Content "# Relato de prueba`n`nAna abre la puerta."
    Write-Utf8 -Path (Join-Path $relato "config.json") -Content (@{ slug = "relato-prueba"; titulo = "Relato de prueba"; tipo = "relato"; escala = "relato"; estado = "finalizado" } | ConvertTo-Json)
    & (Join-Path $relato "scripts\compilar.ps1") | Out-Null
    Assert-True (Test-Path -LiteralPath $relatoMd) "compilar conserva publicacion/borrador/"
    Assert-True (Test-Path -LiteralPath (Join-Path $relato "publicacion\relato-prueba.md")) "compilar genera el libro"

    # Con un formato pedido, el manifest es un fichero de trabajo; el .md, fuente del formato, se conserva (ADR 0037).
    & (Join-Path $relato "scripts\borrador.ps1") -Epub | Out-Null
    $relatoBorradores = @(Get-ChildItem -LiteralPath (Join-Path $relato "publicacion\borrador\prosa") -Force | ForEach-Object Name)
    Assert-True (($relatoBorradores -join ",") -eq "relato-prueba-borrador.epub,relato-prueba-borrador.md") "relato: con -Epub quedan el EPUB y su .md, sin manifest"

    # Novela: un capítulo, solo escenas completas; un hueco intermedio se señala.
    $novela = New-Obra "novela" @{ slug = "novela-prueba"; titulo = "Novela de prueba"; tipo = "novela"; escala = "novela-multi-hilo"; estado = "escritura" }
    $cap1 = Join-Path $novela "capitulos\cap-01-inicio"
    Write-Utf8 -Path (Join-Path $cap1 "guion.md") -Content @"
# Capítulo cap-01-inicio — El inicio

## Escenas

<!-- ESCENA aaaa1111: La llegada -->
### E_0001 — La llegada

$Ok B_0001 $([char]0x00B7) a1b2c3d4 [1] — Llega.
$Ok a1b2c3d5 [2] — Mira.

<!-- ESCENA bbbb2222: La duda -->

$Ok b1b2c3d4 [1] — Duda.
$Pend B_0004 $([char]0x00B7) b1b2c3d5 [2] — Decide.

<!-- ESCENA cccc3333: La salida -->

$Ok c1b2c3d4 [1] — Sale.

<!-- ESCENA dddd4444: El final -->

$Pend d1b2c3d4 [1] — Termina.
"@
    Write-Utf8 -Path (Join-Path $cap1 "draft.md") -Content @'
<!-- ESCENA aaaa1111: La llegada -->

## a1b2c3d4 [1] — Llega

Elena llega a la estación.

*Nota del escritor: revisar el andén.*

## a1b2c3d5 [2] — Mira

Mira el reloj.

<!-- ESCENA bbbb2222: La duda -->

## b1b2c3d4 [1] — Duda

Prosa de una escena sin cerrar.

<!-- ESCENA cccc3333: La salida | hilo: hilo-elena -->

## c1b2c3d4 [1] — Sale

Sale sin mirar atrás.

### Notas del escritor
Esto no es prosa.
'@
    Write-Utf8 -Path (Join-Path $cap1 "escena-dddd4444.pendiente.md") -Content "Candidata sin aceptar."
    Write-Utf8 -Path (Join-Path $novela "capitulos\cap-02-nada\guion.md") -Content "# Capítulo cap-02-nada — Nada`n`n<!-- ESCENA eeee5555: Vacía -->`n`n$Pend e1b2c3d4 [1] — Nada.`n"

    & (Join-Path $novela "scripts\borrador.ps1") | Out-Null
    $capDir = Join-Path $novela "publicacion\borrador\prosa\cap-01"
    $capMd = Join-Path $capDir "novela-prueba-cap-01-borrador.md"
    Assert-True (Test-Path -LiteralPath $capMd) "novela: sin capítulo usa el capítulo en curso, en su carpeta cap-NN"
    Assert-True ((Get-Campo $capMd "title") -ceq "Novela de prueba · Capítulo 1 (borrador)") "novela: el título distingue el capítulo"
    $cuerpoNovela = Get-Cuerpo $capMd
    Assert-True ($cuerpoNovela -ceq "# Capítulo 1 — El inicio`n`nElena llega a la estación.`n`nMira el reloj.`n`n*[Escena pendiente: La duda]*`n`nSale sin mirar atrás.") "novela: escenas completas, hueco señalado, sin notas, encabezados ni marcadores"
    Assert-True ($cuerpoNovela -notmatch "Prosa de una escena sin cerrar" -and $cuerpoNovela -notmatch "Candidata") "novela: no incluye escenas incompletas ni candidatas"
    $manifiesto = Get-Content -Raw -LiteralPath (Join-Path $capDir "novela-prueba-cap-01-borrador.manifest.json") | ConvertFrom-Json
    Assert-True ((@($manifiesto.alcance.escenas_incluidas) -join ",") -eq "aaaa1111,cccc3333" -and (@($manifiesto.alcance.escenas_pendientes_intermedias) -join ",") -eq "bbbb2222") "novela: el manifiesto registra el alcance"
    Assert-True ((Get-Campo $capMd "subtitle") -match "Capítulo 1 — El inicio · escenas completas: 2 de 4") "novela: declara la cobertura"
    Assert-Throws { & (Join-Path $novela "scripts\borrador.ps1") -Capitulo "cap-02" | Out-Null } "novela: rechaza un capítulo sin escenas completas" "no tiene escenas completas"
    Assert-Throws { & (Join-Path $novela "scripts\borrador.ps1") -Capitulo 7 | Out-Null } "novela: rechaza un capítulo inexistente" "no identifica"
    & (Join-Path $novela "scripts\borrador.ps1") -Capitulo 1 | Out-Null
    Assert-True (@(Get-ChildItem -LiteralPath $capDir -Force).Count -eq 2) "novela: regenerar sustituye el borrador sin acumular ni dejar temporales"
    # Los borradores sueltos de estructuras anteriores (en publicacion/borrador/ o en
    # prosa/ sin carpeta de capítulo) se retiran al regenerar su alcance; los de otro capítulo, no.
    Write-Utf8 -Path (Join-Path $novela "publicacion\borrador\novela-prueba-cap-01-borrador.epub") -Content "antiguo"
    Write-Utf8 -Path (Join-Path $novela "publicacion\borrador\prosa\novela-prueba-cap-01-borrador.md") -Content "antiguo"
    Write-Utf8 -Path (Join-Path $novela "publicacion\borrador\prosa\novela-prueba-cap-02-borrador.md") -Content "otro capítulo"
    & (Join-Path $novela "scripts\borrador.ps1") -Capitulo 1 -Epub | Out-Null
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $novela "publicacion\borrador\novela-prueba-cap-01-borrador.epub"))) "novela: retira el borrador suelto en publicacion/borrador/"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $novela "publicacion\borrador\prosa\novela-prueba-cap-01-borrador.md"))) "novela: retira el borrador suelto en prosa/ sin carpeta de capítulo"
    Assert-True (Test-Path -LiteralPath (Join-Path $novela "publicacion\borrador\prosa\novela-prueba-cap-02-borrador.md")) "novela: no toca el borrador suelto de otro capítulo"
    $novelaBorradores = @(Get-ChildItem -LiteralPath $capDir -Force | ForEach-Object Name)
    Assert-True (($novelaBorradores -join ",") -eq "novela-prueba-cap-01-borrador.epub,novela-prueba-cap-01-borrador.md") "novela: con -Epub quedan el EPUB y su .md, sin manifest ni temporales"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $novela "config.json") | ConvertFrom-Json).estado -eq "escritura") "novela: no cambia el estado"

    # --- Guion (ADR 0036) ---
    # Relato: guion completo; por defecto etiqueta y acción, sin tonos, datos de escena ni ⚡.
    $relatoG = New-Obra "relato-guion" @{ slug = "relato-g"; titulo = "Relato G"; tipo = "relato"; escala = "relato"; estado = "fichas" }
    Write-Utf8 -Path (Join-Path $relatoG "guion.md") -Content @"
# Guion — Relato G

## Escenas

### E_0001 — Inicio

- Ubicación: Casa
- Objetivo: Salir.
- Salida: continua

#### Beats

$Pend B_0001 — Ana abre la puerta. [Clínico — BREVE]
$Pend B_0002 — Luis le pide que se quede $([char]0x26A1) "Quédate" [Tenso — EXTENSA] [elipsis]

### E_0002 — Calle

- Salida: separador

#### Beats

$Pend B_0003 — Ana cruza la calle. [Contemplativo — MEDIA]
"@
    & (Join-Path $relatoG "scripts\borrador.ps1") -Guion | Out-Null
    $relatoGMd = Join-Path $relatoG "publicacion\borrador\guion\relato-g-guion-borrador.md"
    Assert-True ((Get-Cuerpo $relatoGMd) -ceq "## E_0001 — Inicio`n`n**B_0001** Ana abre la puerta.`n`n**B_0002** Luis le pide que se quede`n`n## E_0002 — Calle`n`n**B_0003** Ana cruza la calle.") "guion relato: etiqueta y acción, sin tonos, datos ni literalidad"
    Assert-True ((Get-Campo $relatoGMd "title") -ceq "Relato G (guion, borrador)" -and (Get-Campo $relatoGMd "subtitle") -match "^Guion en borrador del .*escenas: 2 · beats: 3") "guion relato: portada y cobertura"
    & (Join-Path $relatoG "scripts\borrador.ps1") -Guion -Anotado | Out-Null
    $anotado = Get-Cuerpo (Join-Path $relatoG "publicacion\borrador\guion\relato-g-guion-anotado-borrador.md")
    Assert-True ($anotado -match [regex]::Escape("*Ubicación: Casa*") -and $anotado -match [regex]::Escape("**B_0002** Luis le pide que se quede $([char]0x26A1) `"Quédate`" · [Tenso — EXTENSA] [elipsis]")) "guion relato: --anotado añade datos de escena, literalidad y etiquetas"
    Assert-True (Test-Path -LiteralPath $relatoGMd) "guion relato: la versión anotada no sustituye a la limpia"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $relatoG "publicacion\borrador\guion\relato-g-guion-borrador.manifest.json") | ConvertFrom-Json).tipo -eq "borrador-guion") "guion relato: manifiesto de tipo borrador-guion"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $relatoG "config.json") | ConvertFrom-Json).estado -eq "fichas") "guion relato: no cambia el estado"
    Assert-Throws { & (Join-Path $relatoG "scripts\borrador.ps1") -Anotado | Out-Null } "guion: --anotado sin --guion se rechaza" "solo se usan con --guion"
    Assert-Throws { & (Join-Path $relatoG "scripts\borrador.ps1") -Guion -Hilo uno | Out-Null } "guion: --hilo fuera de multi-hilo se rechaza" "solo existe en novela multi-hilo"

    # Novela: capítulo en curso del guion (primero con beats pendientes); beats sin etiqueta salen sin ella.
    & (Join-Path $novela "scripts\borrador.ps1") -Guion | Out-Null
    $novelaGMd = Join-Path $novela "publicacion\borrador\guion\cap-01\novela-prueba-cap-01-guion-borrador.md"
    $novelaG = Get-Cuerpo $novelaGMd
    Assert-True ($novelaG -ceq "# Capítulo 1 — El inicio`n`n## E_0001 — La llegada`n`n**B_0001** Llega.`n`nMira.`n`n## La duda`n`nDuda.`n`n**B_0004** Decide.`n`n## La salida`n`nSale.`n`n## El final`n`nTermina.") "guion novela: capítulo en curso, en su carpeta, con etiquetas visuales y sin stable_id, seq ni estados"
    Assert-True ((Get-Campo $novelaGMd "title") -ceq "Novela de prueba · Capítulo 1 (guion, borrador)") "guion novela: el título distingue el capítulo"
    & (Join-Path $novela "scripts\borrador.ps1") -Guion -Capitulo 2 | Out-Null
    Assert-True ((Get-Cuerpo (Join-Path $novela "publicacion\borrador\guion\cap-02\novela-prueba-cap-02-guion-borrador.md")) -ceq "# Capítulo 2 — Nada`n`n## Vacía`n`nNada.") "guion novela: capítulo indicado"
    Assert-Throws { & (Join-Path $novela "scripts\borrador.ps1") -Guion -Capitulo 7 | Out-Null } "guion novela: rechaza un capítulo inexistente" "no identifica"
    New-Item -ItemType Directory -Force -Path (Join-Path $novela "capitulos\cap-03-sin-guion") | Out-Null
    Assert-Throws { & (Join-Path $novela "scripts\borrador.ps1") -Guion -Capitulo 3 | Out-Null } "guion novela: rechaza un capítulo sin guion" "no tiene guion.md"

    # Multi-hilo antes de ensamblar: guiones por hilo; con más de un hilo hay que indicarlo.
    $multi = New-Obra "multihilo" @{ slug = "multi"; titulo = "Multi"; tipo = "novela"; escala = "novela-multi-hilo"; estado = "hilos_beats" }
    foreach ($h in "uno", "dos") {
        Write-Utf8 -Path (Join-Path $multi "hilos\hilo-$h\cap-01\guion.md") -Content "# Hilo $h — cap-01: Apertura`n`n<!-- ESCENA aa$($h)0001: Arranque | hilo: hh$h -->`n### E_0001 — Arranque`n`n- $Pend B_0001 $([char]0x00B7) b1$($h)0001 [1] — Empieza el hilo $h ``[Tenso — MEDIA]`` ``[Personajes: Ana]```n"
    }
    Assert-Throws { & (Join-Path $multi "scripts\borrador.ps1") -Guion | Out-Null } "guion multi-hilo: sin --hilo con varios hilos se rechaza" "indica el hilo"
    & (Join-Path $multi "scripts\borrador.ps1") -Guion -Hilo dos | Out-Null
    Assert-True ((Get-Cuerpo (Join-Path $multi "publicacion\borrador\guion\hilo-dos\cap-01\multi-dos-cap-01-guion-borrador.md")) -ceq "# Hilo dos — cap-01: Apertura`n`n## E_0001 — Arranque`n`n**B_0001** Empieza el hilo dos") "guion multi-hilo: capítulo del hilo indicado, en hilo-<hilo>/cap-NN, sin etiquetas entre comillas invertidas"
    Assert-True ((Get-Campo (Join-Path $multi "publicacion\borrador\guion\hilo-dos\cap-01\multi-dos-cap-01-guion-borrador.md") "title") -ceq "Multi · Hilo dos · Capítulo 1 (guion, borrador)") "guion multi-hilo: el título distingue hilo y capítulo"

    Write-Host "OK: borrador-regression"
} finally {
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
