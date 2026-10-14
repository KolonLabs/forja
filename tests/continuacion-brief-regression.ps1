# continuacion-brief-regression.ps1 — Prueba aislada de canon_previo y fichas_semilla.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-continuacion-regression-" + [guid]::NewGuid().ToString("N"))

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message, [string]$Pattern = "")
    try { & $Action } catch {
        if ($Pattern -and $_.Exception.Message -notmatch $Pattern) {
            throw "ASSERT: $Message. Error inesperado: $($_.Exception.Message)"
        }
        return
    }
    throw "ASSERT: $Message"
}

function New-Brief {
    param([string]$Slug, [string]$Escala = "relato", [hashtable]$Extra = @{})
    $brief = [ordered]@{
        slug = $Slug
        titulo = "Continuacion de prueba"
        escala = $Escala
        estilo_base = "explicito"
        logline = "Una mujer ve algo que no entiende."
        premisa = "Premisa de prueba."
        genero = "Erotica"
        tono = "Frio"
        explicitud = "maximo"
        pov = "1a persona, presente"
        extension_estimada = "13000 palabras"
        protagonistas = @(@{ nombre = "Marta"; deseo = "Mirar"; obstaculo = "La familia"; arco = "De ver a tomar" })
        hechos = @(@{
            acto = "Acto I - La boda"
            objetivo = "Ver sin ser vista."
            efecto_lector = "Complicidad."
            tension = "Que alguien la mire."
            hechos = @("Marta ve a su marido arrodillado ante un hombre sin rostro y no se mueve de la sombra.")
        })
        _mapa = "# MAPA`n`nMapa de prueba."
    }
    foreach ($k in $Extra.Keys) { $brief[$k] = $Extra[$k] }
    return ([pscustomobject]$brief)
}

function ConvertTo-BriefObject {
    param($Brief)
    return ($Brief | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
}

$previousObras = $env:FORJA_OBRAS
try {
    New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null
    $HubRoot = $RepoRoot
    . (Join-Path $RepoRoot "scripts\lib\common.ps1")

    $fichaOk = @{ ruta = "fichas/personaje_marta.md"; contenido = "# Ficha - Marta`n`n- 54 anos." }

    # Sin campos de continuacion: no cambia nada.
    Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "sin-campos"))

    # Validacion
    $valido = ConvertTo-BriefObject (New-Brief "valido" -Extra @{ canon_previo = "## Estado al empezar`n`nAlberto sabe."; fichas_semilla = @($fichaOk) })
    Test-ContinuacionBrief $valido

    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "n1" "novela-simple" @{ canon_previo = "x" })) } "rechaza canon_previo fuera de relato" "solo se admiten en la escala relato"
    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "n2" "novela-simple" @{ fichas_semilla = @($fichaOk) })) } "rechaza fichas_semilla fuera de relato" "solo se admiten en la escala relato"
    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "c1" -Extra @{ canon_previo = "   " })) } "rechaza canon vacio" "canon_previo"
    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "f0" -Extra @{ fichas_semilla = @() })) } "rechaza lista de fichas vacia" "no puede estar vacio"
    foreach ($ruta in @("../config.json", "fichas/../config.json", "fichas/sub/x.md", "/etc/x.md", "fichas/Marta.md", "fichas/marta.txt", "config.json", "fichas/_x.md")) {
        $mala = @{ ruta = $ruta; contenido = "x" }
        Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "r" -Extra @{ fichas_semilla = @($mala) })) } "rechaza ruta '$ruta'" "ruta de ficha invalida"
    }
    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "f1" -Extra @{ fichas_semilla = @(@{ ruta = "fichas/a.md" }) })) } "exige contenido" "requiere 'ruta' y 'contenido'"
    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "f2" -Extra @{ fichas_semilla = @(@{ ruta = "fichas/a.md"; contenido = "" }) })) } "rechaza contenido vacio" "no tiene contenido"
    Assert-Throws { Test-ContinuacionBrief (ConvertTo-BriefObject (New-Brief "f3" -Extra @{ fichas_semilla = @($fichaOk, $fichaOk) })) } "rechaza rutas duplicadas" "duplicada"

    # Escritura aislada
    $ws = Join-Path $RunRoot "ws"
    New-Item -ItemType Directory -Force -Path $ws | Out-Null
    Write-BriefMd -TargetDir $ws -Brief $valido
    $briefMd = Get-Content -LiteralPath (Join-Path $ws "BRIEF.md") -Raw -Encoding UTF8
    Assert-True ($briefMd -match "## Canon heredado" -and $briefMd -match "Alberto sabe\.") "BRIEF.md incluye el canon heredado"
    Write-FichasSemilla -TargetDir $ws -Brief $valido
    $ficha = Get-Content -LiteralPath (Join-Path $ws "fichas\personaje_marta.md") -Raw -Encoding UTF8
    Assert-True ($ficha -match "# Ficha - Marta") "escribe la ficha semilla"
    Assert-Throws { Write-FichasSemilla -TargetDir $ws -Brief $valido } "no sobrescribe fichas existentes" "no se sobrescribe"

    $sinCanon = Join-Path $RunRoot "sin-canon"
    New-Item -ItemType Directory -Force -Path $sinCanon | Out-Null
    Write-BriefMd -TargetDir $sinCanon -Brief (ConvertTo-BriefObject (New-Brief "sin-canon"))
    Assert-True ((Get-Content -LiteralPath (Join-Path $sinCanon "BRIEF.md") -Raw) -notmatch "Canon heredado") "sin canon_previo no aparece la seccion"

    # Extremo a extremo en una copia del hub: dispatcher + creador de relato.
    $hubCopia = Join-Path $RunRoot "hub"
    # Raíces por defecto (ADR 0027): Forja-resultados junto al hub; FORJA_RESULTADOS
    # mueve ambas y FORJA_OBRAS/FORJA_PUBLICADOS prevalecen sobre ella.
    $previas = @{ R = $env:FORJA_RESULTADOS; O = $env:FORJA_OBRAS; P = $env:FORJA_PUBLICADOS }
    Remove-Item Env:FORJA_RESULTADOS, Env:FORJA_OBRAS, Env:FORJA_PUBLICADOS -ErrorAction SilentlyContinue
    Assert-True ((Get-ObrasRoot -Hub $hubCopia) -eq [System.IO.Path]::GetFullPath((Join-Path $RunRoot "Forja-resultados\Obras"))) "obras por defecto en Forja-resultados\Obras"
    Assert-True ((Get-PublicadosRoot -Hub $hubCopia) -eq [System.IO.Path]::GetFullPath((Join-Path $RunRoot "Forja-resultados\Publicados"))) "publicados por defecto en Forja-resultados\Publicados"
    $env:FORJA_RESULTADOS = Join-Path $RunRoot "otra"
    Assert-True ((Get-ObrasRoot -Hub $hubCopia) -eq [System.IO.Path]::GetFullPath((Join-Path $RunRoot "otra\Obras"))) "FORJA_RESULTADOS mueve la raíz común"
    $env:FORJA_OBRAS = Join-Path $RunRoot "solo-obras"
    Assert-True ((Get-ObrasRoot -Hub $hubCopia) -eq [System.IO.Path]::GetFullPath((Join-Path $RunRoot "solo-obras"))) "FORJA_OBRAS prevalece sobre la raíz común"
    $env:FORJA_RESULTADOS = $previas.R; $env:FORJA_PUBLICADOS = $previas.P
    $obras = Join-Path $RunRoot "Obras"
    $env:FORJA_OBRAS = $obras
    New-Item -ItemType Directory -Force -Path $hubCopia | Out-Null
    foreach ($dir in @("scripts", "shared", ".opencode")) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot $dir) -Destination (Join-Path $hubCopia $dir) -Recurse
    }
    $json = (ConvertTo-BriefObject (New-Brief "continuacion-e2e" -Extra @{ canon_previo = "## Estado al empezar`n`nVicente sabe de los dos."; fichas_semilla = @($fichaOk, @{ ruta = "fichas/lugar_casa-de-rosa.md"; contenido = "# Ficha - Casa de Rosa" }) })) | ConvertTo-Json -Depth 10
    $json | & pwsh -NoProfile -File (Join-Path $hubCopia "scripts\new-project.ps1") | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "ASSERT: new-project fallo con continuacion valida" }
    $creado = Join-Path $obras "continuacion-e2e"
    Assert-True (Test-Path -LiteralPath (Join-Path $creado "fichas\personaje_marta.md")) "el workspace nace con la ficha semilla"
    Assert-True (Test-Path -LiteralPath (Join-Path $creado "fichas\lugar_casa-de-rosa.md")) "acepta guion medio en el slug de ficha"
    Assert-True ((Get-Content -LiteralPath (Join-Path $creado "BRIEF.md") -Raw -Encoding UTF8) -match "Vicente sabe de los dos") "el workspace nace con el canon heredado"

    # Capa de entornos: skills compartidas, agentes y comandos en ambas capas, opencode aislado del hub.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $creado ".opencode\skills"))) "sin skills duplicadas en .opencode"
    Assert-True ((Get-ChildItem -LiteralPath (Join-Path $creado ".claude\skills") -Directory).Count -ge 15) "skills en .claude/skills"
    Assert-True ((Get-ChildItem -LiteralPath (Join-Path $creado ".opencode\agents") -File).Count -eq 7) "7 agentes opencode"
    Assert-True ((Get-ChildItem -LiteralPath (Join-Path $creado ".claude\agents") -File).Count -eq 7) "7 agentes Claude Code"
    Assert-True ((Get-ChildItem -LiteralPath (Join-Path $creado ".opencode\commands") -File).Count -eq 10) "10 comandos opencode"
    Assert-True ((Get-ChildItem -LiteralPath (Join-Path $creado ".claude\commands") -File).Count -eq 10) "10 comandos Claude Code"
    # La obra vive fuera del hub, con su propio git y sin commits (ADR 0026).
    Assert-True (Test-Path -LiteralPath (Join-Path $creado ".git")) "la obra nace con su repositorio git"
    Assert-True ($null -eq (git -C $creado rev-parse --verify --quiet HEAD 2>$null)) "la obra nace sin commits"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $creado ".gitignore")) -match "(?m)^\.forja-transaccion/$") ".gitignore de la obra excluye el staging"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $creado ".gitignore")) -notmatch "draft") ".gitignore de la obra versiona los borradores"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $creado ".gitignore")) -match "(?m)^tmp/$") ".gitignore de la obra excluye las carpetas tmp/ a cualquier nivel (ADR 0041)"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $hubCopia "workspaces"))) "el hub no recibe obras"
    $agentsObra = Get-Content -Raw -LiteralPath (Join-Path $creado "AGENTS.md") -Encoding UTF8
    Assert-True ($agentsObra -match "## Historial y publicación" -and $agentsObra -match "/compilar" -and $agentsObra -match "No crees copias de seguridad") "AGENTS.md de la obra declara git propio, sin copias y /compilar"
    Assert-True (Test-Path -LiteralPath (Join-Path $creado "scripts\compilar.ps1")) "la obra nace con compilar.ps1"
    $mapaSkill = Get-Content -Raw -LiteralPath (Join-Path $hubCopia ".opencode\skills\scaffolding-mapa\SKILL.md") -Encoding UTF8
    Assert-True ($mapaSkill -notmatch "lo asigna el hub" -and $mapaSkill -match "publicacion/") "la skill de MAPA no atribuye publicado al hub y documenta publicacion/"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $creado ".claude\settings.json") | ConvertFrom-Json).agent -eq "director") "Claude Code arranca en el director"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $creado "CLAUDE.md")) -match "@AGENTS.md") "CLAUDE.md importa AGENTS.md"
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $creado "opencode.json") | ConvertFrom-Json).agent.scaffolder.disable -eq $true) "opencode desactiva el scaffolder del hub"

    # Sin explicitud no se crea nada: no hay nivel por defecto.
    $sinNivel = ConvertTo-BriefObject (New-Brief "sin-explicitud")
    $sinNivel.PSObject.Properties.Remove("explicitud")
    $falloNivel = $false
    try { ($sinNivel | ConvertTo-Json -Depth 10) | & pwsh -NoProfile -File (Join-Path $hubCopia "scripts
ew-project.ps1") 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { $falloNivel = $true } } catch { $falloNivel = $true }
    Assert-True $falloNivel "new-project rechaza un brief sin explicitud"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $obras "sin-explicitud"))) "sin explicitud no queda workspace"
    Assert-True ((Get-Content -LiteralPath (Join-Path $creado "AGENTS.md") -Raw -Encoding UTF8) -match "\*\*Explicitud:\*\* maximo \(explícito total") "AGENTS.md describe el nivel elegido"

    # Un brief invalido no deja workspace parcial.
    $malo = (ConvertTo-BriefObject (New-Brief "continuacion-mala" -Extra @{ fichas_semilla = @(@{ ruta = "../fuera.md"; contenido = "x" }) })) | ConvertTo-Json -Depth 10
    $fallo = $false
    try { $malo | & pwsh -NoProfile -File (Join-Path $hubCopia "scripts\new-project.ps1") 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { $fallo = $true } } catch { $fallo = $true }
    Assert-True $fallo "new-project rechaza fichas_semilla con ruta fuera de fichas/"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $obras "continuacion-mala"))) "no crea workspace con un brief invalido"

    Write-Host "OK: continuacion-brief-regression"
} finally {
    $env:FORJA_OBRAS = $previousObras
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
