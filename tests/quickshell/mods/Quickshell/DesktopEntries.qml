pragma Singleton
import QtQuick
import Harness
QtObject {
    id: d
    property DesktopEntry a: DesktopEntry { name: "Firefox"; genericName: "Web Browser"; icon: "firefox"; keywords: ["web"] }
    property DesktopEntry b: DesktopEntry { name: "Kitty"; icon: "kitty"; comment: "Terminal" }
    property DesktopEntry c: DesktopEntry { name: "Hidden"; noDisplay: true }
    function heuristicLookup(name) { return name === "firefox" ? a : null }
    function byId(id) { return null }
    property ObjectListModel applications: ObjectListModel { values: [ d.a, d.b, d.c ] }
}
