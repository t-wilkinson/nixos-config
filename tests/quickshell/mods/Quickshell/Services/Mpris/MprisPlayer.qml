import QtQuick
QtObject {
    property string identity: "Firefox"
    property string trackTitle: "Some Song"
    property string trackArtist: "Some Artist"
    property string trackArtUrl: ""
    property bool isPlaying: true
    property bool canTogglePlaying: true
    property bool canGoNext: true
    property bool canGoPrevious: true
    function togglePlaying() { isPlaying = !isPlaying; console.log("HARNESS: togglePlaying") }
    function next() { console.log("HARNESS: next") }
    function previous() { console.log("HARNESS: previous") }
}
