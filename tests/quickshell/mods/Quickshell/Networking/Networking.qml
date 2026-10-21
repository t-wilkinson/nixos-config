pragma Singleton
import QtQuick
import Harness
QtObject {
    id: n
    property bool wifiEnabled: true
    property QtObject net: QtObject { property string name: "HOMELAB_5G"; property bool connected: true }
    property QtObject wifi: QtObject { property int type: 1; property string name: "wlan0"; property ObjectListModel networks: ObjectListModel { values: [ n.net ] } }
    property ObjectListModel devices: ObjectListModel { values: [ n.wifi ] }
}
