<#
.SYNOPSIS
    Renumerar líneas que empiezan por un prefijo dado seguido de un número
    y un delimitador opcional. Si no se especifica prefijo, renumera las líneas
    que comienzan por un dígito y un delimitador ('.' o ':').

.DESCRIPTION
    Lee un fichero de texto y renumera las líneas cuyo comienzo coincide con:
      - Opcionalmente, un conjunto de prefijos literales indicados en `-LineStart`
            - Un número entero
            - Un delimitador opcional ('.' o ':') y espacio opcional (ej: "1. Línea")
                También soporta líneas sin delimitador tras el número (p.ej.: "CHUNK:SCN-028").
    Garantiza que los números sean únicos y consecutivos empezando en `-Start`.

.PARAMETER Path
    Ruta al fichero de entrada.

.PARAMETER InPlace
    Si se especifica, sobrescribe el fichero original. En caso contrario imprime
    el resultado por la salida estándar.

.PARAMETER Start
    Número inicial para la renumeración (por defecto 1).

.PARAMETER Pad
    Longitud mínima del padding con ceros (ej: 3 -> 001.). Por defecto 0 (sin padding).

.PARAMETER Backup
    Cuando `-InPlace` está activo, crea una copia de seguridad con extensión ".bak".

.PARAMETER DryRun
    No escribe nada, sólo muestra qué cambios haría.

.PARAMETER LineStart
    Lista de cadenas literales que deben aparecer al inicio de la línea para que sea renumerada.
    Por ejemplo: "#", "##", "**", "SCN-".
    Si no se indica este parámetro, se renumerarán todas las líneas que empiecen por número y punto.

.EXAMPLE
    .\renumerar.ps1 -Path capitulos/capitulo_1.md -InPlace -Backup -Start 1 -Pad 2

.EXAMPLE
    # Renumerar sólo líneas que empiezan por "#"
    .\renumerar.ps1 -Path archivo.md -InPlace -LineStart "#"

.EXAMPLE
    # Renumerar líneas con varios prefijos
    .\renumerar.ps1 -Path archivo.md -InPlace -LineStart "#","##","**"

.EXAMPLE
    # Renumerar líneas que empiezan por "SCN-"
    .\renumerar.ps1 -Path archivo.md -InPlace -LineStart "SCN-"

.EXAMPLE
    # Renumerar cabeceras de CHUNK tipo "CHUNK:SCN-028" (sin delimitador)
    .\renumerar.ps1 -Path capitulo.md -InPlace -Start 28 -LineStart "CHUNK:SCN-"
#>

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path,

    [switch]$InPlace,
    [int]$Start = 1,
    [int]$Pad = 0,
    [switch]$Backup,
    [switch]$DryRun,

    [string[]]$LineStart
)

if (-not (Test-Path -Path $Path)) {
    Write-Error "Fichero no encontrado: $Path"
    exit 2
}

# Cargar contenido preservando codificación y separadores
$content = Get-Content -LiteralPath $Path -ErrorAction Stop -Encoding UTF8 -Raw
$lines = [System.Text.RegularExpressions.Regex]::Split($content, '\r?\n')

# Construcción dinámica del patrón según prefijos solicitados.
# Usamos grupos con nombre para unificar lógica.
# Normalizar LineStart para soportar paso desde cmd.exe/powershell -File:
# -LineStart '#','##','**' o -LineStart "#,##,**"
if ($LineStart) {
    if ($LineStart.Count -eq 1) {
        $single = $LineStart[0]
        # Si viene como CSV, separar por coma
        if ($single -match ',') {
            $LineStart = $single -split '\s*,\s*'
        }
    }
    # Quitar comillas envolventes y espacios para TODOS los elementos
    $LineStart = $LineStart | ForEach-Object {
        $x = $_
        if ($null -ne $x) {
            $x = $x.Trim()
            $x = $x.Trim("'`"")  # elimina ' y "
        }
        $x
    } | Where-Object { $_ -and $_ -ne '' }
}
if ($LineStart -and $LineStart.Count -gt 0) {
    # Ordenar por longitud descendente para evitar coincidencias parciales (ej.: "##" antes que "#")
    $sorted = $LineStart | Where-Object { $_ -ne $null } | Sort-Object { $_.Length } -Descending
    $escaped = $sorted | ForEach-Object { [System.Text.RegularExpressions.Regex]::Escape($_) }
    if ($escaped.Count -eq 0) {
        # Si tras filtrar no queda nada, caemos a modo sin prefijos
        $regex = '^(?<indent>\s*)(?<num>\d+)\.(?<sp2>\s*)(?<rest>.*)$'
    } else {
        $alts = ($escaped -join '|')
        # ^[indent][prefix][sp1][num][delim?][sp2][rest]
        # Hacemos el delimitador opcional para soportar patrones como "CHUNK:SCN-028"
        $regex = '^(?<indent>\s*)(?:(?<prefix>' + $alts + '))(?<sp1>\s*)(?<num>\d+)(?<delim>(?:\.|:)?)?(?<sp2>\s*)(?<rest>.*)$'
    }
} else {
    # Sin prefijos: líneas que empiezan por número y delimitador '.' o ':'
    $regex = '^(?<indent>\s*)(?<num>\d+)(?<delim>(?:\.|:))(?<sp2>\s*)(?<rest>.*)$'
}

$counter = $Start
$changed = $false

$out = for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $m = [System.Text.RegularExpressions.Regex]::Match($line, $regex)
    if ($m.Success) {
        $indent = $m.Groups['indent'].Value
        $prefix = if ($m.Groups['prefix'].Success) { $m.Groups['prefix'].Value } else { '' }
        $sp1 = if ($m.Groups['sp1'].Success) { $m.Groups['sp1'].Value } else { '' }
        $sp2 = $m.Groups['sp2'].Value
        $rest = $m.Groups['rest'].Value
        # Si no hay delimitador capturado, preservar vacío (no introducir por defecto uno)
        $delim = if ($m.Groups['delim'].Success) { $m.Groups['delim'].Value } else { '' }

        if ($Pad -gt 0) {
            $num = $counter.ToString().PadLeft($Pad, '0')
        } else {
            $num = $counter.ToString()
        }

        $newLine = "${indent}${prefix}${sp1}${num}${delim}${sp2}${rest}"
        if ($newLine -ne $line) { $changed = $true }
        $counter++
        $newLine
    } else {
        $line
    }
}

if ($DryRun) {
    Write-Host "DryRun: no se escribirá. Resultado mostrado abajo:`n"
    $out -join "`r`n" | Write-Output
    exit 0
}

if ($InPlace) {
    if ($Backup) {
        $bak = "$Path.bak"
        Copy-Item -LiteralPath $Path -Destination $bak -Force
    }
    Set-Content -LiteralPath $Path -Value ($out -join "`r`n") -Encoding UTF8 -Force
    if ($changed) { Write-Host "Fichero actualizado: $Path" } else { Write-Host "No se detectaron cambios." }
} else {
    $out -join "`n" | Write-Output
}
