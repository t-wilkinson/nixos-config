import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

// Notification daemon: popups in the top right, a history panel (Super+N or the bell in
// the bar) and do-not-disturb. State and IPC: ShellState.qml.
Scope {
    id: root

    function clear() {
        const all = Array.from(server.trackedNotifications.values);
        for (let i = 0; i < all.length; i++)
            all[i].dismiss();
    }

    Component.onCompleted: ShellState.clearNotifications = root.clear

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
        visible: !ShellState.dnd && !ShellState.notificationsOpen && popupColumn.implicitHeight > 0
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

    // History panel on the right
    PanelWindow {
        anchors {
            top: true
            right: true
            bottom: true
        }
        margins {
            top: Theme.gap * 2
            right: Theme.gap * 2
            bottom: Theme.gap * 2
        }
        exclusiveZone: 0
        implicitWidth: 400
        visible: ShellState.notificationsOpen
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:notification-history"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.colors.surfaceContainer
            border.width: 1
            border.color: Theme.colors.outlineVariant
            focus: true
            Keys.onEscapePressed: ShellState.notificationsOpen = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: Theme.gap * 2

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: "Notifications"
                        font.pixelSize: Theme.fontSize + 4
                        font.weight: Font.DemiBold
                    }
                    IconButton {
                        icon: ShellState.dnd ? "notifications_off" : "notifications_active"
                        active: ShellState.dnd
                        onClicked: ShellState.dnd = !ShellState.dnd
                    }
                    IconButton {
                        icon: "clear_all"
                        onClicked: root.clear()
                    }
                    IconButton {
                        icon: "close"
                        onClicked: ShellState.notificationsOpen = false
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    visible: history.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: "Nothing new"
                    color: Theme.colors.outline
                }

                ListView {
                    id: history
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Theme.gap
                    model: Array.from(server.trackedNotifications.values).reverse() // newest first

                    delegate: NotificationCard {
                        required property Notification modelData
                        notification: modelData
                        width: ListView.view.width
                    }
                }
            }
        }
    }
}
