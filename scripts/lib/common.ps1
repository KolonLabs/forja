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
        [string]$Escala,
        [string]$EstiloBase,
        [string]$EstiloSecundario
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

    # 2. Agentes de escala (7 en relato)
    $scaleAgents = Join-Path $ScaleDir "agentes"
    if (Test-Path -LiteralPath $scaleAgents) {
        Get-ChildItem -LiteralPath $scaleAgents -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetOC "agents\$($_.Name)") -Force
        }
    }

    # 3. Scripts locales de escala. Relato usa solo helpers de integridad y no
    # recibe infraestructura ni conoce directorios superiores.
    $scaleScripts = Join-Path $ScaleDir "scripts"
    if (Test-Path -LiteralPath $scaleScripts -PathType Container) {
        $targetScripts = Join-Path $TargetDir "scripts"
        if (-not (Test-Path -LiteralPath $targetScripts -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $targetScripts | Out-Null
        }
        Get-ChildItem -LiteralPath $scaleScripts -File | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetScripts $_.Name) -Force
        }
    }

    # 4. PIPELINE.md
    Copy-Item -LiteralPath (Join-Path $ScaleDir "PIPELINE.md") -Destination (Join-Path $TargetDir "PIPELINE.md") -Force

    # 5. ORQUESTACION.md
    Copy-Item -LiteralPath (Join-Path $ScaleDir "ORQUESTACION.md") -Destination (Join-Path $TargetDir "ORQUESTACION.md") -Force

    # 6. Guía de uso para la persona usuaria
    $userGuide = Join-Path $SharedDir "GUIA.md"
    if (Test-Path -LiteralPath $userGuide -PathType Leaf) {
        Copy-Item -LiteralPath $userGuide -Destination (Join-Path $TargetDir "GUIA.md") -Force
    }

    # 7. Skills filtrados por escala
    $hubSkills = Join-Path $SharedDir ".opencode\skills"
    $wsSkills = Join-Path $targetOC "skills"
    $excluded = @()
    $allowed = @()
    if ($Escala -eq "relato") {
        # Relato no parte de un paquete genérico por exclusión: recibe solo las
        # invariantes que realmente usa. El resto se define como override propio
        # de escala en $ScaleDir\skills.
        $styleNames = @($EstiloBase, $EstiloSecundario) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        if ($styleNames.Count -eq 0) {
            $configPath = Join-Path $TargetDir "config.json"
            if (Test-Path -LiteralPath $configPath -PathType Leaf) {
                $workspaceConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $styleNames = @($workspaceConfig.estilo_base, $workspaceConfig.estilo_secundario) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
            }
        }
        if ($styleNames.Count -eq 0) {
            throw "Inject-Pipeline relato: falta estilo_base para seleccionar las skills de estilo."
        }
        foreach ($styleName in $styleNames) {
            $skillName = "estilo-$styleName"
            if (-not (Test-Path -LiteralPath (Join-Path $hubSkills $skillName) -PathType Container)) {
                throw "Inject-Pipeline relato: skill de estilo no encontrada: $skillName"
            }
            $allowed += $skillName
        }
        $allowed += "mecanica-prosa"
    } elseif ($Escala -eq "novela-simple") {
        $excluded = @("diseno-hilo","plantilla-hilo","trenzado-narrativo","validacion-cross-hilo")
    }

    if (Test-Path -LiteralPath $hubSkills) {
        Get-ChildItem -LiteralPath $hubSkills -Directory | ForEach-Object {
            if ($Escala -eq "relato" -and $_.Name -notin $allowed) { return }
            if ($_.Name -in $excluded) { return }
            $dest = Join-Path $wsSkills $_.Name
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse
        }
    }

    # 8. Skills específicos de la escala; sobrescriben contratos genéricos cuando comparten nombre.
    $scaleSkills = Join-Path $ScaleDir "skills"
    if (Test-Path -LiteralPath $scaleSkills) {
        Get-ChildItem -LiteralPath $scaleSkills -Directory | ForEach-Object {
            $src = Join-Path $scaleSkills $_.Name
            $dest = Join-Path $wsSkills $_.Name
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Copy-Item -LiteralPath $src -Destination $dest -Recurse
        }
    }

    # 9. Comandos comunes
    $hubCommands = Join-Path $SharedDir ".opencode\commands"
    $wsCommands = Join-Path $targetOC "commands"
    if (Test-Path -LiteralPath $hubCommands) {
        Get-ChildItem -LiteralPath $hubCommands -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $wsCommands $_.Name) -Force
        }
    }

    # 10. Overrides de comandos por escala. Se copian después de los comunes
    # para que el workspace reciba instrucciones sin contaminación de otra escala.
    $scaleCommands = Join-Path $ScaleDir "commands"
    if (Test-Path -LiteralPath $scaleCommands) {
        Get-ChildItem -LiteralPath $scaleCommands -File -Filter "*.md" | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $wsCommands $_.Name) -Force
        }
    }

    # 11. Scripts Python de infraestructura (solo novelas)
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

function Get-RelatoHechoCount {
    param($Brief)

    $count = 0
    foreach ($acto in $Brief.hechos) {
        if ($null -ne $acto.hechos) {
            $count += @($acto.hechos).Count
        }
    }
    return $count
}

function ConvertTo-RelatoHechoTexto {
    param([string]$Texto)

    # El briefing puede traer un prefijo H_XX/H_XXXX antiguo. El workspace es
    # dueño de la numeración global y lo sustituye al escribir _actos.md.
    $normalizado = [regex]::Replace($Texto.Trim(), '^H_\d{1,4}\s*(?:[—:]\s*)?', '')
    if ($normalizado -match '\[D(?:\s|·|\])') {
        throw "relato no admite hechos [D]; describe el patrón dentro del hecho para que el guionista lo materialice con beats ordinarios."
    }
    return [regex]::Replace($normalizado, 'H_(\d{1,4})', {
        param($match)
        return ('H_{0:D4}' -f [int]$match.Groups[1].Value)
    })
}

function Convert-RelatoDraftToAnchors {
    param([string]$DraftPath)

    $draft = Get-Content -LiteralPath $DraftPath -Raw -Encoding UTF8
    $convertido = [regex]::Replace($draft, '(?m)^##\s+(B_\d{4})(?:\s+—[^\r\n]*)?\s*\r?\n?', {
        param($match)
        return "<!-- $($match.Groups[1].Value) -->`n"
    })
    if ($convertido -eq $draft) {
        return $false
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($DraftPath, $convertido, $utf8NoBom)
    return $true
}

function Get-RelatoGuionEscenas {
    param([string]$GuionPath)

    $guion = Get-Content -LiteralPath $GuionPath -Raw -Encoding UTF8
    $sceneMatches = [regex]::Matches($guion, '(?m)^###\s+(E_\d{4})\s*(?:—|-|:)\s*(.+?)\s*$')
    if ($sceneMatches.Count -eq 0) {
        throw "El guion no contiene escenas operativas E_XXXX compatibles. No es seguro derivar una edición sin migrar primero su estructura."
    }

    $escenas = @()
    $seenScenes = @{}
    $seenBeats = @{}
    for ($index = 0; $index -lt $sceneMatches.Count; $index++) {
        $match = $sceneMatches[$index]
        $sceneId = $match.Groups[1].Value
        if ($seenScenes.ContainsKey($sceneId)) {
            throw "El guion repite la escena $sceneId."
        }
        $seenScenes[$sceneId] = $true
        $end = if ($index + 1 -lt $sceneMatches.Count) { $sceneMatches[$index + 1].Index } else { $guion.Length }
        $block = $guion.Substring($match.Index + $match.Length, $end - ($match.Index + $match.Length))
        $salida = [regex]::Match($block, '(?mi)^-\s*Salida:\s*(continua|separador)\s*$')
        if (-not $salida.Success) {
            throw "La escena $($match.Groups[1].Value) no declara 'Salida: continua|separador'."
        }

        $beats = @([regex]::Matches($block, '(?m)^\s*(?:[-*]\s*)?(?:⬜|🔄|✅)?\s*(B_\d{4})\s+—') | ForEach-Object { $_.Groups[1].Value })
        if ($beats.Count -eq 0) {
            throw "La escena $($match.Groups[1].Value) no contiene beats B_XXXX."
        }
        foreach ($beat in $beats) {
            if ($seenBeats.ContainsKey($beat)) {
                throw "El guion repite el beat $beat en más de una escena."
            }
            $seenBeats[$beat] = $true
        }

        $escenas += [pscustomobject]@{
            id = $sceneId
            nombre = $match.Groups[2].Value.Trim()
            salida = $salida.Groups[1].Value.ToLowerInvariant()
            beats = $beats
        }
    }
    return $escenas
}

function Test-RelatoIdSequence {
    param([string[]]$Esperados, [string[]]$Actuales)

    if ($Esperados.Count -ne $Actuales.Count) { return $false }
    for ($index = 0; $index -lt $Esperados.Count; $index++) {
        if ($Esperados[$index] -ne $Actuales[$index]) { return $false }
    }
    return $true
}

function Convert-RelatoDraftToSceneContract {
    param(
        [string]$DraftPath,
        [string]$GuionPath
    )

    $headingsMigrated = Convert-RelatoDraftToAnchors -DraftPath $DraftPath
    $escenas = @(Get-RelatoGuionEscenas -GuionPath $GuionPath)
    $draft = Get-Content -LiteralPath $DraftPath -Raw -Encoding UTF8
    $expectedBeats = @($escenas | ForEach-Object { $_.beats } | ForEach-Object { $_ })
    $actualBeats = @([regex]::Matches($draft, '(?m)^<!--\s*(B_\d{4})\s*-->\s*$') | ForEach-Object { $_.Groups[1].Value })
    if (-not (Test-RelatoIdSequence -Esperados $expectedBeats -Actuales $actualBeats)) {
        throw "El draft no contiene exactamente los beats del guion, en el mismo orden. No es seguro derivar una edición."
    }

    $markerPattern = '(?m)^<!--\s*ESCENA\s+(E_\d{4})\s*:\s*(.*?)\s*\|\s*salida:\s*(continua|separador)\s*-->\s*$'
    $markers = [regex]::Matches($draft, $markerPattern)
    $markersMigrated = $false
    if ($markers.Count -eq 0) {
        foreach ($escena in $escenas) {
            $firstBeat = $escena.beats[0]
            $safeName = ($escena.nombre -replace '--', '—' -replace '\|', '/')
            $marker = "<!-- ESCENA $($escena.id): $safeName | salida: $($escena.salida) -->"
            $anchorPattern = "(?m)^<!--\s*$([regex]::Escape($firstBeat))\s*-->\s*$"
            $anchorRegex = [regex]::new($anchorPattern)
            if ($anchorRegex.Matches($draft).Count -ne 1) {
                throw "No se pudo insertar el marcador de $($escena.id) antes de $firstBeat."
            }
            $draft = $anchorRegex.Replace($draft, "$marker`n<!-- $firstBeat -->", 1)
        }
        $markersMigrated = $true
        $markers = [regex]::Matches($draft, $markerPattern)
    }

    $expectedEscenas = @($escenas | ForEach-Object { $_.id })
    $actualEscenas = @($markers | ForEach-Object { $_.Groups[1].Value })
    if (-not (Test-RelatoIdSequence -Esperados $expectedEscenas -Actuales $actualEscenas)) {
        throw "Los marcadores ESCENA del draft no coinciden exactamente con el guion."
    }
    for ($index = 0; $index -lt $escenas.Count; $index++) {
        $escena = $escenas[$index]
        if ($markers[$index].Groups[3].Value.ToLowerInvariant() -ne $escena.salida) {
            throw "La salida del marcador $($escena.id) no coincide con su guion."
        }
        $start = $markers[$index].Index + $markers[$index].Length
        $end = if ($index + 1 -lt $markers.Count) { $markers[$index + 1].Index } else { $draft.Length }
        $block = $draft.Substring($start, $end - $start)
        $sceneBeats = @([regex]::Matches($block, '(?m)^<!--\s*(B_\d{4})\s*-->\s*$') | ForEach-Object { $_.Groups[1].Value })
        if (-not (Test-RelatoIdSequence -Esperados $escena.beats -Actuales $sceneBeats)) {
            throw "Los beats contenidos en $($escena.id) no coinciden con el guion."
        }
    }

    if ($headingsMigrated -or $markersMigrated) {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($DraftPath, $draft, $utf8NoBom)
    }
    return [pscustomobject]@{
        headings_migrated = $headingsMigrated
        scene_markers_migrated = $markersMigrated
    }
}

function Write-RelatoEditionMapa {
    param(
        [string]$TargetDir,
        [string]$Titulo,
        [string]$Origen,
        [int]$Numero
    )

    $content = (@'
# MAPA — {0}

## Flujo de esta edición

```text
guion.md (E_XXXX + B_XXXX)
  → relato-draft.md (prosa por escena, anclas invisibles B_XXXX)
  → /corregir, /revisar o /expandir
  → /publicar
  → relato.md (manuscrito limpio)
```

## Archivos de edición

| Archivo | Uso |
|---|---|
| EDICION.md | Linaje y motivo de la edición {1} derivada de `{2}`. |
| relato-edicion-anterior.md | Manuscrito publicado de referencia, solo lectura. |
| correcciones.md | Registro de pasadas e IDs afectados. |
| guion.md | Escenas operativas y beats canónicos. |
| relato-draft.md | Prosa continua por escena; las anclas no son secciones. |
| contexto_narrativo.md | Memoria local que se actualiza desde la primera escena afectada. |
| .forja-transaccion/ | Staging recuperable gestionado por el director; no se edita a mano. |

Estado actual: `correccion`. No modifiques `relato-edicion-anterior.md`; termina con `/publicar` para volver a `finalizado`.
'@) -f $Titulo, $Numero, $Origen
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText((Join-Path $TargetDir "MAPA.md"), $content, $utf8NoBom)
}

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
        ultimo_hecho_seq = if ($escala -eq "relato") { Get-RelatoHechoCount -Brief $Brief } else { 0 }
        ultimo_beat_seq = 0
        ultimo_escena_seq = 0
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
- **Estilo base:** $($Brief.estilo_base)$(if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) { " + $($Brief.estilo_secundario) (matiz; prevalece el base)" } else { "" })
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
    param(
        [string]$TargetDir,
        $Brief,
        [switch]$AsignarIdsGlobales
    )

    Test-BriefField $Brief "hechos" "Write-ActosMd"

    $content = "# Actos — $($Brief.titulo)`n`n"
    $content += "> Las escenas y beats los genera el guionista a partir de estos hechos.`n"
    $content += "> El director puede anadir notas al final durante el desarrollo.`n`n"

    $hechoSeq = 0
    foreach ($h in $Brief.hechos) {
        $content += "## $($h.acto)`n`n"
        if ($h.objetivo) { $content += "**Objetivo narrativo:** $($h.objetivo)`n`n" }
        if ($h.efecto_lector) { $content += "**Que debe sentir el lector:** $($h.efecto_lector)`n`n" }
        if ($h.tension) { $content += "**Tension:** $($h.tension)`n`n" }
        $content += "### Hechos`n`n"
        foreach ($hc in $h.hechos) {
            if ($AsignarIdsGlobales) {
                $hechoSeq++
                $texto = ConvertTo-RelatoHechoTexto -Texto ([string]$hc)
                $content += ("- H_{0:D4} — {1}`n" -f $hechoSeq, $texto)
            } else {
                $content += "- $($hc)`n"
            }
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

    if ($Escala -eq "relato") {
        $skillsActivos = @(
            "mecanica-prosa", "beats-estructura", "contexto-narrativo", "contexto-subagente",
            "estructura-narrativa", "plantilla-guion", "plantilla-draft", "plantilla-ficha",
            "tonos-beat", "validacion-coherencia", "validacion-crudeza", "validacion-geometria",
            "validacion-sensorial", "validacion-tono", "estilo-$($Brief.estilo_base)"
        )
    } else {
        $skillsActivos = @(
            "mecanica-prosa", "beats-estructura", "estructura-narrativa", "tonos-beat",
            "hechos-distribuidos", "estilo-$($Brief.estilo_base)"
        )
    }
    if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) {
        $skillsActivos += "estilo-$($Brief.estilo_secundario)"
    }
    if ($Escala -ne "relato") {
        $skillsActivos += @(
            "plantilla-personaje", "plantilla-lugar", "plantilla-objeto", "plantilla-animal",
            "plantilla-evento", "plantilla-organizacion", "consistencia-narrativa",
            "desarrollo-narrativa", "fichas-personajes", "estilo-prosa"
        )
        $skillsActivos += @("plantilla-arco", "qdrant", "neo4j", "auditoria-neo4j")
    }
    if ($Escala -eq "novela-multi-hilo") {
        $skillsActivos += @("plantilla-hilo", "diseno-hilo", "trenzado-narrativo", "validacion-cross-hilo")
    }
    $skillsStr = ($skillsActivos -join ", ")
    $estiloRef = "``estilo-$($Brief.estilo_base)``"
    $estiloSecondaryRule = ""
    if ($Brief.PSObject.Properties.Name.Contains("estilo_secundario") -and $Brief.estilo_secundario) {
        $estiloRef += " + ``estilo-$($Brief.estilo_secundario)`` (matiz)"
        $estiloSecondaryRule = " El estilo base prevalece; el secundario solo aporta matices compatibles y nunca altera restricciones, explicitud, hechos ni beats."
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

    $integritySection = ""
    if ($Escala -eq "relato") {
        $integritySection = @"

## Integridad de relato

El director usa ``scripts/relato-transaccion.ps1`` para hechos, diseño, ajustes de guion, componentes, escritura, correcciones y publicación. No edites ``.forja-transaccion/`` ni escribas directamente artefactos canónicos; el staging se retoma si sigue siendo válido o se descarta explícitamente.
"@
    }

    @"
# $($Brief.titulo)

**Workspace generado por Forja Hub.**
**Escala:** $Escala | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** $estiloRef$estiloSecondaryRule
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
$integritySection
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




