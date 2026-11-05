package com.example.desktopclient;

import org.junit.jupiter.api.Test;

import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertTrue;

class RuntimeSmokeTest {
    @Test
    void runsOnTheConfiguredJavaBaseline() {
        assertTrue(Runtime.version().feature() >= 21,
                "Build and test with Java 21 or newer");
    }

    @Test
    void resolvesAUserDataDirectory() {
        Path path = AppDirectories.dataDirectory();
        assertTrue(path.isAbsolute(), "The application data directory must be absolute");
        assertTrue(path.toString().toLowerCase().contains("desktop"),
                "The data directory should be app-specific");
    }
}
