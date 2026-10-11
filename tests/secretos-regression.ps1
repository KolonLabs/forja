# secretos-regression.ps1 — Lectura de secretos en PowerShell y Python (ADR 0029).
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-secretos-regression-" + [guid]::NewGuid().ToString("N"))
$Scripts = Join-Path $RepoRoot "shared\scripts"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

$previo = @{ F = $env:FORJA_SECRETOS; A = $env:FORJA_PRUEBA_A; B = $env:FORJA_PRUEBA_B }
try {
    New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null
    $archivo = Join-Path $RunRoot "secretos.env"
    [System.IO.File]::WriteAllText($archivo, "# comentario`nFORJA_PRUEBA_A=valor-a-123`nFORJA_PRUEBA_B=`"con comillas`"`nFORJA_PRUEBA_VACIA=`n", [System.Text.UTF8Encoding]::new($true))
    $env:FORJA_SECRETOS = $archivo
    Remove-Item Env:FORJA_PRUEBA_A, Env:FORJA_PRUEBA_B -ErrorAction SilentlyContinue

    # PowerShell
    . (Join-Path $Scripts "secretos.ps1")
    Assert-True ((Get-ForjaSecreto FORJA_PRUEBA_A) -ceq "valor-a-123") "ps: lee del archivo (con BOM)"
    Assert-True ((Get-ForjaSecreto FORJA_PRUEBA_B) -ceq "con comillas") "ps: quita comillas"
    Assert-True ($null -eq (Find-ForjaSecreto FORJA_PRUEBA_VACIA)) "ps: un valor vacío no está definido"
    $fallo = $null; try { Get-ForjaSecreto FORJA_PRUEBA_NO_EXISTE } catch { $fallo = $_.Exception.Message }
    Assert-True ($fallo -match "no está definido" -and $fallo -match [regex]::Escape($archivo)) "ps: el error dice dónde definirlo"
    $fallo = $null; try { Get-ForjaSecreto "minusculas" } catch { $fallo = $_.Exception.Message }
    Assert-True ($fallo -match "no válido") "ps: rechaza nombres no válidos"
    $env:FORJA_PRUEBA_A = "desde-entorno"
    Assert-True ((Get-ForjaSecreto FORJA_PRUEBA_A) -ceq "desde-entorno") "ps: la variable de entorno prevalece"
    $informe = Test-ForjaSecreto FORJA_PRUEBA_A
    Assert-True ($informe -match "variable de entorno" -and $informe -notmatch "desde-entorno") "ps: la comprobación no muestra el valor"
    Remove-Item Env:FORJA_PRUEBA_A

    # Python
    $python = (Get-Command python -ErrorAction Stop).Source
    $salida = & $python -B (Join-Path $Scripts "secretos.py") --comprobar FORJA_PRUEBA_A
    Assert-True ($LASTEXITCODE -eq 0 -and $salida -match "definido \(fuente: archivo" -and $salida -notmatch "valor-a-123") "py: comprueba sin mostrar el valor"
    & $python -B (Join-Path $Scripts "secretos.py") --comprobar FORJA_PRUEBA_VACIA | Out-Null
    Assert-True ($LASTEXITCODE -eq 1) "py: un valor vacío no está definido"
    $codigo = "import sys; sys.path.insert(0, r'$Scripts'); from secretos import obtener_secreto as o; print(o('FORJA_PRUEBA_A') == 'valor-a-123', o('FORJA_PRUEBA_B') == 'con comillas')"
    Assert-True ((& $python -B -c $codigo) -eq "True True") "py: lee del archivo y quita comillas"
    $env:FORJA_PRUEBA_B = "entorno-b"
    $codigo = "import sys; sys.path.insert(0, r'$Scripts'); from secretos import obtener_secreto as o; print(o('FORJA_PRUEBA_B') == 'entorno-b')"
    Assert-True ((& $python -B -c $codigo) -eq "True") "py: la variable de entorno prevalece"

    Write-Host "OK: secretos-regression"
} finally {
    $env:FORJA_SECRETOS = $previo.F; $env:FORJA_PRUEBA_A = $previo.A; $env:FORJA_PRUEBA_B = $previo.B
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force }
}
