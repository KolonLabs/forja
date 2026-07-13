# common.ps1 — Utilidades compartidas para scripts de creación de workspaces
# Requiere: $HubRoot definido (raíz de Forja)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Validación
# ------------------------------------------------------------

function Test-BriefField {
    param($Brief, [string]$Field, [string]$Context)
    if (-not $Brief.PSObject.Properties.Name.Contains($Field) -or -not $Brief.$Field) {
        throw "$Context`: brief no contiene '$Field' o está vacio"
    }
}

function Test-HechosStructure {
    param($Brief)
    
    Test-BriefField $Brief "hechos" "hechos"
    $hechos = $Brief.hechos
    if (-not ($hechos -is [array])) { throw "hechos debe ser un array de actos" }
    if ($hechos.Count -eq 0) { throw "hechos está vacío: define al menos un acto" }
    
    $actNum = 1
    foreach ($acto in $hechos) {
        foreach ($field in @("acto","objetivo","efecto_lector","tension")) {
            if (-not $acto.PSObject.Properties.Name.Contains($field) -or -not $acto.$field) {
                throw "hechos[$(($actNum-1))]: falta campo '$field' para acto '$(if ($acto.acto) { $acto.acto } else { '(sin nombre)' })'"
            }
        }
        if (-not ($acto.hechos -is [array]) -or $acto.hechos.Count -eq 0) {
            throw "hechos[$(($actNum-1))]: 'hechos' debe ser un array con al menos un elemento para acto '$(if ($acto.acto) { $acto.acto } else { '(sin nombre)' })'"
        }
        foreach ($hecho in $acto.hechos) {
            if (-not ($hecho -is [string]) -or [string]::IsNullOrWhiteSpace($hecho)) {
                throw "hechos[$(($actNum-1))]: cada hecho debe ser texto no vacio"
            }
        }
        $actNum++
    }

    # Los actos multi-hilo se enlazan por el slug canonico del hilo.
    if ($Brief.escala -eq "novela-multi-hilo") {
        Test-MultiHiloBrief $Brief
        $validHilos = @()
        foreach ($h in $Brief.hilos) {
            $validHilos += Get-HiloSlug $h
        }
        foreach ($acto in $hechos) {
            if (-not $acto.PSObject.Properties.Name.Contains("hilo") -or -not $acto.hilo) {
                throw "hechos[acto '$($acto.acto)']: falta campo 'hilo' (requerido en novela-multi-hilo)"
            }
            if ($acto.hilo -notin $validHilos) {
                throw "hechos[acto '$($acto.acto)']: hilo '$($acto.hilo)' no definido en hilos[] (válidos: $($validHilos -join ', '))"
            }
        }
        foreach ($slug in $validHilos) {
            if (-not ($hechos | Where-Object { $_.hilo -eq $slug } | Select-Object -First 1)) {
                throw "novela-multi-hilo: el hilo '$slug' no tiene ningun acto definido en hechos[]"
            }
        }
    }
}


function Get-ListText {
    param($Items)
    if ($null -eq $Items) { return "" }
    if ($Items -is [string]) { return $Items }
    if ($Items -is [System.Collections.IEnumerable] -and -not ($Items -is [string])) {
        return ($Items | ForEach-Object { "- $_" }) -join "`n"
    }
    return "$Items"
}

function Get-ProtagonistasText {
    param($Protas)
    if ($null -eq $Protas) { return "" }
    $lines = @()
    foreach ($p in $Protas) {
        $lines += "### $($p.nombre)"
        if ($p.deseo) { $lines += "- **Deseo:** $($p.deseo)" }
        if ($p.obstaculo) { $lines += "- **Obstaculo:** $($p.obstaculo)" }
        if ($p.arco) { $lines += "- **Arco:** $($p.arco)" }
        $lines += ""
    }
    return ($lines -join "`n").Trim()
}

# ------------------------------------------------------------
# Inyección de pipeline (agentes + skills + ORQUESTACION + PIPELINE)
# ------------------------------------------------------------

function Inject-Pipeline {
    param(
        [string]$TargetDir,
        [string]$Escala
    )
    $SharedDir = Join-Path $HubRoot "shared"
    $ScaleDir = Join-Path $SharedDir "pipelines\$Escala"
    $targetOC = Join-Path $TargetDir ".opencode"

    if (-not (Test-Path -LiteralPath $ScaleDir)) {
        throw "Inject-Pipeline: pipeline no encontrado: $ScaleDir"
    }

    # 1. Agentes fijos (memoria, cronista, epub — solo novelas)
    if ($Escala -ne "relato") {
        $commonAgents = Join-Path $SharedDir ".opencode\agents"
        if (Test-Path -LiteralPath $commonAgents) {
            Get-ChildItem -LiteralPath $commonAgents -File -Filter "*.md" | ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetOC "agents\$($_.Name)") -Force
            }
        }
    }

    # 2. Agentes de escala (6)
    $scaleAgents = Join-Path $ScaleDir "agentes"
    if (Test-Path -LiteralPath $scaleAgents) {
        Get-ChildItem -LiteralPath $scaleAgents -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetOC "agents\$($_.Name)") -Force
        }
    }

    # 3. PIPELINE.md
    Copy-Item -LiteralPath (Join-Path $ScaleDir "PIPELINE.md") -Destination (Join-Path $TargetDir "PIPELINE.md") -Force

    # 4. ORQUESTACION.md
    Copy-Item -LiteralPath (Join-Path $ScaleDir "ORQUESTACION.md") -Destination (Join-Path $TargetDir "ORQUESTACION.md") -Force

    # 5. Skills filtrados por escala
    $hubSkills = Join-Path $SharedDir ".opencode\skills"
    $wsSkills = Join-Path $targetOC "skills"
    $excluded = @()
    if ($Escala -eq "relato") {
        $excluded = @("auditoria-neo4j","diseno-hilo","hechos-estructura","neo4j","plantilla-arco","plantilla-hilo","qdrant","trenzado-narrativo","validacion-cross-hilo")
    } elseif ($Escala -eq "novela-simple") {
        $excluded = @("diseno-hilo","plantilla-hilo","trenzado-narrativo","validacion-cross-hilo")
    }

    if (Test-Path -LiteralPath $hubSkills) {
        Get-ChildItem -LiteralPath $hubSkills -Directory | ForEach-Object {
            if ($_.Name -in $excluded) { return }
            $dest = Join-Path $wsSkills $_.Name
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse
        }
    }

    # 6. Skills de la escala (4: contexto-subagente, estructura-narrativa, plantilla-guion, beats-estructura)
    $scaleSkills = Join-Path $ScaleDir "skills"
    if (Test-Path -LiteralPath $scaleSkills) {
        Get-ChildItem -LiteralPath $scaleSkills -Directory | ForEach-Object {
            $src = Join-Path $scaleSkills $_.Name
            $dest = Join-Path $wsSkills $_.Name
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Copy-Item -LiteralPath $src -Destination $dest -Recurse
        }
    }

    # 7. Comandos
    $hubCommands = Join-Path $SharedDir ".opencode\commands"
    $wsCommands = Join-Path $targetOC "commands"
    if (Test-Path -LiteralPath $hubCommands) {
        Get-ChildItem -LiteralPath $hubCommands -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $wsCommands $_.Name) -Force
        }
    }

    # 8. Scripts Python de infraestructura (solo novelas)
    if ($Escala -ne "relato") {
        $scriptsDir = Join-Path $TargetDir "scripts"
        if (-not (Test-Path -LiteralPath $scriptsDir)) {
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
        }
        Copy-Item -LiteralPath (Join-Path $HubRoot "scripts\qdrant.py") -Destination (Join-Path $scriptsDir "qdrant.py") -Force
        Copy-Item -LiteralPath (Join-Path $HubRoot "scripts\neo4j.py") -Destination (Join-Path $scriptsDir "neo4j.py") -Force
    }
}

function Test-MultiHiloBrief {
    param($Brief)

    Test-BriefField $Brief "hilos" "novela-multi-hilo"
    Test-BriefField $Brief "_hilos" "novela-multi-hilo"
    if (-not ($Brief.hilos -is [array]) -or $Brief.hilos.Count -lt 2) {
        throw "novela-multi-hilo: hilos debe contener al menos dos hilos"
    }
    if (-not ($Brief._hilos -is [array]) -or $Brief._hilos.Count -eq 0) {
        throw "novela-multi-hilo: _hilos debe contener los archivos iniciales de cada hilo"
    }

    $knownSlugs = @{}
    foreach ($hilo in $Brief.hilos) {
        foreach ($field in @("slug", "nombre", "epoca", "conflicto")) {
            if (-not $hilo.PSObject.Properties.Name.Contains($field) -or -not $hilo.$field) {
                throw "novela-multi-hilo: hilos[] requiere '$field'"
            }
        }
        $slug = Get-HiloSlug $hilo
        if ($hilo.slug -ne $slug -or $slug -notmatch '^hilo-[a-z0-9]+(-[a-z0-9]+)*$') {
            throw "novela-multi-hilo: el slug de hilo '$($hilo.slug)' debe usar el formato hilo-<kebab-case>"
        }
        if ($knownSlugs.ContainsKey($slug)) {
            throw "novela-multi-hilo: slug de hilo duplicado '$slug'"
        }
        $knownSlugs[$slug] = $true
    }

    $seedSlugs = @{}
    foreach ($seed in $Brief._hilos) {
        foreach ($field in @("slug", "diseno_hilo_md", "guion_hilo_md")) {
            if (-not $seed.PSObject.Properties.Name.Contains($field) -or -not $seed.$field) {
                throw "novela-multi-hilo: _hilos[] requiere '$field'"
            }
        }
        if (-not $knownSlugs.ContainsKey($seed.slug)) {
            throw "novela-multi-hilo: _hilos contiene el slug desconocido '$($seed.slug)'"
        }
        if ($seedSlugs.ContainsKey($seed.slug)) {
            throw "novela-multi-hilo: _hilos contiene el slug duplicado '$($seed.slug)'"
        }
        $seedSlugs[$seed.slug] = $true
    }
    foreach ($slug in $knownSlugs.Keys) {
        if (-not $seedSlugs.ContainsKey($slug)) {
            throw "novela-multi-hilo: falta _hilos para '$slug'"
        }
    }
}

# ------------------------------------------------------------
# Escritura de archivos del workspace desde brief JSON
# ------------------------------------------------------------

function Write-ConfigJson {
    param([string]$TargetDir, $Brief)
    
    $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    $escala = $Brief.escala
    $tipo = if ($escala -eq "relato") { "relato" } else { "novela" }
    
    $config = [ordered]@{
        titulo = $Brief.titulo
        slug = $Brief.slug
        tipo = $tipo
        escala = $escala
        estado = "diseno"
        estilo_base = $Brief.estilo_base
        creado = $now
        ultima_modificacion = $now
        ultimo_hecho_seq = 0
        ultimo_beat_seq = 0
    }
    if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) {
        $config.estilo_secundario = $Brief.estilo_secundario
    }

    # Campos opcionales desde el brief
    foreach ($key in @("logline","genero","subgenero","tono","atmosfera","explicitud","pov","extension_estimada","capitulos_estimados","antagonista_o_conflicto","temas","referencias","restricciones","puntos_conexion")) {
        if ($Brief.PSObject.Properties.Name -contains $key -and $null -ne $Brief.$key) {
            $config[$key] = $Brief.$key
        }
    }
    if ($Brief.protagonistas) { $config.protagonistas = $Brief.protagonistas }
    if ($Brief.personajes_clave) { $config.personajes_clave = $Brief.personajes_clave }
    if ($Brief.setting) { $config.setting = $Brief.setting }
    if ($Brief.reflexion_agente) { $config.reflexion_agente = $Brief.reflexion_agente }

    $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $TargetDir "config.json") -Encoding UTF8
}

function Write-BriefMd {
    param([string]$TargetDir, $Brief)
    
    $generoLine = $Brief.genero
    if ($Brief.PSObject.Properties.Name.Contains("subgenero") -and $Brief.subgenero) {
        $generoLine += " / $($Brief.subgenero)"
    }

    $protasBlock = Get-ProtagonistasText $Brief.protagonistas
    
    $personajesBlock = ""
    if ($Brief.personajes_clave) {
        $personajesBlock = "`n`n## Personajes clave`n`n" + (Get-ListText $Brief.personajes_clave)
    }

    $temasBlock = ""
    if ($Brief.temas) {
        $temasBlock = "`n`n## Temas`n`n" + (Get-ListText $Brief.temas)
    }

    $refsBlock = ""
    if ($Brief.referencias) {
        $refsBlock = "`n`n## Referencias`n`n" + (Get-ListText $Brief.referencias)
    }

    $reflexionBlock = ""
    if ($Brief.reflexion_agente) {
        $r = $Brief.reflexion_agente
        $reflexionBlock = "`n`n## Reflexion editorial"
        if ($r.fortalezas) { $reflexionBlock += "`n`n### Fortalezas`n`n" + (Get-ListText $r.fortalezas) }
        if ($r.riesgos) { $reflexionBlock += "`n`n### Riesgos`n`n" + (Get-ListText $r.riesgos) }
        if ($r.decisiones_usuario) { $reflexionBlock += "`n`n### Decisiones del usuario`n`n" + (Get-ListText $r.decisiones_usuario) }
    }

    $settingBlock = ""
    if ($Brief.setting) {
        $settingBlock = "`n`n## Setting`n`n$($Brief.setting)"
    }

    $antagBlock = ""
    if ($Brief.PSObject.Properties.Name.Contains("antagonista_o_conflicto") -and $Brief.antagonista_o_conflicto) {
        $antagBlock = "`n`n## Conflicto`n`n$($Brief.antagonista_o_conflicto)"
    }

    @"
# Brief — $($Brief.titulo)

## Logline
$($Brief.logline)

## Premisa
$(if ($Brief.PSObject.Properties.Name.Contains("premisa") -and $Brief.premisa) { $Brief.premisa } else { "---" })

## Genero y voz
- **Genero:** $generoLine
- **Estilo base:** $($Brief.estilo_base)$(if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) { " + $($Brief.estilo_secundario) (fusion)" } else { "" })
- **Tono:** $(if ($Brief.PSObject.Properties.Name.Contains("tono") -and $Brief.tono) { $Brief.tono } else { "---" })
- **Explicitud:** $(if ($Brief.PSObject.Properties.Name.Contains("explicitud") -and $Brief.explicitud) { $Brief.explicitud } else { "maximo" })
- **POV:** $(if ($Brief.PSObject.Properties.Name.Contains("pov") -and $Brief.pov) { $Brief.pov } else { "---" })
- **Atmosfera:** $(if ($Brief.PSObject.Properties.Name.Contains("atmosfera") -and $Brief.atmosfera) { $Brief.atmosfera } else { "---" })
- **Extension estimada:** $(if ($Brief.PSObject.Properties.Name.Contains("extension_estimada") -and $Brief.extension_estimada) { $Brief.extension_estimada } else { "---" })

## Protagonistas
$($protasBlock)$($personajesBlock)$($antagBlock)$($settingBlock)$($temasBlock)$($refsBlock)$($reflexionBlock)
"@ | Set-Content -LiteralPath (Join-Path $TargetDir "BRIEF.md") -Encoding UTF8
}

function Write-ActosMd {
    param([string]$TargetDir, $Brief)

    Test-BriefField $Brief "hechos" "Write-ActosMd"

    $content = "# Actos — $($Brief.titulo)`n`n"
    $content += "> Las escenas y beats los genera el guionista a partir de estos hechos.`n"
    $content += "> El director puede anadir notas al final durante el desarrollo.`n`n"

    foreach ($h in $Brief.hechos) {
        $content += "## $($h.acto)`n`n"
        if ($h.objetivo) { $content += "**Objetivo narrativo:** $($h.objetivo)`n`n" }
        if ($h.efecto_lector) { $content += "**Que debe sentir el lector:** $($h.efecto_lector)`n`n" }
        if ($h.tension) { $content += "**Tension:** $($h.tension)`n`n" }
        $content += "### Hechos`n`n"
        foreach ($hc in $h.hechos) {
            $content += "- $($hc)`n"
        }
        $content += "`n"
    }
    $content += "## Notas del director`n`n(Espacio para notas durante el desarrollo)`n"

    Set-Content -LiteralPath (Join-Path $TargetDir "_actos.md") -Value $content -Encoding UTF8
}

function Write-ActosMdMultiHilo {
    param([string]$TargetDir, $Brief)

    Test-BriefField $Brief "hilos" "Write-ActosMdMultiHilo"
    Test-BriefField $Brief "hechos" "Write-ActosMdMultiHilo"

    $content = "# Actos — $($Brief.titulo)`n`n"
    $content += "> Estructura Hilo > Acto > Hechos.`n"
    $content += "> Las escenas y beats los genera el guionista a partir de estos hechos.`n"
    $content += "> El director puede anadir notas al final durante el desarrollo.`n`n"

    # Agrupar por hilo evita secciones duplicadas si el brief intercalo actos.
    foreach ($hiloDef in $Brief.hilos) {
        $hiloSlug = Get-HiloSlug $hiloDef
        $content += "## Hilo: $($hiloDef.nombre) — slug: $hiloSlug`n`n"

        foreach ($h in ($Brief.hechos | Where-Object { $_.hilo -eq $hiloSlug })) {
            $content += "### $($h.acto)`n`n"
            if ($h.objetivo) { $content += "**Objetivo narrativo:** $($h.objetivo)`n`n" }
            if ($h.efecto_lector) { $content += "**Que debe sentir el lector:** $($h.efecto_lector)`n`n" }
            if ($h.tension) { $content += "**Tension:** $($h.tension)`n`n" }
            $content += "#### Hechos`n`n"
            foreach ($hc in $h.hechos) {
                $content += "- $($hc)`n"
            }
            $content += "`n"
        }
    }
    $content += "## Notas del director`n`n(Espacio para notas durante el desarrollo)`n"

    Set-Content -LiteralPath (Join-Path $TargetDir "_actos.md") -Value $content -Encoding UTF8
}

function Write-AgentsMd {
    param([string]$TargetDir, $Brief, [string]$Escala)

    $explicitud = if ($Brief.PSObject.Properties.Name.Contains("explicitud") -and $Brief.explicitud) { $Brief.explicitud } else { "maximo" }
    $tonoRule = if ($Brief.PSObject.Properties.Name.Contains("tono") -and $Brief.tono) { $Brief.tono } else { "coherente con $($Brief.estilo_base)" }
    $restricciones = if ($Brief.PSObject.Properties.Name.Contains("restricciones") -and $Brief.restricciones) { Get-ListText $Brief.restricciones } else { "- (ninguna)" }
    $temas = if ($Brief.PSObject.Properties.Name.Contains("temas") -and $Brief.temas) { Get-ListText $Brief.temas } else { "- (ver BRIEF.md)" }

    $skillsActivos = @(
        "mecanica-prosa", "beats-estructura", "estructura-narrativa", "tonos-beat",
        "hechos-distribuidos",
        "estilo-$($Brief.estilo_base)"
    )
    if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) {
        $skillsActivos += "estilo-$($Brief.estilo_secundario)"
    }
    $skillsActivos += @(
        "plantilla-guion", "plantilla-ficha", "plantilla-personaje", "plantilla-lugar",
        "plantilla-objeto", "plantilla-animal", "plantilla-evento",
        "plantilla-organizacion",
        "validacion-crudeza", "validacion-coherencia", "validacion-geometria",
        "validacion-sensorial", "validacion-tono",
        "consistencia-narrativa", "contexto-subagente", "desarrollo-narrativa",
        "fichas-personajes", "estilo-prosa"
    )
    if ($Escala -ne "relato") {
        $skillsActivos += @("plantilla-arco", "qdrant", "neo4j", "auditoria-neo4j")
    }
    if ($Escala -eq "novela-multi-hilo") {
        $skillsActivos += @("plantilla-hilo", "diseno-hilo", "trenzado-narrativo", "validacion-cross-hilo")
    }
    $skillsActivos += @("generar", "revisar", "expandir", "publicar")

    $skillsStr = ($skillsActivos -join ", ")
    $estiloRef = "``estilo-$($Brief.estilo_base)``"
    if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) {
        $estiloRef += " + ``estilo-$($Brief.estilo_secundario)`` (fusion)"
    }

    $hiloSection = ""
    if ($Escala -eq "novela-multi-hilo") {
        $hiloSection = @"

### Hilos
Hilos en ``config.json.hilos`` y ``hilos/hilo-*/``.
``config.json.hilos[].estado`` indica el progreso de cada hilo (pendiente | disenado | guion_listo).
"@
    }

    $infraSection = ""
    if ($Escala -ne "relato") {
        $infraSection = "Qdrant ``:6333`` y Neo4j ``:7687`` compartidos, aislados por el slug ``$($Brief.slug)`` en los datos."
    } else {
        $infraSection = "Modo ligero: sin Qdrant ni Neo4j. Memoria en contexto_narrativo.md."
    }

    @"
# $($Brief.titulo)

**Workspace generado por Forja Hub.**
**Escala:** $Escala | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** $estiloRef
- **Tono:** $tonoRule
- **Explicitud:** $explicitud (sin eufemismos, vocabulario directo).
- **POV:** $(if ($Brief.PSObject.Properties.Name.Contains("pov") -and $Brief.pov) { $Brief.pov } else { "segun BRIEF.md" }).

### Temas
$temas

### Restricciones
$restricciones

### Skills activos
$skillsStr
$hiloSection
## Infraestructura
$infraSection

## Arranque
``/generar`` (el director lee ``config.json`` y ``PIPELINE.md`` y orquesta segun ``ORQUESTACION.md``).
"@ | Set-Content -LiteralPath (Join-Path $TargetDir "AGENTS.md") -Encoding UTF8
}

function Write-MapaMd {
    param([string]$TargetDir, $Brief)
    
    if (-not ($Brief.PSObject.Properties.Name -contains "_mapa") -or -not $Brief._mapa) {
        throw "Write-MapaMd: brief no contiene '_mapa'"
    }
    Set-Content -LiteralPath (Join-Path $TargetDir "MAPA.md") -Value $Brief._mapa -Encoding UTF8
}

# ------------------------------------------------------------
# Hilos (multi-hilo)
# ------------------------------------------------------------

function Get-HiloSlug {
    param($Hilo)
    if ($Hilo.slug) {
        return ($Hilo.slug -replace '[^a-z0-9-]', '').Trim('-')
    }
    if ($Hilo.nombre) {
        $s = $Hilo.nombre.ToLower()
        $s = $s -replace '[áàä]', 'a' -replace '[éèë]', 'e' -replace '[íìï]', 'i'
        $s = $s -replace '[óòö]', 'o' -replace '[úùü]', 'u' -replace 'ñ', 'n'
        $s = $s -replace '[^a-z0-9]+', '-'
        return "hilo-" + $s.Trim('-')
    }
    throw "Cada hilo necesita slug o nombre."
}

function New-OperationalHilos {
    param($BriefHilos, [string]$Now)
    $ops = @()
    foreach ($h in $BriefHilos) {
        $slug = Get-HiloSlug $h
        $id = $slug
        $ops += [ordered]@{
            id = $id
            stable_id = if ($h.stable_id) { $h.stable_id } else { [guid]::NewGuid().ToString("N").Substring(0,8) }
            nombre = if ($h.nombre) { $h.nombre } else { $slug }
            slug = $slug
            epoca = if ($h.epoca) { $h.epoca } else { "" }
            ubicacion = if ($h.PSObject.Properties.Name -contains "ubicacion" -and $h.ubicacion) { $h.ubicacion } else { "" }
            conflicto = if ($h.conflicto) { $h.conflicto } else { "" }
            tono = if ($h.PSObject.Properties.Name -contains "tono" -and $h.tono) { $h.tono } else { "" }
            personajes = if ($h.personajes) { $h.personajes } else { @() }
            estado = "pendiente"
            archivo_diseno = "hilos/$id/diseno-hilo.md"
            archivo_guion = "hilos/$id/guion-hilo.md"
            ultimo_capitulo = $null
            seq = 0
            parent_id = "global"
        }
    }
    # Preserve la colección aunque solo haya un hilo; de otro modo PowerShell
    # entrega el diccionario escalar y rompe Count, foreach y config.json.
    Write-Output -NoEnumerate $ops
}

function Seed-HiloFolders {
    param([string]$TargetDir, $OperationalHilos, $Brief)
    
    if (-not ($Brief.PSObject.Properties.Name -contains "_hilos") -or -not $Brief._hilos) {
        throw "Seed-HiloFolders: brief no contiene '_hilos'"
    }
    
    foreach ($h in $OperationalHilos) {
        $folder = Join-Path $TargetDir "hilos\$($h.id)"
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        
        $hiloData = $Brief._hilos | Where-Object { $_.slug -eq $h.slug } | Select-Object -First 1
        if (-not $hiloData) { throw "Seed-HiloFolders: no se encontraron datos para hilo '$($h.slug)'" }
        
        Set-Content -LiteralPath (Join-Path $folder "diseno-hilo.md") -Value $hiloData.diseno_hilo_md -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $folder "guion-hilo.md") -Value $hiloData.guion_hilo_md -Encoding UTF8
    }
}


# ------------------------------------------------------------
# Inicialización de infraestructura (novelas)
# ------------------------------------------------------------

function Initialize-Infra {
    param([string]$TargetDir, $Brief)
    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) { $pythonCmd = "python" }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $pythonCmd = "python3" }
    if (-not $pythonCmd) { throw "Python no encontrado. Las novelas requieren Qdrant y Neo4j operativos." }

    foreach ($infra in @(
        @{ Nombre = "Qdrant"; Script = "qdrant.py" },
        @{ Nombre = "Neo4j"; Script = "neo4j.py" }
    )) {
        & $pythonCmd (Join-Path $PSScriptRoot "..\$($infra.Script)") init
        if ($LASTEXITCODE -ne 0) {
            throw "$($infra.Nombre) no pudo inicializarse (codigo de salida $LASTEXITCODE)."
        }
        Write-Host "$($infra.Nombre) inicializado"
    }
}




