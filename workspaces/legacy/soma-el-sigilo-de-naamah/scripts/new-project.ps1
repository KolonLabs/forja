#Requires -Version 5.1
<#
.SYNOPSIS
  Crea un workspace de Forja con pipeline inyectado segun escala.
  Soporta relato, novela-simple y novela-multi-hilo.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-z0-9]+(-[a-z0-9]+)*$')]
    [string]$Slug,

    [Parameter(Mandatory = $false)]
    [string]$Titulo,

    [ValidateSet("explicito", "contemporaneo", "erotico", "fantasia", "noir", "romantico", "thriller")]
    [string]$Estilo = "explicito",

    [ValidateSet("relato", "novela-simple", "novela-multi-hilo")]
    [string]$Escala = "novela-simple",

    [string]$EstiloSecundario = "",

    [string]$Premisa = "",
    [string]$BriefJsonPath = "",

    [switch]$ConQdrant,
    [switch]$ConNeo4j,
    [switch]$SinInfra
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Funciones auxiliares
# ------------------------------------------------------------

function Get-ListText($items) {
    if ($null -eq $items) { return "" }
    if ($items -is [string]) { return $items }
    if ($items -is [System.Collections.IEnumerable] -and -not ($items -is [string])) {
        return ($items | ForEach-Object { "- $_" }) -join "`n"
    }
    return "$items"
}

function Get-ProtagonistasText($protas) {
    if ($null -eq $protas) { return "" }
    $lines = @()
    foreach ($p in $protas) {
        if ($p -is [pscustomobject]) {
            $lines += "### $($p.nombre)"
            if ($p.deseo) { $lines += "- **Deseo:** $($p.deseo)" }
            if ($p.obstaculo) { $lines += "- **Obstaculo:** $($p.obstaculo)" }
            if ($p.arco) { $lines += "- **Arco:** $($p.arco)" }
            $lines += ""
        }
    }
    return ($lines -join "`n").Trim()
}

function Get-HiloSlug($hilo) {
    if ($hilo.slug) {
        return ($hilo.slug -replace '[^a-z0-9-]', '').Trim('-')
    }
    if ($hilo.nombre) {
        $s = $hilo.nombre.ToLower()
        $s = $s -replace '[áàä]', 'a' -replace '[éèë]', 'e' -replace '[íìï]', 'i'
        $s = $s -replace '[óòö]', 'o' -replace '[úùü]', 'u' -replace 'ñ', 'n'
        $s = $s -replace '[^a-z0-9]+', '-'
        return $s.Trim('-')
    }
    throw "Cada hilo necesita slug o nombre."
}

function Expand-TemplateFile($templatePath, $replacements) {
    $text = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
    foreach ($kv in $replacements.GetEnumerator()) {
        $text = $text -replace [regex]::Escape("{{$($kv.Key)}}"), [string]$kv.Value
    }
    return $text
}

function Expand-MapaConditionals($text, $escala) {
    $isNovela = $escala -ne "relato"
    $isMultiHilo = $escala -eq "novela-multi-hilo"

    if ($isNovela) {
        $text = $text -replace '\{\{#if novela\}\}\r?\n?', ''
        $text = $text -replace '\r?\n?\{\{/if\}\}', ''
    } else {
        $text = $text -replace '(?s)\{\{#if novela\}\}.*?\{\{/if\}\}', ''
    }

    if ($isMultiHilo) {
        $text = $text -replace '\{\{#if multi-hilo\}\}\r?\n?', ''
        $text = $text -replace '\r?\n?\{\{/if\}\}', ''
    } else {
        $text = $text -replace '(?s)\{\{#if multi-hilo\}\}.*?\{\{/if\}\}', ''
    }

    return $text
}

function Inject-ScalePipeline {
    param(
        [string]$SharedDir,
        [string]$TargetDir,
        [string]$Escala
    )
    $targetOC = Join-Path $TargetDir ".opencode"

    # --- 1. Agentes comunes (7) ---
    $commonAgents = Join-Path $SharedDir ".opencode\agents"
    if (Test-Path -LiteralPath $commonAgents) {
        Get-ChildItem -LiteralPath $commonAgents -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetOC "agents\$($_.Name)") -Force
        }
    }

    # --- 2. Director y guionista de la escala (sobrescriben) ---
    $scalePipelineDir = Join-Path $SharedDir "pipelines\$Escala"
    if (-not (Test-Path -LiteralPath $scalePipelineDir)) {
        throw "Pipeline de escala no encontrado: $scalePipelineDir"
    }
    Copy-Item -LiteralPath (Join-Path $scalePipelineDir "director.md") -Destination (Join-Path $targetOC "agents\director.md") -Force
    Copy-Item -LiteralPath (Join-Path $scalePipelineDir "guionista.md") -Destination (Join-Path $targetOC "agents\guionista.md") -Force

    # --- 3. PIPELINE.md ---
    Copy-Item -LiteralPath (Join-Path $scalePipelineDir "PIPELINE.md") -Destination (Join-Path $TargetDir "PIPELINE.md") -Force

    # --- 4. Skills (TODOS los 37, sin filtrar) ---
    $hubSkills = Join-Path $SharedDir ".opencode\skills"
    $wsSkills = Join-Path $targetOC "skills"
    if (Test-Path -LiteralPath $hubSkills) {
        Get-ChildItem -LiteralPath $hubSkills -Directory | ForEach-Object {
            $dest = Join-Path $wsSkills $_.Name
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse
        }
    }

    # --- 5. Comandos (TODOS los 4) ---
    $hubCommands = Join-Path $SharedDir ".opencode\commands"
    $wsCommands = Join-Path $targetOC "commands"
    if (Test-Path -LiteralPath $hubCommands) {
        Get-ChildItem -LiteralPath $hubCommands -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $wsCommands $_.Name) -Force
        }
    }

    # --- 6. Contratos (MAPA.md y ORQUESTACION.md) ---
    $contratosDir = Join-Path $SharedDir "contratos"
    if (Test-Path -LiteralPath $contratosDir) {
        Copy-Item -LiteralPath (Join-Path $contratosDir "ORQUESTACION.md") -Destination (Join-Path $TargetDir "ORQUESTACION.md") -Force
        # MAPA.md se expande en main con sustituciones y condicionales
    }

    # --- 7. Plantillas de la escala ---
    $scalePlantillas = Join-Path $SharedDir "plantillas\$Escala"
    $wsPlantillas = Join-Path $TargetDir "plantillas"
    if (Test-Path -LiteralPath $scalePlantillas) {
        Get-ChildItem -LiteralPath $scalePlantillas | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $wsPlantillas -Recurse -Force
        }
    }
}

function New-OperationalHilos {
    param($briefHilos, [string]$Now, [string]$PipelineDir)
    $ops = @()
    foreach ($h in $briefHilos) {
        $slug = Get-HiloSlug $h
        $id = "hilo-$slug"
        $ops += [ordered]@{
            id = $id
            nombre = if ($h.nombre) { $h.nombre } else { $slug }
            slug = $slug
            epoca = if ($h.epoca) { $h.epoca } else { "" }
            conflicto = if ($h.conflicto) { $h.conflicto } else { "" }
            personajes = if ($h.personajes) { $h.personajes } else { @() }
            estado = "pendiente"
            archivo_diseno = "hilos/$id/diseno-hilo.md"
            archivo_guion = "hilos/$id/guion-hilo.md"
            ultimo_capitulo = $null
        }
    }
    return $ops
}

function Seed-HiloFolders {
    param(
        [string]$TargetDir,
        [string]$SharedDir,
        [string]$Titulo,
        [string]$Now,
        $operationalHilos
    )
    $tplDiseno = Join-Path $SharedDir "plantillas\novela-multi-hilo\diseno-hilo.md"
    $tplGuion = Join-Path $SharedDir "plantillas\novela-multi-hilo\guion-hilo.md"
    foreach ($h in $operationalHilos) {
        $folder = Join-Path $TargetDir "hilos\$($h.id)"
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        $personajes = if ($h.personajes -and $h.personajes.Count -gt 0) {
            ($h.personajes | ForEach-Object { "- $_" }) -join "`n"
        } else { "- (pendiente)" }
        $repl = @{
            NOMBRE = $h.nombre
            SLUG = $h.slug
            EPOCA = if ($h.epoca) { $h.epoca } else { "" }
            UBICACION = if ($h.ubicacion) { $h.ubicacion } else { "" }
            CONFLICTO = if ($h.conflicto) { $h.conflicto } else { "(pendiente)" }
            PERSONAJES = $personajes
            PERSONAJE1 = if ($h.personajes -and $h.personajes.Count -ge 1) { $h.personajes[0] } else { "(pendiente)" }
            PERSONAJE2 = if ($h.personajes -and $h.personajes.Count -ge 2) { $h.personajes[1] } else { "(pendiente)" }
            FECHA = $Now
            TITULO = $Titulo
            TONO = if ($h.tono) { $h.tono } else { "(coherente con estilo global)" }
        }
        Expand-TemplateFile $tplDiseno $repl | Set-Content -LiteralPath (Join-Path $folder "diseno-hilo.md") -Encoding UTF8
        Expand-TemplateFile $tplGuion $repl | Set-Content -LiteralPath (Join-Path $folder "guion-hilo.md") -Encoding UTF8
    }
}

function Build-MultiHiloGuionReplacements {
    param($operationalHilos, $brief, [string]$Titulo, [string]$Estilo)
    $repl = @{
        TITULO = $Titulo
        ESTILO = $Estilo
        NUM_HILOS = [string]$operationalHilos.Count
        PUNTOS_CONEXION = if ($brief -and $brief.puntos_conexion) {
            Get-ListText $brief.puntos_conexion
        } else { "- (pendiente -- definir en FASE 0 con el director)" }
        HILO1 = ""; HILO2 = ""; HILO3 = ""
        HILO1_ID = ""; HILO2_ID = ""; HILO3_ID = ""
        HILO1_NOMBRE = ""; HILO2_NOMBRE = ""; HILO3_NOMBRE = ""
        HILO1_SLUG = ""; HILO2_SLUG = ""; HILO3_SLUG = ""
        HILO1_EPOCA = ""; HILO2_EPOCA = ""; HILO3_EPOCA = ""
    }
    for ($i = 0; $i -lt [Math]::Min($operationalHilos.Count, 3); $i++) {
        $n = $i + 1
        $repl["HILO$n"] = $operationalHilos[$i].nombre
        $repl["HILO${n}_ID"] = $operationalHilos[$i].id
        $repl["HILO${n}_NOMBRE"] = $operationalHilos[$i].nombre
        $repl["HILO${n}_SLUG"] = $operationalHilos[$i].slug
        $repl["HILO${n}_EPOCA"] = if ($operationalHilos[$i].epoca) { $operationalHilos[$i].epoca } else { "--" }
    }
    return $repl
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

$HubRoot = Split-Path -Parent $PSScriptRoot
$TemplateDir = Join-Path $HubRoot "workspaces\_template"
$SharedDir = Join-Path $HubRoot "shared"
$brief = $null

# -- 1. Inicializacion y carga de brief.json --

if ($BriefJsonPath) {
    if (-not (Test-Path -LiteralPath $BriefJsonPath)) { throw "No se encuentra el briefing: $BriefJsonPath" }
    $brief = Get-Content -LiteralPath $BriefJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $Slug -and $brief.slug) { $Slug = $brief.slug }
    if (-not $Titulo -and $brief.titulo) { $Titulo = $brief.titulo }
    if ($brief.estilo_base) { $Estilo = $brief.estilo_base }
    if ($brief.estilo_secundario -and -not $EstiloSecundario) { $EstiloSecundario = $brief.estilo_secundario }
    if ($brief.escala) { $Escala = $brief.escala }
    if ($brief.premisa -and -not $Premisa) { $Premisa = $brief.premisa }
}

if (-not $Slug -or -not $Titulo) { throw "Se requieren Slug y Titulo (o BriefJsonPath completo)." }

$TargetDir = Join-Path $HubRoot "workspaces\$Slug"

if (-not (Test-Path -LiteralPath $TemplateDir)) { throw "Plantilla no encontrada: $TemplateDir" }
if (-not (Test-Path -LiteralPath $SharedDir)) { throw "Directorio shared no encontrado: $SharedDir" }
if (Test-Path -LiteralPath $TargetDir) { throw "Ya existe: $TargetDir" }

# -- 2. Determinar infraestructura (Qdrant / Neo4j) --

$UsarQdrant = $false
$UsarNeo4j = $false
if ($Escala -ne "relato") {
    if ($SinInfra) {
        $UsarQdrant = $false
        $UsarNeo4j = $false
    } elseif ($ConQdrant -or $ConNeo4j) {
        if ($ConQdrant) { $UsarQdrant = $true }
        if ($ConNeo4j) { $UsarNeo4j = $true }
    } else {
        $UsarQdrant = $true
        $UsarNeo4j = $true
    }
}

Write-Host "Creando workspace ($Escala): $TargetDir"

# -- 3. Copiar template base --

Copy-Item -LiteralPath $TemplateDir -Destination $TargetDir -Recurse

# -- 4. Inyectar pipeline segun escala --

Write-Host "Inyectando pipeline $Escala..."
Inject-ScalePipeline -SharedDir $SharedDir -TargetDir $TargetDir -Escala $Escala

# -- 5. Fecha y configuracion temporal --

$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
$tipo = if ($Escala -eq "relato") { "relato" } else { "novela" }

# -- 6. Generar project.toml --

$projectTomlContent = @"
name = "$Slug"
type = "fiction-pipeline"
pipeline = "shared/pipelines/$Escala"

[defaults]
language = "es"
default_agent = "director"

[project]
slug = "$Slug"
titulo = "$Titulo"
escala = "$Escala"
estilo_base = "$Estilo"
$(
    if ($EstiloSecundario) { "estilo_secundario = `"$EstiloSecundario`"" } else { "" }
)

[infra]
qdrant = $($UsarQdrant.ToString().ToLower())
neo4j = $($UsarNeo4j.ToString().ToLower())

[paths]
fichas = "fichas/"
$(if ($Escala -ne "relato") { "capitulos = `"capitulos/`"" })
plantillas = "plantillas/"
publicados = "publicados/"
$(if ($Escala -eq "novela-multi-hilo") { "hilos = `"hilos/`"" })
"@
Set-Content -LiteralPath (Join-Path $TargetDir "project.toml") -Value $projectTomlContent -Encoding UTF8

# -- 7. Generar config.json --

$config = [ordered]@{
    titulo = $Titulo
    slug = $Slug
    tipo = $tipo
    escala = $Escala
    estado = "diseno"
    estilo_base = $Estilo
    creado = $now
    ultima_modificacion = $now
    capitulos_completados = 0
    ultimo_hecho_global = if ($Escala -eq "relato") { "H_00" } else { "H_0000" }
    ultimo_beat_global = if ($Escala -eq "relato") { "B_00" } else { "B_0000" }
}
if ($EstiloSecundario) { $config.estilo_secundario = $EstiloSecundario }

if ($brief) {
    foreach ($key in @("logline","genero","subgenero","tono","atmosfera","explicitud","pov","extension_estimada","capitulos_estimados","antagonista_o_conflicto","temas","referencias","restricciones","puntos_conexion")) {
        if ($brief.PSObject.Properties.Name -contains $key -and $null -ne $brief.$key) {
            $config[$key] = $brief.$key
        }
    }
    if ($brief.protagonistas) { $config.protagonistas = $brief.protagonistas }
    if ($brief.personajes_clave) { $config.personajes_clave = $brief.personajes_clave }
    if ($brief.setting) { $config.setting = $brief.setting }
    if ($brief.reflexion_agente) { $config.reflexion_agente = $brief.reflexion_agente }
}

if ($Escala -ne "relato" -and $UsarQdrant) {
    $config.version_qdrant = "pendiente"
}
if ($Escala -ne "relato" -and $UsarNeo4j) {
    $config.version_neo4j = "pendiente"
}

if ($Escala -eq "novela-multi-hilo" -and $brief -and $brief.hilos) {
    $config.hilos = @(New-OperationalHilos $brief.hilos $now $SharedDir)
    if ($brief -and $brief.partes) { $config.partes = $brief.partes }
}

$config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $TargetDir "config.json") -Encoding UTF8

# -- 8. Generar AGENTS.md --

$explicitud = if ($brief -and $brief.explicitud) { $brief.explicitud } else { "maximo" }
$tonoRule = if ($brief -and $brief.tono) { $brief.tono } else { "coherente con $Estilo" }
$restricciones = if ($brief -and $brief.restricciones) { Get-ListText $brief.restricciones } else { "- (ninguna)" }
$temas = if ($brief -and $brief.temas) { Get-ListText $brief.temas } else { "- (ver BRIEF.md)" }

$skillsActivos = @(
    "mecanica-prosa", "beats-estructura", "estructura-narrativa", "tonos-beat",
    "estilo-$Estilo"
)
if ($EstiloSecundario) { $skillsActivos += "estilo-$EstiloSecundario" }
$skillsActivos += @(
    "plantilla-guion", "plantilla-ficha", "plantilla-personaje", "plantilla-lugar",
    "plantilla-objeto", "plantilla-animal", "plantilla-arco", "plantilla-evento",
    "plantilla-organizacion",
    "validacion-crudeza", "validacion-coherencia", "validacion-geometria",
    "validacion-sensorial", "validacion-tono",
    "consistencia-narrativa", "contexto-subagente", "desarrollo-narrativa",
    "fichas-personajes",
    "estilo-prosa"
)
if ($Escala -eq "novela-multi-hilo") {
    $skillsActivos += @("plantilla-hilo", "diseno-hilo", "trenzado-narrativo", "validacion-cross-hilo")
}
if ($Escala -ne "relato") {
    if ($UsarQdrant) { $skillsActivos += "qdrant" }
    if ($UsarNeo4j) { $skillsActivos += @("neo4j", "auditoria-neo4j") }
}
$skillsActivos += @("generar", "revisar", "expandir", "publicar")

$skillsStr = ($skillsActivos -join ", ")
$estiloRef = "``estilo-$Estilo``"
if ($EstiloSecundario) { $estiloRef += " + ``estilo-$EstiloSecundario`` (fusion)" }
$hiloSection = if ($Escala -eq "novela-multi-hilo") {
@"

### Hilos
Hilos en ``config.json.hilos`` y ``hilos/hilo-*/``.
``config.json.hilos[].estado`` indica el progreso de cada hilo (pendiente | disenado | guion_listo).
"@
} else { "" }
$infraSection = ""
if ($Escala -ne "relato" -and ($UsarQdrant -or $UsarNeo4j)) {
    $infraSection += ""
    if ($UsarQdrant) { $infraSection += "Qdrant ``:6333`` (colecciones ``${Slug}_beats``, ``${Slug}_summaries``, ``${Slug}_entidades``) " }
    if ($UsarNeo4j) { $infraSection += "Neo4j ``:7687`` (grafo ``$Slug``)" }
}

$agentsMd = @"
# $Titulo

**Workspace generado por Forja Hub.**
**Escala:** $Escala | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** $estiloRef
- **Tono:** $tonoRule
- **Explicitud:** $explicitud (sin eufemismos, vocabulario directo).
- **POV:** $(if ($brief -and $brief.pov) { $brief.pov } else { "segun BRIEF.md" }).

### Temas
$temas

### Restricciones
$restricciones

### Skills activos
$skillsStr
$hiloSection

## Infraestructura
$(if ($infraSection) { $infraSection } else { "Modo ligero: sin Qdrant ni Neo4j. Memoria en contexto_narrativo.md (relato) o contexto.md (novela sin infra)." })

## Arranque
``/generar`` (el director lee ``config.json`` y ``PIPELINE.md`` y orquesta segun ``ORQUESTACION.md``).
"@
Set-Content -LiteralPath (Join-Path $TargetDir "AGENTS.md") -Value $agentsMd -Encoding UTF8

# -- 9. Generar BRIEF.md --

$hilosBrief = ""
$puntosBrief = ""
if ($Escala -eq "novela-multi-hilo") {
    if ($brief -and $brief.hilos) {
        $hilosBrief = "`n`n## Hilos`n`n" + (($brief.hilos | ForEach-Object {
            $sl = Get-HiloSlug $_
            "- **$(if ($_.nombre) { $_.nombre } else { $sl })** ($sl): $(if ($_.epoca) { $_.epoca } else { '---' }) -- $(if ($_.conflicto) { $_.conflicto } else { '---' })"
        }) -join "`n")
    }
    if ($brief -and $brief.puntos_conexion) {
        $puntosBrief = "`n`n## Puntos de conexion`n`n$(Get-ListText $brief.puntos_conexion)"
    }
}

$escalaHumana = switch ($Escala) {
    "relato" { "Relato (<20K palabras, ~30 escenas, 4 fases)" }
    "novela-simple" { "Novela simple (>20K palabras, una linea temporal, 6 fases)" }
    "novela-multi-hilo" { "Novela multi-hilo (multiples lineas temporales/POVs, 8 fases)" }
}

$reflexionText = if ($brief -and $brief.reflexion_agente) {
    $r = $brief.reflexion_agente
    $fortalezas = Get-ListText $r.fortalezas
    $riesgos = Get-ListText $r.riesgos
    $decisionesLine = ""
    if ($r.decisiones_usuario) {
        $decisionesLine = "`n`n**Decisiones del usuario:** $(Get-ListText $r.decisiones_usuario)"
    }
    "**Fortalezas:** $fortalezas`n`n**Riesgos:** $riesgos$decisionesLine"
} else { "--- (completar en briefing del hub si aplica)" }

$briefMd = @"
# Brief -- $Titulo

## Logline
$(if ($brief -and $brief.logline) { $brief.logline } else { "---" })

## Premisa
$(if ($brief -and $brief.premisa) { $brief.premisa } elseif ($Premisa) { $Premisa } else { "---" })

## Genero y voz
- **Genero:** $(if ($brief -and $brief.genero) { $brief.genero } else { "---" })$(if ($brief -and $brief.subgenero) { " / $($brief.subgenero)" } else { "" })
- **Estilo base:** $Estilo$(if ($EstiloSecundario) { " + $EstiloSecundario (fusion)" } else { "" })
- **Tono:** $(if ($brief -and $brief.tono) { $brief.tono } else { "---" })
- **Explicitud:** $explicitud
- **POV:** $(if ($brief -and $brief.pov) { $brief.pov } else { "---" })
- **Atmosfera:** $(if ($brief -and $brief.atmosfera) { $brief.atmosfera } else { "---" })

## Protagonistas
$(if ($brief) { Get-ProtagonistasText $brief.protagonistas } else { "- (definir en FASE 0 / _brainstorming.md)" })

## Conflicto
$(if ($brief -and $brief.antagonista_o_conflicto) { $brief.antagonista_o_conflicto } else { "---" })

## Estructura
- **Escala:** $escalaHumana
- **Extension:** $(if ($brief -and $brief.extension_estimada) { $brief.extension_estimada } else { "---" })
- **Capitulos estimados:** $(if ($brief -and $brief.capitulos_estimados) { $brief.capitulos_estimados } else { "---" })
- **Referencias:** $(if ($brief -and $brief.referencias) { Get-ListText $brief.referencias } else { "---" })$hilosBrief$puntosBrief

## Restricciones
$(if ($brief) { Get-ListText $brief.restricciones } else { "- (ver AGENTS.md / BRIEF.md)" })

## Reflexion editorial
$reflexionText
"@
Set-Content -LiteralPath (Join-Path $TargetDir "BRIEF.md") -Value $briefMd -Encoding UTF8

# -- 10. Crear carpetas --

if ($Escala -eq "relato") {
    # Relato: sin capitulos/
    $capDir = Join-Path $TargetDir "capitulos"
    if (Test-Path -LiteralPath $capDir) { Remove-Item -LiteralPath $capDir -Recurse -Force }
}

$dirs = @("fichas", "publicados")
if ($Escala -ne "relato") { $dirs += "capitulos" }
if ($Escala -eq "novela-multi-hilo") { $dirs += "hilos" }
foreach ($d in $dirs) {
    $p = Join-Path $TargetDir $d
    if (-not (Test-Path -LiteralPath $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

# Para relato: asegurar que no quede hilos/ del template
if ($Escala -ne "novela-multi-hilo") {
    $hilosDir = Join-Path $TargetDir "hilos"
    if (Test-Path -LiteralPath $hilosDir) {
        Remove-Item -LiteralPath $hilosDir -Recurse -Force
    }
}

# -- 11. Expandir MAPA.md desde contratos --

$mapaContratos = Join-Path $SharedDir "contratos\MAPA.md"
if (Test-Path -LiteralPath $mapaContratos) {
    $mapaExpanded = Expand-TemplateFile $mapaContratos @{
        TITULO = $Titulo
        SLUG = $Slug
        ESCALA = $Escala
    }
    $mapaExpanded = Expand-MapaConditionals $mapaExpanded $Escala
    Set-Content -LiteralPath (Join-Path $TargetDir "MAPA.md") -Value $mapaExpanded -Encoding UTF8
}

# -- 12. Generar guion inicial desde plantilla --

if ($Escala -eq "relato") {
    $guionTpl = Join-Path $SharedDir "plantillas\relato\guion-relato.md"
    if (Test-Path -LiteralPath $guionTpl) {
        $extension = if ($brief -and $brief.extension_estimada) { $brief.extension_estimada } else { "por definir" }
        $guionRepl = @{
            TITULO = $Titulo
            ESTILO = $Estilo
            EXTENSION = $extension
        }
        Expand-TemplateFile $guionTpl $guionRepl | Set-Content -LiteralPath (Join-Path $TargetDir "guion-relato.md") -Encoding UTF8
    }
} elseif ($Escala -eq "novela-simple") {
    $guionTpl = Join-Path $SharedDir "plantillas\novela-simple\guion-novela.md"
    if (Test-Path -LiteralPath $guionTpl) {
        $capitulos = if ($brief -and $brief.capitulos_estimados) { $brief.capitulos_estimados } else { "por definir" }
        $guionRepl = @{
            TITULO = $Titulo
            ESTILO = $Estilo
            CAPITULOS = [string]$capitulos
        }
        Expand-TemplateFile $guionTpl $guionRepl | Set-Content -LiteralPath (Join-Path $TargetDir "guion-novela.md") -Encoding UTF8
    }
} elseif ($Escala -eq "novela-multi-hilo") {
    $guionTpl = Join-Path $SharedDir "plantillas\novela-multi-hilo\guion-novela.md"
    if (Test-Path -LiteralPath $guionTpl) {
        $repl = Build-MultiHiloGuionReplacements -operationalHilos $config.hilos -brief $brief -Titulo $Titulo -Estilo $Estilo
        Expand-TemplateFile $guionTpl $repl | Set-Content -LiteralPath (Join-Path $TargetDir "guion-novela.md") -Encoding UTF8
    }
}

# -- 13. Sembrar hilos (multi-hilo) --

if ($Escala -eq "novela-multi-hilo" -and $config.hilos) {
    Seed-HiloFolders -TargetDir $TargetDir -SharedDir $SharedDir -Titulo $Titulo -Now $now -operationalHilos $config.hilos
}

# -- 14. Generar archivos de trabajo --

$premisaBlock = if ($brief -and $brief.premisa) { $brief.premisa } elseif ($Premisa) { $Premisa.Trim() } else { "" }
$protagonistasBlock = if ($brief) { Get-ProtagonistasText $brief.protagonistas } else { "" }

if ($Escala -eq "relato") {
    # contexto_narrativo.md desde plantilla
    $ctxTpl = Join-Path $SharedDir "plantillas\relato\contexto_narrativo.md"
    if (Test-Path -LiteralPath $ctxTpl) {
        Expand-TemplateFile $ctxTpl @{ TITULO = $Titulo } | Set-Content -LiteralPath (Join-Path $TargetDir "contexto_narrativo.md") -Encoding UTF8
    }
    # relato-draft.md
    Set-Content -LiteralPath (Join-Path $TargetDir "relato-draft.md") -Value "# Borrador -- $Titulo`n`n> Secciones ``## B_NNNN`` generadas por el escritor beat a beat." -Encoding UTF8
} else {
    # contexto.md
    Set-Content -LiteralPath (Join-Path $TargetDir "contexto.md") -Value "# Contexto -- $Titulo`n`n> Actualizar tras cada capitulo.`n" -Encoding UTF8
}

# _brainstorming.md
@"
# Brainstorming -- $Titulo

## Premisa
$premisaBlock

## Protagonistas
$protagonistasBlock

## Notas
(Espacio para notas creativas durante el desarrollo)
"@ | Set-Content -LiteralPath (Join-Path $TargetDir "_brainstorming.md") -Encoding UTF8

# _actos.md
@"
# Actos -- $Titulo

## Acto I -- Planteamiento

(Definir en FASE 0 de diseno)

## Acto II -- Desarrollo

(Definir en FASE 0 de diseno)

## Acto III -- Resolucion

(Definir en FASE 0 de diseno)
"@ | Set-Content -LiteralPath (Join-Path $TargetDir "_actos.md") -Encoding UTF8

# -- 15. Configurar Qdrant y Neo4j --

if ($Escala -ne "relato") {
    $pythonCmd = $null
    # Buscar python3 o python
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    }

    if ($pythonCmd -and $UsarQdrant) {
        Write-Host "Verificando Qdrant (localhost:6333)..."
        $qdrantAvailable = $false
        try {
            $tcp = Test-NetConnection -ComputerName localhost -Port 6333 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $qdrantAvailable = $tcp
        } catch { }
        if ($qdrantAvailable) {
            Write-Host "  Qdrant disponible. Inicializando..."
            try {
                & $pythonCmd "$HubRoot\scripts\qdrant.py" init 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Qdrant inicializado correctamente." -ForegroundColor Green
                    if ($config.ContainsKey("version_qdrant")) {
                        $config.version_qdrant = "activo"
                        $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $TargetDir "config.json") -Encoding UTF8
                    }
                } else {
                    Write-Warning "  Qdrant init devolvio codigo $LASTEXITCODE. Verificar manualmente."
                }
            } catch {
                Write-Warning "  No se pudo ejecutar qdrant.py init: $_"
            }
        } else {
            Write-Warning "  Qdrant no disponible en localhost:6333. Inicializacion pospuesta."
        }
    }

    if ($pythonCmd -and $UsarNeo4j) {
        Write-Host "Verificando Neo4j (localhost:7687)..."
        $neo4jAvailable = $false
        try {
            $tcp = Test-NetConnection -ComputerName localhost -Port 7687 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $neo4jAvailable = $tcp
        } catch { }
        if ($neo4jAvailable) {
            Write-Host "  Neo4j disponible. Inicializando..."
            try {
                & $pythonCmd "$HubRoot\scripts\neo4j.py" init 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Neo4j inicializado correctamente." -ForegroundColor Green
                    if ($config.ContainsKey("version_neo4j")) {
                        $config.version_neo4j = "activo"
                        $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $TargetDir "config.json") -Encoding UTF8
                    }
                } else {
                    Write-Warning "  Neo4j init devolvio codigo $LASTEXITCODE. Verificar manualmente."
                }
            } catch {
                Write-Warning "  No se pudo ejecutar neo4j.py init: $_"
            }
        } else {
            Write-Warning "  Neo4j no disponible en localhost:7687. Inicializacion pospuesta."
        }
    }

    if (-not $pythonCmd -and ($UsarQdrant -or $UsarNeo4j)) {
        Write-Warning "  Python no encontrado. Qdrant/Neo4j no se inicializaran."
    }
}

# -- 16. Confirmacion --

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Workspace creado [$Escala]" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Ruta:      $TargetDir"
Write-Host "  Escala:    $Escala ($(if ($Escala -eq 'relato') {'4 fases'} elseif ($Escala -eq 'novela-simple') {'6 fases'} else {'8 fases'}))"
Write-Host "  Estilo:    $Estilo$(if ($EstiloSecundario) { " + $EstiloSecundario (fusion)" } else { '' })"
Write-Host "  Skills:    $($skillsActivos.Count) activos"
if ($Escala -eq "novela-multi-hilo" -and $config.hilos) {
    Write-Host "  Hilos:     $($config.hilos.Count) ($(($config.hilos | ForEach-Object { $_.nombre }) -join ', '))"
}
Write-Host ""
if ($Escala -ne "relato") {
    Write-Host "  Infra:     Qdrant=$UsarQdrant | Neo4j=$UsarNeo4j"
}
Write-Host ""
Write-Host "  Para comenzar:" -ForegroundColor Yellow
Write-Host "    opencode --cwd ""workspaces\$Slug"""
Write-Host "    /generar"
Write-Host ""
