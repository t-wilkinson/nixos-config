import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// The playing song/video in the bar: click to play/pause, scroll down for the next track and
// up for the previous one, right click for the sidebar (full controls). Hidden when nothing
// is playing.
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

    // Touchpads send fractions of a notch: one track per full notch
    property real pending: 0
    onWheel: wheel => {
        pending += wheel.angleDelta.y;
        if (Math.abs(pending) < 120)
            return;
        const forward = pending < 0;
        pending = 0;
        if (!player)
            return;
        if (forward && player.canGoNext)
            player.next();
        else if (!forward && player.canGoPrevious)
            player.previous();
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
