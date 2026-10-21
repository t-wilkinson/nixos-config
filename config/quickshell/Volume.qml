import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Output volume. Click to mute, scroll to change.
MouseArea {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : true

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 28
    cursorShape: Qt.PointingHandCursor
    onClicked: if (ready) sink.audio.muted = !sink.audio.muted
    onWheel: wheel => {
        if (ready)
            sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
    }

    // Binds the sink so its volume and mute state are live
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Icon {
            text: root.muted ? "volume_off" : root.volume > 0.5 ? "volume_up" : root.volume > 0 ? "volume_down" : "volume_mute"
            color: root.muted ? Theme.colors.outline : Theme.colors.onSurfaceVariant
        }
        StyledText {
            text: Math.round(root.volume * 100) + "%"
            color: Theme.colors.onSurfaceVariant
        }
    }
}
