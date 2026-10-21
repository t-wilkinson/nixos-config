import QtQuick
QtObject {
    id: v
    default property Component delegate
    property var model: []
    property list<QtObject> instances
    Component.onCompleted: {
        const m = Array.from(model);
        for (let i = 0; i < m.length; i++) {
            const o = delegate.createObject(null, { modelData: m[i] });
            if (!o) console.error("HARNESS: Variants delegate failed: " + delegate.errorString());
            else instances.push(o);
        }
    }
}
