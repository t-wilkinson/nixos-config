pragma Singleton
import QtQuick
import Harness
QtObject { id: t; property SystemTrayItem a: SystemTrayItem {}; property ObjectListModel items: ObjectListModel { values: [ t.a ] } }
