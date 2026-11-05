# Desktop Client Starter

A small, runnable Java Swing desktop application packaged for **macOS (Apple Silicon + Intel)** and **Windows x64** with **Conveyor** and a bundled **JetBrains Runtime (JBR) 21**.

The starter includes a working Swing window, runtime diagnostics, a per-user writable data directory, Maven tests, Conveyor packaging configuration, and GitHub Actions workflows.

## Technology stack

- Java 21 / Swing (`java.desktop`)
- JetBrains Runtime 21 bundled by Conveyor (end users do not need a system Java installation)
- Maven 3.9+
- Conveyor 22.3.1
- GitHub Actions
- Background update mode: Sparkle-based updates on macOS and Windows' native update integration

## Run locally

Requirements: JDK 21 and Maven 3.9 or newer.

```bash
mvn clean verify
mvn exec:java -Dexec.mainClass=com.example.desktopclient.Main
```

Or build the runnable JAR and start it directly:

```bash
mvn clean package
java -jar target/desktop-client.jar
```

The example has no runtime third-party dependencies. Maven copies any future runtime-scope dependencies into `target/classpath-jars` for Conveyor.

## Package locally with Conveyor

1. Install Conveyor 22.3.1: <https://conveyor.hydraulic.dev/22.3.1/>
2. Review `conveyor.conf`. The sample repository is configured as `Link-Kou/Conveyor-swing-demo`.
3. Before shipping a real product, replace `com.example.desktopclient`, `Example Vendor`, the display name, and the application icon with your permanent product identity and assets.
4. Build the Maven application and create the local Conveyor site:

```bash
mvn clean verify
conveyor make site
```

`site` creates the packages and update metadata locally. The exact outputs are determined by Conveyor's target defaults. Conveyor can cross-build macOS and Windows packages from its supported Linux build environment.

## Automatic GitHub Releases

The release workflow runs when a tag matching `v*` is pushed. It verifies that the tag matches the Maven version, tests the project, then runs Conveyor to publish the generated site and packages to GitHub Releases.

### One-time setup

1. Install Conveyor locally and generate your persistent signing key:

   ```bash
   conveyor keys generate
   ```

2. Copy the `app.signing-key` value from Conveyor's generated defaults into a GitHub Actions repository secret named `SIGNING_KEY`.
3. Ensure Actions is enabled and the workflow has `contents: write` permission. The workflow uses the automatically supplied `GITHUB_TOKEN` for GitHub Releases publishing.
4. Review the Conveyor EULA and license terms for your use case. Conveyor's open-source and commercial licensing terms differ.

### Publish a release

Update `<version>` in `pom.xml`, commit the change, then push a matching tag. For example, when the POM version is `1.0.1`:

```bash
git tag v1.0.1
git push origin v1.0.1
```

The tag must match the Maven version exactly. The Conveyor config reads the project version from Maven, so the generated packages and update metadata use the same version.

### Trusted code signing for public distribution

The starter is configured for Conveyor's application signing key. That key provides a stable application/update identity; it is **not** a substitute for publisher certificates trusted by the operating systems.

For normal public distribution, configure:

- macOS: Apple Developer ID Application certificate and Apple notarization credentials.
- Windows: a trusted Authenticode signing certificate.

The optional certificate settings are documented as comments in `ci.conveyor.conf`. Store private material in GitHub Actions Secrets and restore certificate files during the workflow; never commit certificates, passwords, or private keys.

## Updates

`app.updates = background` enables Conveyor's background update mode:

- Windows: Windows' native update mechanism can install updates in the background.
- macOS: the app checks while running and stages updates for a later relaunch through Sparkle.

On macOS, users should move the app from Downloads into Applications before relying on Sparkle updates; App Translocation can interfere with updates for apps launched directly from Downloads.

Keep these stable after the first public release:

- `app.rdns-name`
- Conveyor signing key
- `app.site.base-url`
- publisher signing identity

The sample update URL points to this repository's GitHub Releases `latest/download` endpoint. If you move update hosting later, plan the transition carefully for already-installed clients.

## Writable application data

Do not write user data into the installation directory. `AppDirectories` resolves a user-writable location:

- macOS: `~/Library/Application Support/Desktop Client Starter`
- Windows: `%LOCALAPPDATA%/Desktop Client Starter`
- Linux (development only): `$XDG_DATA_HOME/desktop-client-starter` or `~/.local/share/desktop-client-starter`

## Project layout

```text
.
├── .github/workflows/ci.yml
├── .github/workflows/release.yml
├── icons/app-256.png
├── src/main/java/com/example/desktopclient/
├── src/test/java/com/example/desktopclient/
├── pom.xml
├── conveyor.conf
└── ci.conveyor.conf
```

## Important notes

- JDK 21 is used to compile and test. Conveyor bundles the target-specific JBR 21 runtime into the distributed app.
- The `target/classpath-jars` folder is added to the packaged app classpath so future runtime Maven dependencies are included.
- The `com.example` application identifier is a placeholder. Change it before the first real release, not after users have installed the app.
- The GitHub repo is public, but a public repository alone does not determine your app's open-source license. Choose a `LICENSE` file appropriate for your intended distribution before treating the app as open source.

## References

- Conveyor docs: <https://conveyor.hydraulic.dev/22.3.1/>
- Conveyor JVM config: <https://conveyor.hydraulic.dev/22.3.1/configs/jvm/>
- Conveyor CI: <https://conveyor.hydraulic.dev/22.3.1/continuous-integration/>
- JetBrains Runtime: <https://github.com/JetBrains/JetBrainsRuntime>
- GitHub setup-java: <https://github.com/actions/setup-java>
