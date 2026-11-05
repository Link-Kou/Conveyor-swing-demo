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
$DistDir = Join-Path $RootDir "target\dist"
Remove-Item $InputDir, $RuntimeDir, $DistDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $InputDir, $DistDir | Out-Null
Copy-Item (Join-Path $RootDir "target\desktop-client.jar") (Join-Path $InputDir "desktop-client.jar")
$Dependencies = Get-ChildItem (Join-Path $RootDir "target\classpath-jars") -Filter "*.jar" -File -ErrorAction SilentlyContinue
foreach ($dependency in $Dependencies) { Copy-Item $dependency.FullName $InputDir }
$Jdeps = Join-Path $JbrHome "bin\jdeps.exe"
$Jlink = Join-Path $JbrHome "bin\jlink.exe"
$Jpackage = Join-Path $JbrHome "bin\jpackage.exe"
$Jmods = Join-Path $JbrHome "jmods"
$JavaInfo = & (Join-Path $JbrHome "bin\\java.exe") -XshowSettings:properties -version 2>&1 | Out-String
if ($Architecture -eq "windows-x86" -and $JavaInfo -notmatch "os.arch\\s*=\\s*(x86|i[3-6]86)") {
    throw "The Windows x86 package must use a 32-bit JBR. Detected Java properties: $JavaInfo"
}
if ($Architecture -eq "windows-x64" -and $JavaInfo -notmatch "os.arch\\s*=\\s*amd64") {
    throw "The Windows x64 package must use a 64-bit JBR. Detected Java properties: $JavaInfo"
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
$RuntimeSize = (Get-ChildItem $RuntimeDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("Trimmed runtime size: {0:N1} MB" -f ($RuntimeSize / 1MB))
& $Jpackage --type exe --name "Desktop Client Starter" --app-version $AppVersion --vendor "Example Vendor" --description "A Java Swing desktop application" --input $InputDir --main-jar desktop-client.jar --main-class com.example.desktopclient.Main --runtime-image $RuntimeDir --dest $DistDir --win-per-user-install --win-menu --win-menu-group "Desktop Client Starter" --win-shortcut --win-dir-chooser --win-upgrade-uuid "7b2a0e0d-4c87-4c58-9d41-7f6c21a9a101"
if ($LASTEXITCODE -ne 0) { throw "jpackage failed with exit code $LASTEXITCODE" }
Write-Host "Created package for $Architecture:"
Get-ChildItem $DistDir | Format-Table Name, Length
