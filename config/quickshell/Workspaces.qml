import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// Ten workspaces as pills: the focused one is wide and colored, occupied ones are solid,
// empty ones are faint. Click to switch. Shows the group of ten holding the focused
// workspace (1-10, 11-20, ...), matching Super+N in keybinds.conf.
Item {
    id: root

    property int count: 10
    readonly property int base: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id > 0
        ? Math.floor((Hyprland.focusedWorkspace.id - 1) / count) * count : 0

    function workspace(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i];
        return null;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Scroll over the workspaces to move between them (elsewhere on the bar: volume)
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        acceptedButtons: Qt.NoButton
        onWheel: wheel => Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace m-1" : "workspace m+1")
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.count

            delegate: MouseArea {
                id: pill

                required property int index
                readonly property int wsId: root.base + index + 1
                readonly property var ws: root.workspace(wsId)
                readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                readonly property bool occupied: ws !== null && ws.toplevels.values.length > 0

                implicitWidth: focused ? 28 : 12
                implicitHeight: 12
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsId)

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Theme.animMs
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: pill.focused ? Theme.colors.primary : pill.occupied ? Theme.colors.surfaceVariantText : Theme.colors.outlineVariant
                    Behavior on color { ColorAnimation { duration: Theme.animMs } }
                }
            }
        }
    }
}
