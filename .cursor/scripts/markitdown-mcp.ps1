$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$markitdownMcp = Join-Path $repoRoot ".venv-markitdown\Scripts\markitdown-mcp.exe"

if (-not (Test-Path $markitdownMcp)) {
    [Console]::Error.WriteLine("markitdown-mcp was not found at $markitdownMcp. Create .venv-markitdown and install markitdown-mcp first.")
    exit 1
}

& $markitdownMcp @args
exit $LASTEXITCODE
