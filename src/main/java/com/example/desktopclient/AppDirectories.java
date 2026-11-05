package com.example.desktopclient;

import java.nio.file.Path;

/** Resolves a per-user writable data directory outside the installed application. */
public final class AppDirectories {
    private static final String APP_DIRECTORY = "Desktop Client Starter";

    private AppDirectories() { }

    public static Path dataDirectory() {
        String os = System.getProperty("os.name", "").toLowerCase();
        String home = System.getProperty("user.home");

        if (os.contains("mac")) {
            return Path.of(home, "Library", "Application Support", APP_DIRECTORY);
        }
        if (os.contains("win")) {
            String localAppData = System.getenv("LOCALAPPDATA");
            Path base = localAppData == null || localAppData.isBlank()
                    ? Path.of(home, "AppData", "Local")
                    : Path.of(localAppData);
            return base.resolve(APP_DIRECTORY);
        }

        String xdgDataHome = System.getenv("XDG_DATA_HOME");
        Path base = xdgDataHome == null || xdgDataHome.isBlank()
                ? Path.of(home, ".local", "share")
                : Path.of(xdgDataHome);
        return base.resolve("desktop-client-starter");
    }
}
