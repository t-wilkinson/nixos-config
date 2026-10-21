import QtQuick
QtObject {
    property string name: "sink"
    property QtObject audio: QtObject { property real volume: 0.42; property bool muted: false; signal volumesChanged() }
}
