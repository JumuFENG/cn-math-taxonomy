$ErrorActionPreference = 'Stop'
$port = 5333
$url = "http://127.0.0.1:$port/"
$python = Get-Command py.exe -ErrorAction SilentlyContinue

if ($python) {
    $arguments = @('-3', '-m', 'http.server', "$port", '--bind', '127.0.0.1')
} else {
    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $python) {
        Write-Host 'Python 3 was not found. Install Python 3 and add it to PATH.'
        Read-Host 'Press Enter to exit'
        exit 1
    }
    $arguments = @('-m', 'http.server', "$port", '--bind', '127.0.0.1')
}

$stdout = Join-Path $env:TEMP 'cn-math-taxonomy-server.stdout.log'
$stderr = Join-Path $env:TEMP 'cn-math-taxonomy-server.stderr.log'
try {
    $server = Start-Process -FilePath $python.Source -ArgumentList $arguments -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
} catch {
    Write-Host "Could not start Python: $($_.Exception.Message)"
    Read-Host 'Press Enter to exit'
    exit 1
}

for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 1 | Out-Null
        Start-Process $url
        exit 0
    } catch {
        if ($server.HasExited) { break }
        Start-Sleep -Seconds 1
    }
}

Write-Host "The server did not start at $url."
if (Test-Path $stderr) { Get-Content $stderr -Tail 10 }
Read-Host 'Press Enter to exit'
exit 1
