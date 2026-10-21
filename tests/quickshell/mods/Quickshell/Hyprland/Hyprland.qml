pragma Singleton
import QtQuick
import Harness
QtObject {
    id: h
    property MockWorkspace ws1: MockWorkspace { windows: 1 }
    property MockWorkspace ws12: MockWorkspace { windows: 0 }
    property QtObject mon: QtObject { property string name: "DP-1"; property int x: 0; property int y: 0; property int width: 2560; property int height: 1440; property real scale: 1 }
    property QtObject t1: QtObject {
        property string address: "55d0c0ffee"; property string title: "Firefox — Docs"
        property QtObject workspace: h.ws1; property QtObject monitor: h.mon; property QtObject wayland: QtObject {}
        property var lastIpcObject: ({ at: [10, 50], size: [1260, 1380], "class": "firefox", title: "Firefox — Docs" })
    }
    property QtObject t2: QtObject {
        property string address: "55d0c0ff00"; property string title: "kitty"
        property QtObject workspace: h.ws12; property QtObject monitor: h.mon; property QtObject wayland: QtObject {}
        property var lastIpcObject: ({ at: [1290, 50], size: [1260, 1380], "class": "kitty", title: "kitty" })
    }
    property ObjectListModel workspaces: ObjectListModel { values: [ h.ws1, h.ws12 ] }
    property ObjectListModel toplevels: ObjectListModel { values: [ h.t1, h.t2 ] }
    property ObjectListModel monitors: ObjectListModel { values: [ h.mon ] }
    property QtObject focusedWorkspace: ws12
    property QtObject focusedMonitor: mon
    property QtObject activeToplevel: t2
    Component.onCompleted: { ws1.id = 1; ws12.id = 12; }
    function dispatch(req) { console.log("HARNESS: dispatch " + req) }
    function refreshToplevels() { console.log("HARNESS: refreshToplevels") }
    function refreshWorkspaces() {}
}
