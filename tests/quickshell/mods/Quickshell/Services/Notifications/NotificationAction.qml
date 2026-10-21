import QtQuick
QtObject { property string identifier; property string text; function invoke() { console.log("HARNESS: action " + identifier) } }
