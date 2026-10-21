pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What's open, shared by the bar, keybinds (IPC) and the panels themselves.
//   qs ipc call launcher toggle
//   qs ipc call power toggle
//   qs ipc call notifications toggle | toggleDnd | clear
Singleton {
    id: root

    property bool launcherOpen: false
    property bool powerMenuOpen: false
    property bool notificationsOpen: false
    property bool dnd: false

    // Set by Notifications.qml so `clear` works over IPC
    property var clearNotifications: () => {}

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcherOpen = !root.launcherOpen; }
        function open(): void { root.launcherOpen = true; }
        function close(): void { root.launcherOpen = false; }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.powerMenuOpen = !root.powerMenuOpen; }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.notificationsOpen = !root.notificationsOpen; }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clearNotifications(); }
    }
}
