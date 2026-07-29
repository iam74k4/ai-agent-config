# MarkItDown MCP: prefer .cursor/venv-markitdown, else PATH (see .cursor/docs/mcp.md)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cursorDir = Split-Path -Parent $scriptDir
$venvDir = if ($env:MARKITDOWN_MCP_VENV) { $env:MARKITDOWN_MCP_VENV } else { Join-Path $cursorDir "venv-markitdown" }
$venvExecutable = Join-Path $venvDir "Scripts\markitdown-mcp.exe"

if (Test-Path $venvExecutable) {
    & $venvExecutable @args
    exit $LASTEXITCODE
}

$onPath = Get-Command markitdown-mcp -ErrorAction SilentlyContinue
if ($onPath) {
    & $onPath.Source @args
    exit $LASTEXITCODE
}

[Console]::Error.WriteLine("markitdown-mcp was not found at $venvExecutable and is not on PATH. Run scripts/setup.ps1 first.")
exit 1
