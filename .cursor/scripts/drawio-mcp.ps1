# Start drawio-mcp-server after clearing stale instances.
#
# Cursor does not always stop the server when it exits, and the leftover
# process keeps ports 3000 (HTTP) and 3333 (WebSocket) bound.
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$stopped = $false

function Stop-DrawioProcess([int]$TargetProcessId) {
    if ($TargetProcessId -eq $PID) { return }
    try {
        Stop-Process -Id $TargetProcessId -Force -ErrorAction Stop
        $script:stopped = $true
    } catch {
        # Already gone, or owned by another account.
    }
}

try {
    Get-CimInstance Win32_Process -ErrorAction Stop |
        Where-Object { $_.CommandLine -and $_.CommandLine -like "*drawio-mcp-server*" } |
        ForEach-Object { Stop-DrawioProcess $_.ProcessId }
} catch {
    Write-Verbose "could not enumerate running processes"
}

# Only stop drawio-related listeners, so other applications on port 3000 survive.
if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    foreach ($port in @(3000, 3333)) {
        Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
            $owner = Get-CimInstance Win32_Process -Filter "ProcessId = $($_.OwningProcess)" -ErrorAction SilentlyContinue
            if ($owner -and $owner.CommandLine -like "*drawio-mcp*") {
                Stop-DrawioProcess $owner.ProcessId
            }
        }
    }
}

# Wait for the ports to be released.
if ($stopped) {
    Start-Sleep -Seconds 2
}

& npx -y drawio-mcp-server --editor --http-port 3000
exit $LASTEXITCODE
