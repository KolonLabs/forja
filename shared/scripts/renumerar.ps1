<#
.SYNOPSIS
    Renumera identificadores con prefijo (H_XXXX, E_XXXX, B_XXXX...) en las líneas que los definen.

.DESCRIPTION
    Solo cuenta como definición una línea que empieza (tras sangría opcional) por uno de los
    prefijos de -LineStart, seguido del número y del separador -Separator. Las menciones en
    mitad de línea y las líneas de notas sin separador (p. ej. "- H_0001 se superpone...")
    no se tocan.

    Los números se reasignan en orden de aparición desde -Start, con un único contador
    compartido por todos los prefijos indicados en la llamada. Sin -InPlace no escribe nada.

    Imprime la tabla de cambios "viejo -> nuevo". Las referencias a esos identificadores en
    otras líneas u otros ficheros NO se actualizan: entrégale la tabla al LLM para que las revise.

    Conserva codificación (UTF-8, con o sin BOM), saltos de línea (LF o CRLF) y el salto final.
    Si el resultado es idéntico, no reescribe el fichero. Es idempotente.

.PARAMETER Path
    Fichero a renumerar.

.PARAMETER LineStart
    Prefijos literales al inicio de línea, incluido lo que precede al número: "⬜ B_", "### E_",
    "- H_", "| B_". Varios en una sola cadena separada por comas ("⬜ B_,🔄 B_,✅ B_"), que es la
    forma que funciona también con pwsh -File. Comparten un único contador.

.PARAMETER Separator
    Texto literal que debe seguir al número para que la línea sea una definición. Por defecto
    cualquiera de los formatos vigentes: " —" (relato), ":" o " [" (hechos de novela: "- H_0003: ...",
    "- H_0004 [D · ...]: ...") y " |" (tablas). Pásalo solo para restringirlo a uno. Cadena vacía:
    sin comprobación (no recomendable: las notas "- H_0001 se superpone..." entrarían).

.PARAMETER Start
    Primer número asignado (por defecto 1).

.PARAMETER Pad
    Dígitos mínimos con ceros a la izquierda (por defecto 4: B_0001).

.PARAMETER InPlace
    Escribe el resultado. Sin este modificador solo muestra la tabla de cambios.

.EXAMPLE
    pwsh -File scripts/renumerar.ps1 guion.md -LineStart "⬜ B_"
    Muestra cómo quedarían los beats, sin escribir.

.EXAMPLE
    pwsh -File scripts/renumerar.ps1 guion.md -LineStart "### E_" -InPlace

.EXAMPLE
    pwsh -File scripts/renumerar.ps1 _actos.md -LineStart "- H_" -InPlace

.EXAMPLE
    pwsh -File scripts/renumerar.ps1 guion.md -LineStart "⬜ B_,🔄 B_,✅ B_" -InPlace
    Beats de relato en cualquier estado, con un único contador.

.EXAMPLE
    pwsh -File scripts/renumerar.ps1 capitulos/cap-05/guion.md -LineStart "| B_" -Start 120 -InPlace
#>

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string[]]$LineStart,

    # Formatos de definición vigentes: " —" (relato, U+2014 escrito así para no depender de la
    # codificación del script), ":" y " [" (hechos de novela), " |" (tablas).
    [string[]]$Separator = @(" $([char]0x2014)", ":", " [", " |"),
    [int]$Start = 1,
    [int]$Pad = 4,
    [switch]$InPlace,
    # Compatibilidad con la versión anterior: equivale a no pasar -InPlace.
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Error "Fichero no encontrado: $Path"
    exit 2
}

# Prefijos: admite -LineStart "a","b" y -LineStart "a,b"; quita comillas sobrantes.
$prefijos = @($LineStart | ForEach-Object { $_ -split '\s*,\s*' } |
    ForEach-Object { $_.Trim().Trim("'`"") } | Where-Object { $_ })
if ($prefijos.Count -eq 0) {
    Write-Error "-LineStart no contiene ningún prefijo."
    exit 2
}
# Los más largos primero, para que "##" no quede eclipsado por "#".
$alts = ($prefijos | Sort-Object { $_.Length } -Descending |
    ForEach-Object { [regex]::Escape($_) }) -join '|'
$separadores = @($Separator | Where-Object { $_ })
$tras = if ($separadores.Count -gt 0) {
    '(?=' + (($separadores | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
} else { '(?!\d)' }
$regex = [regex]('^(?<indent>[ \t]*)(?<prefix>' + $alts + ')(?<num>\d+)' + $tras)

# Lectura preservando BOM y saltos de línea.
$full = (Resolve-Path -LiteralPath $Path).ProviderPath
$bytes = [IO.File]::ReadAllBytes($full)
$bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$texto = [Text.UTF8Encoding]::new($false).GetString($bytes, $(if ($bom) { 3 } else { 0 }), $bytes.Length - $(if ($bom) { 3 } else { 0 }))
$nl = if ($texto.Contains("`r`n")) { "`r`n" } else { "`n" }
$lineas = $texto -split '\r?\n'   # un salto final deja un elemento vacío que el join restaura

$contador = $Start
$cambios = [System.Collections.Generic.List[string]]::new()
$vistos = @{}
$definiciones = 0

for ($i = 0; $i -lt $lineas.Count; $i++) {
    $m = $regex.Match($lineas[$i])
    if (-not $m.Success) { continue }
    $definiciones++
    $prefijo = $m.Groups['prefix'].Value
    $viejo = $m.Groups['num'].Value
    $nuevo = $contador.ToString().PadLeft($Pad, '0')
    $contador++

    $clave = "$prefijo$viejo"
    if ($vistos.ContainsKey($clave)) {
        Write-Warning "Línea $($i + 1): $($prefijo.Trim())$viejo ya aparecía en la línea $($vistos[$clave]); revisa sus referencias a mano."
    } else {
        $vistos[$clave] = $i + 1
    }

    if ($viejo -ne $nuevo) {
        $id = ($prefijo -replace '^.*?(?=[A-Za-z]+_?$)', '')   # "⬜ B_" -> "B_"
        $cambios.Add(("{0}{1} -> {0}{2}  (línea {3})" -f $id, $viejo, $nuevo, ($i + 1)))
        $lineas[$i] = $m.Groups['indent'].Value + $prefijo + $nuevo + $lineas[$i].Substring($m.Length)
    }
}

if ($definiciones -eq 0) {
    Write-Output "No hay líneas que empiecen por $($prefijos -join ' / ') seguidas de número y $(($separadores | ForEach-Object { "'$_'" }) -join ' o ')."
    exit 0
}
if ($cambios.Count -eq 0) {
    Write-Output "Sin cambios: $definiciones definiciones ya numeradas desde $Start."
    exit 0
}

Write-Output "Cambios ($($cambios.Count) de $definiciones definiciones):"
$cambios | ForEach-Object { Write-Output "  $_" }

if ($InPlace -and -not $DryRun) {
    [IO.File]::WriteAllText($full, ($lineas -join $nl), [Text.UTF8Encoding]::new($bom))
    Write-Output "Fichero actualizado: $Path"
    Write-Output "Las referencias en mitad de línea, en notas y en otros ficheros siguen con los números viejos: revísalas con esta tabla."
} else {
    Write-Output "Simulación: no se ha escrito nada. Repite con -InPlace para aplicar."
}
