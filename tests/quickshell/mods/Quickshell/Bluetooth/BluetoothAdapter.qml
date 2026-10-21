import QtQuick
import Harness
QtObject {
    id: a
    property bool enabled: true
    property string name: "hci0"
    property BluetoothDevice d1: BluetoothDevice {}
    property BluetoothDevice d2: BluetoothDevice { name: "Keyboard"; icon: "input-keyboard"; connected: false; batteryAvailable: false }
    property ObjectListModel devices: ObjectListModel { values: [ a.d1, a.d2 ] }
}
