$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$javaCommand = Get-Command java -ErrorAction SilentlyContinue

if (-not $javaCommand) {
    Write-Error "JDK not found on PATH. Install a Java 17+ JDK and reopen the terminal before running this script."
    exit 1
}

$env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $javaCommand.Source)
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

$wrapperScript = Join-Path $projectRoot 'mvnw.cmd'
if (-not (Test-Path $wrapperScript)) {
    Write-Error "Maven wrapper not found at $wrapperScript."
    exit 1
}

Set-Location $projectRoot

Write-Host "Starting UPI Offline Mesh demo..."
Write-Host "Project: $projectRoot"
Write-Host "Java: $env:JAVA_HOME"

function Test-PortIsFree {
    param([int]$port)

    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    foreach ($listener in $listeners) {
        if ($listener.Port -eq $port) {
            return $false
        }
    }

    return $true
}

$selectedPort = if ($env:UPI_PORT) { [int]$env:UPI_PORT } else { 8080 }
if (-not (Test-PortIsFree $selectedPort)) {
    Write-Error "Port $selectedPort is already in use. Stop the process using it, then run the demo again."
    exit 1
}

$env:SERVER_PORT = $selectedPort
Write-Host "Using port: $selectedPort"
Write-Host "Command: $wrapperScript spring-boot:run"

& $wrapperScript spring-boot:run
exit $LASTEXITCODE
