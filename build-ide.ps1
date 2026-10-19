param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Platform,
    [Parameter(Mandatory = $true)][string]$Bds
)

$ErrorActionPreference = "Stop"
if (Get-Process bds -ErrorAction SilentlyContinue) {
    Write-Error "C++Builder is already open. Close it, then run build.bat again."
}

$err = Join-Path $env:TEMP "winscp-bds.err"
$bak = Join-Path $env:TEMP "winscp-cbproj-bak"
if (Test-Path $bak) { Remove-Item $bak -Recurse -Force }
New-Item $bak -ItemType Directory | Out-Null
Get-ChildItem $Source -Filter *.cbproj | ForEach-Object { Copy-Item $_.FullName $bak }

$needle = "<Platform Condition=`"'`$(Platform)'==''`">Win32</Platform>"
$replacement = "<Platform Condition=`"'`$(Platform)'==''`">$Platform</Platform>"
if ($Platform -ne "Win32") {
    Get-ChildItem $Source -Filter *.cbproj | ForEach-Object {
        $text = [IO.File]::ReadAllText($_.FullName)
        if (-not $text.Contains($needle)) { throw "No default platform in $($_.Name)" }
        [IO.File]::WriteAllText($_.FullName, $text.Replace($needle, $replacement))
    }
}

$env:INTERM_PATH = $Source
$env:FINAL_PATH = $Source
$env:CONFIG = "Release"
if (Test-Path $err) { Remove-Item $err }
Write-Host "Opening C++Builder to build $Platform. It closes itself when the log goes idle."
$ide = Start-Process -FilePath $Bds -ArgumentList @("-ns", "-b", "WinSCP.groupproj", "-o$err") -WorkingDirectory $Source -PassThru

try {
    $quiet = 0
    $lastLen = -1
    while (-not $ide.HasExited) {
        Start-Sleep -Seconds 5
        $len = 0
        if (Test-Path $err) { $len = (Get-Item $err).Length }
        $busy = Get-Process bcc64, dcc64, ilink64, tlib64, cgrc -ErrorAction SilentlyContinue
        if ($busy -or $len -ne $lastLen) {
            $quiet = 0
            $lastLen = $len
            continue
        }
        $quiet += 5
        if ($len -eq 0 -and $quiet -ge 600) { throw "C++Builder produced no build log. Dismiss any dialog it is showing." }
        if ($len -gt 0 -and $quiet -ge 45) { break }
    }
}
finally {
    if (-not $ide.HasExited) {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$($ide.Id)"
        if ($proc) { Invoke-CimMethod -InputObject $proc -MethodName Terminate | Out-Null }
        $ide.WaitForExit(15000) | Out-Null
    }
    Get-ChildItem $bak -Filter *.cbproj | ForEach-Object {
        [IO.File]::Copy($_.FullName, (Join-Path $Source $_.Name), $true)
    }
}

$exe = Join-Path $Source "$Platform\Release\WinSCP.exe"
if (-not (Test-Path $exe)) {
    if (Test-Path $err) { Get-Content $err -Tail 40 }
    Write-Error "Build failed. See $err"
}
Write-Host "Built $exe"
