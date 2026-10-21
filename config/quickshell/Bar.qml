import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// The top bar, one per screen (shell.qml makes one per entry in Quickshell.screens).
//   left    overview button, window title
//   center  clock | workspaces (in the exact middle) | playing media (click to play/pause)
//   right   tray, volume, notifications, settings sidebar, power
// Scrolling anywhere on the bar, right up to the screen edge: the left half sets this
// monitor's brightness, the right half the volume. Over the workspaces it switches workspace.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    readonly property PwNode sink: Pipewire.defaultAudioSink

    function changeVolume(delta) {
        if (sink !== null && sink.audio !== null)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta));
    }

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

    // Covers the whole window, including the transparent strip above and beside the bar, so
    // the pointer can be pushed against the top of the screen. Widgets that handle scrolling
    // themselves (workspaces) take it first.
    MouseArea {
        id: wheelArea

        property real pending: 0 // touchpads and smooth wheels send fractions of a notch

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            pending += wheel.angleDelta.y;
            const notches = pending > 0 ? Math.floor(pending / 120) : Math.ceil(pending / 120);
            if (notches === 0)
                return;
            pending -= notches * 120;
            if (wheel.x < width / 2)
                Brightness.adjust(bar.modelData.name, notches * Brightness.step);
            else
                bar.changeVolume(notches * 0.05);
        }
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

        RowLayout {
            id: left
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
            StyledText {
                id: title
                // Up to the clock
                Layout.maximumWidth: Math.max(0, clock.x - left.x - x - Theme.gap * 4)
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                color: Theme.colors.surfaceVariantText
            }
        }

        Workspaces {
            id: workspaces
            anchors.centerIn: parent
        }

        Clock {
            id: clock
            anchors {
                right: workspaces.left
                verticalCenter: parent.verticalCenter
                rightMargin: Theme.gap * 3
            }
        }

        MediaWidget {
            anchors {
                left: workspaces.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.gap * 3
            }
            // Up to the tray
            width: Math.min(implicitWidth, right.x - x - Theme.gap * 4)
        }

        RowLayout {
            id: right
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
