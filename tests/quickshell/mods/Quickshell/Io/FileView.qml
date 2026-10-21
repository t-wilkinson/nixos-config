import QtQuick
QtObject {
    default property QtObject adapter
    property string path
    property bool watchChanges
    property bool printErrors: true
    property bool preload: true
    property bool blockLoading
    signal fileChanged()
    signal adapterUpdated()
    function reload() {}
    function writeAdapter() {}
    function text() { return "" }
}
