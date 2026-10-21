import QtQuick

// A round button with a Material Symbols icon
MouseArea {
    id: root

    property alias icon: glyph.text
    property alias iconSize: glyph.size
    property bool active: false
    property color activeColor: Theme.colors.primaryContainer
    property color activeIconColor: Theme.colors.onPrimaryContainer

    implicitWidth: 32
    implicitHeight: 32
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.active ? root.activeColor : Theme.colors.onSurface
        opacity: root.active ? 1 : (root.pressed ? 0.16 : root.containsMouse ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: Theme.animMs } }
    }

    Icon {
        id: glyph
        anchors.centerIn: parent
        fill: root.active ? 1 : 0
        color: root.active ? root.activeIconColor : Theme.colors.onSurfaceVariant
    }
}
