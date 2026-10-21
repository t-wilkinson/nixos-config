pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors, fonts and sizes for the whole shell.
//
// Colors come from the wallpaper: matugen writes ~/.local/state/theme/colors.json
// (config/matugen/templates/colors.json), and this file reloads whenever it changes, so
// `theme-wallpaper` recolors the shell live. The defaults below are the same scheme
// generated from #7db7e0, used until the first wallpaper is set.
Singleton {
    id: root

    // Material You roles (camelCase of matugen's names) plus wallpaper-shifted accents
    // (red, orange, yellow, green, cyan, blue, magenta). Use as Theme.colors.primary etc.
    readonly property alias colors: adapter

    readonly property string font: "Rubik"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int fontSize: 13
    readonly property int radius: 14
    readonly property int smallRadius: 8
    readonly property int gap: 6
    readonly property int barHeight: 38
    readonly property int animMs: 160

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme/colors.json"
        watchChanges: true
        onFileChanged: reload()
        printErrors: false // missing until the first `theme-wallpaper`

        JsonAdapter {
            id: adapter
            property string mode: "dark"
            property string sourceColor: "#7db7e0"
            property string primary: "#94cdf7"
            property string onPrimary: "#00344d"
            property string primaryContainer: "#004c6e"
            property string onPrimaryContainer: "#c8e6ff"
            property string secondary: "#b7c9d9"
            property string onSecondary: "#21323f"
            property string secondaryContainer: "#384956"
            property string onSecondaryContainer: "#d3e5f5"
            property string tertiary: "#cec0e8"
            property string onTertiary: "#352b4b"
            property string tertiaryContainer: "#4b4163"
            property string onTertiaryContainer: "#e9ddff"
            property string error: "#ffb4ab"
            property string onError: "#690005"
            property string errorContainer: "#93000a"
            property string onErrorContainer: "#ffdad6"
            property string background: "#101417"
            property string onBackground: "#dfe3e8"
            property string surface: "#101417"
            property string onSurface: "#dfe3e8"
            property string surfaceVariant: "#41484d"
            property string onSurfaceVariant: "#c1c7ce"
            property string surfaceDim: "#101417"
            property string surfaceBright: "#353a3e"
            property string surfaceContainerLowest: "#0a0f12"
            property string surfaceContainerLow: "#181c20"
            property string surfaceContainer: "#1c2024"
            property string surfaceContainerHigh: "#262a2e"
            property string surfaceContainerHighest: "#313539"
            property string outline: "#8b9198"
            property string outlineVariant: "#41484d"
            property string shadow: "#000000"
            property string scrim: "#000000"
            property string inverseSurface: "#dfe3e8"
            property string inverseOnSurface: "#2d3135"
            property string inversePrimary: "#246488"
            property string red: "#ffb2bd"
            property string orange: "#ffb59e"
            property string yellow: "#d8c770"
            property string green: "#91d5ac"
            property string cyan: "#85d1e8"
            property string blue: "#9ccbfb"
            property string magenta: "#d8bafa"
        }
    }
}
