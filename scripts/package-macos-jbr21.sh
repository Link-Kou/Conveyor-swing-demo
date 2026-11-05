#!/usr/bin/env bash
set -euo pipefail
JBR_HOME="${1:?JBR_HOME required}"
APP_VERSION="${2:?APP_VERSION required}"
PLATFORM="${3:?PLATFORM required}"
ARCH="${4:?ARCH required}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT="$ROOT/target/jpackage-input"
RUNTIME="$ROOT/target/jpackage-runtime"
DIST="$ROOT/target/dist"
rm -rf "$INPUT" "$RUNTIME" "$DIST"
mkdir -p "$INPUT" "$DIST"
cp "$ROOT/target/desktop-client.jar" "$INPUT/desktop-client.jar"
if compgen -G "$ROOT/target/classpath-jars/*.jar" >/dev/null; then cp "$ROOT"/target/classpath-jars/*.jar "$INPUT/"; fi
for tool in java jdeps jlink jpackage; do test -x "$JBR_HOME/bin/$tool"; done
test -d "$JBR_HOME/jmods"
if [ "$ARCH" = aarch64 ]; then EXPECTED=aarch64; else EXPECTED=x86_64; fi
INFO="$("$JBR_HOME/bin/java" -XshowSettings:properties -version 2>&1)"
echo "$INFO"
echo "$INFO" | grep -Eq "os.arch = $EXPECTED" || { echo "JBR architecture mismatch"; exit 1; }
DETECTED="$("$JBR_HOME/bin/jdeps" --multi-release 17 --ignore-missing-deps --print-module-deps --class-path "$INPUT/*" "$INPUT/desktop-client.jar")"
MODULES="$(printf '%s,%s' "$DETECTED" 'java.desktop,jdk.crypto.ec,jdk.localedata' | tr ',' '\n' | sed '/^$/d' | sort -u | paste -sd, -)"
echo "jlink modules: $MODULES"
"$JBR_HOME/bin/jlink" --module-path "$JBR_HOME/jmods" --add-modules "$MODULES" --include-locales=zh,en --strip-debug --no-man-pages --no-header-files --compress=2 --output "$RUNTIME"
RUNTIME_INFO="$("$RUNTIME/bin/java" -XshowSettings:properties -version 2>&1)"
echo "$RUNTIME_INFO"
echo "$RUNTIME_INFO" | grep -Eq "os.arch = $EXPECTED" || { echo "jlink runtime architecture mismatch"; exit 1; }
du -sh "$RUNTIME"
"$JBR_HOME/bin/jpackage" --type dmg --name "Desktop Client Starter" --app-version "$APP_VERSION" --vendor "Example Vendor" --description "A Java Swing desktop application" --input "$INPUT" --main-jar desktop-client.jar --main-class com.example.desktopclient.Main --mac-package-identifier com.example.desktopclient --runtime-image "$RUNTIME" --dest "$DIST"
echo "Built $PLATFORM"; ls -lh "$DIST"
