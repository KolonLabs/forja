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
    param([string]$Workspace, [string]$Estado, [int]$UltimoHecho = 2, [string[]]$Pendientes)

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
    if ($null -ne $Pendientes) { $config.hechos_revision_pendiente = @($Pendientes) }
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
- Salida: continua

#### Beats

⬜ B_0001 — Ana recibe una llamada que altera su plan. [Clínico — MEDIA]
⬜ B_0002 — Ana decide salir pese al riesgo. [Tenso — BREVE]

### E_0002 — Consecuencia

- Ubicación: Calle
- Tiempo y POV: Mediodía, Ana
- Objetivo: Llegar a la cita.
- Resultado: Descubre la trampa.
- Salida: continua

#### Beats

⬜ B_0003 — Ana descubre que la cita era una trampa. [Revelación / Opresivo — EXTENSA]
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

$previousObras = $env:FORJA_OBRAS
try {
    $workspace = Join-Path $RunRoot "workspace"
    $scripts = Join-Path $workspace "scripts"
    New-Item -ItemType Directory -Force -Path $scripts | Out-Null
    $helper = Join-Path $scripts "relato-transaccion.ps1"
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared\pipelines\relato\scripts\relato-transaccion.ps1") -Destination $helper -Force
    # Catálogo común de tonos (ADR 0035): relato-transaccion comprueba los tonos del guion con él.
    $tonos = Join-Path $workspace ".claude\skills\tonos-beat"
    New-Item -ItemType Directory -Force -Path $tonos | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared\skills\tonos-beat\SKILL.md") -Destination $tonos -Force
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

    # Hechos en fichas: en una copia aislada, un hecho cambiado queda pendiente hasta que guion revise sus beats.
    $revision = Join-Path $RunRoot "revision"
    Copy-Item -LiteralPath $workspace -Destination $revision -Recurse
    $helperRevision = Join-Path $revision "scripts\relato-transaccion.ps1"
    $siguienteRevision = Join-Path $revision ".forja-transaccion\siguiente"
    $actosDosCambiado = $actosDos.Replace("vuelve imposible ignorar la cita", "le obliga a acudir a la cita")

    & $helperRevision -Accion Preparar -Operacion hechos | Out-Null
    Write-Utf8 -Path (Join-Path $siguienteRevision "_actos.md") -Content $actosDosCambiado
    Assert-Throws { & $helperRevision -Accion Confirmar } "un hecho cambiado en fichas exige registrar su revisión"
    Write-Utf8 -Path (Join-Path $siguienteRevision "_actos.md") -Content $actosUno
    Write-Config -Workspace $siguienteRevision -Estado "fichas" -Pendientes @("H_0002")
    Assert-Throws { & $helperRevision -Accion Confirmar } "en fichas no se puede retirar un hecho"
    Write-Utf8 -Path (Join-Path $siguienteRevision "_actos.md") -Content $actosDosCambiado
    & $helperRevision -Accion Confirmar | Out-Null
    $pendientes = @((Get-Content -Raw -LiteralPath (Join-Path $revision "config.json") | ConvertFrom-Json).hechos_revision_pendiente)
    Assert-Equal "H_0002" ($pendientes -join ",") "hechos registra el hecho pendiente de revisión"

    & $helperRevision -Accion Preparar -Operacion hechos | Out-Null
    Write-Config -Workspace $siguienteRevision -Estado "fichas" -Pendientes @()
    Assert-Throws { & $helperRevision -Accion Confirmar } "hechos no puede cerrar una revisión pendiente"
    & $helperRevision -Accion Descartar | Out-Null

    & $helperRevision -Accion Preparar -Operacion componentes | Out-Null
    Write-Utf8 -Path (Join-Path $siguienteRevision "relato-draft.md") "# Draft — Fixture de relato`n"
    Write-Utf8 -Path (Join-Path $siguienteRevision "contexto_narrativo.md") "# Contexto narrativo`n`n- Inicio."
    Write-Config -Workspace $siguienteRevision -Estado "escritura" -Pendientes @("H_0002")
    Assert-Throws { & $helperRevision -Accion Confirmar } "componentes no avanza con hechos pendientes de revisión"
    & $helperRevision -Accion Descartar | Out-Null

    & $helperRevision -Accion Preparar -Operacion guion | Out-Null
    Write-Config -Workspace $siguienteRevision -Estado "fichas" -Pendientes @()
    Assert-Throws { & $helperRevision -Accion Confirmar } "cerrar una revisión exige cambiar guion.md"
    Write-Config -Workspace $siguienteRevision -Estado "fichas" -Pendientes @("H_0002", "H_0001")
    Write-Utf8 -Path (Join-Path $siguienteRevision "guion.md") -Content $guionAbierto.Replace("decide salir pese al riesgo", "sale obligada por la cita")
    Assert-Throws { & $helperRevision -Accion Confirmar } "guion no puede añadir revisiones pendientes"
    Write-Config -Workspace $siguienteRevision -Estado "fichas" -Pendientes @()
    & $helperRevision -Accion Confirmar | Out-Null
    $pendientes = @((Get-Content -Raw -LiteralPath (Join-Path $revision "config.json") | ConvertFrom-Json).hechos_revision_pendiente)
    Assert-Equal 0 $pendientes.Count "guion cierra la revisión pendiente"

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

    # Separadores (ADR 0040): en una copia aislada, E_0001 termina con `salida: separador`.
    # El corte va tras E_0001, antes del primer párrafo de E_0002; sustituir el marcador
    # de E_0001 por `---` lo adelantaría una escena.
    $separadores = Join-Path $RunRoot "separadores"
    Copy-Item -LiteralPath $workspace -Destination $separadores -Recurse
    $helperSeparadores = Join-Path $separadores "scripts\relato-transaccion.ps1"
    Write-Utf8 -Path (Join-Path $separadores "guion.md") -Content ([regex]::new('- Salida: continua').Replace($guionCerrado, '- Salida: separador', 1))
    $draftSeparadores = Join-Path $separadores "relato-draft.md"
    Write-Utf8 -Path $draftSeparadores -Content ((Get-Content -Raw -LiteralPath $draftSeparadores).Replace("E_0001: Inicio | salida: continua", "E_0001: Inicio | salida: separador"))
    & $helperSeparadores -Accion Preparar -Operacion publicar | Out-Null
    $manuscritoSeparadores = Join-Path $separadores ".forja-transaccion\siguiente\relato.md"
    Write-Config -Workspace (Join-Path $separadores ".forja-transaccion\siguiente") -Estado "finalizado"
    $parrafoUno = "Ana recibe la llamada y el sonido le rompe la rutina.`n`nGuarda las llaves en el bolsillo y sale antes de poder arrepentirse."
    $parrafoDos = "En la calle descubre que la cita era una trampa y cambia de rumbo."
    Write-Utf8 -Path $manuscritoSeparadores "# Fixture de relato`n`n---`n`n$parrafoUno`n`n$parrafoDos`n"
    Assert-Throws { & $helperSeparadores -Accion Confirmar } "publicar rechaza el separador adelantado una escena"
    Write-Utf8 -Path $manuscritoSeparadores "# Fixture de relato`n`n$parrafoUno`n`n$parrafoDos`n"
    Assert-Throws { & $helperSeparadores -Accion Confirmar } "publicar rechaza que falte el separador"
    Write-Utf8 -Path $manuscritoSeparadores "# Fixture de relato`n`n$parrafoUno`n`n---`n`n$parrafoDos`n`n---`n"
    Assert-Throws { & $helperSeparadores -Accion Confirmar } "publicar rechaza un separador de más tras la última escena"
    Write-Utf8 -Path $manuscritoSeparadores "# Fixture de relato`n`n$parrafoUno`n`n---`n`n$parrafoDos`n"
    & $helperSeparadores -Accion Confirmar | Out-Null
    Assert-Equal "finalizado" ((Get-Content -Raw -LiteralPath (Join-Path $separadores "config.json") | ConvertFrom-Json).estado) "publicar acepta el separador tras la escena con salida separador"

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

    # Compilación en la obra (ADR 0026): solo Markdown, sin depender de Pandoc.
    $compilar = Join-Path $scripts "compilar.ps1"
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared\scripts\compilar.ps1") -Destination $compilar -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot "shared\scripts\publicacion-comun.ps1") -Destination (Join-Path $scripts "publicacion-comun.ps1") -Force
    & $compilar | Out-Null
    $publicacion = Join-Path $workspace "publicacion"
    $libroMd = Get-Content -Raw -LiteralPath (Join-Path $publicacion "fixture-relato.md")
    Assert-True ($libroMd -match '^---\r?\ntitle: "Fixture de relato"\r?\nauthor: "Amaro Alba"\r?\nlang: "es"\r?\n(?s:.*?)\r?\n---\r?\n\r?\nAna recibe') "compilar pone título y autor en el frontmatter, sin duplicar el título del manuscrito (ADR 0038)"
    $manifiestoObra = Get-Content -Raw -LiteralPath (Join-Path $publicacion "manifest.json") | ConvertFrom-Json
    Assert-Equal "relato.md" $manifiestoObra.manuscrito.archivo "el manifiesto apunta al manuscrito"
    Assert-Equal (Get-FileHash -LiteralPath (Join-Path $workspace "relato.md") -Algorithm SHA256).Hash.ToLowerInvariant() $manifiestoObra.manuscrito.sha256 "el manifiesto congela el hash del manuscrito"
    Assert-Equal "publicado" ((Get-Content -Raw -LiteralPath (Join-Path $workspace "config.json") | ConvertFrom-Json).estado) "compilar asigna publicado"
    & $compilar -Titulo "Otro título" | Out-Null
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $publicacion "fixture-relato.md")) -match '(?m)^title: "Otro título"\r?$') "compilar regenera una obra ya publicada"
    Assert-True (@(Get-ChildItem -LiteralPath $workspace -Directory -Force -Filter ".publicacion-*").Count -eq 0) "compilar no deja carpetas temporales"
    Write-Config -Workspace $workspace -Estado "escritura"
    Assert-Throws { & $compilar | Out-Null } "compilar rechaza una obra sin terminar"
    Assert-Equal "escritura" ((Get-Content -Raw -LiteralPath (Join-Path $workspace "config.json") | ConvertFrom-Json).estado) "un rechazo no cambia el estado"

    # Inyección: el relato recibe el override local y no infraestructura de novela.
    $HubRoot = $RepoRoot
    . (Join-Path $RepoRoot "scripts\lib\common.ps1")
    Assert-Throws { ConvertTo-RelatoHechoTexto -Texto "H_0002 [D · H_0001–H_0002]: pauta heredada" } "el creador de relato rechaza [D] en el brief"
    $injected = Join-Path $RunRoot "injected"
    foreach ($directory in @(".opencode\agents", ".claude\skills", ".opencode\commands")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $injected $directory) | Out-Null
    }
    Inject-Pipeline -TargetDir $injected -Escala "relato" -EstiloBase "contemporaneo"
    Assert-True (Test-Path -LiteralPath (Join-Path $injected "scripts\relato-transaccion.ps1")) "inyección incluye helper local"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $injected ".claude\skills\qdrant"))) "relato no recibe qdrant"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $injected ".claude\skills\hechos-distribuidos"))) "relato no recibe el contrato [D] de novela"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".claude\skills\mecanica-prosa\SKILL.md")) -match "única prosa cohesionada") "inyección aplica override de mecánica"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $injected ".opencode\skills"))) "las skills no se duplican en .opencode"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".claude\skills\mecanica-prosa\SKILL.md")) -match "user-invocable: false") "las skills no se ofrecen como comandos en Claude Code"
    Write-OpencodeConfig -TargetDir $injected
    $ocConfig = Get-Content -Raw -LiteralPath (Join-Path $injected "opencode.json") | ConvertFrom-Json
    Assert-Equal "director" $ocConfig.default_agent "opencode arranca en el director"
    Assert-True ($ocConfig.agent.scaffolder.disable -eq $true -and $ocConfig.agent.bibliotecario.disable -eq $true) "opencode desactiva los agentes del hub"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".opencode\commands\revisar.md")) -match "aún no fue escrita") "inyección aplica override de comandos de relato"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $injected ".opencode\agents\director.md")) -match 'Prepara `escritura`') "inyección aplica director transaccional"
    foreach ($tool in @("compilar.ps1", "borrador.ps1", "publicacion-comun.ps1", "build-epub.ps1", "build-pdf.ps1", "build.css", "templates\forja-kdp.typ")) {
        Assert-True (Test-Path -LiteralPath (Join-Path $injected "scripts\$tool")) "inyección incluye scripts\$tool"
    }
    Assert-True (Test-Path -LiteralPath (Join-Path $injected "imagenes\LEEME.md")) "inyección incluye la guía de imagenes/ (ADR 0040)"
    Assert-True (Test-Path -LiteralPath (Join-Path $injected ".opencode\commands\compilar.md")) "inyección incluye /compilar en opencode"
    Assert-True (Test-Path -LiteralPath (Join-Path $injected ".claude\commands\compilar.md")) "inyección incluye /compilar en Claude Code"
    Inject-Pipeline -TargetDir $injected -Escala "relato" -EstiloBase "contemporaneo"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $injected "scripts\templates\templates"))) "reinyectar no anida templates"

    # Edición derivada: el staging interno del origen no se hereda y el origen permanece intacto.
    $editionHub = Join-Path $RunRoot "edition-hub"
    $editionWorkspaces = Join-Path $editionHub "workspaces"
    $env:FORJA_OBRAS = $editionWorkspaces
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
    # La edición es otra obra: no hereda el git ni el libro compilado del origen.
    New-Item -ItemType Directory -Force -Path (Join-Path $editionSource ".git"), (Join-Path $editionSource "publicacion") | Out-Null
    Write-Utf8 -Path (Join-Path $editionSource "publicacion\origen.md") -Content "# Libro del origen"
    # Relato antiguo: sin explicitud en config.json; su nivel efectivo está en AGENTS.md.
    Write-Utf8 -Path (Join-Path $editionSource "AGENTS.md") -Content "# Fixture`n`n- **Explicitud:** medio (sugerido pero presente)."
    # Un origen sin explicitud declarada en ningún sitio no puede editarse sin suponer un nivel.
    $sinNivel = Join-Path $editionWorkspaces "origen-sin-nivel"
    Copy-Item -LiteralPath $editionSource -Destination $sinNivel -Recurse
    Remove-Item -LiteralPath (Join-Path $sinNivel "AGENTS.md")
    Assert-Throws { & (Join-Path $RepoRoot "scripts
ew-edicion-relato.ps1") -Origen "origen-sin-nivel" -Slug "origen-sin-nivel-2a" -ForjaRootOverride $editionHub | Out-Null } "la edición rechaza un origen sin explicitud"
    & (Join-Path $RepoRoot "scripts\new-edicion-relato.ps1") -Origen "origen" -Slug "origen-2a-edicion" -ForjaRootOverride $editionHub | Out-Null
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $editionTarget "publicacion"))) "la edición no hereda el libro compilado"
    Assert-True ((git -C $editionTarget rev-parse --show-toplevel 2>$null) -and ((Resolve-Path (git -C $editionTarget rev-parse --show-toplevel)).Path -eq (Resolve-Path $editionTarget).Path)) "la edición tiene su propio repositorio git"
    Assert-True ($null -eq (git -C $editionTarget rev-parse --verify --quiet HEAD 2>$null)) "la edición nace sin commits"
    Assert-Equal "publicado" ((Get-Content -Raw -LiteralPath (Join-Path $editionSource "config.json") | ConvertFrom-Json).estado) "la edición no altera el origen"
    Assert-Equal "correccion" ((Get-Content -Raw -LiteralPath (Join-Path $editionTarget "config.json") | ConvertFrom-Json).estado) "la edición queda corregible"
    Assert-True (Test-Path -LiteralPath (Join-Path $editionTarget "relato-edicion-anterior.md")) "la edición conserva el manuscrito publicado"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $editionTarget ".forja-transaccion"))) "la edición no hereda staging interno"
    Assert-Equal "medio" ((Get-Content -Raw -LiteralPath (Join-Path $editionTarget "config.json") | ConvertFrom-Json).explicitud) "la edición conserva la explicitud del origen"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $editionTarget "AGENTS.md")) -match "\*\*Explicitud:\*\* medio") "AGENTS.md de la edición declara el nivel del origen"

    Write-Output "OK: regresión de workflow de relato superada."
} finally {
    $env:FORJA_OBRAS = $previousObras
    if (Test-Path -LiteralPath $RunRoot) {
        Remove-Item -LiteralPath $RunRoot -Recurse -Force
    }
}
