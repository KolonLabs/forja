# crear-libro.ps1 — Ensambla un libro desde workspaces publicados
# Uso: .\scripts\crear-libro.ps1 -Libro "cronicas-del-deseo" -Fuentes @("rutina","la-fachada")
#      .\scripts\crear-libro.ps1 -Libro "mi-novela" -Fuentes @("mi-novela")

param(
    [Parameter(Mandatory=$true)]
    [string]$Libro,                         # Slug del libro (carpeta en publicados/)
    [Parameter(Mandatory=$true)]
    [string[]]$Fuentes,                     # Slugs de workspaces a incluir (1 para novela, N para antologia)
    [string]$Titulo = $Libro,              # Titulo del libro
    [string]$Autor = "Amaro Alba",
    [switch]$Epub,                          # Generar EPUB
    [switch]$Pdf,                           # Generar PDF
    [string]$PdfFormat = "paperback"
)

$ErrorActionPreference = "Stop"
$ForjaRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ForjaRoot "publicados\$Libro"

if (Test-Path $OutputDir) {
    Write-Host "Limpiando salida anterior: $OutputDir"
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -Force -ItemType Directory $OutputDir | Out-Null

Write-Host "=== Forja: crear libro ==="
Write-Host "  Libro:    $Titulo"
Write-Host "  Fuentes:  $($Fuentes -join ', ')"
Write-Host "  Salida:   $OutputDir"

# --- Ensamblar contenido desde workspaces ---
$tmpDir = Join-Path $OutputDir "temp"
New-Item -Force -ItemType Directory $tmpDir | Out-Null
$combinedMd = Join-Path $tmpDir "_TODO.md"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$sb = [System.Text.StringBuilder]::new()
$sb.Append("# $Titulo`n`n") | Out-Null
$sb.Append("## $Autor`n`n`n") | Out-Null

foreach ($slug in $Fuentes) {
    $wsPath = Join-Path $ForjaRoot "workspaces\$slug"
    if (-not (Test-Path $wsPath)) {
        Write-Warning "Workspace '$slug' no encontrado. Saltando."
        continue
    }
    
    $cfg = Get-Content -Raw -Encoding UTF8 (Join-Path $wsPath "config.json") | ConvertFrom-Json
    $wsTitulo = $cfg.titulo
    $wsTipo = $cfg.tipo

    if ($wsTipo -eq "novela") {
        $mdPath = Join-Path $wsPath "novela.md"
        if (Test-Path $mdPath) {
            Write-Host "  Incluyendo novela: $wsTitulo"
            $content = Get-Content -Raw -Encoding UTF8 $mdPath
            $sb.Append($content.Trim()) | Out-Null
            $sb.Append("`n`n") | Out-Null
        } else {
            Write-Warning "  '$wsTitulo': novela.md no encontrado. Ejecuta /publicar en el workspace primero."
        }
    } else {
        $mdPath = Join-Path $wsPath "relato.md"
        if (Test-Path $mdPath) {
            Write-Host "  Incluyendo relato: $wsTitulo"
            $content = Get-Content -Raw -Encoding UTF8 $mdPath
            $sb.Append($content.Trim()) | Out-Null
            $sb.Append("`n`n") | Out-Null
        } else {
            Write-Warning "  '$wsTitulo': relato.md no encontrado. Ejecuta /publicar en el workspace primero."
        }
    }

    # Marcar workspace como publicado
    if ($cfg.estado -eq "publicado") {
        Write-Host "    [ya publicado]"
    } elseif ($cfg.estado -eq "publicacion") {
        $cfg.estado = "publicado"
        $cfg.ultima_modificacion = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        $cfg | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $wsPath "config.json") -Encoding UTF8
        Write-Host "    [marcado como publicado]"
    }
}

# Escribir MD combinado
$finalText = $sb.ToString()
[System.IO.File]::WriteAllText($combinedMd, $finalText, $utf8NoBom)
Write-Host "`n  MD combinado: $combinedMd ($((Get-Item $combinedMd).Length) bytes)"

# Copiar MD limpio a la salida
$libroMd = Join-Path $OutputDir "$Libro.md"
Copy-Item $combinedMd $libroMd
Write-Host "  Libro MD: $libroMd"

# --- EPUB ---
if ($Epub) {
    $pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
    if (-not $pandoc) {
        $candidates = @("C:\Program Files\Pandoc\pandoc.exe","$env:LOCALAPPDATA\Pandoc\pandoc.exe")
        foreach ($c in $candidates) { if (Test-Path $c) { $pandoc = $c; break } }
    }
    if (-not $pandoc) { 
        Write-Warning "Pandoc no encontrado. EPUB omitido."
    } else {
        $epubPath = Join-Path $OutputDir "$Libro.epub"
        $cssPath = Join-Path $PSScriptRoot "build.css"
        $args = @($combinedMd, '--from','markdown','--to','epub',
                  '--metadata',"title=$Titulo",'--metadata',"author=$Autor",
                  '--metadata','lang=es','--toc','--toc-depth=1','-o',$epubPath)
        if (Test-Path $cssPath) { $args += '--css',$cssPath }
        & $pandoc $args 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  EPUB: $epubPath ($([math]::Round((Get-Item $epubPath).Length/1KB,1)) KB)"
        } else {
            Write-Warning "Pandoc falló. EPUB no generado."
        }
    }
}

Write-Host "`n=== Libro creado: $OutputDir ==="
