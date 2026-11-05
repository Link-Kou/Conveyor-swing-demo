package com.example.desktopclient;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.SwingConstants;
import java.awt.BorderLayout;
import java.awt.Desktop;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Toolkit;
import java.awt.datatransfer.StringSelection;
import java.io.IOException;
import java.io.Serial;
import java.nio.file.Files;
import java.nio.file.Path;

/** Small Swing window used to verify the packaged runtime and desktop integration. */
public final class MainWindow extends JFrame {
    @Serial
    private static final long serialVersionUID = 1L;

    private final JTextArea details = new JTextArea();
    private final JLabel status = new JLabel("Ready");
    private final transient Path dataDirectory = AppDirectories.dataDirectory();

    public MainWindow() {
        super("Desktop Client Starter");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setMinimumSize(new Dimension(680, 440));
        setSize(780, 540);
        setLocationRelativeTo(null);

        JLabel heading = new JLabel("Java Swing + JBR + jpackage", SwingConstants.CENTER);
        heading.setFont(heading.getFont().deriveFont(Font.BOLD, 23f));
        heading.setBorder(BorderFactory.createEmptyBorder(24, 16, 8, 16));

        details.setEditable(false);
        details.setLineWrap(true);
        details.setWrapStyleWord(true);
        details.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 13));
        details.setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));
        refreshDetails();

        JButton refresh = new JButton("Refresh");
        refresh.addActionListener(event -> refreshDetails());

        JButton openData = new JButton("Open data folder");
        openData.addActionListener(event -> openDataDirectory());

        JButton copy = new JButton("Copy diagnostics");
        copy.addActionListener(event -> copyDiagnostics());

        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        actions.add(refresh);
        actions.add(openData);
        actions.add(copy);

        JPanel content = new JPanel(new BorderLayout(12, 12));
        content.setBorder(BorderFactory.createEmptyBorder(8, 20, 12, 20));
        content.add(heading, BorderLayout.NORTH);
        content.add(new JScrollPane(details), BorderLayout.CENTER);
        content.add(actions, BorderLayout.SOUTH);

        status.setBorder(BorderFactory.createEmptyBorder(4, 22, 12, 22));
        JPanel root = new JPanel(new BorderLayout());
        root.add(content, BorderLayout.CENTER);
        root.add(status, BorderLayout.SOUTH);
        setContentPane(root);
    }

    private void refreshDetails() {
        String version = MainWindow.class.getPackage().getImplementationVersion();
        details.setText("Application: Desktop Client Starter\n"
                + "Application version: " + (version == null ? "development" : version) + "\n"
                + "Java version: " + System.getProperty("java.version") + "\n"
                + "Java vendor: " + System.getProperty("java.vendor") + "\n"
                + "Java home: " + System.getProperty("java.home") + "\n"
                + "Operating system: " + System.getProperty("os.name") + "\n"
                + "OS version: " + System.getProperty("os.version") + "\n"
                + "Architecture: " + System.getProperty("os.arch") + "\n"
                + "User data directory: " + dataDirectory + "\n\n"
                + "If this window was launched from an installed package, the bundled JBR is active.\n"
                + "End users do not need to install Java separately.\n"
                + "jpackage creates the native installer with a bundled, trimmed JBR runtime.\n");
        details.setCaretPosition(0);
        status.setText("Runtime information refreshed");
    }

    private void openDataDirectory() {
        try {
            Files.createDirectories(dataDirectory);
            if (!Desktop.isDesktopSupported()) {
                status.setText("Desktop folder opening is not supported on this system");
                return;
            }
            Desktop.getDesktop().open(dataDirectory.toFile());
            status.setText("Opened " + dataDirectory);
        } catch (IOException | UnsupportedOperationException exception) {
            status.setText("Could not open data folder: " + exception.getMessage());
        }
    }

    private void copyDiagnostics() {
        StringSelection selection = new StringSelection(details.getText());
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(selection, null);
        status.setText("Runtime diagnostics copied to clipboard");
    }
}
