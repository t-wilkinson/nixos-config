import QtQuick
QtObject {
    property bool tracked
    property bool lastGeneration: false
    property real expireTimeout: -1
    property string appName: "Firefox"
    property string appIcon: ""
    property string summary: "Download finished"
    property string body: "file.zip <b>done</b>"
    property int urgency: 1
    property list<QtObject> actions: [ NotificationAction { identifier: "default"; text: "Open" }, NotificationAction { identifier: "show"; text: "Show in folder" } ]
    property string image: ""
    function dismiss() { tracked = false; console.log("HARNESS: dismissed " + summary) }
    function expire() { tracked = false }
}
