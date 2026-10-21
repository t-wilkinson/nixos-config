import QtQuick
import QtQuick.Window
Window {
    property PanelAnchors anchors: PanelAnchors {}
    property PanelMargins margins: PanelMargins {}
    property int exclusiveZone
    property int exclusionMode
    property real implicitWidth
    property real implicitHeight
    property var screen
    property Region mask
    property bool aboveWindows
    property bool focusable
    width: implicitWidth > 0 ? implicitWidth : screen && screen.width ? screen.width : 800
    height: implicitHeight > 0 ? implicitHeight : 40
    visible: true
}
