package com.example.desktopclient;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/** Application entry point. */
public final class Main {
    private Main() { }

    public static void main(String[] args) {
        System.setProperty("apple.awt.application.name", "Desktop Client Starter");
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception ignored) {
                // Keep Swing's cross-platform look and feel if the native LAF is unavailable.
            }
            new MainWindow().setVisible(true);
        });
    }
}
