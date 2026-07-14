# relato-transaccion.ps1 — Commit recuperable de artefactos canónicos de relato.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Preparar", "Confirmar", "Recuperar")]
    [string]$Accion,
    [ValidateSet("diseno", "correccion", "publicar")]
    [string]$Operacion
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$TransactionRoot = Join-Path $WorkspaceRoot ".forja-transaccion"
$NextRoot = Join-Path $TransactionRoot "siguiente"
$BackupRoot = Join-Path $TransactionRoot "respaldo"
$ManifestPath = Join-Path $TransactionRoot "manifest.json"
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$KnownFiles = @("config.json", "guion.md", "relato-draft.md", "contexto_narrativo.md", "cola_d.md", "correcciones.md", "relato.md")
$OperationFiles = @{
    diseno = @("config.json", "guion.md", "cola_d.md")
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

function Assert-DraftContract {
    param([object[]]$Escenas, [string]$DraftPath)

    $draft = Get-Content -LiteralPath $DraftPath -Raw -Encoding UTF8
    $markerPattern = '(?m)^<!--\s*ESCENA\s+(E_\d{4})\s*:\s*(.*?)\s*\|\s*salida:\s*(continua|separador)\s*-->\s*$'
    $markers = [regex]::Matches($draft, $markerPattern)
    $expectedScenes = @($Escenas | ForEach-Object { $_.id })
    $actualScenes = @($markers | ForEach-Object { $_.Groups[1].Value })
    if (-not (Test-RelatoIdSequence -Esperados $expectedScenes -Actuales $actualScenes)) {
        throw "Los marcadores ESCENA del draft no coinciden exactamente con el guion."
    }

    for ($index = 0; $index -lt $Escenas.Count; $index++) {
        $escena = $Escenas[$index]
        if ($markers[$index].Groups[3].Value.ToLowerInvariant() -ne $escena.salida) {
            throw "La salida del marcador $($escena.id) no coincide con el guion."
        }
        $start = $markers[$index].Index + $markers[$index].Length
        $end = if ($index + 1 -lt $markers.Count) { $markers[$index + 1].Index } else { $draft.Length }
        $block = $draft.Substring($start, $end - $start)
        $beats = @([regex]::Matches($block, '(?m)^<!--\s*(B_\d{4})\s*-->\s*$') | ForEach-Object { $_.Groups[1].Value })
        if (-not (Test-RelatoIdSequence -Esperados $escena.beats -Actuales $beats)) {
            throw "Los beats del draft en $($escena.id) no coinciden con el guion."
        }
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
    param($NextConfig, $CurrentConfig, [object[]]$Escenas)

    foreach ($property in @("ultimo_beat_seq", "ultimo_escena_seq")) {
        if ($NextConfig.PSObject.Properties.Name -notcontains $property) {
            throw "El config de staging no contiene $property."
        }
        try {
            $nextValue = [int]$NextConfig.$property
            $currentValue = [int]$CurrentConfig.$property
        } catch {
            throw "Los contadores $property deben ser numéricos."
        }
        if ($nextValue -lt $currentValue) {
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

function Assert-CleanManuscript {
    param([string]$ManuscriptPath)

    $manuscript = Get-Content -LiteralPath $ManuscriptPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($manuscript)) {
        throw "relato.md no puede quedar vacío."
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

    $requiredFiles = switch ($Operation) {
        "diseno" { @("config.json", "guion.md") }
        "correccion" { @("config.json", "guion.md", "relato-draft.md", "contexto_narrativo.md") }
        "publicar" { @("config.json", "guion.md", "relato-draft.md", "relato.md") }
    }
    foreach ($file in $requiredFiles) {
        $path = Join-Path $NextRoot $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Falta $file en el staging de $Operation."
        }
    }

    $nextConfig = Get-Config -Path (Join-Path $NextRoot "config.json")
    $currentConfig = Get-Config -Path (Join-Path $WorkspaceRoot "config.json")
    $escenas = @(Get-RelatoGuionEscenas -GuionPath (Join-Path $NextRoot "guion.md"))
    Assert-ConfigCounters -NextConfig $nextConfig -CurrentConfig $currentConfig -Escenas $escenas

    if ($Operation -eq "diseno" -and $nextConfig.estado -ne "fichas") {
        throw "El diseño confirmado debe dejar config.json.estado = 'fichas'."
    }
    if ($Operation -in @("correccion", "publicar")) {
        Assert-DraftContract -Escenas $escenas -DraftPath (Join-Path $NextRoot "relato-draft.md")
    }
    if ($Operation -eq "publicar") {
        Assert-AllBeatsClosed -GuionPath (Join-Path $NextRoot "guion.md")
        if ($nextConfig.estado -ne "finalizado") {
            throw "La publicación confirmada debe dejar config.json.estado = 'finalizado'."
        }
        Assert-CleanManuscript -ManuscriptPath (Join-Path $NextRoot "relato.md")
    }
}

function Start-Transaction {
    param([string]$Operation)

    if ([string]::IsNullOrWhiteSpace($Operation)) {
        throw "Preparar requiere -Operacion diseno, correccion o publicar."
    }
    if (Test-Path -LiteralPath $TransactionRoot) {
        throw "Ya existe una transacción. Ejecuta -Accion Recuperar antes de preparar otra."
    }

    New-Item -ItemType Directory -Force -Path $NextRoot | Out-Null
    foreach ($file in $KnownFiles) {
        $source = Join-Path $WorkspaceRoot $file
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $NextRoot $file) -Force
        }
    }
    Write-Manifest ([ordered]@{
        version = 1
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
    $files = @($OperationFiles[$operation] | Where-Object { Test-Path -LiteralPath (Join-Path $NextRoot $_) -PathType Leaf })
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
            Remove-Item -LiteralPath $TransactionRoot -Recurse -Force
            Write-Output "Staging pendiente descartado; los archivos vivos no se habían modificado."
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

switch ($Accion) {
    "Preparar" { Start-Transaction -Operation $Operacion }
    "Confirmar" { Confirm-Transaction }
    "Recuperar" { Recover-Transaction }
}
