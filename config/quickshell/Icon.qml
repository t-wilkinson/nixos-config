import QtQuick

// A Material Symbols glyph by name, e.g. Icon { text: "volume_up" }
Text {
    property real fill: 0
    property int size: 18

    color: Theme.colors.onSurface
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "opsz": size })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
