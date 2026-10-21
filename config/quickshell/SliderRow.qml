import QtQuick
import QtQuick.Layouts

// Icon + slider (0..1) + percentage. Clicking the icon runs `iconClicked` (e.g. mute).
RowLayout {
    id: root

    property string icon
    property real value: 0
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked()

    spacing: 10

    IconButton {
        icon: root.icon
        active: !root.dimmed
        onClicked: root.iconClicked()
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Theme.colors.surfaceContainerHighest

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: 4
                color: root.dimmed ? Theme.colors.outline : Theme.colors.primary
            }
        }
        Rectangle {
            x: track.width * Math.max(0, Math.min(1, root.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: root.dimmed ? Theme.colors.outline : Theme.colors.primary
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function set(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => { if (pressed) set(mouse.x); }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    StyledText {
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: Theme.colors.surfaceVariantText
    }
}
