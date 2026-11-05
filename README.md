# Desktop Client Starter

A Java Swing desktop application packaged with **JetBrains Runtime 17**, **jlink**, **jdeps** and **jpackage**. Conveyor is not used by this branch.

## Supported packages

| Platform | Runtime architecture | Output |
|---|---|---|
| macOS Apple Silicon | arm64 | DMG |
| macOS Intel | x64 | DMG |
| Windows | x64 | EXE installer |
| Windows | x86 (32-bit) | EXE installer |

Each package contains a private, trimmed Java runtime. End users do not need to install Java.

## Toolchain

- Java 17 source and bytecode target
- JetBrains Runtime 17.0.14 JBRSDK (b1367.22)
- Maven
- jdeps to infer required Java modules
- jlink to create a reduced runtime image
- jpackage to create native installers
- GitHub Actions native runners for each target platform

The Windows 32-bit package uses JetBrains' Windows x86 JBRSDK. The 32-bit JBRSDK and its jlink/jpackage tools are used to produce a 32-bit application image and installer.

## Build locally

Install a JBRSDK 17 matching the host platform and WiX Toolset 3 on Windows.

```bash
mvn --batch-mode clean package
```

On macOS:

```bash
scripts/package-macos.sh "$JAVA_HOME" 1.0.1 macos-aarch64
```

On Windows PowerShell:

```powershell
./scripts/package-windows.ps1 -JbrHome $env:JAVA_HOME -AppVersion 1.0.1 -Architecture windows-x64
```

The scripts:
1. Copy the application JAR and runtime dependency JARs into the jpackage input directory.
2. Run jdeps --print-module-deps to identify statically referenced modules.
3. Retain Swing/AWT, EC cryptography and Chinese/English locale data explicitly.
4. Run jlink with compression, debug symbols, man pages and header files stripped.
5. Run jpackage to create a DMG (macOS) or EXE installer (Windows).

The reduced runtime is written to target/jpackage-runtime; installers are written to target/dist.

## GitHub Actions

The JBR 17 Native Packages workflow runs on:
- pushing a tag matching v*: build all four platform packages and publish them to a GitHub Release;
- manual workflow_dispatch: build all four packages and upload them as workflow artifacts.

The workflow builds on native macOS Apple Silicon, macOS Intel and Windows runners. Windows x86 packaging runs the 32-bit JBRSDK on a Windows x64 runner under WOW64.

To publish a release, update the version in pom.xml, commit the change, then push a matching tag. For the current project version:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Code signing

This workflow creates unsigned packages. For public distribution, configure Apple Developer ID signing and notarization for macOS, and an Authenticode certificate for Windows. Store all signing material in GitHub Actions Secrets; never commit private keys or certificates.

## User data

Application data is stored outside the installation directory:
- macOS: ~/Library/Application Support/Desktop Client Starter
- Windows: %LOCALAPPDATA%/Desktop Client Starter

## License

MIT. See LICENSE.
