[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
# Native commands report failure through $LASTEXITCODE, which this script checks
# itself. PowerShell 7.4+ would otherwise turn any non-zero exit into a throw.
$PSNativeCommandUseErrorActionPreference = $false
$repoRoot = Split-Path -Parent $PSScriptRoot
$repoName = Split-Path -Leaf $repoRoot
$mcpFile = Join-Path $repoRoot ".cursor\mcp.json"
$workspaceFile = if ($env:WORKSPACE_FILE) { $env:WORKSPACE_FILE } else { Join-Path $repoRoot "$repoName.code-workspace" }
$venvDir = if ($env:MARKITDOWN_MCP_VENV) { $env:MARKITDOWN_MCP_VENV } else { Join-Path $repoRoot ".cursor\venv-markitdown" }
$passed = 0
$warnings = 0
$failed = 0

function Write-Pass([string]$Message) {
    Write-Host "  PASS  $Message" -ForegroundColor Green
    $script:passed++
}

function Write-Warn([string]$Message) {
    Write-Host "  WARN  $Message" -ForegroundColor Yellow
    $script:warnings++
}

function Write-Fail([string]$Message) {
    Write-Host "  FAIL  $Message" -ForegroundColor Red
    $script:failed++
}

function Test-Command([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        Write-Pass "$Name: $($command.Source)"
    } else {
        Write-Warn "$Name is not available"
    }
}

Write-Host "Diagnosing $repoRoot`n"
Write-Host "==> Commands"
Test-Command "git"
Test-Command "node"
Test-Command "python"

Write-Host "`n==> Repository files"
foreach ($item in @(
    @{ Path = (Join-Path $repoRoot "AGENTS.md"); Label = "AGENTS.md"; Required = $true },
    @{ Path = (Join-Path $repoRoot "CLAUDE.md"); Label = "CLAUDE.md"; Required = $false },
    @{ Path = (Join-Path $repoRoot ".github\copilot-instructions.md"); Label = "Copilot instructions"; Required = $false }
)) {
    if (Test-Path $item.Path) {
        Write-Pass "$($item.Label) exists"
    } elseif ($item.Required) {
        Write-Fail "$($item.Label) is missing"
    } else {
        Write-Warn "$($item.Label) is missing"
    }
}

Write-Host "`n==> Generated files"
if (Test-Path $workspaceFile) {
    try {
        $source = Get-Content -Raw $workspaceFile
        $json = [regex]::Replace($source, "(?s)/\*.*?\*/", "")
        $json = [regex]::Replace($json, "(?m)(^|[^:])//.*$", '$1')
        $null = $json | ConvertFrom-Json
        Write-Pass "$(Split-Path -Leaf $workspaceFile) is valid JSONC"
    } catch {
        Write-Fail "$(Split-Path -Leaf $workspaceFile) is not valid JSONC"
    }
} else {
    Write-Warn "$(Split-Path -Leaf $workspaceFile) is missing; run scripts/setup.ps1"
}

if (Test-Path $mcpFile) {
    try {
        $source = Get-Content -Raw $mcpFile
        $null = $source | ConvertFrom-Json
        Write-Pass ".cursor/mcp.json is valid JSON"
        if ($source -match "YOUR_[A-Z_]*KEY|YOUR_GITHUB_PAT|__REPO_ROOT__") {
            Write-Fail ".cursor/mcp.json contains an unresolved placeholder"
        }
    } catch {
        Write-Fail ".cursor/mcp.json is not valid JSON"
    }

    # The file holds tokens, so it should not be reachable by other accounts.
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
        $others = @((Get-Acl -Path $mcpFile).Access | Where-Object {
            $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]) -ne $identity
        })
        if ($others.Count -eq 0) {
            Write-Pass ".cursor/mcp.json is readable only by its owner"
        } else {
            Write-Warn ".cursor/mcp.json grants access to other accounts; re-run scripts/setup.ps1 -Force"
        }
    } catch {
        Write-Warn "could not inspect permissions on .cursor/mcp.json"
    }
} else {
    Write-Warn ".cursor/mcp.json is missing; run scripts/setup.ps1"
}

Write-Host "`n==> Optional MCP dependencies"
$markitdown = Join-Path $venvDir "Scripts\markitdown-mcp.exe"
if (Test-Path $markitdown) {
    Write-Pass "MarkItDown venv is ready"
} elseif (Get-Command markitdown-mcp -ErrorAction SilentlyContinue) {
    Write-Pass "markitdown-mcp is available on PATH"
} else {
    Write-Warn "MarkItDown is unavailable; run scripts/setup.ps1 or install it manually"
}

if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeMajor = [int](& node -p "process.versions.node.split('.')[0]")
    if ($nodeMajor -ge 20) {
        Write-Pass "Node.js $nodeMajor supports draw.io MCP"
    } else {
        Write-Warn "Node.js $nodeMajor is older than the draw.io MCP recommendation (20)"
    }
} else {
    Write-Warn "draw.io MCP is unavailable without Node.js"
}

Write-Host "`nSummary: $passed passed, $warnings warning(s), $failed failure(s)"
if ($failed -gt 0) {
    exit 1
}
