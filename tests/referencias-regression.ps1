# referencias-regression.ps1 — Validación de referencias/, canon previo y fichas heredadas (ADR 0032).
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Script = Join-Path $RepoRoot "shared\scripts\validar-referencias.py"
$RunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("forja-referencias-regression-" + [guid]::NewGuid().ToString("N"))
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

function Invoke-Validar {
    param([string[]]$Argumentos)
    $salida = & python -X utf8 -B $Script --json @Argumentos 2>&1
    return [pscustomobject]@{ Codigo = $LASTEXITCODE; Datos = (($salida -join "`n") | ConvertFrom-Json) }
}

function Get-Mensajes {
    param($Resultado, [string]$Nivel)
    return @($Resultado.Datos.hallazgos | Where-Object nivel -eq $Nivel | ForEach-Object { "$($_.archivo): $($_.mensaje)" })
}

try {
    $fuente = Join-Path $RunRoot "obra-previa"
    Write-Utf8 -Path (Join-Path $fuente "capitulo_1_inicio.md") -Content "---`nnumero: 1`n---`n<!-- CHUNK: notas -->`nMarta abre la puerta del piso y llama a Luna, que no viene. La galga mira la calle como si esperara a alguien que todavía no ha llegado."
    Write-Utf8 -Path (Join-Path $fuente "capitulo_2_oferta.md") -Content "Krauss deja el maletín sobre la mesa.`n`n—Seré breve —dijo—. Ciento cincuenta mil euros para cada uno."
    Write-Utf8 -Path (Join-Path $fuente "_plantilla.md") -Content "Plantilla que no cuenta."
    $hash = (& python -X utf8 -B $Script --fuente $fuente --hash-fuente).Trim()

    $obra = Join-Path $RunRoot "obra"
    $canon = @"
---
titulo: Canon de la obra previa
tipo: canon-previo
origen: Obra previa (2 capítulos)
fecha: 2026-10-13
proposito: continuidad de personajes
fuente_sha256: $hash
colisiones_aceptadas: [Luna]
---

## Personajes

### Marta Giner
- Llama a su galga desde la puerta [cap. 1: «Marta abre la puerta del piso»]

### Krauss
- Ofrece dinero para comprar el silencio [cap. 2: «Ciento cincuenta mil euros para cada uno»]

### Luna
- Galga de Marta [cap. 1: «llama a Luna, que no viene»]
"@
    Write-Utf8 -Path (Join-Path $obra "referencias\canon-previo.md") -Content $canon
    Write-Utf8 -Path (Join-Path $obra "referencias\guia-hilos.md") -Content "---`ntitulo: Esbozo de hilos`ntipo: guia-previa`norigen: notas previas`nfecha: 2026-10-13`nproposito: orientar la intención`n---`n`nLa protagonista vive, observa y siente."
    Write-Utf8 -Path (Join-Path $obra "fichas\personaje_krauss.md") -Content "# Krauss`n`n## Canon heredado`n- Origen: Obra previa (dossier ``referencias/canon-previo.md``)`n"
    Write-Utf8 -Path (Join-Path $obra "fichas\personaje_luna-ortiz.md") -Content "# Luna Ortiz`n"

    $ok = Invoke-Validar @("--obra", $obra, "--fuente", $fuente)
    Assert-True ($ok.Codigo -eq 0) "dossier válido con citas verificadas: $((Get-Mensajes $ok 'error') -join ' | ')"
    Assert-True ((Get-Mensajes $ok "aviso").Count -eq 0) "sin avisos: heredado y colisión aceptada no avisan ($((Get-Mensajes $ok 'aviso') -join ' | '))"
    Assert-True (@($ok.Datos.referencias).Count -eq 2) "revisa las dos referencias"

    # Un personaje con el mismo nombre sin heredar ni aceptar es un aviso, no un error.
    Write-Utf8 -Path (Join-Path $obra "fichas\personaje_marta-ruiz.md") -Content "# Marta Ruiz`n"
    $choque = Invoke-Validar @("--obra", $obra)
    Assert-True ($choque.Codigo -eq 0 -and ((Get-Mensajes $choque "aviso") -match "marta").Count -eq 1) "avisa del choque de nombres «marta»"
    Remove-Item -LiteralPath (Join-Path $obra "fichas\personaje_marta-ruiz.md")

    # Citas: inexistente, en otro capítulo, sin cita y demasiado corta.
    $malo = $canon.Replace("[cap. 1: «Marta abre la puerta del piso»]", "[cap. 1: «Marta cierra la ventana del salón»]").Replace(
        "[cap. 2: «Ciento cincuenta mil euros para cada uno»]", "[cap. 1: «Ciento cincuenta mil euros para cada uno»]").Replace(
        "- Galga de Marta [cap. 1: «llama a Luna, que no viene»]", "- Galga de Marta`n- Mira la calle [cap. 1: «la galga»]")
    Write-Utf8 -Path (Join-Path $obra "referencias\canon-previo.md") -Content $malo
    $citas = Invoke-Validar @("--obra", $obra, "--fuente", $fuente)
    $errores = Get-Mensajes $citas "error"
    Assert-True ($citas.Codigo -eq 1) "las citas defectuosas bloquean"
    Assert-True (($errores -match "cita inexistente").Count -eq 1) "detecta la cita inexistente"
    Assert-True (($errores -match "no en el cap\. 1").Count -eq 1) "detecta la cita en otro capítulo"
    Assert-True (($errores -match "hecho sin cita").Count -eq 1) "detecta el hecho sin cita"
    Assert-True (($errores -match "cita de 2 palabras").Count -eq 1) "detecta la cita demasiado corta"

    # Fuente cambiada desde el dossier: aviso de desfase.
    Write-Utf8 -Path (Join-Path $obra "referencias\canon-previo.md") -Content $canon
    Write-Utf8 -Path (Join-Path $fuente "capitulo_3_nuevo.md") -Content "Un capítulo añadido después."
    $desfase = Invoke-Validar @("--obra", $obra, "--fuente", $fuente)
    Assert-True ($desfase.Codigo -eq 0 -and ((Get-Mensajes $desfase "aviso") -match "fuente ha cambiado").Count -eq 1) "avisa de la fuente cambiada"

    # Copiar la fuente no es una referencia.
    $copia = "---`ntitulo: Capítulo copiado`ntipo: canon-previo`norigen: obra previa`nfecha: 2026-10-13`nproposito: prueba`nfuente_sha256: $hash`n---`n`nMarta abre la puerta del piso y llama a Luna, que no viene. La galga mira la calle como si esperara a alguien que todavía no ha llegado.`n"
    Write-Utf8 -Path (Join-Path $obra "referencias\copia.md") -Content $copia
    $copiado = Invoke-Validar @("--obra", $obra, "--archivo", "referencias/copia.md", "--fuente", $fuente)
    Assert-True ((Get-Mensajes $copiado "error") -match "copia la fuente").Count -eq 1 "detecta la copia literal de la fuente"
    Remove-Item -LiteralPath (Join-Path $obra "referencias\copia.md")

    # Cabecera, formato y tamaño.
    Write-Utf8 -Path (Join-Path $obra "referencias\sin-cabecera.md") -Content "# Notas`n`nTexto suelto."
    Write-Utf8 -Path (Join-Path $obra "referencias\documento.pdf") -Content "%PDF"
    Write-Utf8 -Path (Join-Path $obra "referencias\enorme.md") -Content ("---`ntitulo: Enorme`ntipo: documentacion`norigen: x`nfecha: 2026-10-13`nproposito: x`n---`n`n## Todo`n`n" + ("palabra " * 6100))
    $forma = Invoke-Validar @("--obra", $obra)
    $errores = Get-Mensajes $forma "error"
    Assert-True (($errores -match "sin-cabecera.md: falta la cabecera").Count -eq 1) "exige cabecera"
    Assert-True (($errores -match "documento.pdf: no es Markdown").Count -eq 1) "rechaza lo que no es Markdown"
    Assert-True (($errores -match "enorme.md: 610\d palabras").Count -eq 1) "rechaza una referencia demasiado grande"
    Assert-True (((Get-Mensajes $forma "aviso") -match "«Todo»").Count -eq 1) "avisa de una sección que no cabe como pasaje"

    # Ficha heredada sin dossier válido.
    Write-Utf8 -Path (Join-Path $obra "fichas\personaje_krauss.md") -Content "# Krauss`n`n## Canon heredado`n- Origen: ``referencias/no-existe.md```n"
    $heredada = Invoke-Validar @("--obra", $obra, "--archivo", "referencias/guia-hilos.md")
    Assert-True (((Get-Mensajes $heredada "error") -match "no existe o no es canon-previo").Count -eq 1) "la ficha heredada exige un dossier canon-previo"

    Write-Host "OK: referencias-regression"
} finally {
    if (Test-Path -LiteralPath $RunRoot) { Remove-Item -LiteralPath $RunRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
