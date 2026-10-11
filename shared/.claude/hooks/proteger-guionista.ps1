# proteger-guionista.ps1 — Hook PreToolUse del subagente guionista (Claude Code).
# Equivale a los permisos `edit` del guionista en opencode: no puede escribir prosa
# (draft.md, capitulo.md), el manuscrito (novela.md) ni los hechos (_actos.md).
# Recibe el JSON del hook por stdin; sale con 2 para bloquear (el motivo va a stderr).
$ErrorActionPreference = "Stop"
try {
    $hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}
$path = $hookInput.tool_input.file_path
if ([string]::IsNullOrWhiteSpace($path)) { exit 0 }

$root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $hookInput.cwd }
$full = [System.IO.Path]::GetFullPath($path)
$name = [System.IO.Path]::GetFileName($full).ToLowerInvariant()
$rel = $full
if ($root) {
    $rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if ($full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) { $rel = $full.Substring($rootFull.Length) }
}
$rel = $rel.Replace('\', '/').ToLowerInvariant()

$bloqueado = ($name -in @("draft.md", "capitulo.md")) -or ($rel -in @("novela.md", "_actos.md"))
if ($bloqueado) {
    [Console]::Error.WriteLine("Bloqueado: el guionista no escribe $rel. La prosa, el manuscrito y los hechos los gestiona el director.")
    exit 2
}
exit 0
