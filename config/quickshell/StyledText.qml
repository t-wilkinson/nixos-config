import QtQuick

// Text in the shell's font and default color
Text {
    color: Theme.colors.surfaceText
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
