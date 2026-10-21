import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// Overview (Super+Tab, or the grid button in the bar): the ten workspaces of the current
// group with live previews of their windows, where each window really is.
//   click a workspace       go there
//   click a window          focus it
//   drag a window           move it to another workspace
//   middle click a window   close it
//   type                    search apps instead; Enter launches the first match
//   Esc / click outside     close
Scope {
    id: root

    LazyLoader {
        active: ShellState.overviewOpen

        PanelWindow {
            id: win

            readonly property var monitor: Hyprland.focusedMonitor
            readonly property real monitorWidth: monitor ? monitor.width / monitor.scale : 1920
            readonly property real monitorHeight: monitor ? monitor.height / monitor.scale : 1080
            readonly property int base: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id > 0
                ? Math.floor((Hyprland.focusedWorkspace.id - 1) / 10) * 10 : 0
            readonly property real cellWidth: Math.min(360, (width - 160) / 5)
            readonly property real cellHeight: cellWidth * monitorHeight / monitorWidth
            readonly property real scale: cellWidth / monitorWidth
            readonly property var results: search.text.trim() === "" ? [] : Apps.search(search.text).slice(0, 8)

            function close() {
                ShellState.overviewOpen = false;
            }
            function launch(app) {
                if (app) {
                    app.execute();
                    close();
                }
            }

            // On the focused monitor
            screen: Quickshell.screens.find(s => win.monitor !== null && s.name === win.monitor.name) || null
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
            WlrLayershell.namespace: "quickshell:overview"

            // Window positions come from Hyprland's client list; fetch it fresh on open
            Component.onCompleted: Hyprland.refreshToplevels()

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.scrim
                opacity: 0.5
            }
            MouseArea {
                anchors.fill: parent
                onClicked: win.close()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 18

                // Search box: typing searches apps
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 520
                    implicitHeight: 46
                    radius: height / 2
                    color: Theme.colors.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.colors.outlineVariant

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
                            placeholderText: "Type to search apps"
                            placeholderTextColor: Theme.colors.surfaceVariantText
                            color: Theme.colors.surfaceText
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 2
                            background: null
                            onTextChanged: results.currentIndex = 0
                            Keys.onEscapePressed: {
                                if (text === "")
                                    win.close();
                                else
                                    text = "";
                            }
                            Keys.onDownPressed: results.incrementCurrentIndex()
                            Keys.onUpPressed: results.decrementCurrentIndex()
                            onAccepted: win.launch(results.currentItem ? results.currentItem.modelData : null)
                        }
                    }
                }

                // App results while searching
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: win.results.length > 0
                    implicitWidth: 520
                    implicitHeight: results.contentHeight + 16
                    radius: Theme.radius
                    color: Theme.colors.surfaceContainer
                    border.width: 1
                    border.color: Theme.colors.outlineVariant

                    ListView {
                        id: results
                        anchors.fill: parent
                        anchors.margins: 8
                        interactive: false
                        model: win.results
                        highlightMoveDuration: Theme.animMs
                        highlight: Rectangle {
                            radius: Theme.smallRadius + 4
                            color: Theme.colors.primaryContainer
                        }

                        delegate: MouseArea {
                            id: result
                            required property DesktopEntry modelData
                            required property int index
                            width: ListView.view.width
                            implicitHeight: 44
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: results.currentIndex = index
                            onClicked: win.launch(modelData)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 12
                                IconImage {
                                    implicitSize: 26
                                    source: Quickshell.iconPath(result.modelData.icon, "application-x-executable")
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: result.modelData.name
                                    color: result.ListView.isCurrentItem ? Theme.colors.primaryContainerText : Theme.colors.surfaceText
                                }
                            }
                        }
                    }
                }

                // Workspaces, 5 x 2
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: win.results.length === 0
                    columns: 5
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: 10

                        delegate: Rectangle {
                            id: cell

                            required property int index
                            readonly property int wsId: win.base + index + 1
                            readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                            readonly property var windows: Array.from(Hyprland.toplevels.values)
                                .filter(t => t.workspace !== null && t.workspace.id === wsId)

                            implicitWidth: win.cellWidth
                            implicitHeight: win.cellHeight
                            radius: Theme.radius
                            color: drop.containsDrag ? Theme.colors.secondaryContainer : Theme.colors.surfaceContainer
                            border.width: focused ? 2 : 1
                            border.color: focused ? Theme.colors.primary : Theme.colors.outlineVariant

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Hyprland.dispatch("workspace " + cell.wsId);
                                    win.close();
                                }
                            }

                            DropArea {
                                id: drop
                                anchors.fill: parent
                                keys: ["window"]
                                onDropped: drag => {
                                    Hyprland.dispatch("movetoworkspacesilent " + cell.wsId + ",address:0x" + drag.source.address);
                                    Hyprland.refreshToplevels();
                                }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: cell.windows.length === 0
                                text: cell.wsId
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                color: Theme.colors.outline
                            }

                            // Each window at its real position and size, scaled down
                            Repeater {
                                model: cell.windows

                                delegate: Item {
                                    id: window

                                    required property var modelData
                                    readonly property var ipc: modelData.lastIpcObject
                                    readonly property var wsMonitor: modelData.monitor
                                    readonly property string address: modelData.address
                                    readonly property real x0: ipc && ipc.at ? (ipc.at[0] - (wsMonitor ? wsMonitor.x : 0)) * win.scale : 0
                                    readonly property real y0: ipc && ipc.at ? (ipc.at[1] - (wsMonitor ? wsMonitor.y : 0)) * win.scale : 0

                                    x: x0
                                    y: y0
                                    width: Math.max(16, ipc && ipc.size ? ipc.size[0] * win.scale : 0)
                                    height: Math.max(12, ipc && ipc.size ? ipc.size[1] * win.scale : 0)
                                    z: dragArea.drag.active ? 10 : 1

                                    // Lift the whole cell while dragging, so the window draws over the
                                    // cells after it
                                    Binding {
                                        target: cell
                                        property: "z"
                                        value: 5
                                        when: dragArea.drag.active
                                    }

                                    Drag.active: dragArea.drag.active
                                    Drag.keys: ["window"]
                                    Drag.source: window
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2

                                    ClippingRectangle {
                                        anchors.fill: parent
                                        radius: Theme.smallRadius
                                        color: Theme.colors.surfaceContainerHighest
                                        border.width: 1
                                        border.color: dragArea.containsMouse ? Theme.colors.primary : Theme.colors.outlineVariant

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: window.modelData.wayland
                                            live: cell.focused
                                        }
                                    }
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: Math.min(32, parent.height * 0.5)
                                        source: Apps.iconFor(window.ipc ? window.ipc["class"] : "")
                                    }

                                    MouseArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        drag.target: window
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.MiddleButton) {
                                                Hyprland.dispatch("closewindow address:0x" + window.address);
                                                Hyprland.refreshToplevels();
                                            } else {
                                                Hyprland.dispatch("focuswindow address:0x" + window.address);
                                                win.close();
                                            }
                                        }
                                        onReleased: {
                                            if (drag.active)
                                                window.Drag.drop();
                                            window.x = window.x0;
                                            window.y = window.y0;
                                        }
                                    }

                                    ToolTip.visible: dragArea.containsMouse && !dragArea.drag.active
                                    ToolTip.delay: 400
                                    ToolTip.text: window.modelData.title
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
