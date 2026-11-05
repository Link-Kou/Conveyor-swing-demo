[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$JbrHome,[Parameter(Mandatory=$true)][string]$AppVersion)
$ErrorActionPreference="Stop"
$Root=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Input=Join-Path $Root "target\jpackage-input"; $Runtime=Join-Path $Root "target\jpackage-runtime"
$Image=Join-Path $Root "target\jpackage-app-image"; $Dist=Join-Path $Root "target\dist"
Remove-Item $Input,$Runtime,$Image,$Dist -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $Input,$Dist | Out-Null
Copy-Item (Join-Path $Root "target\desktop-client.jar") (Join-Path $Input "desktop-client.jar")
Get-ChildItem (Join-Path $Root "target\classpath-jars") -Filter "*.jar" -File -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item $_.FullName $Input }
$JbrHome=(Resolve-Path $JbrHome).Path
$Java=Join-Path $JbrHome "bin\java.exe"; $Jdeps=Join-Path $JbrHome "bin\jdeps.exe"
$Jlink=Join-Path $JbrHome "bin\jlink.exe"; $Jpackage=Join-Path $JbrHome "bin\jpackage.exe"
foreach($p in @($Java,$Jdeps,$Jlink,$Jpackage)){if(-not(Test-Path $p)){throw "Missing JBR 21 tool: $p"}}
if(-not(Test-Path (Join-Path $JbrHome "jmods"))){throw "JBR SDK jmods missing"}
$Info=(& $Java -XshowSettings:properties -version 2>&1 | Out-String); Write-Host $Info
if($Info -notmatch '(?m)^\s*os\.arch\s*=\s*amd64\s*$' -or $Info -notmatch '(?m)^\s*sun\.arch\.data\.model\s*=\s*64\s*$'){throw "Expected Windows x64 JBR 21"}
$Detected=& $Jdeps --multi-release 17 --ignore-missing-deps --print-module-deps --class-path (Join-Path $Input "*") (Join-Path $Input "desktop-client.jar")
if($LASTEXITCODE -ne 0){throw "jdeps failed"}
$Modules=(@(($Detected -join "").Split(","))+@("java.desktop","jdk.crypto.ec","jdk.localedata") | Where-Object {$_} | Sort-Object -Unique) -join ","
Write-Host "jlink modules: $Modules"
& $Jlink --module-path (Join-Path $JbrHome "jmods") --add-modules $Modules --include-locales=zh,en --strip-debug --no-man-pages --no-header-files --compress=2 --output $Runtime
if($LASTEXITCODE -ne 0){throw "jlink failed"}
$RuntimeJava=Join-Path $Runtime "bin\java.exe"
$RuntimeInfo=(& $RuntimeJava -XshowSettings:properties -version 2>&1 | Out-String); Write-Host $RuntimeInfo
if($RuntimeInfo -notmatch '(?m)^\s*sun\.arch\.data\.model\s*=\s*64\s*$'){throw "jlink output is not x64"}
$Size=(Get-ChildItem $Runtime -Recurse -File | Measure-Object Length -Sum).Sum
Write-Host ("Trimmed runtime: {0:N1} MB" -f ($Size/1MB))
& $Jpackage --type app-image --name "Desktop Client Starter" --app-version $AppVersion --vendor "Example Vendor" --description "A Java Swing desktop application" --input $Input --main-jar desktop-client.jar --main-class com.example.desktopclient.Main --runtime-image $Runtime --dest $Image
if($LASTEXITCODE -ne 0){throw "jpackage app-image failed"}
$App=Join-Path $Image "Desktop Client Starter"
foreach($p in @((Join-Path $App "Desktop Client Starter.exe"),(Join-Path $App "runtime\bin\java.exe"))){if(-not(Test-Path $p)){throw "Missing app-image executable: $p"}}
& $Jpackage --type exe --app-image $App --name "Desktop Client Starter" --app-version $AppVersion --vendor "Example Vendor" --description "A Java Swing desktop application" --dest $Dist --win-per-user-install --win-menu --win-menu-group "Desktop Client Starter" --win-shortcut --win-dir-chooser --win-upgrade-uuid "7b2a0e0d-4c87-4c58-9d41-7f6c21a9a101"
if($LASTEXITCODE -ne 0){throw "jpackage EXE failed"}
Get-ChildItem $Dist | Format-Table Name,Length
