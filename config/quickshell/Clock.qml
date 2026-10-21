import QtQuick
import Quickshell

// "Tue 21 Oct  14:05"
StyledText {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd d MMM   hh:mm")
    font.weight: Font.Medium
}
