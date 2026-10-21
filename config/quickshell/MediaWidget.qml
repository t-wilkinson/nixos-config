import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// The playing song/video in the bar: click to play/pause, right click for the sidebar (full
// controls, next/previous). Hidden when nothing is playing. Scrolling over it changes the
// volume, like the rest of the bar's right half.
MouseArea {
    id: root

    readonly property var player: Players.active

    visible: player !== null && player.trackTitle !== ""
    implicitWidth: row.implicitWidth
    implicitHeight: 28
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            ShellState.sidebarOpen = !ShellState.sidebarOpen;
        else if (player && player.canTogglePlaying)
            player.togglePlaying();
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        Icon {
            text: root.player && root.player.isPlaying ? "pause_circle" : "play_circle"
            fill: 1
            size: 20
            color: Theme.colors.primary
        }
        StyledText {
            Layout.fillWidth: true
            text: {
                if (!root.player)
                    return "";
                const artist = root.player.trackArtist;
                return artist ? root.player.trackTitle + "  ·  " + artist : root.player.trackTitle;
            }
            color: Theme.colors.surfaceVariantText
        }
    }
}
