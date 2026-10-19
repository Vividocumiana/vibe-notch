//
//  TerminalAppRegistry.swift
//  ClaudeIsland
//
//  Centralized registry of apps that can host a Claude Code session:
//  terminals, editors (VS Code & friends) and the Claude desktop app.
//

import Foundation

/// Registry of known host application names and bundle identifiers
struct TerminalAppRegistry: Sendable {
    /// `.app` bundle names (the part before `.app` in the executable path)
    static let appBundleNames: Set<String> = [
        "terminal", "iterm", "iterm2", "ghostty", "alacritty", "kitty",
        "hyper", "warp", "wezterm", "tabby", "rio", "contour",
        "visual studio code", "visual studio code - insiders", "vscodium",
        "cursor", "windsurf", "zed", "zed preview",
        "claude"  // Claude desktop app (Code tab)
    ]

    /// Window owner names / CLI executable names, matched exactly
    static let appNames: Set<String> = [
        "terminal", "iterm2", "iterm", "ghostty", "alacritty", "kitty",
        "hyper", "warp", "wezterm", "wezterm-gui", "tabby", "rio", "contour",
        "foot", "st", "urxvt", "xterm",
        "code", "code - insiders", "vscodium", "electron",
        "cursor", "windsurf", "zed",
        "claude"
    ]

    /// Bundle identifiers for host apps (for window enumeration / frontmost checks)
    static let bundleIdentifiers: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "io.alacritty",
        "org.alacritty",
        "net.kovidgoyal.kitty",
        "co.zeit.hyper",
        "dev.warp.Warp-Stable",
        "com.github.wez.wezterm",
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.vscodium",
        "com.todesktop.230313mzl4w4u92",  // Cursor
        "com.exafunction.windsurf",
        "dev.zed.Zed",
        "com.anthropic.claudefordesktop"  // Claude desktop app
    ]

    /// Check if a window owner name or process path belongs to a known host app.
    ///
    /// For `.app` bundles only the *main* executable matches
    /// (`Foo.app/Contents/MacOS/foo`), so helper processes such as
    /// "Code Helper (Plugin)" are skipped and the walk reaches the app whose
    /// PID matches `NSWorkspace.frontmostApplication`. The `claude` CLI binary
    /// shipped inside the VS Code extension or the desktop app is never a bundle
    /// main executable, so it is no longer mistaken for a terminal.
    static func isTerminal(_ appNameOrCommand: String) -> Bool {
        let value = appNameOrCommand.trimmingCharacters(in: .whitespaces)

        if let range = value.range(of: ".app/Contents/MacOS/") {
            // Reject nested helper bundles (…/Frameworks/X Helper.app/…)
            let bundlePath = String(value[..<range.lowerBound])
            if bundlePath.contains(".app/") { return false }
            let bundleName = (bundlePath as NSString).lastPathComponent.lowercased()
            return appBundleNames.contains(bundleName)
        }

        if value.contains("/") {
            // Plain executable path: only real terminal emulators, never `claude`
            let exe = (value as NSString).lastPathComponent.lowercased()
            return exe != "claude" && appNames.contains(exe)
        }

        // Window owner name (e.g. "Code", "Claude", "iTerm2")
        return appNames.contains(value.lowercased())
    }

    /// Check if a bundle identifier is a known host app
    static func isTerminalBundle(_ bundleId: String) -> Bool {
        bundleIdentifiers.contains(bundleId)
    }
}
