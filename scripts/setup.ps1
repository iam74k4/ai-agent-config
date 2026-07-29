# Bootstrap this repository after a fresh clone.
#
# Generates the multi-root workspace file, .cursor/mcp.json, and the MarkItDown
# venv so that a clone is usable without editing machine-specific paths by hand.
# macOS/Linux, or Windows with WSL/Git Bash: use scripts/setup.sh instead.
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoVenv,
    [switch]$NoMcp,
    [switch]$NoWorkspace
)

$ErrorActionPreference = "Stop"
# Native commands report failure through $LASTEXITCODE, which this script checks
# itself. PowerShell 7.4+ would otherwise turn any non-zero exit into a throw.
$PSNativeCommandUseErrorActionPreference = $false

$repoRoot = Split-Path -Parent $PSScriptRoot
$repoName = Split-Path -Leaf $repoRoot
$parentDir = Split-Path -Parent $repoRoot
$workspaceFile = if ($env:WORKSPACE_FILE) { $env:WORKSPACE_FILE } else { Join-Path $repoRoot "$repoName.code-workspace" }
$mcpFile = Join-Path $repoRoot ".cursor\mcp.json"
$venvDir = if ($env:MARKITDOWN_MCP_VENV) { $env:MARKITDOWN_MCP_VENV } else { Join-Path $repoRoot ".cursor\venv-markitdown" }
$templateFile = Join-Path $repoRoot "templates\workspace.code-workspace.template"
$warnings = [System.Collections.Generic.List[string]]::new()

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message"
}

function Write-Info([string]$Message) {
    Write-Host "  $Message"
}

function Write-WarningMessage([string]$Message) {
    Write-Host "  ! $Message" -ForegroundColor Yellow
    $warnings.Add($Message)
}

# Limit a file that holds secrets to the current account.
function Protect-File([string]$Path) {
    try {
        if ($env:OS -eq "Windows_NT") {
            $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $acl.AddAccessRule(
                (New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "FullControl", "Allow"))
            )
            Set-Acl -Path $Path -AclObject $acl
        } else {
            & chmod 600 $Path
        }
    } catch {
        Write-WarningMessage "could not restrict permissions on $Path"
    }
}

function Write-TextFile([string]$Path, [string]$Content, [switch]$Private) {
    if ($DryRun) {
        Write-Info "would write $Path"
        return
    }

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    if ($Private) {
        # Restrict the file before any secret reaches disk.
        New-Item -ItemType File -Force -Path $Path | Out-Null
        Protect-File $Path
    }

    # The repository standardizes on LF; ConvertTo-Json emits CRLF on Windows.
    $normalized = $Content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($Path, $normalized + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Info "wrote $Path"
}

function Get-Python {
    foreach ($command in @("py", "python", "python3")) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { continue }
        # MarkItDown needs 3.10+; a bare --version check accepts older builds
        # and fails later with a confusing pip error.
        & $command -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) { return $command }
    }
    return $null
}

function Get-Folders {
    $folders = @(
        [PSCustomObject]@{
            name = $repoName
            path = "."
        }
    )

    Get-ChildItem -Directory -Path $parentDir | Sort-Object Name | ForEach-Object {
        if ($_.FullName -ne $repoRoot -and (Test-Path (Join-Path $_.FullName ".git"))) {
            $folders += [PSCustomObject]@{
                name = $_.Name
                path = "..\$($_.Name)"
            }
        }
    }

    return $folders
}

function New-Task([string]$Label, [string]$Command, [string]$Folder) {
    return [ordered]@{
        label = $Label
        type = "shell"
        command = $Command
        options = [ordered]@{
            cwd = "`${workspaceFolder:$Folder}"
        }
        problemMatcher = @()
        presentation = [ordered]@{
            reveal = "silent"
            panel = "shared"
        }
    }
}

function Get-Tasks($Folders) {
    $fetchLabels = @($Folders | ForEach-Object { "Git: fetch ($($_.name))" })
    $statusLabels = @($Folders | ForEach-Object { "Git: status ($($_.name))" })
    $tasks = @(
        [ordered]@{
            label = "Git: fetch all workspaces"
            dependsOn = $fetchLabels
            dependsOrder = "parallel"
            problemMatcher = @()
            group = [ordered]@{
                kind = "build"
                isDefault = $true
            }
            presentation = [ordered]@{
                reveal = "always"
                panel = "shared"
                showReuseMessage = $false
                clear = $false
            }
        },
        [ordered]@{
            label = "Git: status all workspaces"
            dependsOn = $statusLabels
            dependsOrder = "sequence"
            problemMatcher = @()
            presentation = [ordered]@{
                reveal = "always"
                panel = "shared"
                showReuseMessage = $true
                clear = $true
            }
        }
    )

    foreach ($folder in $Folders) {
        $banner = $folder.name.Replace("'", "''")
        $tasks += New-Task "Git: fetch ($($folder.name))" "git fetch --all --prune" $folder.name
        $tasks += New-Task "Git: status ($($folder.name))" "Write-Output '=== $banner ==='; git status -sb" $folder.name
    }
    return $tasks
}

function Set-Workspace {
    Write-Step "Workspace file"
    if (-not (Test-Path $templateFile)) {
        Write-WarningMessage "template not found: $templateFile"
        return
    }

    [object[]]$folders = @(Get-Folders)
    Write-Info "folders: $($folders.name -join ', ')"
    if ($folders.Count -eq 1) {
        Write-Info "no sibling Git repositories found; add them later and re-run this script"
    }

    $template = Get-Content -Raw -Path $templateFile
    # Pass the arrays with -InputObject: piping unrolls them, and a single
    # folder would then serialize as an object instead of an array.
    $folderJson = ConvertTo-Json -InputObject $folders -Depth 10
    $taskJson = ConvertTo-Json -InputObject @(Get-Tasks $folders) -Depth 10
    $content = $template.Replace("__REPO_NAME__", $repoName).Replace("__FOLDERS__", $folderJson).Replace("__TASKS__", $taskJson)
    Write-TextFile $workspaceFile $content.TrimEnd()
}

function Set-McpConfig {
    Write-Step "MCP config"
    if ((Test-Path $mcpFile) -and -not $Force) {
        Write-Info "keeping existing $mcpFile (use -Force to regenerate)"
        return
    }

    $servers = [ordered]@{
        context7 = [ordered]@{
            url = "https://mcp.context7.com/mcp"
        }
    }

    if ($env:CONTEXT7_API_KEY) {
        $servers.context7.headers = [ordered]@{
            CONTEXT7_API_KEY = $env:CONTEXT7_API_KEY
        }
        Write-Info "context7: enabled with API key from CONTEXT7_API_KEY"
    } else {
        Write-Info "context7: enabled without API key (set CONTEXT7_API_KEY for higher rate limits)"
    }

    $githubToken = $null
    if ($env:GITHUB_MCP_PAT) {
        $githubToken = $env:GITHUB_MCP_PAT
    } elseif ($env:GITHUB_PAT) {
        $githubToken = $env:GITHUB_PAT
    } elseif ($env:GITHUB_TOKEN) {
        # GITHUB_TOKEN is set automatically by CI systems and other tooling, so
        # baking it into a config file on disk is rarely what the user intended.
        $githubToken = $env:GITHUB_TOKEN
        Write-WarningMessage "using GITHUB_TOKEN because GITHUB_MCP_PAT is unset; set GITHUB_MCP_PAT to control which token is written"
    }

    if ($githubToken) {
        $servers.github = [ordered]@{
            url = "https://api.githubcopilot.com/mcp/"
            headers = [ordered]@{
                Authorization = "Bearer $githubToken"
            }
        }
        Write-Info "github: enabled using a token from the environment"
    } else {
        Write-Info "github: skipped (set GITHUB_MCP_PAT and re-run with -Force to enable)"
    }

    $markitdown = Join-Path $venvDir "Scripts\markitdown-mcp.exe"
    if ((Test-Path $markitdown) -or (Get-Command markitdown-mcp -ErrorAction SilentlyContinue)) {
        $servers.markitdown = [ordered]@{
            command = "powershell"
            args = @(
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                (Join-Path $repoRoot ".cursor\scripts\markitdown-mcp.ps1")
            )
        }
        Write-Info "markitdown: enabled"
    } else {
        Write-Info "markitdown: skipped (no venv and no markitdown-mcp on PATH)"
    }

    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        $nodeMajor = [int](& node -p "process.versions.node.split('.')[0]")
        if ($nodeMajor -ge 20) {
            $servers.drawio = [ordered]@{
                command = "powershell"
                args = @(
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    (Join-Path $repoRoot ".cursor\scripts\drawio-mcp.ps1")
                )
            }
            Write-Info "drawio: enabled (Node.js $nodeMajor)"
        } else {
            Write-Info "drawio: skipped (needs Node.js 20 or later)"
        }
    } else {
        Write-Info "drawio: skipped (needs Node.js 20 or later)"
    }

    $config = [ordered]@{ mcpServers = $servers } | ConvertTo-Json -Depth 10
    Write-TextFile $mcpFile $config -Private
}

function Set-MarkItDownVenv {
    Write-Step "MarkItDown virtual environment"
    $python = Get-Python
    if (-not $python) {
        Write-WarningMessage "Python 3.10+ was not found; skipping MarkItDown setup"
        return
    }

    $mcpExecutable = Join-Path $venvDir "Scripts\markitdown-mcp.exe"
    if (Test-Path $mcpExecutable) {
        Write-Info "already installed at $venvDir"
        return
    }

    if ($DryRun) {
        Write-Info "would create $venvDir and install markitdown-mcp"
        return
    }

    if (-not (Test-Path $venvDir)) {
        & $python -m venv $venvDir
        if ($LASTEXITCODE -ne 0) {
            Write-WarningMessage "could not create $venvDir"
            return
        }
    }

    $venvPython = Join-Path $venvDir "Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        Write-WarningMessage "venv Python was not created at $venvPython"
        return
    }

    Write-Info "installing markitdown-mcp (downloads packages)"
    & $venvPython -m pip install --quiet --upgrade pip markitdown-mcp
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $mcpExecutable)) {
        Write-WarningMessage "markitdown-mcp installation failed; re-run this script or install it manually"
        return
    }
    Write-Info "installed $mcpExecutable"
}

Write-Host "Setting up $repoRoot"
if ($DryRun) {
    Write-Host "Dry run: no files will be written"
}

Write-Step "Required tools"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required. Install Git and run this script again."
}
Write-Info "Git: $(& git --version)"

if (-not $NoVenv) { Set-MarkItDownVenv }
if (-not $NoMcp) { Set-McpConfig }
if (-not $NoWorkspace) { Set-Workspace }

Write-Step "Next steps"
Write-Info "1. Open $(Split-Path -Leaf $workspaceFile) in Cursor"
Write-Info "2. Restart Cursor completely so it loads .cursor/mcp.json"
Write-Info "3. Verify the result with scripts/doctor.ps1"

if ($warnings.Count -gt 0) {
    Write-Host "`nCompleted with $($warnings.Count) warning(s):"
    $warnings | ForEach-Object { Write-Host "  - $_" }
}
