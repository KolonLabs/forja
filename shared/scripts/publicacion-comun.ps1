# publicacion-comun.ps1 -- Utilidades de compilar.ps1 y borrador.ps1 (ADR 0026, ADR 0028).
# Se carga con dot-sourcing; no se ejecuta por sí solo.

function Get-FileSha256 {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-ObraConfig {
    param([string]$WorkspaceRoot)

    $path = Join-Path $WorkspaceRoot "config.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Falta config.json en $WorkspaceRoot."
    }
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    try {
        $config = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "config.json no es válido. $_"
    }
    if ("$($config.slug)" -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        throw "config.json.slug '$($config.slug)' no es un slug kebab-case."
    }
    return [pscustomobject]@{ Path = $path; Raw = $raw; Config = $config }
}

function Get-GitEstado {
    # Commit de la obra y si alguno de los archivos indicados tiene cambios sin
    # commitear. Sin git o sin commits devuelve nulos: compilar no depende del historial.
    param([string]$WorkspaceRoot, [string[]]$Paths)

    $estado = [ordered]@{ commit = $null; sin_commit = $null }
    if (-not (Test-Path -LiteralPath (Join-Path $WorkspaceRoot ".git"))) { return $estado }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $estado }

    $commit = & git -C $WorkspaceRoot rev-parse --verify --quiet HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) { return $estado }
    $estado.commit = "$commit".Trim()
    $cambios = & git -C $WorkspaceRoot status --porcelain -- @Paths 2>$null
    $estado.sin_commit = -not [string]::IsNullOrWhiteSpace(($cambios | Out-String))
    return $estado
}
