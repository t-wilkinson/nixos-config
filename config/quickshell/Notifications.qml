import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

// Notification daemon and popups (top right). The history lives in the sidebar
// (Sidebar.qml); do-not-disturb and IPC in ShellState.qml.
Scope {
    id: root

    function clear() {
        const all = Array.from(server.trackedNotifications.values);
        for (let i = 0; i < all.length; i++)
            all[i].dismiss();
    }

    Component.onCompleted: {
        ShellState.notifications = server.trackedNotifications;
        ShellState.clearNotifications = root.clear;
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => notification.tracked = true
    }


    // Popups: each tracked notification shows for its timeout (5 s by default, critical
    // ones until dismissed), then stays in the history until dismissed.
    PanelWindow {
        id: popups

        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.barHeight + Theme.gap * 3
            right: Theme.gap * 2
        }
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: popupColumn.implicitHeight
        visible: !ShellState.dnd && !ShellState.sidebarOpen && popupColumn.implicitHeight > 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:notifications"

        ColumnLayout {
            id: popupColumn
            width: parent.width
            spacing: Theme.gap

            Repeater {
                model: server.trackedNotifications

                delegate: NotificationCard {
                    id: popup

                    required property Notification modelData
                    property bool showing: !modelData.lastGeneration

                    notification: modelData
                    Layout.fillWidth: true
                    visible: showing

                    Timer {
                        running: popup.showing && !popup.critical
                        interval: popup.modelData.expireTimeout > 0 ? popup.modelData.expireTimeout * 1000 : 5000
                        onTriggered: popup.showing = false
                    }
                }
            }
        }
    }
}
