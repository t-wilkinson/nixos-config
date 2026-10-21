import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// System tray. Left click activates, middle click is the secondary action, right click
// (or left click on menu-only items) opens the item's menu.
RowLayout {
    spacing: Theme.gap

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: 18
            implicitHeight: 18
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();
                } else if (modelData.hasMenu) {
                    const pos = item.mapToItem(null, 0, item.height + Theme.gap * 2);
                    modelData.display(QsWindow.window, pos.x, pos.y);
                }
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
