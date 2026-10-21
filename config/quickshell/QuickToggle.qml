import QtQuick
import QtQuick.Layouts

// A quick-settings tile: icon, label and a status line. Click toggles; the arrow (when
// `hasDetails`) opens the related settings app.
Rectangle {
    id: root

    property string icon
    property string label
    property string status: ""
    property bool active: false
    property bool hasDetails: false
    signal toggled()
    signal details()

    implicitHeight: 58
    radius: Theme.radius
    color: active ? Theme.colors.primaryContainer : Theme.colors.surfaceContainerHigh
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 6
        spacing: 10

        Icon {
            text: root.icon
            fill: root.active ? 1 : 0
            size: 22
            color: root.active ? Theme.colors.primaryContainerText : Theme.colors.surfaceVariantText
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                text: root.label
                font.weight: Font.DemiBold
                color: root.active ? Theme.colors.primaryContainerText : Theme.colors.surfaceText
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.status
                font.pixelSize: Theme.fontSize - 2
                color: root.active ? Theme.colors.primaryContainerText : Theme.colors.surfaceVariantText
                opacity: 0.85
            }
        }
        IconButton {
            visible: root.hasDetails
            icon: "chevron_right"
            onClicked: root.details()
        }
    }
}
