pragma Singleton
import QtQuick
import Harness
QtObject { id: m; property MprisPlayer p: MprisPlayer {}; property ObjectListModel players: ObjectListModel { values: [ m.p ] } }
