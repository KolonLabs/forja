# paridad-entornos-regression.ps1 — Comprobaciones mecánicas entre las capas opencode y Claude Code de shared/.
# No juzga la equivalencia editorial (eso es revisión); detecta desfases de inventario, restos de un
# entorno en el otro y modelos fuera del reparto acordado (ADR 0024).
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Shared = Join-Path $RepoRoot "shared"
$fallos = [System.Collections.Generic.List[string]]::new()

function Get-Parts {
    param([string]$Path)
    $raw = [System.IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
    $m = [regex]::Match($raw, '\A---\n(.*?)\n---[ \t]*\n(.*)\z', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $m.Success) { throw "Sin frontmatter: $Path" }
    return [pscustomobject]@{ Front = $m.Groups[1].Value; Body = $m.Groups[2].Value.Trim() }
}

function Get-Names {
    param([string[]]$Dirs, [string[]]$Exclude = @())
    $names = @()
    foreach ($d in $Dirs) {
        if (Test-Path -LiteralPath $d) {
            $names += @(Get-ChildItem -LiteralPath $d -File -Filter "*.md" | ForEach-Object { $_.BaseName })
        }
    }
    return @($names | Where-Object { $_ -notin $Exclude } | Sort-Object -Unique)
}

# Reparto de modelos acordado para Claude Code.
$Modelos = @{
    "director" = "claude-sonnet-5-5"; "guionista" = "claude-sonnet-5-5"; "auditor-beats" = "claude-sonnet-5-5"
    "validador" = "claude-sonnet-5-5"; "cronista" = "claude-sonnet-5-5"
    "escritor" = "claude-opus-5-5"; "integrador" = "claude-opus-5-5"
    "entidades" = "claude-haiku-5-5"; "memoria" = "claude-haiku-5-5"
}
$RestosOpencode = 'deepseek|qwen|venice/|maxCompletionTokens|skill\(\{|(?m)^(temperature|top_p|top_k|mode|hidden|permission|options):'
$RestosClaude = 'claude-(sonnet|opus|haiku)|omitClaudeMd|(?m)^tools:|(?m)^effort:|Agent\('

$escalas = @(Get-ChildItem -LiteralPath (Join-Path $Shared "pipelines") -Directory | Where-Object { Test-Path (Join-Path $_.FullName "claude") })
if ($escalas.Count -eq 0) { throw "ASSERT: ninguna escala tiene capa Claude" }

foreach ($e in $escalas) {
    $esc = $e.Name
    $cl = Join-Path $e.FullName "claude"
    $novela = $esc -ne "relato"
    $excluidos = if ($novela) { @("corregir") } else { @() }

    $ocAgentDirs = @((Join-Path $e.FullName "agentes")) + $(if ($novela) { @(Join-Path $Shared ".opencode\agents") } else { @() })
    $clAgentDirs = @((Join-Path $cl "agents")) + $(if ($novela) { @(Join-Path $Shared ".claude\agents") } else { @() })
    $ocAgents = Get-Names $ocAgentDirs
    $clAgents = Get-Names $clAgentDirs
    if (($ocAgents -join ",") -ne ($clAgents -join ",")) { $fallos.Add("[$esc] agentes distintos: opencode=$($ocAgents -join ',') claude=$($clAgents -join ',')") }

    $ocCmds = Get-Names @((Join-Path $Shared ".opencode\commands"), (Join-Path $e.FullName "commands")) $excluidos
    $clCmds = Get-Names @((Join-Path $Shared ".claude\commands"), (Join-Path $cl "commands")) $excluidos
    if (($ocCmds -join ",") -ne ($clCmds -join ",")) { $fallos.Add("[$esc] comandos distintos: opencode=$($ocCmds -join ',') claude=$($clCmds -join ',')") }

    foreach ($a in $clAgents) {
        $clPath = $clAgentDirs | ForEach-Object { Join-Path $_ "$a.md" } | Where-Object { Test-Path $_ } | Select-Object -First 1
        $ocPath = $ocAgentDirs | ForEach-Object { Join-Path $_ "$a.md" } | Where-Object { Test-Path $_ } | Select-Object -First 1
        $c = Get-Parts $clPath
        $o = Get-Parts $ocPath
        if (($c.Front + "`n" + $c.Body) -match $RestosOpencode) { $fallos.Add("[$esc] $a (claude) contiene restos de opencode: '$($Matches[0])'") }
        if (($o.Front + "`n" + $o.Body) -match $RestosClaude) { $fallos.Add("[$esc] $a (opencode) contiene restos de Claude: '$($Matches[0])'") }
        if ($c.Front -notmatch "(?m)^name: $([regex]::Escape($a))$") { $fallos.Add("[$esc] $a (claude) sin name coherente") }
        $model = [regex]::Match($c.Front, '(?m)^model:\s*(\S+)').Groups[1].Value
        if ($Modelos.ContainsKey($a) -and $model -ne $Modelos[$a]) { $fallos.Add("[$esc] $a usa '$model'; acordado '$($Modelos[$a])'") }
        if (-not $novela -and $c.Body -ne $o.Body) { $fallos.Add("[$esc] ${a}: el cuerpo Claude difiere del de opencode (relato no tiene adaptaciones)") }
    }

    if ($novela) {
        # El guionista no escribe prosa, manuscrito ni hechos: deny en opencode, hook en Claude Code.
        $ocG = (Get-Parts (Join-Path $e.FullName "agentes\guionista.md")).Front
        $clG = (Get-Parts (Join-Path $cl "agents\guionista.md")).Front
        foreach ($patron in @('"\*\*/draft.md": deny', '"\*\*/capitulo.md": deny', '"novela.md": deny', '"_actos.md": deny')) {
            if ($ocG -notmatch $patron) { $fallos.Add("[$esc] guionista (opencode) sin la regla $patron") }
        }
        if ($clG -notmatch 'proteger-guionista\.ps1') { $fallos.Add("[$esc] guionista (claude) sin el hook proteger-guionista") }
        if (-not (Test-Path -LiteralPath (Join-Path $Shared ".claude\hooks\proteger-guionista.ps1"))) { $fallos.Add("falta shared/.claude/hooks/proteger-guionista.ps1") }
    }

    foreach ($f in @("settings.json", "CLAUDE.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $cl $f))) { $fallos.Add("[$esc] falta claude/$f") }
    }
    $settings = Get-Content -Raw -LiteralPath (Join-Path $cl "settings.json") | ConvertFrom-Json
    if ($settings.agent -ne "director") { $fallos.Add("[$esc] settings.json no fija director como agente principal") }
}

# Contrato de referencias (multihilo): fijo es un índice y la etiqueta usa el stable_id del hilo.
foreach ($f in (Get-ChildItem -LiteralPath $Shared -Recurse -File -Filter "*.md")) {
    $txt = [System.IO.File]::ReadAllText($f.FullName)
    if ($txt -match 'relevancia_por_hilo[:=]<(slug|hilo|hilo_activo)>') { $fallos.Add("$($f.FullName): etiqueta relevancia_por_hilo sin stable_id ('$($Matches[0])')") }
    if ($txt -match 'Markdown del archivo tal cual') { $fallos.Add("$($f.FullName): describe fijo de referencia como copia del archivo") }
}

if ($fallos.Count -gt 0) {
    $fallos | ForEach-Object { Write-Host "FALLO: $_" }
    throw "ASSERT: paridad de entornos con $($fallos.Count) fallo(s)"
}
Write-Host "OK: paridad de entornos ($(($escalas | ForEach-Object Name) -join ', '))"
