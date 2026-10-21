import QtQuick
QtObject {
    id: l
    default property Component component
    property bool active: false
    property QtObject item: null
    function load() {
        if (active && !item) {
            item = component.createObject(null);
            if (!item) console.error("HARNESS: LazyLoader failed: " + component.errorString());
        } else if (!active && item) { item.destroy(); item = null; }
    }
    onActiveChanged: load()
    Component.onCompleted: load()
}
