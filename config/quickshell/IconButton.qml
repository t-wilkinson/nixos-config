import QtQuick

// A round button with a Material Symbols icon
MouseArea {
    id: root

    property alias icon: glyph.text
    property alias iconSize: glyph.size
    property bool active: false
    property int badge: 0 // a count in the corner when > 0
    property color activeColor: Theme.colors.primaryContainer
    property color activeIconColor: Theme.colors.primaryContainerText

    implicitWidth: 32
    implicitHeight: 32
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.active ? root.activeColor : Theme.colors.surfaceText
        opacity: root.active ? 1 : (root.pressed ? 0.16 : root.containsMouse ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: Theme.animMs } }
    }

    Icon {
        id: glyph
        anchors.centerIn: parent
        fill: root.active ? 1 : 0
        color: root.active ? root.activeIconColor : Theme.colors.surfaceVariantText
    }

    Rectangle {
        visible: root.badge > 0
        anchors {
            top: parent.top
            right: parent.right
        }
        implicitWidth: Math.max(16, count.implicitWidth + 8)
        implicitHeight: 16
        radius: 8
        color: Theme.colors.primary

        StyledText {
            id: count
            anchors.centerIn: parent
            text: root.badge > 99 ? "99+" : root.badge
            color: Theme.colors.primaryText
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }
}
