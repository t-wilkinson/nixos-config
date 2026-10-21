pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What's open, shared by the bar, keybinds (IPC) and the panels themselves.
//   qs ipc call overview toggle        workspaces + windows overview, type to search apps
//   qs ipc call launcher toggle        app launcher
//   qs ipc call sidebar toggle         quick settings, media, Bluetooth, notifications
//   qs ipc call power toggle           power menu
//   qs ipc call notifications toggleDnd | clear
Singleton {
    id: root

    property bool overviewOpen: false
    property bool launcherOpen: false
    property bool sidebarOpen: false
    property bool powerMenuOpen: false
    property bool dnd: false

    // Set by Notifications.qml: the tracked notifications (a model) and how to clear them
    property var notifications: null
    property var clearNotifications: () => {}

    function closeAll() {
        overviewOpen = false;
        launcherOpen = false;
        sidebarOpen = false;
        powerMenuOpen = false;
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { const o = !root.overviewOpen; root.closeAll(); root.overviewOpen = o; }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { const o = !root.launcherOpen; root.closeAll(); root.launcherOpen = o; }
        function open(): void { root.closeAll(); root.launcherOpen = true; }
        function close(): void { root.launcherOpen = false; }
    }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { root.sidebarOpen = !root.sidebarOpen; }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { const o = !root.powerMenuOpen; root.closeAll(); root.powerMenuOpen = o; }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.sidebarOpen = !root.sidebarOpen; }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clearNotifications(); }
    }
}
