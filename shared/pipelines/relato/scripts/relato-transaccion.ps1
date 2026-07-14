# relato-transaccion.ps1 — Commit recuperable de artefactos canónicos de relato.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Preparar", "Confirmar", "Recuperar", "Descartar")]
    [string]$Accion,
    [ValidateSet("hechos", "diseno", "guion", "componentes", "escritura", "correccion", "publicar")]
    [string]$Operacion
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$TransactionRoot = Join-Path $WorkspaceRoot ".forja-transaccion"
$NextRoot = Join-Path $TransactionRoot "siguiente"
$BackupRoot = Join-Path $TransactionRoot "respaldo"
$ManifestPath = Join-Path $TransactionRoot "manifest.json"
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$KnownFiles = @("config.json", "_actos.md", "guion.md", "relato-draft.md", "contexto_narrativo.md", "cola_d.md", "correcciones.md", "relato.md")
$OperationFiles = @{
    hechos = @("config.json", "_actos.md")
    diseno = @("config.json", "guion.md", "cola_d.md")
    guion = @("config.json", "guion.md", "cola_d.md")
    componentes = @("config.json", "guion.md", "relato-draft.md", "contexto_narrativo.md")
    escritura = @("config.json", "guion.md", "relato-draft.md", "contexto_narrativo.md")
    correccion = @("config.json", "guion.md", "relato-draft.md", "contexto_narrativo.md", "correcciones.md")
    publicar = @("config.json", "guion.md", "relato-draft.md", "relato.md")
}

function Write-Manifest {
    param($Manifest)

    [System.IO.File]::WriteAllText(
        $ManifestPath,
        ($Manifest | ConvertTo-Json -Depth 8),
        $Utf8NoBom
    )
}

function Read-Manifest {
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "No existe el manifiesto de la transacción."
    }
    try {
        return Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "El manifiesto de la transacción no es válido. $_"
    }
}

function Assert-KnownFiles {
    param([string[]]$Files)

    foreach ($file in $Files) {
        if ($file -notin $KnownFiles) {
            throw "El manifiesto contiene un archivo no permitido: $file"
        }
    }
}

function Get-RelatoGuionEscenas {
    param([string]$GuionPath)

    $guion = Get-Content -LiteralPath $GuionPath -Raw -Encoding UTF8
    $sceneMatches = [regex]::Matches($guion, '(?m)^###\s+(E_\d{4})\s*(?:—|-|:)\s*(.+?)\s*$')
    if ($sceneMatches.Count -eq 0) {
        throw "El guion no contiene escenas operativas E_XXXX compatibles."
    }

    $escenas = [System.Collections.Generic.List[object]]::new()
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
            throw "La escena $sceneId no declara 'Salida: continua|separador'."
        }

        $beats = @([regex]::Matches($block, '(?m)^\s*(?:[-*]\s*)?(?:⬜|🔄|✅)?\s*(B_\d{4})\s+—') | ForEach-Object { $_.Groups[1].Value })
        if ($beats.Count -eq 0) {
            throw "La escena $sceneId no contiene beats B_XXXX."
        }
        foreach ($beat in $beats) {
            if ($seenBeats.ContainsKey($beat)) {
                throw "El guion repite el beat $beat."
            }
            $seenBeats[$beat] = $true
        }

        $escenas.Add([pscustomobject]@{
            id = $sceneId
            salida = $salida.Groups[1].Value.ToLowerInvariant()
            beats = $beats
        })
    }
    return $escenas.ToArray()
}

function Test-RelatoIdSequence {
    param([string[]]$Esperados, [string[]]$Actuales)

    if ($Esperados.Count -ne $Actuales.Count) { return $false }
    for ($index = 0; $index -lt $Esperados.Count; $index++) {
        if ($Esperados[$index] -ne $Actuales[$index]) { return $false }
    }
    return $true
}

function Get-NarrativeText {
    param([string]$Text)

    return ([regex]::Replace($Text, '<!--[\s\S]*?-->', '')).Trim()
}

function Assert-DraftContract {
    param(
        [object[]]$Escenas,
        [string]$DraftPath,
        [switch]$Completo
    )

    $draft = Get-Content -LiteralPath $DraftPath -Raw -Encoding UTF8
    $markerPattern = '(?m)^<!--\s*ESCENA\s+(E_\d{4})\s*:\s*(.*?)\s*\|\s*salida:\s*(continua|separador)\s*-->\s*$'
    $markers = [regex]::Matches($draft, $markerPattern)
    $declaredMarkers = [regex]::Matches($draft, '(?mi)<!--\s*ESCENA\b')
    if ($declaredMarkers.Count -ne $markers.Count) {
        throw "El draft contiene marcadores ESCENA inválidos."
    }
    if ($markers.Count -gt $Escenas.Count) {
        throw "El draft contiene más escenas que el guion."
    }
    if ($Completo -and $markers.Count -ne $Escenas.Count) {
        throw "Los marcadores ESCENA del draft no coinciden exactamente con el guion."
    }

    $expectedAnchors = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $markers.Count; $index++) {
        $escena = $Escenas[$index]
        $marker = $markers[$index]
        if ($marker.Groups[1].Value -ne $escena.id) {
            throw "Los marcadores ESCENA del draft deben ser un prefijo ordenado del guion."
        }
        if ($marker.Groups[3].Value.ToLowerInvariant() -ne $escena.salida) {
            throw "La salida del marcador $($escena.id) no coincide con el guion."
        }

        $start = $marker.Index + $marker.Length
        $end = if ($index + 1 -lt $markers.Count) { $markers[$index + 1].Index } else { $draft.Length }
        $block = $draft.Substring($start, $end - $start)
        $anchorMatches = [regex]::Matches($block, '(?m)^<!--\s*(B_\d{4})\s*-->\s*$')
        $beats = @($anchorMatches | ForEach-Object { $_.Groups[1].Value })
        if (-not (Test-RelatoIdSequence -Esperados $escena.beats -Actuales $beats)) {
            throw "Los beats del draft en $($escena.id) no coinciden con el guion."
        }

        for ($beatIndex = 0; $beatIndex -lt $anchorMatches.Count; $beatIndex++) {
            $beatStart = $anchorMatches[$beatIndex].Index + $anchorMatches[$beatIndex].Length
            $beatEnd = if ($beatIndex + 1 -lt $anchorMatches.Count) { $anchorMatches[$beatIndex + 1].Index } else { $block.Length }
            $segment = $block.Substring($beatStart, $beatEnd - $beatStart)
            if ([string]::IsNullOrWhiteSpace((Get-NarrativeText -Text $segment))) {
                throw "El tramo $($beats[$beatIndex]) de $($escena.id) no contiene prosa narrativa."
            }
        }
        foreach ($beat in $escena.beats) { $expectedAnchors.Add($beat) }
    }

    $actualAnchors = @([regex]::Matches($draft, '(?m)^<!--\s*(B_\d{4})\s*-->\s*$') | ForEach-Object { $_.Groups[1].Value })
    if (-not (Test-RelatoIdSequence -Esperados $expectedAnchors.ToArray() -Actuales $actualAnchors)) {
        throw "El draft contiene anclas B_XXXX fuera de sus escenas o en un orden inválido."
    }
}

function Get-Config {
    param([string]$Path)

    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "El config.json no es válido: $_"
    }
}

function Get-IdMaximum {
    param([string[]]$Ids)

    if ($Ids.Count -eq 0) { return 0 }
    return [int](($Ids | ForEach-Object { [int]$_.Substring(2) } | Measure-Object -Maximum).Maximum)
}

function Assert-ConfigCounters {
    param($NextConfig, $CurrentConfig, [object[]]$Escenas, [string]$Operation)

    foreach ($property in @("ultimo_hecho_seq", "ultimo_beat_seq", "ultimo_escena_seq")) {
        if ($NextConfig.PSObject.Properties.Name -notcontains $property -or $CurrentConfig.PSObject.Properties.Name -notcontains $property) {
            throw "Ambos config.json deben contener $property."
        }
        try {
            $nextValue = [int]$NextConfig.$property
            $currentValue = [int]$CurrentConfig.$property
        } catch {
            throw "Los contadores $property deben ser numéricos."
        }
        if ($property -eq "ultimo_hecho_seq" -and $Operation -ne "hechos" -and $nextValue -ne $currentValue) {
            throw "ultimo_hecho_seq solo cambia al modificar hechos antes del diseño; esta transacción debe conservarlo."
        }
        if (($property -ne "ultimo_hecho_seq" -or $Operation -eq "hechos") -and $nextValue -lt $currentValue) {
            throw "El contador $property no puede retroceder."
        }
    }

    $maxBeat = Get-IdMaximum -Ids @($Escenas | ForEach-Object { $_.beats } | ForEach-Object { $_ })
    $maxScene = Get-IdMaximum -Ids @($Escenas | ForEach-Object { $_.id })
    if ([int]$NextConfig.ultimo_beat_seq -lt $maxBeat) {
        throw "ultimo_beat_seq es menor que el mayor B_XXXX del guion."
    }
    if ([int]$NextConfig.ultimo_escena_seq -lt $maxScene) {
        throw "ultimo_escena_seq es menor que el mayor E_XXXX del guion."
    }
}

function Assert-HechoContract {
    param([string]$ActosPath, $NextConfig)

    $actos = Get-Content -LiteralPath $ActosPath -Raw -Encoding UTF8
    $ids = @([regex]::Matches($actos, '(?m)^-\s+(H_\d{4})\b[^\r\n]*?—') | ForEach-Object { $_.Groups[1].Value })
    if ($ids.Count -eq 0) {
        throw "_actos.md no contiene hechos H_XXXX compatibles."
    }
    if (($ids | Select-Object -Unique).Count -ne $ids.Count) {
        throw "_actos.md repite un H_XXXX."
    }
    $maxHecho = Get-IdMaximum -Ids $ids
    if ([int]$NextConfig.ultimo_hecho_seq -ne $maxHecho) {
        throw "ultimo_hecho_seq debe coincidir con el mayor H_XXXX de _actos.md durante diseño."
    }
}

function Assert-StateTransition {
    param([string]$Operation, $NextConfig, $CurrentConfig)

    if ($NextConfig.PSObject.Properties.Name -notcontains "estado" -or $CurrentConfig.PSObject.Properties.Name -notcontains "estado") {
        throw "Ambos config.json deben contener estado."
    }
    $currentState = [string]$CurrentConfig.estado
    $nextState = [string]$NextConfig.estado
    switch ($Operation) {
        "hechos" {
            if ($currentState -ne "diseno" -or $nextState -ne "diseno") {
                throw "hechos solo puede confirmar ajustes diseno → diseno."
            }
        }
        "diseno" {
            if ($currentState -ne "diseno" -or $nextState -ne "fichas") {
                throw "diseno requiere transición diseno → fichas."
            }
        }
        "guion" {
            if ($currentState -ne "fichas" -or $nextState -ne "fichas") {
                throw "guion solo puede confirmar ajustes fichas → fichas."
            }
        }
        "componentes" {
            if ($currentState -ne "fichas" -or $nextState -ne "escritura") {
                throw "componentes requiere transición fichas → escritura."
            }
        }
        "escritura" {
            if ($currentState -ne "escritura" -or $nextState -ne "escritura") {
                throw "escritura solo puede confirmar escenas en estado escritura."
            }
        }
        "correccion" {
            if ($currentState -notin @("escritura", "correccion") -or $nextState -ne $currentState) {
                throw "correccion debe conservar el estado actual de escritura o correccion."
            }
        }
        "publicar" {
            if ($currentState -notin @("escritura", "correccion") -or $nextState -ne "finalizado") {
                throw "publicar requiere transición escritura|correccion → finalizado."
            }
        }
    }
}

function Assert-ClosedCola {
    param([string]$ColaPath, [string]$ActosPath)

    if (-not (Test-Path -LiteralPath $ColaPath -PathType Leaf)) {
        throw "El diseño y los ajustes de guion requieren cola_d.md."
    }
    $cola = Get-Content -LiteralPath $ColaPath -Raw -Encoding UTF8
    if ($cola -notmatch '(?mi)^#\s*Cola\s+\[D\]\s*—\s*cerrada\s*$') {
        throw "cola_d.md debe declarar el encabezado '# Cola [D] — cerrada'."
    }
    if ([regex]::Matches($cola, '(?mi)^-\s*Estado global:\s*cerrada\s*$').Count -ne 1) {
        throw "cola_d.md debe declarar una sola vez 'Estado global: cerrada'."
    }

    $actos = Get-Content -LiteralPath $ActosPath -Raw -Encoding UTF8
    $expected = @([regex]::Matches($actos, '(?m)^-\s+(H_\d{4})\b[^\r\n]*\[D(?:\s|·|\])') | ForEach-Object { $_.Groups[1].Value })
    $entries = [regex]::Matches($cola, '(?m)^##\s+(H_\d{4})\s+—\s+.+?\s*$')
    $seen = @{}
    for ($entryIndex = 0; $entryIndex -lt $entries.Count; $entryIndex++) {
        $entry = $entries[$entryIndex]
        $id = $entry.Groups[1].Value
        if ($seen.ContainsKey($id)) { throw "cola_d.md repite la entrada $id." }
        $seen[$id] = $true
        $end = if ($entryIndex + 1 -lt $entries.Count) { $entries[$entryIndex + 1].Index } else { $cola.Length }
        $block = $cola.Substring($entry.Index + $entry.Length, $end - ($entry.Index + $entry.Length))
        $state = [regex]::Match($block, '(?mi)^-\s*Estado:\s*(resuelto|pendiente|bloqueo)\s*$')
        if (-not $state.Success -or $state.Groups[1].Value.ToLowerInvariant() -ne "resuelto") {
            throw "La recurrencia $id debe estar en Estado: resuelto antes de cerrar la cola."
        }
    }
    if ($expected.Count -eq 0 -and $cola -notmatch '(?mi)^-\s*Sin recurrencias\s+\[D\]\.\s*$') {
        throw "Una cola sin [D] debe declarar 'Sin recurrencias [D].'."
    }
    if ($expected.Count -gt 0 -and $cola -match '(?mi)^-\s*Sin recurrencias\s+\[D\]\.\s*$') {
        throw "cola_d.md declara que no hay [D], pero _actos.md sí contiene recurrencias."
    }
    if ($expected.Count -ne $seen.Count -or @($expected | Where-Object { -not $seen.ContainsKey($_) }).Count -gt 0) {
        throw "cola_d.md debe contener exactamente una entrada resuelta por cada hecho [D] de _actos.md."
    }
}

function Assert-NonEmptyFile {
    param([string]$Path, [string]$Name)

    if ([string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $Path -Raw -Encoding UTF8))) {
        throw "$Name no puede quedar vacío."
    }
}

function Assert-CleanManuscript {
    param([string]$ManuscriptPath)

    $manuscript = Get-Content -LiteralPath $ManuscriptPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($manuscript)) {
        throw "relato.md no puede quedar vacío."
    }
    if ($manuscript -notmatch '(?m)^#\s+\S') {
        throw "relato.md debe empezar con un título Markdown."
    }
    $body = [regex]::Replace($manuscript, '^\s*#\s+[^\r\n]+(?:\r?\n|$)', '')
    if ([string]::IsNullOrWhiteSpace($body)) {
        throw "relato.md debe contener prosa además del título."
    }
    if ($manuscript -match '<!--|\b[BE]_\d{4}\b') {
        throw "relato.md conserva marcadores o IDs de control."
    }
    if ($manuscript -match '(?m)^---\s*\r?$\s*(?:\r?\n)^---\s*$') {
        throw "relato.md contiene separadores duplicados."
    }
}

function Assert-AllBeatsClosed {
    param([string]$GuionPath)

    $guion = Get-Content -LiteralPath $GuionPath -Raw -Encoding UTF8
    $matches = [regex]::Matches($guion, '(?m)^\s*(?:[-*]\s*)?(⬜|🔄|✅)?\s*(B_\d{4})\s+—')
    $unfinished = @($matches | Where-Object { $_.Groups[1].Value -ne "✅" } | ForEach-Object { $_.Groups[2].Value })
    if ($unfinished.Count -gt 0) {
        throw "No se puede publicar: beats sin cerrar ($($unfinished -join ', '))."
    }
}

function Assert-Stage {
    param([string]$Operation)

    $requiredFiles = @($OperationFiles[$Operation])
    foreach ($file in $requiredFiles) {
        $path = Join-Path $NextRoot $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Falta $file en el staging de $Operation."
        }
    }

    $nextConfig = Get-Config -Path (Join-Path $NextRoot "config.json")
    $currentConfig = Get-Config -Path (Join-Path $WorkspaceRoot "config.json")
    if ($Operation -eq "hechos") {
        Assert-ConfigCounters -NextConfig $nextConfig -CurrentConfig $currentConfig -Escenas @() -Operation $Operation
        Assert-StateTransition -Operation $Operation -NextConfig $nextConfig -CurrentConfig $currentConfig
        Assert-HechoContract -ActosPath (Join-Path $NextRoot "_actos.md") -NextConfig $nextConfig
        return
    }
    $escenas = @(Get-RelatoGuionEscenas -GuionPath (Join-Path $NextRoot "guion.md"))
    Assert-ConfigCounters -NextConfig $nextConfig -CurrentConfig $currentConfig -Escenas $escenas -Operation $Operation
    Assert-StateTransition -Operation $Operation -NextConfig $nextConfig -CurrentConfig $currentConfig

    switch ($Operation) {
        { $_ -in @("diseno", "guion") } {
            Assert-ClosedCola -ColaPath (Join-Path $NextRoot "cola_d.md") -ActosPath (Join-Path $WorkspaceRoot "_actos.md")
        }
        "componentes" {
            Assert-DraftContract -Escenas $escenas -DraftPath (Join-Path $NextRoot "relato-draft.md")
            Assert-NonEmptyFile -Path (Join-Path $NextRoot "contexto_narrativo.md") -Name "contexto_narrativo.md"
        }
        { $_ -in @("escritura", "correccion") } {
            Assert-DraftContract -Escenas $escenas -DraftPath (Join-Path $NextRoot "relato-draft.md")
            Assert-NonEmptyFile -Path (Join-Path $NextRoot "contexto_narrativo.md") -Name "contexto_narrativo.md"
            if ($Operation -eq "correccion") {
                Assert-NonEmptyFile -Path (Join-Path $NextRoot "correcciones.md") -Name "correcciones.md"
            }
        }
        "publicar" {
            Assert-DraftContract -Escenas $escenas -DraftPath (Join-Path $NextRoot "relato-draft.md") -Completo
            Assert-AllBeatsClosed -GuionPath (Join-Path $NextRoot "guion.md")
            Assert-CleanManuscript -ManuscriptPath (Join-Path $NextRoot "relato.md")
        }
    }
}

function Start-Transaction {
    param([string]$Operation)

    if ([string]::IsNullOrWhiteSpace($Operation)) {
        throw "Preparar requiere una operación válida."
    }
    if (Test-Path -LiteralPath $TransactionRoot) {
        throw "Ya existe una transacción. Ejecuta -Accion Recuperar y retómala o usa -Accion Descartar antes de preparar otra."
    }

    New-Item -ItemType Directory -Force -Path $NextRoot | Out-Null
    foreach ($file in $KnownFiles) {
        $source = Join-Path $WorkspaceRoot $file
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $NextRoot $file) -Force
        }
    }
    Write-Manifest ([ordered]@{
        version = 2
        estado = "preparada"
        operacion = $Operation
        creada = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    })
    Write-Output "Staging preparado: .forja-transaccion/siguiente/ ($Operation)."
}

function Confirm-Transaction {
    $manifest = Read-Manifest
    if ($manifest.estado -ne "preparada") {
        throw "Solo se puede confirmar una transacción preparada; estado actual: $($manifest.estado)."
    }
    $operation = [string]$manifest.operacion
    if ($operation -notin $OperationFiles.Keys) {
        throw "La operación del manifiesto no es válida: $operation"
    }

    Assert-Stage -Operation $operation
    $files = @($OperationFiles[$operation])
    Assert-KnownFiles -Files $files
    $existing = @($files | Where-Object { Test-Path -LiteralPath (Join-Path $WorkspaceRoot $_) -PathType Leaf })
    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    foreach ($file in $existing) {
        Copy-Item -LiteralPath (Join-Path $WorkspaceRoot $file) -Destination (Join-Path $BackupRoot $file) -Force
    }

    $manifest | Add-Member -NotePropertyName "archivos" -NotePropertyValue $files -Force
    $manifest | Add-Member -NotePropertyName "existentes" -NotePropertyValue $existing -Force
    $manifest.estado = "aplicando"
    Write-Manifest $manifest

    foreach ($file in $files) {
        Copy-Item -LiteralPath (Join-Path $NextRoot $file) -Destination (Join-Path $WorkspaceRoot $file) -Force
    }

    $manifest.estado = "completada"
    Write-Manifest $manifest
    Remove-Item -LiteralPath $TransactionRoot -Recurse -Force
    Write-Output "Transacción $operation confirmada."
}

function Recover-Transaction {
    if (-not (Test-Path -LiteralPath $TransactionRoot -PathType Container)) {
        Write-Output "No hay transacción pendiente."
        return
    }

    $manifest = Read-Manifest
    switch ($manifest.estado) {
        "preparada" {
            Write-Output "Staging preparado recuperado para reanudar: operación $($manifest.operacion). Usa Descartar solo si ya no es válido."
        }
        "aplicando" {
            $files = @($manifest.archivos)
            $existing = @($manifest.existentes)
            Assert-KnownFiles -Files $files
            foreach ($file in $files) {
                $target = Join-Path $WorkspaceRoot $file
                if (Test-Path -LiteralPath $target -PathType Leaf) {
                    Remove-Item -LiteralPath $target -Force
                }
                if ($file -in $existing) {
                    Copy-Item -LiteralPath (Join-Path $BackupRoot $file) -Destination $target -Force
                }
            }
            Remove-Item -LiteralPath $TransactionRoot -Recurse -Force
            Write-Output "Transacción interrumpida restaurada al último conjunto coherente."
        }
        "completada" {
            Remove-Item -LiteralPath $TransactionRoot -Recurse -Force
            Write-Output "Transacción ya completada; se limpiaron sus metadatos."
        }
        default {
            throw "Estado de transacción desconocido: $($manifest.estado)."
        }
    }
}

function Discard-Transaction {
    if (-not (Test-Path -LiteralPath $TransactionRoot -PathType Container)) {
        Write-Output "No hay transacción pendiente que descartar."
        return
    }

    $manifest = Read-Manifest
    switch ($manifest.estado) {
        "preparada" {
            Remove-Item -LiteralPath $TransactionRoot -Recurse -Force
            Write-Output "Staging preparado descartado; los archivos vivos no se habían modificado."
        }
        "aplicando" {
            throw "No se puede descartar una transacción aplicando: ejecuta -Accion Recuperar para restaurarla."
        }
        "completada" {
            Remove-Item -LiteralPath $TransactionRoot -Recurse -Force
            Write-Output "Transacción ya completada; se limpiaron sus metadatos."
        }
        default {
            throw "Estado de transacción desconocido: $($manifest.estado)."
        }
    }
}

switch ($Accion) {
    "Preparar" { Start-Transaction -Operation $Operacion }
    "Confirmar" { Confirm-Transaction }
    "Recuperar" { Recover-Transaction }
    "Descartar" { Discard-Transaction }
}
