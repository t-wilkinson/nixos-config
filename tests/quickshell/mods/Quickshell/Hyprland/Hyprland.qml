pragma Singleton
import QtQuick
import Harness
QtObject {
    id: h
    property MockWorkspace ws1: MockWorkspace { windows: 1 }
    property MockWorkspace ws12: MockWorkspace { windows: 0 }
    property ObjectListModel workspaces: ObjectListModel { values: [ h.ws1, h.ws12 ] }
    property QtObject focusedWorkspace: ws12
    property QtObject activeToplevel: QtObject { property string title: "nvim ~/dev" }
    Component.onCompleted: { ws1.id = 1; ws12.id = 12; }
    function dispatch(req) { console.log("HARNESS: dispatch " + req) }
}
