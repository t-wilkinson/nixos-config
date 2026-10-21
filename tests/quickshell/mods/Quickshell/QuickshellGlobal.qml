pragma Singleton
import QtQuick
QtObject {
    property list<QtObject> screens: [ ShellScreen {} ]
    function env(name) { return name === "HOME" ? "/tmp/harness-home" : "" }
    function iconPath(name, fallback) { return "image://icon/" + name }
    function execDetached(cmd) { console.log("HARNESS: exec " + JSON.stringify(cmd)) }
}
