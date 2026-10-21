pragma Singleton
import QtQuick
import Harness
QtObject {
    id: d
    property DesktopEntry a: DesktopEntry { name: "Firefox"; genericName: "Web Browser"; icon: "firefox"; keywords: ["web"] }
    property DesktopEntry b: DesktopEntry { name: "Kitty"; icon: "kitty"; comment: "Terminal" }
    property DesktopEntry c: DesktopEntry { name: "Hidden"; noDisplay: true }
    property ObjectListModel applications: ObjectListModel { values: [ d.a, d.b, d.c ] }
}
