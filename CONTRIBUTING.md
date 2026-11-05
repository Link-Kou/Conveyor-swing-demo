# Contributing

- Keep the Java baseline at 21 unless the project baseline is deliberately changed.
- Run `mvn --batch-mode clean verify` before submitting changes.
- Do not commit signing keys, certificates, passwords, generated `target/` files, or local Conveyor state.
- Keep the application reverse-DNS identity, Conveyor signing key, and update URL stable after the first public release.
- Put all user data under the OS user-data directory, not in the installation directory.
