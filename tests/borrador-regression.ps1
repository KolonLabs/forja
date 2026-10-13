# borrador-regression.ps1 — Borradores de revisión de relato y novela (ADR 0028).
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
    param([string]$Path)
    $texto = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8) -replace "`r`n", "`n"
    return ($texto -split "\*Borrador del [^\n]*\n", 2)[1].Trim()
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
    Assert-True ((Get-Content -Raw -LiteralPath $relatoMd) -match "escenas escritas: 3 de 4") "relato: declara la cobertura"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $relato "config.json") | ConvertFrom-Json).estado -eq "escritura") "relato: no cambia el estado"
    Assert-Throws { & (Join-Path $relato "scripts\borrador.ps1") -Capitulo 1 | Out-Null } "relato: rechaza un capítulo" "no tiene capítulos"

    # /compilar conserva los borradores al sustituir publicacion/.
    Write-Utf8 -Path (Join-Path $relato "relato.md") -Content "# Relato de prueba`n`nAna abre la puerta."
    Write-Utf8 -Path (Join-Path $relato "config.json") -Content (@{ slug = "relato-prueba"; titulo = "Relato de prueba"; tipo = "relato"; escala = "relato"; estado = "finalizado" } | ConvertTo-Json)
    & (Join-Path $relato "scripts\compilar.ps1") | Out-Null
    Assert-True (Test-Path -LiteralPath $relatoMd) "compilar conserva publicacion/borrador/"
    Assert-True (Test-Path -LiteralPath (Join-Path $relato "publicacion\relato-prueba.md")) "compilar genera el libro"

    # Con un formato pedido, el .md y el manifest son ficheros de trabajo: solo queda el formato.
    & (Join-Path $relato "scripts\borrador.ps1") -Epub | Out-Null
    $relatoBorradores = @(Get-ChildItem -LiteralPath (Join-Path $relato "publicacion\borrador\prosa") -Force | ForEach-Object Name)
    Assert-True (($relatoBorradores -join ",") -eq "relato-prueba-borrador.epub") "relato: con -Epub solo queda el EPUB del relato completo"

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
    $capMd = Join-Path $novela "publicacion\borrador\prosa\novela-prueba-cap-01-borrador.md"
    Assert-True (Test-Path -LiteralPath $capMd) "novela: sin capítulo usa el capítulo en curso"
    $cuerpoNovela = Get-Cuerpo $capMd
    Assert-True ($cuerpoNovela -ceq "# Capítulo 1 — El inicio`n`nElena llega a la estación.`n`nMira el reloj.`n`n*[Escena pendiente: La duda]*`n`nSale sin mirar atrás.") "novela: escenas completas, hueco señalado, sin notas, encabezados ni marcadores"
    Assert-True ($cuerpoNovela -notmatch "Prosa de una escena sin cerrar" -and $cuerpoNovela -notmatch "Candidata") "novela: no incluye escenas incompletas ni candidatas"
    $manifiesto = Get-Content -Raw -LiteralPath (Join-Path $novela "publicacion\borrador\prosa\novela-prueba-cap-01-borrador.manifest.json") | ConvertFrom-Json
    Assert-True ((@($manifiesto.alcance.escenas_incluidas) -join ",") -eq "aaaa1111,cccc3333" -and (@($manifiesto.alcance.escenas_pendientes_intermedias) -join ",") -eq "bbbb2222") "novela: el manifiesto registra el alcance"
    Assert-True ((Get-Content -Raw -LiteralPath $capMd) -match "escenas completas: 2 de 4") "novela: declara la cobertura"
    Assert-Throws { & (Join-Path $novela "scripts\borrador.ps1") -Capitulo "cap-02" | Out-Null } "novela: rechaza un capítulo sin escenas completas" "no tiene escenas completas"
    Assert-Throws { & (Join-Path $novela "scripts\borrador.ps1") -Capitulo 7 | Out-Null } "novela: rechaza un capítulo inexistente" "no identifica"
    & (Join-Path $novela "scripts\borrador.ps1") -Capitulo 1 | Out-Null
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $novela "publicacion\borrador\prosa") -Force).Count -eq 2) "novela: regenerar sustituye el borrador sin acumular ni dejar temporales"
    # Un borrador suelto en publicacion/borrador/ (anterior a prosa/) se sustituye al regenerar su alcance.
    Write-Utf8 -Path (Join-Path $novela "publicacion\borrador\novela-prueba-cap-01-borrador.epub") -Content "antiguo"
    & (Join-Path $novela "scripts\borrador.ps1") -Capitulo 1 -Epub | Out-Null
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $novela "publicacion\borrador\novela-prueba-cap-01-borrador.epub"))) "novela: retira el borrador suelto del mismo capítulo"
    $novelaBorradores = @(Get-ChildItem -LiteralPath (Join-Path $novela "publicacion\borrador\prosa") -Force | ForEach-Object Name)
    Assert-True (($novelaBorradores -join ",") -eq "novela-prueba-cap-01-borrador.epub") "novela: con -Epub solo queda el EPUB del capítulo, sin .md, manifest ni temporales"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $novela "config.json") | ConvertFrom-Json).estado -eq "escritura") "novela: no cambia el estado"

    Write-Host "OK: borrador-regression"
} finally {
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
