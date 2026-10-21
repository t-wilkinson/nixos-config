//@ pragma UseQApplication
// (QApplication is needed for tray item menus.)

// Quickshell desktop shell. Started by Hyprland (config/hypr/hyprland/execs.conf) as
// `qs -n -d`; edits here reload live. Colors follow the wallpaper (Theme.qml).
//
//   Bar.qml            top bar: workspaces, window title, clock, tray, volume
//   Notifications.qml  notification daemon, popups, history panel
//   Osd.qml            volume indicator
//   Launcher.qml       app launcher
//   PowerMenu.qml      lock / suspend / log out / reboot / power off
//   ShellState.qml     what's open + IPC (`qs ipc show` lists the commands)
import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Notifications {}
    Osd {}
    Launcher {}
    PowerMenu {}

    // Create the IPC handlers at startup, before anything else touches ShellState
    Component.onCompleted: ShellState.dnd
}
