# secretos.ps1 -- Lectura de secretos del usuario (ADR 0029). Se carga con dot-sourcing.
# Orden: variable de entorno del proceso con el mismo nombre; después el archivo de
# secretos (FORJA_SECRETOS o ~/.forja/secretos.env). Nunca escribe ni muestra valores.

function Get-ForjaSecretosPath {
    if (-not [string]::IsNullOrWhiteSpace($env:FORJA_SECRETOS)) { return $env:FORJA_SECRETOS }
    return Join-Path $HOME ".forja\secretos.env"
}

function Find-ForjaSecreto {
    # Devuelve @{ Valor; Fuente } o $null si el secreto no está definido.
    param([Parameter(Mandatory = $true)][string]$Nombre)

    if ($Nombre -cnotmatch '^[A-Z][A-Z0-9_]*$') {
        throw "secretos: nombre '$Nombre' no válido. Usa MAYUSCULAS_CON_GUIONES_BAJOS."
    }
    $valor = [Environment]::GetEnvironmentVariable($Nombre)
    if (-not [string]::IsNullOrWhiteSpace($valor)) {
        return [pscustomobject]@{ Valor = $valor; Fuente = "variable de entorno" }
    }

    $path = Get-ForjaSecretosPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    foreach ($linea in [System.IO.File]::ReadAllLines($path)) {
        $linea = $linea.Trim()
        if ($linea -eq "" -or $linea.StartsWith("#")) { continue }
        $partes = $linea.Split("=", 2)
        if ($partes.Count -ne 2 -or $partes[0].Trim() -ne $Nombre) { continue }
        $valor = $partes[1].Trim()
        if ($valor.Length -ge 2 -and (($valor[0] -eq '"' -and $valor[-1] -eq '"') -or ($valor[0] -eq "'" -and $valor[-1] -eq "'"))) {
            $valor = $valor.Substring(1, $valor.Length - 2)
        }
        if ([string]::IsNullOrWhiteSpace($valor)) { return $null }
        return [pscustomobject]@{ Valor = $valor; Fuente = "archivo $path" }
    }
    return $null
}

function Get-ForjaSecreto {
    # Devuelve el valor o lanza un error que dice dónde definirlo, sin mostrar nada.
    param([Parameter(Mandatory = $true)][string]$Nombre)

    $secreto = Find-ForjaSecreto -Nombre $Nombre
    if (-not $secreto) {
        throw "secretos: '$Nombre' no está definido. Añádelo a $(Get-ForjaSecretosPath) o como variable de entorno."
    }
    return $secreto.Valor
}

function Test-ForjaSecreto {
    # Informa de si el secreto existe y de dónde sale, nunca de su valor.
    param([Parameter(Mandatory = $true)][string]$Nombre)

    $secreto = Find-ForjaSecreto -Nombre $Nombre
    if ($secreto) { return "$Nombre definido (fuente: $($secreto.Fuente))" }
    return "$Nombre no definido"
}
