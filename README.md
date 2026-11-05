# Desktop Client Starter

Java Swing desktop application packaged with **JetBrains Runtime 21 JBRSDK**, **jdeps**, **jlink**, and **jpackage**. This branch uses an independent GitHub Actions workflow and does not use Conveyor.

## Supported native packages

| Platform | JBR SDK architecture | Output |
|---|---|---|
| macOS Apple Silicon | osx-aarch64 | DMG |
| macOS Intel | osx-x64 | DMG |
| Windows 64-bit | windows-x64 | EXE installer |

The workflow pins JetBrains Runtime **21.0.11 (b1163.125)**. Every package contains a private trimmed Java runtime; end users do not need to install Java.

## Build pipeline

1. Maven compiles the app and copies runtime dependency JARs.
2. JBR 21 jdeps analyzes the application with --print-module-deps.
3. Swing/AWT, EC cryptography, and Chinese/English locale modules are explicitly retained.
4. JBR 21 jlink creates a reduced runtime using --strip-debug, --no-man-pages, --no-header-files, and --compress=2.
5. JBR 21 jpackage creates macOS DMG or Windows EXE packages.

The workflow verifies the downloaded SDK SHA-512 checksum and runtime architecture before packaging.

## Local build

Install Maven, a matching platform-specific JBR 21 JBRSDK (including jmods), and WiX Toolset 3 on Windows.

```bash
mvn --batch-mode clean package
```

macOS:

```bash
scripts/package-macos-jbr21.sh "$JAVA_HOME" 1.0.1 macos-aarch64 aarch64
```

For Intel macOS, use `macos-x64 x64` for the final two arguments.

Windows PowerShell:

```powershell
./scripts/package-windows-jbr21.ps1 -JbrHome $env:JAVA_HOME -AppVersion 1.0.1
```

Packages are written to `target/dist`; the trimmed runtime is written to `target/jpackage-runtime`.

## GitHub Actions

Workflow: `.github/workflows/jbr21.yml`

- Runs on pushes to `jpackage-jbr21-macos-win64` and manual workflow_dispatch.
- Builds on native macOS Apple Silicon, macOS Intel, and Windows x64 runners.
- Uploads one artifact per platform, retained for 14 days.
- Does not publish GitHub Releases or require tags.

## Signing

Packages are unsigned. Public distribution should add Apple Developer ID signing and notarization for macOS, and Authenticode signing for Windows. Keep credentials in GitHub Actions Secrets.

## License

MIT. See LICENSE.
