import QtQuick
import Harness
QtObject {
    id: s
    property bool keepOnReload; property bool persistenceSupported; property bool bodySupported
    property bool bodyMarkupSupported; property bool bodyHyperlinksSupported; property bool actionsSupported
    property bool imageSupported; property bool actionIconsSupported; property bool inlineReplySupported
    signal notification(QtObject notification)
    property Notification n1: Notification { tracked: true }
    property Notification n2: Notification { tracked: true; urgency: 2; summary: "Battery low"; actions: [] }
    property ObjectListModel trackedNotifications: ObjectListModel { values: [ s.n1, s.n2 ] }
}
