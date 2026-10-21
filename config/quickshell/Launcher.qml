import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// App launcher: type to filter installed apps, Up/Down to move, Enter to launch, Esc to
// close. Opened by Super+Tab (qs ipc call launcher toggle) or the apps button in the bar.
Scope {
    id: root

    LazyLoader {
        active: ShellState.launcherOpen

        PanelWindow {
            id: window

            implicitWidth: 560
            implicitHeight: 520
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:launcher"

            function launch(app) {
                if (!app)
                    return;
                app.execute();
                ShellState.launcherOpen = false;
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius + 4
                color: Theme.colors.surfaceContainer
                border.width: 1
                border.color: Theme.colors.outlineVariant

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: height / 2
                        color: Theme.colors.surfaceContainerHighest

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 10

                            Icon {
                                text: "search"
                                color: Theme.colors.surfaceVariantText
                            }
                            TextField {
                                id: search
                                Layout.fillWidth: true
                                focus: true
                                placeholderText: "Search apps"
                                placeholderTextColor: Theme.colors.surfaceVariantText
                                color: Theme.colors.surfaceText
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 2
                                background: null
                                onTextChanged: list.currentIndex = 0
                                Keys.onEscapePressed: ShellState.launcherOpen = false
                                Keys.onDownPressed: list.incrementCurrentIndex()
                                Keys.onUpPressed: list.decrementCurrentIndex()
                                onAccepted: window.launch(list.currentItem ? list.currentItem.modelData : null)
                            }
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: Apps.search(search.text)
                        highlightMoveDuration: Theme.animMs
                        highlight: Rectangle {
                            radius: Theme.smallRadius + 4
                            color: Theme.colors.primaryContainer
                        }

                        delegate: MouseArea {
                            id: entry

                            required property DesktopEntry modelData
                            required property int index

                            width: ListView.view.width
                            implicitHeight: 48
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = index
                            onClicked: window.launch(modelData)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                IconImage {
                                    implicitSize: 30
                                    source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: entry.modelData.name
                                        color: entry.ListView.isCurrentItem ? Theme.colors.primaryContainerText : Theme.colors.surfaceText
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: entry.modelData.comment || entry.modelData.genericName
                                        font.pixelSize: Theme.fontSize - 2
                                        color: entry.ListView.isCurrentItem ? Theme.colors.primaryContainerText : Theme.colors.surfaceVariantText
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
