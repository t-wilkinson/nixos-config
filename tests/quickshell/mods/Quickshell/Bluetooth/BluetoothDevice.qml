import QtQuick
QtObject {
    property string name: "Headphones"; property string icon: "audio-headset"
    property bool connected: true; property bool paired: true
    property bool batteryAvailable: true; property real battery: 0.8
    function connect() { connected = true; console.log("HARNESS: bt connect " + name) }
    function disconnect() { connected = false; console.log("HARNESS: bt disconnect " + name) }
}
