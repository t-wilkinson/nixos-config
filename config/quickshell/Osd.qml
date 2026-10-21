import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// Indicator at the bottom of the screen when the volume or mute changes (from the keyboard,
// the bar or any other app; on the focused monitor) or a monitor's brightness changes (on
// that monitor). Clicks pass through it.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    property bool shown: false
    property bool armed: false // ignore the initial values when the sink first binds
    property string kind: "volume" // or "brightness"
    property real brightness: 0
    property string monitor: ""

    readonly property real value: kind === "brightness" ? brightness : ready ? sink.audio.volume : 0
    readonly property bool off: kind === "volume" && (!ready || sink.audio.muted)

    function show(kind, monitor) {
        if (!armed)
            return;
        root.kind = kind;
        root.monitor = monitor;
        shown = true;
        hideTimer.restart();
    }
    function focusedMonitor() {
        return Hyprland.focusedMonitor !== null ? Hyprland.focusedMonitor.name : "";
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: root.ready ? root.sink.audio : null
        function onVolumesChanged() {
            root.show("volume", root.focusedMonitor());
        }
        function onMutedChanged() {
            root.show("volume", root.focusedMonitor());
        }
    }

    Connections {
        target: Brightness
        function onAdjusted(monitor, value) {
            root.brightness = value;
            root.show("brightness", monitor);
        }
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
            screen: Quickshell.screens.find(s => s.name === root.monitor) || null
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
                        text: root.kind === "brightness" ? "brightness_6" : root.off ? "volume_off" : "volume_up"
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
                            width: parent.width * Math.max(0, Math.min(1, root.value))
                            height: parent.height
                            radius: 4
                            color: root.off ? Theme.colors.outline : Theme.colors.primary
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(root.value * 100)
                    }
                }
            }
        }
    }
}
