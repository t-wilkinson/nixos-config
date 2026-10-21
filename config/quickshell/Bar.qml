import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// The top bar, one per screen (shell.qml makes one per entry in Quickshell.screens).
// Left: overview button, workspaces (scroll to switch), window title.
// Center: clock and the playing media (click to play/pause).
// Right: tray, volume, notifications, settings sidebar, power.
// Scrolling anywhere else on the bar changes the volume.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    readonly property PwNode sink: Pipewire.defaultAudioSink

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

    PwObjectTracker {
        objects: bar.sink ? [bar.sink] : []
    }

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

        // Volume on scroll. Widgets above it that handle scrolling themselves (workspaces,
        // media, volume) take the event first.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                if (bar.sink === null || bar.sink.audio === null)
                    return;
                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + step));
            }
        }

        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.gap
            }
            spacing: Theme.gap * 2

            IconButton {
                icon: "grid_view"
                active: ShellState.overviewOpen
                onClicked: {
                    const open = !ShellState.overviewOpen;
                    ShellState.closeAll();
                    ShellState.overviewOpen = open;
                }
            }
            Workspaces {}
            StyledText {
                Layout.maximumWidth: bar.width / 5
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                color: Theme.colors.surfaceVariantText
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Theme.gap * 3

            Clock {}
            MediaWidget {
                Layout.maximumWidth: bar.width / 4
            }
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
                badge: ShellState.notifications !== null ? ShellState.notifications.values.length : 0
                onClicked: ShellState.sidebarOpen = !ShellState.sidebarOpen
            }
            IconButton {
                icon: "tune"
                active: ShellState.sidebarOpen
                onClicked: ShellState.sidebarOpen = !ShellState.sidebarOpen
            }
            IconButton {
                icon: "power_settings_new"
                onClicked: {
                    ShellState.closeAll();
                    ShellState.powerMenuOpen = true;
                }
            }
        }
    }
}
