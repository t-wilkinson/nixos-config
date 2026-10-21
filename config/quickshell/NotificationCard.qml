import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification: icon or image, app name, summary, body, action buttons, close button.
// Clicking the card runs its default action (or dismisses it).
Rectangle {
    id: card

    required property Notification notification
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical

    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: critical ? Theme.colors.errorContainer : Theme.colors.surfaceContainerHigh
    border.width: 1
    border.color: critical ? Theme.colors.error : Theme.colors.outlineVariant

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const actions = card.notification.actions;
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].identifier === "default") {
                    actions[i].invoke();
                    return;
                }
            }
            card.notification.dismiss();
        }
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 12

        // Image (e.g. a contact photo), else the app icon, else a bell
        Item {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40

            ClippingRectangle {
                anchors.fill: parent
                radius: Theme.smallRadius
                visible: card.notification.image !== ""
                color: "transparent"
                Image {
                    anchors.fill: parent
                    source: card.notification.image
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
            IconImage {
                anchors.fill: parent
                visible: card.notification.image === "" && card.notification.appIcon !== ""
                source: card.notification.appIcon !== "" ? Quickshell.iconPath(card.notification.appIcon, "dialog-information") : ""
            }
            Icon {
                anchors.centerIn: parent
                visible: card.notification.image === "" && card.notification.appIcon === ""
                text: "notifications"
                size: 26
                color: Theme.colors.primary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: card.notification.appName
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.colors.onSurfaceVariant
                }
                IconButton {
                    implicitWidth: 22
                    implicitHeight: 22
                    icon: "close"
                    iconSize: 16
                    onClicked: card.notification.dismiss()
                }
            }
            StyledText {
                Layout.fillWidth: true
                text: card.notification.summary
                font.weight: Font.DemiBold
                color: card.critical ? Theme.colors.onErrorContainer : Theme.colors.onSurface
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notification.body
                textFormat: Text.StyledText
                color: card.critical ? Theme.colors.onErrorContainer : Theme.colors.onSurfaceVariant
                wrapMode: Text.Wrap
                maximumLineCount: 5
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
            RowLayout {
                Layout.fillWidth: true
                visible: actionRepeater.count > 0
                spacing: Theme.gap

                Repeater {
                    id: actionRepeater
                    model: Array.from(card.notification.actions).filter(a => a.identifier !== "default")

                    delegate: MouseArea {
                        id: action
                        required property NotificationAction modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: modelData.invoke()

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: action.containsMouse ? Theme.colors.primary : Theme.colors.secondaryContainer
                        }
                        StyledText {
                            anchors.centerIn: parent
                            text: action.modelData.text
                            color: action.containsMouse ? Theme.colors.onPrimary : Theme.colors.onSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
