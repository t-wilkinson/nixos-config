pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player to show: the one playing now, else the last one that played, else any.
Singleton {
    id: root

    property var lastPlaying: null
    readonly property var all: Array.from(Mpris.players.values)
    readonly property var active: {
        const players = root.all;
        for (let i = 0; i < players.length; i++)
            if (players[i].isPlaying)
                return players[i];
        if (root.lastPlaying !== null && players.indexOf(root.lastPlaying) >= 0)
            return root.lastPlaying;
        return players.length > 0 ? players[0] : null;
    }

    onActiveChanged: if (active !== null && active.isPlaying) lastPlaying = active
}
