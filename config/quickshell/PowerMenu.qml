import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Lock, suspend, log out, reboot, power off. Ctrl+Alt+Delete (qs ipc call power toggle)
// or the power button in the bar. Arrow keys / Tab to move, Enter to choose, Esc to close.
Scope {
    id: root

    readonly property var actions: [
        { icon: "lock", label: "Lock", command: ["loginctl", "lock-session"] },
        { icon: "bedtime", label: "Suspend", command: ["systemctl", "suspend"] },
        { icon: "logout", label: "Log out", command: ["hyprctl", "dispatch", "exit"] },
        { icon: "restart_alt", label: "Reboot", command: ["systemctl", "reboot"] },
        { icon: "power_settings_new", label: "Power off", command: ["systemctl", "poweroff"] }
    ]

    LazyLoader {
        active: ShellState.powerMenuOpen

        PanelWindow {
            // Full screen, dimmed; click outside the buttons to close
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:power"

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.scrim
                opacity: 0.45
            }
            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.powerMenuOpen = false
            }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 16
                focus: true

                property int current: 0

                Keys.onEscapePressed: ShellState.powerMenuOpen = false
                Keys.onLeftPressed: current = (current + root.actions.length - 1) % root.actions.length
                Keys.onRightPressed: current = (current + 1) % root.actions.length
                Keys.onTabPressed: current = (current + 1) % root.actions.length
                Keys.onReturnPressed: run(root.actions[current])

                function run(action) {
                    ShellState.powerMenuOpen = false;
                    Quickshell.execDetached(action.command);
                }

                Repeater {
                    model: root.actions

                    delegate: MouseArea {
                        id: button

                        required property var modelData
                        required property int index
                        readonly property bool selected: row.current === index

                        implicitWidth: 112
                        implicitHeight: 112
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: row.current = index
                        onClicked: row.run(modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius + 10
                            color: button.selected ? Theme.colors.primaryContainer : Theme.colors.surfaceContainerHigh
                            border.width: 1
                            border.color: button.selected ? Theme.colors.primary : Theme.colors.outlineVariant
                            Behavior on color { ColorAnimation { duration: Theme.animMs } }
                        }
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                text: button.modelData.icon
                                size: 34
                                fill: button.selected ? 1 : 0
                                color: button.selected ? Theme.colors.primaryContainerText : Theme.colors.surfaceText
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: button.modelData.label
                                color: button.selected ? Theme.colors.primaryContainerText : Theme.colors.surfaceVariantText
                            }
                        }
                    }
                }
            }
        }
    }
}
