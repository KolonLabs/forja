# marcas-beat-regression.ps1 — Tonos y extensiones de beat dentro del catálogo de tonos-beat.
# Relato: relato-transaccion.ps1 exige [Tono — EXTENSIÓN] del catálogo común y arcos con sus tonos (ADR 0035).
# Novela: etiquetas-guion.py informa de tonos y extensiones fuera del catálogo.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-marcas-beat-" + [guid]::NewGuid().ToString("N"))
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

try {
    # --- Relato: mismo catálogo y formato que novela (ADR 0035) ---
    $relato = Join-Path $RunRoot "relato"
    Copy-Item (Join-Path $RepoRoot "shared\pipelines\relato\scripts\relato-transaccion.ps1") (New-Item -ItemType Directory -Force (Join-Path $relato "scripts")) | Out-Null
    $skill = Join-Path $relato ".claude\skills\tonos-beat"
    New-Item -ItemType Directory -Force $skill | Out-Null
    Copy-Item (Join-Path $RepoRoot "shared\skills\tonos-beat\SKILL.md") $skill
    Write-Utf8 (Join-Path $relato "config.json") '{"estado":"fichas","ultimo_hecho_seq":1,"ultimo_beat_seq":2,"ultimo_escena_seq":1,"hechos_revision_pendiente":[]}'
    $guion = "# Guion`n`n## Escenas`n`n### E_0001 — Uno`n`n{0}- Salida: continua`n`n#### Beats`n`n⬜ B_0001 — Ana abre la puerta. {1}`n⬜ B_0002 — Luis entra. [Tenso — EXTENSA] [elipsis]`n"
    Write-Utf8 (Join-Path $relato "guion.md") ($guion -f "", "[Clínico — MEDIA]")

    function Confirmar-Guion([string]$Arco, [string]$Marca) {
        Push-Location $relato
        try {
            pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion guion | Out-Null
            Write-Utf8 (Join-Path $relato ".forja-transaccion\siguiente\guion.md") ($guion -f $Arco, $Marca)
            $salida = pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Confirmar 2>&1
            # La consola parte el error al ancho de la terminal: se une antes de buscar.
            return [pscustomobject]@{ Codigo = $LASTEXITCODE; Salida = ((($salida -join " ") -replace "\s+\|\s+", " ") -replace "\s+", " ") }
        } finally {
            if (Test-Path (Join-Path $relato ".forja-transaccion")) {
                pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Descartar 2>&1 | Out-Null
            }
            Pop-Location
        }
    }

    $c = Confirmar-Guion "" "[Rudo — MEDIA]"
    Assert-True ($c.Codigo -ne 0 -and $c.Salida -match "tono «Rudo»") "relato: un tono fuera de catálogo bloquea el guion ($($c.Salida))"
    $c = Confirmar-Guion "" "[registro: tenso]"
    Assert-True ($c.Codigo -ne 0 -and $c.Salida -match "formato anterior") "relato: el formato [registro:] se rechaza ($($c.Salida))"
    $c = Confirmar-Guion "- Arco tonal: Clínico → Tenso`n" "[Clínico — MEDIA]"
    Assert-True ($c.Codigo -ne 0 -and $c.Salida -match "arco tonal de escena") "relato: la escena no declara arco tonal ($($c.Salida))"
    $c = Confirmar-Guion "" ""
    Assert-True ($c.Codigo -ne 0 -and $c.Salida -match "B_0001: sin \[Tono") "relato: un beat sin tono se rechaza ($($c.Salida))"
    $c = Confirmar-Guion "" "[Explícito / Sumiso — MEDIA]"
    Assert-True ($c.Codigo -eq 0 -and $c.Salida -match "confirmada") "relato: tonos del catálogo y [elipsis] se confirman ($($c.Salida))"
    # --- Novela ---
    $novela = Join-Path $RunRoot "novela"
    $skillN = Join-Path $novela ".claude\skills\tonos-beat"
    New-Item -ItemType Directory -Force $skillN, (Join-Path $novela "scripts") | Out-Null
    Copy-Item (Join-Path $RepoRoot "shared\skills\tonos-beat\SKILL.md") $skillN
    Copy-Item (Join-Path $RepoRoot "shared\pipelines\novela-simple\scripts\etiquetas-guion.py") (Join-Path $novela "scripts")
    Write-Utf8 (Join-Path $novela "capitulos\cap-01-uno\guion.md") ("<!-- ESCENA aaaa1111: Uno -->`n" +
        "⬜ a1a1a1a1 [1] — Mira el patio [Contemplativo — MEDIA] [Ana]`n" +
        "⬜ b2b2b2b2 [2] — Abre el sobre [Revelación / Tenso — BREVE] [Ana]`n" +
        "⬜ f6f6f6f6 [6] — Sigue su mano [Explícito / Sumiso — MEDIA] [Ana]`n" +
        "⬜ c3c3c3c3 [3] — Se marcha [Melancólico — LARGA] [Ana]`n" +
        "⬜ d4d4d4d4 [4] — Vuelve [Clínico / Tenso / Opresivo — MEDIA] [Ana]`n" +
        "⬜ e5e5e5e5 [5] — Cierra la puerta [Ana]`n")
    $r = (python -X utf8 -B (Join-Path $novela "scripts\etiquetas-guion.py") --obra $novela --simular | ConvertFrom-Json).ambitos[0]
    $motivos = @($r.fuera_de_catalogo | ForEach-Object { "$($_.etiqueta): $($_.motivo)" })
    Assert-True ($motivos.Count -eq 4) "novela: cuatro beats fuera de catálogo ($($motivos -join ' | '))"
    Assert-True (($motivos -match "B_0004.*Melancólico").Count -eq 1) "novela: tono inexistente"
    Assert-True (($motivos -match "B_0004.*LARGA").Count -eq 1) "novela: extensión inexistente"
    Assert-True (($motivos -match "B_0005.*más de dos").Count -eq 1) "novela: más de dos tonos"
    Assert-True (($motivos -match "B_0006.*sin").Count -eq 1) "novela: beat sin tono ni extensión"
    Assert-True (($motivos -match "B_000[123]:").Count -eq 0) "novela: Contemplativo, Sumiso y tonos compuestos válidos pasan"

    Write-Host "OK: marcas-beat-regression"
} finally {
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
