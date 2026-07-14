# relato-workflow-regression.ps1 — Pruebas aisladas del contrato de relato.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-relato-regression-" + [guid]::NewGuid().ToString("N"))
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-Utf8 {
    param([string]$Path, [string]$Content)

    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) { throw "ASSERT: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)

    if ($Expected -ne $Actual) { throw "ASSERT: $Message. Esperado '$Expected'; recibido '$Actual'." }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)

    try {
        & $Action
    } catch {
        return
    }
    throw "ASSERT: $Message"
}

function Write-Config {
    param([string]$Workspace, [string]$Estado, [int]$UltimoHecho = 2)

    $config = [ordered]@{
        slug = "fixture-relato"
        titulo = "Fixture de relato"
        tipo = "relato"
        escala = "relato"
        estado = $Estado
        ultimo_hecho_seq = $UltimoHecho
        ultimo_beat_seq = 3
        ultimo_escena_seq = 2
    }
    Write-Utf8 -Path (Join-Path $Workspace "config.json") -Content ($config | ConvertTo-Json -Depth 8)
}

$guionAbierto = @'
# Guion — Fixture de relato

## Escenas

### E_0001 — Inicio

- Ubicación: Casa
- Tiempo y POV: Mañana, Ana
- Objetivo: Resolver una llamada.
- Resultado: Ana decide salir.
- Arco tonal: calma → tensión → decisión
- Salida: continua

#### Beats

⬜ B_0001 — Ana recibe una llamada que altera su plan.
⬜ B_0002 — Ana decide salir pese al riesgo.

### E_0002 — Consecuencia

- Ubicación: Calle
- Tiempo y POV: Mediodía, Ana
- Objetivo: Llegar a la cita.
- Resultado: Descubre la trampa.
- Arco tonal: tensión → revelación → amenaza
- Salida: continua

#### Beats

⬜ B_0003 — Ana descubre que la cita era una trampa.
'@

$guionCerrado = $guionAbierto.Replace("⬜ B_0001", "✅ B_0001").Replace("⬜ B_0002", "✅ B_0002").Replace("⬜ B_0003", "✅ B_0003")
$actosUno = @'
# Actos — Fixture de relato

## Acto I

### Hechos

- H_0001 — Ana recibe una llamada que transforma su mañana.
'@
$actosDos = @'
# Actos — Fixture de relato

## Acto I

### Hechos

- H_0001 — Ana recibe una llamada que transforma su mañana.
- H_0002 — Ana intenta sostener su rutina mientras la llamada vuelve imposible ignorar la cita.
'@
$actosConMarcaD = $actosDos.Replace("H_0002 —", "H_0002 [D · H_0001–H_0002] —")

try {
    $workspace = Join-Path $RunRoot "workspace"
    $scripts = Join-Path $workspace "scripts"
    New-Item -ItemType Directory -Force -Path $scripts | Out-Null
    $helper = Join-Path $scripts "relato-transaccion.ps1"
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared\pipelines\relato\scripts\relato-transaccion.ps1") -Destination $helper -Force
    Write-Config -Workspace $workspace -Estado "diseno" -UltimoHecho 1
    Write-Utf8 -Path (Join-Path $workspace "_actos.md") -Content $actosUno

    # Hechos: ID y contador se confirman juntos, sin salir de diseño; relato rechaza [D].
    & $helper -Accion Preparar -Operacion hechos | Out-Null
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\_actos.md") -Content $actosConMarcaD
    Write-Config -Workspace (Join-Path $workspace ".forja-transaccion\siguiente") -Estado "diseno" -UltimoHecho 2
    Assert-Throws { & $helper -Accion Confirmar } "relato rechaza hechos distribuidos [D]"
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\_actos.md") -Content $actosDos
    & $helper -Accion Confirmar | Out-Null
    Assert-Equal 2 ((Get-Content -Raw -LiteralPath (Join-Path $workspace "config.json") | ConvertFrom-Json).ultimo_hecho_seq) "hechos actualiza su contador"

    # Diseño: solo requiere guion y estado; las recurrencias son beats ordinarios del mapa global.
    & $helper -Accion Preparar -Operacion diseno | Out-Null
    Assert-Throws { & $helper -Accion Confirmar } "diseño sin guion debe fallar"
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\guion.md") -Content $guionAbierto
    Write-Config -Workspace (Join-Path $workspace ".forja-transaccion\siguiente") -Estado "fichas"
    & $helper -Accion Confirmar | Out-Null
    Assert-Equal "fichas" ((Get-Content -Raw -LiteralPath (Join-Path $workspace "config.json") | ConvertFrom-Json).estado) "diseño deja fichas"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $workspace "cola_d.md"))) "diseño no persiste una cola de recurrencias"

    # Componentes: crea el prefijo vacío y cambia de estado junto con contexto.
    & $helper -Accion Preparar -Operacion componentes | Out-Null
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\relato-draft.md") "# Draft — Fixture de relato`n"
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\contexto_narrativo.md") "# Contexto narrativo`n`n- Inicio."
    Write-Config -Workspace (Join-Path $workspace ".forja-transaccion\siguiente") -Estado "escritura"
    & $helper -Accion Confirmar | Out-Null

    # Escritura: una escena validada es un prefijo correcto aunque falte E_0002.
    & $helper -Accion Preparar -Operacion escritura | Out-Null
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\guion.md") ($guionAbierto.Replace("⬜ B_0001", "✅ B_0001").Replace("⬜ B_0002", "✅ B_0002"))
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\relato-draft.md") @'
# Draft — Fixture de relato

<!-- ESCENA E_0001: Inicio | salida: continua -->
<!-- B_0001 -->
Ana recibe la llamada y el sonido le rompe la rutina.
<!-- B_0002 -->
Guarda las llaves en el bolsillo y sale antes de poder arrepentirse.
'@
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\contexto_narrativo.md") "# Contexto narrativo`n`n- Ana salió tras la llamada."
    Write-Config -Workspace (Join-Path $workspace ".forja-transaccion\siguiente") -Estado "escritura"
    & $helper -Accion Confirmar | Out-Null
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $workspace "relato-draft.md")) -match "E_0001") "escritura confirma el primer prefijo"

    # Corrección: exige registro, pero no exige el draft completo.
    & $helper -Accion Preparar -Operacion correccion | Out-Null
    Assert-Throws { & $helper -Accion Confirmar } "corrección sin registro debe fallar"
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\correcciones.md") "# Registro de correcciones`n`n- B_0001: se aclara la llamada."
    & $helper -Accion Confirmar | Out-Null

    # Un staging preparado se conserva para reanudar y se descarta de forma explícita.
    & $helper -Accion Preparar -Operacion correccion | Out-Null
    & $helper -Accion Recuperar | Out-Null
    Assert-True (Test-Path -LiteralPath (Join-Path $workspace ".forja-transaccion\manifest.json")) "recuperar conserva staging preparado"
    & $helper -Accion Descartar | Out-Null
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $workspace ".forja-transaccion"))) "descartar limpia staging preparado"

    # Cierre de la segunda escena y publicación: un título vacío no basta.
    & $helper -Accion Preparar -Operacion escritura | Out-Null
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\guion.md") -Content $guionCerrado
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\relato-draft.md") @'
# Draft — Fixture de relato

<!-- ESCENA E_0001: Inicio | salida: continua -->
<!-- B_0001 -->
Ana recibe la llamada y el sonido le rompe la rutina.
<!-- B_0002 -->
Guarda las llaves en el bolsillo y sale antes de poder arrepentirse.
<!-- ESCENA E_0002: Consecuencia | salida: continua -->
<!-- B_0003 -->
En la calle descubre que la cita era una trampa y cambia de rumbo.
'@
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\contexto_narrativo.md") "# Contexto narrativo`n`n- Ana conoce la trampa."
    Write-Config -Workspace (Join-Path $workspace ".forja-transaccion\siguiente") -Estado "escritura"
    & $helper -Accion Confirmar | Out-Null

    & $helper -Accion Preparar -Operacion publicar | Out-Null
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\relato.md") "# Fixture de relato`n"
    Write-Config -Workspace (Join-Path $workspace ".forja-transaccion\siguiente") -Estado "finalizado"
    Assert-Throws { & $helper -Accion Confirmar } "publicación sin prosa debe fallar"
    Write-Utf8 -Path (Join-Path $workspace ".forja-transaccion\siguiente\relato.md") @'
# Fixture de relato

Ana recibe una llamada y decide salir. En la calle descubre la trampa y cambia de rumbo.
'@
    & $helper -Accion Confirmar | Out-Null
    Assert-Equal "finalizado" ((Get-Content -Raw -LiteralPath (Join-Path $workspace "config.json") | ConvertFrom-Json).estado) "publicación finaliza el relato"

    # Inyección: el relato recibe el override local y no infraestructura de novela.
    $HubRoot = $RepoRoot
    . (Join-Path $RepoRoot "scripts\lib\common.ps1")
    Assert-Throws { ConvertTo-RelatoHechoTexto -Texto "H_0002 [D · H_0001–H_0002]: pauta heredada" } "el creador de relato rechaza [D] en el brief"
    $injected = Join-Path $RunRoot "injected"
    foreach ($directory in @(".opencode\agents", ".opencode\skills", ".opencode\commands")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $injected $directory) | Out-Null
    }
    Inject-Pipeline -TargetDir $injected -Escala "relato" -EstiloBase "contemporaneo"
    Assert-True (Test-Path -LiteralPath (Join-Path $injected "scripts\relato-transaccion.ps1")) "inyección incluye helper local"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $injected ".opencode\skills\qdrant"))) "relato no recibe qdrant"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $injected ".opencode\skills\hechos-distribuidos"))) "relato no recibe el contrato [D] de novela"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".opencode\skills\mecanica-prosa\SKILL.md")) -match "única prosa cohesionada") "inyección aplica override de mecánica"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".opencode\commands\revisar.md")) -match "aún no fue escrita") "inyección aplica override de comandos de relato"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".opencode\agents\director.md")) -match 'Prepara `escritura`') "inyección aplica director transaccional"

    # Edición derivada: el staging interno del origen no se hereda y el origen permanece intacto.
    $editionHub = Join-Path $RunRoot "edition-hub"
    $editionWorkspaces = Join-Path $editionHub "workspaces"
    $editionSource = Join-Path $editionWorkspaces "origen"
    $editionTarget = Join-Path $editionWorkspaces "origen-2a-edicion"
    New-Item -ItemType Directory -Force -Path (Join-Path $editionSource "fichas") | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared") -Destination (Join-Path $editionHub "shared") -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $workspace "guion.md") -Destination (Join-Path $editionSource "guion.md") -Force
    Copy-Item -LiteralPath (Join-Path $workspace "relato-draft.md") -Destination (Join-Path $editionSource "relato-draft.md") -Force
    Write-Utf8 -Path (Join-Path $editionSource "relato.md") -Content "# Fixture de relato`n`nAna recibe una llamada y descubre una trampa."
    $publishedConfig = [ordered]@{
        slug = "origen"
        titulo = "Fixture de relato"
        tipo = "relato"
        escala = "relato"
        estado = "publicado"
        estilo_base = "contemporaneo"
        estilo_secundario = $null
        creado = "2026-01-01T00:00:00"
        ultima_modificacion = "2026-01-01T00:00:00"
        ultimo_hecho_seq = 2
        ultimo_beat_seq = 3
        ultimo_escena_seq = 2
    }
    Write-Utf8 -Path (Join-Path $editionSource "config.json") -Content ($publishedConfig | ConvertTo-Json -Depth 8)
    New-Item -ItemType Directory -Force -Path (Join-Path $editionSource ".forja-transaccion\siguiente") | Out-Null
    Write-Utf8 -Path (Join-Path $editionSource ".forja-transaccion\manifest.json") -Content '{"estado":"preparada"}'
    & (Join-Path $RepoRoot "scripts\new-edicion-relato.ps1") -Origen "origen" -Slug "origen-2a-edicion" -ForjaRootOverride $editionHub | Out-Null
    Assert-Equal "publicado" ((Get-Content -Raw -LiteralPath (Join-Path $editionSource "config.json") | ConvertFrom-Json).estado) "la edición no altera el origen"
    Assert-Equal "correccion" ((Get-Content -Raw -LiteralPath (Join-Path $editionTarget "config.json") | ConvertFrom-Json).estado) "la edición queda corregible"
    Assert-True (Test-Path -LiteralPath (Join-Path $editionTarget "relato-edicion-anterior.md")) "la edición conserva el manuscrito publicado"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $editionTarget ".forja-transaccion"))) "la edición no hereda staging interno"

    Write-Output "OK: regresión de workflow de relato superada."
} finally {
    if (Test-Path -LiteralPath $RunRoot) {
        Remove-Item -LiteralPath $RunRoot -Recurse -Force
    }
}
