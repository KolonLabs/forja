# renumerar-regression.ps1 — shared/scripts/renumerar.ps1: solo renumera definiciones, conserva el formato y es idempotente.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Script = Join-Path $RepoRoot "shared\scripts\renumerar.ps1"
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("forja-renumerar-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $Tmp | Out-Null
$fallos = [System.Collections.Generic.List[string]]::new()
$raya = [char]0x2014
$casilla = [char]0x2B1C

function Check([bool]$ok, [string]$msg) { if (-not $ok) { $fallos.Add($msg) } }
function Run([string[]]$argv) { $out = & pwsh -NoProfile -File $Script @argv 2>&1; return @($out | ForEach-Object { "$_" }) }
function Put([string]$name, [string]$text, [bool]$bom = $false) {
    $p = Join-Path $Tmp $name
    [IO.File]::WriteAllText($p, $text, [Text.UTF8Encoding]::new($bom)); return $p
}

try {
    # 1. Guion de relato: beats intercalados, escenas, notas y menciones. LF, sin BOM, con salto final.
    $guion = @(
        "### E_0001 $raya La boda"
        "$casilla B_0001 $raya Abre la boda."
        "$casilla B_0101 $raya Beat insertado."
        "$casilla B_0002 $raya Detras de la cabina, como en B_0101."
        "### E_0002 $raya El coche"
        "$casilla B_0003 $raya Finge dormir."
        ""
        "## Notas"
        "- B_0002 se superpone con I (B_0116$([char]0x2013)B_0049)."
        ""
    ) -join "`n"
    $p = Put "guion.md" $guion
    $h0 = (Get-FileHash $p).Hash

    $sim = Run @($p, "-LineStart", "$casilla B_")
    Check ((Get-FileHash $p).Hash -eq $h0) "sin -InPlace no debe escribir"
    Check (($sim -join "`n") -match 'B_0101 -> B_0002') "la simulación debe listar B_0101 -> B_0002"

    $out = Run @($p, "-LineStart", "$casilla B_", "-InPlace")
    $t = [IO.File]::ReadAllText($p)
    $beats = @([regex]::Matches($t, "(?m)^$casilla B_(\d{4})") | ForEach-Object { $_.Groups[1].Value })
    Check (($beats -join ",") -eq "0001,0002,0003,0004") "beats renumerados: $($beats -join ',')"
    Check ($t.Contains("como en B_0101.")) "una mención en mitad de línea no debe cambiar"
    Check ($t.Contains("- B_0002 se superpone con I (B_0116$([char]0x2013)B_0049).")) "una nota sin separador no debe cambiar"
    Check (-not $t.Contains("`r`n")) "debe conservar LF"
    Check ($t.EndsWith("`n") -and -not $t.EndsWith("`n`n`n")) "debe conservar el salto final sin añadir líneas"
    Check (([IO.File]::ReadAllBytes($p))[0] -ne 0xEF) "no debe añadir BOM"
    Check (($out -join "`n") -match 'B_0002 -> B_0003' -and ($out -join "`n") -match 'B_0003 -> B_0004') "la tabla de cambios debe incluir cada desplazamiento"

    $h1 = (Get-FileHash $p).Hash
    $out2 = Run @($p, "-LineStart", "$casilla B_", "-InPlace")
    Check ((Get-FileHash $p).Hash -eq $h1) "la segunda pasada no debe modificar el fichero"
    Check (($out2 -join "`n") -match '^Sin cambios') "la segunda pasada debe informar sin cambios"

    Run @($p, "-LineStart", "### E_", "-InPlace") | Out-Null
    Check ((Get-FileHash $p).Hash -eq $h1) "escenas ya consecutivas: sin cambios"

    # 2. Hechos en _actos.md con CRLF y BOM: notas "- H_XXXX texto" no son definiciones.
    $actos = @(
        "### Hechos"
        "- H_0001 $raya Primero."
        "- H_0012 $raya Movido desde otro acto."
        "- H_0002 $raya Depende de H_0012."
        "## Notas del director"
        "- H_0001 se superpone con la boda."
        ""
    ) -join "`r`n"
    $p2 = Put "actos.md" $actos $true
    Run @($p2, "-LineStart", "- H_", "-InPlace") | Out-Null
    $b = [IO.File]::ReadAllBytes($p2); $t2 = [IO.File]::ReadAllText($p2)
    Check ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) "debe conservar el BOM"
    Check ($t2.Contains("`r`n") -and -not ($t2 -replace "`r`n", "").Contains("`n")) "debe conservar CRLF"
    Check ($t2.Contains("- H_0002 $raya Movido") -and $t2.Contains("- H_0003 $raya Depende de H_0012.")) "hechos renumerados por posición, menciones intactas"
    Check ($t2.Contains("- H_0001 se superpone")) "la nota de hecho no debe renumerarse"

    # 3. Tabla con separador " |" y -Start.
    $tabla = "| Beat | Id |`n|---|---|`n| B_0001 | a7c3e9f1 |`n| B_0002 | b2d8f4a6 |`n"
    $p3 = Put "tabla.md" $tabla
    Run @($p3, "-LineStart", "| B_", "-Start", "120", "-InPlace") | Out-Null
    $t3 = [IO.File]::ReadAllText($p3)
    Check ($t3.Contains("| B_0120 | a7c3e9f1 |") -and $t3.Contains("| B_0121 | b2d8f4a6 |")) "tabla con -Start 120"

    # 4. Sin coincidencias: no escribe y sale bien.
    $h4 = (Get-FileHash $p3).Hash
    $o4 = Run @($p3, "-LineStart", "### E_", "-InPlace")
    Check ($LASTEXITCODE -eq 0 -and (Get-FileHash $p3).Hash -eq $h4) "sin definiciones: exit 0 y sin escritura"
    Check (($o4 -join "`n") -match '^No hay líneas') "sin definiciones: mensaje explicativo"

    # 5. Beats de relato en varios estados (prefijos en una cadena CSV, como llegan por pwsh -File).
    $estados = @(
        "$casilla B_0001 $raya Uno."
        "$([char]::ConvertFromUtf32(0x1F504)) B_0101 $raya En curso."
        "$([char]0x2705) B_0002 $raya Hecho."
        ""
    ) -join "`n"
    $p5 = Put "estados.md" $estados
    Run @($p5, "-LineStart", "$casilla B_,$([char]::ConvertFromUtf32(0x1F504)) B_,$([char]0x2705) B_", "-InPlace") | Out-Null
    $t5 = [IO.File]::ReadAllText($p5)
    Check ($t5.Contains("B_0002 $raya En curso.") -and $t5.Contains("B_0003 $raya Hecho.")) "prefijos de estado comparten contador"

    # 6. Hechos de novela: "- H_0003: ..." y "- H_0004 [D · ...]: ...", con notas y menciones.
    $novela = @(
        "- H_0001: Primero."
        "- H_0009: Insertado."
        "- H_0002 [D $([char]0x00B7) H_0001$([char]0x2013)H_0009]: Distribuido."
        "- H_0001 se retoma en el acto II."
        ""
    ) -join "`n"
    $p6 = Put "actos-novela.md" $novela
    $o6 = Run @($p6, "-LineStart", "- H_", "-InPlace")
    $t6 = [IO.File]::ReadAllText($p6)
    Check ($t6.Contains("- H_0002: Insertado.") -and $t6.Contains("- H_0003 [D $([char]0x00B7) H_0001$([char]0x2013)H_0009]: Distribuido.")) "hechos de novela con ':' y ' [D'"
    Check ($t6.Contains("- H_0001 se retoma")) "nota de novela intacta"
    Check (($o6 -join "`n") -match 'H_0009 -> H_0002') "tabla de cambios de novela"
}
finally {
    Remove-Item -LiteralPath $Tmp -Recurse -Force
}

if ($fallos.Count -gt 0) {
    $fallos | ForEach-Object { Write-Host "FALLO: $_" -ForegroundColor Red }
    exit 1
}
Write-Host "OK: renumerar-regression"
