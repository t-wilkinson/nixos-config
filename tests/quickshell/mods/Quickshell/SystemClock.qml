import QtQuick
QtObject {
    enum Precision { Hours = 1, Minutes = 2, Seconds = 3 }
    property int precision: 3
    property bool enabled: true
    property date date: new Date()
    property int hours: date.getHours()
    property int minutes: date.getMinutes()
}
