import QtQuick
QtObject {
    property string id; property string name; property string genericName; property string comment
    property string icon; property bool noDisplay; property list<string> keywords
    function execute() { console.log("HARNESS: execute " + name) }
}
