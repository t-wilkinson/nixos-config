import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

// The active media player: art, title, artist, previous / play-pause / next.
Rectangle {
    id: root

    readonly property var player: Players.active

    visible: player !== null
    implicitHeight: 96
    radius: Theme.radius
    color: Theme.colors.surfaceContainerHigh

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            implicitWidth: 72
            implicitHeight: 72
            radius: Theme.smallRadius
            color: Theme.colors.surfaceContainerHighest

            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                visible: !root.player || root.player.trackArtUrl === ""
                text: "music_note"
                size: 32
                color: Theme.colors.surfaceVariantText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                font.weight: Font.DemiBold
            }
            StyledText {
                Layout.fillWidth: true
                text: root.player ? root.player.trackArtist : ""
                color: Theme.colors.surfaceVariantText
                visible: text !== ""
            }
            RowLayout {
                spacing: 4
                IconButton {
                    icon: "skip_previous"
                    enabled: root.player !== null && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
                IconButton {
                    icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                    active: true
                    enabled: root.player !== null && root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
                }
                IconButton {
                    icon: "skip_next"
                    enabled: root.player !== null && root.player.canGoNext
                    onClicked: root.player.next()
                }
            }
        }
    }
}
