[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$JbrHome,
    [Parameter(Mandatory = $true)][string]$AppVersion,
    [Parameter(Mandatory = $true)][ValidateSet("windows-x86", "windows-x64")][string]$Architecture
)

$ErrorActionPreference = "Stop"
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$InputDir = Join-Path $RootDir "target\jpackage-input"
$RuntimeDir = Join-Path $RootDir "target\jpackage-runtime"
$AppImageDir = Join-Path $RootDir "target\jpackage-app-image"
$DistDir = Join-Path $RootDir "target\dist"

Remove-Item $InputDir, $RuntimeDir, $AppImageDir, $DistDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $InputDir, $DistDir | Out-Null
Copy-Item (Join-Path $RootDir "target\desktop-client.jar") (Join-Path $InputDir "desktop-client.jar")
$Dependencies = Get-ChildItem (Join-Path $RootDir "target\classpath-jars") -Filter "*.jar" -File -ErrorAction SilentlyContinue
foreach ($dependency in $Dependencies) { Copy-Item $dependency.FullName $InputDir }

$JbrHome = (Resolve-Path $JbrHome).Path
$Jdeps = Join-Path $JbrHome "bin\jdeps.exe"
$Jlink = Join-Path $JbrHome "bin\jlink.exe"
$Jpackage = Join-Path $JbrHome "bin\jpackage.exe"
$Java = Join-Path $JbrHome "bin\java.exe"
$Jmods = Join-Path $JbrHome "jmods"

foreach ($tool in @($Java, $Jdeps, $Jlink, $Jpackage)) {
    if (-not (Test-Path $tool)) { throw "Required JBR tool not found: $tool" }
}
if (-not (Test-Path $Jmods)) { throw "JBR jmods directory not found: $Jmods" }

$JavaInfo = (& $Java -XshowSettings:properties -version 2>&1 | Out-String)
Write-Host "Using JBR_HOME=$JbrHome"
Write-Host $JavaInfo

if ($Architecture -eq "windows-x86") {
    if ($JavaInfo -notmatch "(?m)^\s*os\.arch\s*=\s*x86\s*$" -or
        $JavaInfo -notmatch "(?m)^\s*sun\.arch\.data\.model\s*=\s*32\s*$") {
        throw "The Windows x86 package requires a 32-bit JBR (os.arch=x86, data model=32). Detected: $JavaInfo"
    }
} else {
    if ($JavaInfo -notmatch "(?m)^\s*os\.arch\s*=\s*amd64\s*$" -or
        $JavaInfo -notmatch "(?m)^\s*sun\.arch\.data\.model\s*=\s*64\s*$") {
        throw "The Windows x64 package requires a 64-bit JBR (os.arch=amd64, data model=64). Detected: $JavaInfo"
    }
}

function Get-PeMachine([string]$Path) {
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $reader = [System.IO.BinaryReader]::new($stream)
        $stream.Position = 0x3C
        $peOffset = $reader.ReadInt32()
        $stream.Position = $peOffset + 4
        return $reader.ReadUInt16()
    } finally {
        $stream.Dispose()
    }
}

$ExpectedMachine = if ($Architecture -eq "windows-x86") { 0x014c } else { 0x8664 }
$JavaMachine = Get-PeMachine $Java
if ($JavaMachine -ne $ExpectedMachine) {
    throw ("JBR java.exe PE machine mismatch. Expected 0x{0:X4}, got 0x{1:X4}" -f $ExpectedMachine, $JavaMachine)
}

Write-Host "Analyzing application modules with JBR jdeps..."
$DetectedModules = & $Jdeps --multi-release 17 --ignore-missing-deps --print-module-deps --class-path (Join-Path $InputDir "*") (Join-Path $InputDir "desktop-client.jar")
if ($LASTEXITCODE -ne 0) { throw "jdeps failed with exit code $LASTEXITCODE" }

$ModuleSet = @()
$ModuleSet += ($DetectedModules -join "").Split(",")
$ModuleSet += @("java.desktop", "jdk.crypto.ec", "jdk.localedata")
$Modules = ($ModuleSet | Where-Object { $_ } | Sort-Object -Unique) -join ","
Write-Host "jlink modules: $Modules"

& $Jlink --module-path $Jmods --add-modules $Modules --include-locales=zh,en --strip-debug --no-man-pages --no-header-files --compress=2 --output $RuntimeDir
if ($LASTEXITCODE -ne 0) { throw "jlink failed with exit code $LASTEXITCODE" }

$RuntimeJava = Join-Path $RuntimeDir "bin\java.exe"
if (-not (Test-Path $RuntimeJava)) { throw "jlink output does not contain bin\java.exe" }
$RuntimeMachine = Get-PeMachine $RuntimeJava
if ($RuntimeMachine -ne $ExpectedMachine) {
    throw ("jlink runtime PE machine mismatch. Expected 0x{0:X4}, got 0x{1:X4}" -f $ExpectedMachine, $RuntimeMachine)
}
$RuntimeInfo = (& $RuntimeJava -XshowSettings:properties -version 2>&1 | Out-String)
Write-Host "Trimmed runtime architecture:"
Write-Host $RuntimeInfo
if ($Architecture -eq "windows-x86" -and $RuntimeInfo -notmatch "(?m)^\s*sun\.arch\.data\.model\s*=\s*32\s*$") {
    throw "jlink produced a runtime that is not 32-bit"
}
if ($Architecture -eq "windows-x64" -and $RuntimeInfo -notmatch "(?m)^\s*sun\.arch\.data\.model\s*=\s*64\s*$") {
    throw "jlink produced a runtime that is not 64-bit"
}

$RuntimeSize = (Get-ChildItem $RuntimeDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("Trimmed runtime size: {0:N1} MB" -f ($RuntimeSize / 1MB))

# Build an app-image first, then inspect its actual launcher and bundled JVM
# before producing the Windows installer.
& $Jpackage --type app-image --name "Desktop Client Starter" --app-version $AppVersion --vendor "Example Vendor" --description "A Java Swing desktop application" --input $InputDir --main-jar desktop-client.jar --main-class com.example.desktopclient.Main --runtime-image $RuntimeDir --dest $AppImageDir
if ($LASTEXITCODE -ne 0) { throw "jpackage app-image failed with exit code $LASTEXITCODE" }

$AppImage = Join-Path $AppImageDir "Desktop Client Starter"
$Launcher = Join-Path $AppImage "Desktop Client Starter.exe"
$BundledJava = Join-Path $AppImage "runtime\bin\java.exe"
foreach ($file in @($Launcher, $BundledJava)) {
    if (-not (Test-Path $file)) { throw "Expected app-image executable not found: $file" }
    $machine = Get-PeMachine $file
    if ($machine -ne $ExpectedMachine) {
        throw ("App-image executable architecture mismatch for {0}. Expected 0x{1:X4}, got 0x{2:X4}" -f $file, $ExpectedMachine, $machine)
    }
}

& $Jpackage --type exe --app-image $AppImage --name "Desktop Client Starter" --app-version $AppVersion --vendor "Example Vendor" --description "A Java Swing desktop application" --dest $DistDir --win-per-user-install --win-menu --win-menu-group "Desktop Client Starter" --win-shortcut --win-dir-chooser --win-upgrade-uuid "7b2a0e0d-4c87-4c58-9d41-7f6c21a9a101"
if ($LASTEXITCODE -ne 0) { throw "jpackage exe failed with exit code $LASTEXITCODE" }

Write-Host "Created package for ${Architecture}:"
Get-ChildItem $DistDir | Format-Table Name, Length
