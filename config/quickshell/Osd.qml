import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// Volume indicator at the bottom of the screen whenever the output volume or mute changes
// (from the keyboard, the bar or any other app). Clicks pass through it.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    property bool shown: false
    property bool armed: false // ignore the initial values when the sink first binds

    function show() {
        if (!armed)
            return;
        shown = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: root.ready ? root.sink.audio : null
        function onVolumesChanged() { root.show(); }
        function onMutedChanged() { root.show(); }
    }

    Timer {
        running: true
        interval: 2000
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            anchors.bottom: true
            margins.bottom: 80
            exclusiveZone: 0
            implicitWidth: 320
            implicitHeight: 56
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:osd"

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.colors.surfaceContainerHigh
                border.width: 1
                border.color: Theme.colors.outlineVariant

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 22
                    spacing: 14

                    Icon {
                        text: !root.ready || root.sink.audio.muted ? "volume_off" : "volume_up"
                        size: 22
                        fill: 1
                        color: Theme.colors.primary
                    }

                    // Track and fill
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: Theme.colors.surfaceContainerHighest

                        Rectangle {
                            width: parent.width * Math.min(1, root.ready ? root.sink.audio.volume : 0)
                            height: parent.height
                            radius: 4
                            color: root.ready && root.sink.audio.muted ? Theme.colors.outline : Theme.colors.primary
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: root.ready ? Math.round(root.sink.audio.volume * 100) : ""
                    }
                }
            }
        }
    }
}
