import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// The top bar, one per screen (shell.qml makes one per entry in Quickshell.screens).
// Left: workspaces and the focused window. Center: clock. Right: tray, volume, buttons.
PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.gap
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: Theme.gap
            leftMargin: Theme.gap * 2
            rightMargin: Theme.gap * 2
        }
        radius: Theme.radius
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.colors.outlineVariant

        // Scroll anywhere on the bar to move between workspaces
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => Hyprland.dispatch(event.angleDelta.y > 0 ? "workspace m-1" : "workspace m+1")
        }

        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.gap * 2
            }
            spacing: Theme.gap * 2

            IconButton {
                icon: "apps"
                onClicked: ShellState.launcherOpen = !ShellState.launcherOpen
            }
            Workspaces {}
            StyledText {
                Layout.maximumWidth: bar.width / 4
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                color: Theme.colors.onSurfaceVariant
            }
        }

        Clock {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Theme.gap
            }
            spacing: Theme.gap

            Tray {}
            Volume {}
            IconButton {
                icon: ShellState.dnd ? "notifications_off" : "notifications"
                active: ShellState.notificationsOpen
                onClicked: ShellState.notificationsOpen = !ShellState.notificationsOpen
            }
            IconButton {
                icon: "power_settings_new"
                onClicked: ShellState.powerMenuOpen = !ShellState.powerMenuOpen
            }
        }
    }
}
