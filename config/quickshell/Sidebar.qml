import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// Right sidebar: quick settings, volume, media, Bluetooth devices and notifications.
// Super+N (qs ipc call sidebar toggle), the bell or the settings button in the bar. Esc closes.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: adapter ? Array.from(adapter.devices.values).filter(d => d.paired || d.connected) : []
    readonly property var wifiDevice: Array.from(Networking.devices.values).find(d => d.type === DeviceType.Wifi) || null
    readonly property var connectedNetwork: {
        const devices = Array.from(Networking.devices.values);
        for (const d of devices) {
            const nets = Array.from(d.networks.values).filter(n => n.connected);
            if (nets.length > 0)
                return nets[0];
        }
        return null;
    }

    function run(command) {
        Quickshell.execDetached(command);
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n !== null)
    }

    LazyLoader {
        active: ShellState.sidebarOpen

        PanelWindow {
            anchors {
                top: true
                right: true
                bottom: true
            }
            margins {
                top: Theme.gap
                right: Theme.gap * 2
                bottom: Theme.gap * 2
            }
            exclusiveZone: 0
            implicitWidth: 420
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "quickshell:sidebar"

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius + 4
                color: Theme.colors.surfaceContainer
                border.width: 1
                border.color: Theme.colors.outlineVariant
                focus: true
                Keys.onEscapePressed: ShellState.sidebarOpen = false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Header: date, settings app, lock, power
                    RowLayout {
                        Layout.fillWidth: true
                        SystemClock {
                            id: clock
                            precision: SystemClock.Minutes
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                text: Qt.formatDateTime(clock.date, "hh:mm")
                                font.pixelSize: 26
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                                color: Theme.colors.surfaceVariantText
                            }
                        }
                        IconButton {
                            icon: "settings"
                            onClicked: {
                                ShellState.sidebarOpen = false;
                                root.run(["env", "XDG_CURRENT_DESKTOP=gnome", "gnome-control-center"]);
                            }
                        }
                        IconButton {
                            icon: "lock"
                            onClicked: {
                                ShellState.sidebarOpen = false;
                                root.run(["loginctl", "lock-session"]);
                            }
                        }
                        IconButton {
                            icon: "power_settings_new"
                            onClicked: {
                                ShellState.closeAll();
                                ShellState.powerMenuOpen = true;
                            }
                        }
                    }

                    // Quick toggles
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        QuickToggle {
                            Layout.fillWidth: true
                            icon: Networking.wifiEnabled ? "wifi" : "wifi_off"
                            label: "Wi-Fi"
                            status: root.connectedNetwork ? root.connectedNetwork.name : (Networking.wifiEnabled ? "Not connected" : "Off")
                            active: Networking.wifiEnabled
                            hasDetails: true
                            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                            onDetails: {
                                ShellState.sidebarOpen = false;
                                root.run(["env", "XDG_CURRENT_DESKTOP=gnome", "gnome-control-center", "wifi"]);
                            }
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            icon: root.adapter && root.adapter.enabled ? "bluetooth" : "bluetooth_disabled"
                            label: "Bluetooth"
                            status: {
                                if (!root.adapter)
                                    return "No adapter";
                                if (!root.adapter.enabled)
                                    return "Off";
                                const n = root.btDevices.filter(d => d.connected).length;
                                return n > 0 ? n + " connected" : "On";
                            }
                            active: root.adapter !== null && root.adapter.enabled
                            hasDetails: true
                            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                            onDetails: {
                                ShellState.sidebarOpen = false;
                                root.run(["blueman-manager"]);
                            }
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            icon: ShellState.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                            label: "Do not disturb"
                            status: ShellState.dnd ? "On" : "Off"
                            active: ShellState.dnd
                            onToggled: ShellState.dnd = !ShellState.dnd
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            readonly property bool muted: root.source === null || root.source.audio === null || root.source.audio.muted
                            icon: muted ? "mic_off" : "mic"
                            label: "Microphone"
                            status: muted ? "Muted" : "On"
                            active: !muted
                            hasDetails: true
                            onToggled: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
                            onDetails: {
                                ShellState.sidebarOpen = false;
                                root.run(["pavucontrol"]);
                            }
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            readonly property bool light: Theme.colors.mode === "light"
                            icon: light ? "light_mode" : "dark_mode"
                            label: light ? "Light" : "Dark"
                            status: "Colors from wallpaper"
                            active: !light
                            // Same wallpaper, other mode
                            onToggled: root.run(["sh", "-c", "THEME_MODE=" + (light ? "dark" : "light") + " theme-wallpaper \"$(cat ~/.local/state/theme/wallpaper)\""])
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            icon: "wallpaper"
                            label: "Wallpaper"
                            status: "Pick a new one"
                            onToggled: {
                                ShellState.sidebarOpen = false;
                                root.run(["theme-wallpaper"]);
                            }
                        }
                    }

                    // Volume
                    SliderRow {
                        Layout.fillWidth: true
                        icon: root.sink && root.sink.audio && root.sink.audio.muted ? "volume_off" : "volume_up"
                        value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                        dimmed: root.sink === null || root.sink.audio === null || root.sink.audio.muted
                        onMoved: v => { if (root.sink && root.sink.audio) root.sink.audio.volume = v; }
                        onIconClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                    }
                    SliderRow {
                        Layout.fillWidth: true
                        icon: root.source && root.source.audio && root.source.audio.muted ? "mic_off" : "mic"
                        value: root.source && root.source.audio ? root.source.audio.volume : 0
                        dimmed: root.source === null || root.source.audio === null || root.source.audio.muted
                        onMoved: v => { if (root.source && root.source.audio) root.source.audio.volume = v; }
                        onIconClicked: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
                    }

                    MediaCard {
                        Layout.fillWidth: true
                    }

                    // Bluetooth devices (paired or connected); click to connect / disconnect
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.adapter !== null && root.adapter.enabled && root.btDevices.length > 0
                        spacing: 4

                        StyledText {
                            text: "Bluetooth devices"
                            font.weight: Font.DemiBold
                            color: Theme.colors.surfaceVariantText
                        }
                        Repeater {
                            model: root.btDevices

                            delegate: MouseArea {
                                id: device
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 40
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.smallRadius
                                    color: device.modelData.connected ? Theme.colors.secondaryContainer : Theme.colors.surfaceContainerHigh
                                    opacity: device.containsMouse || device.modelData.connected ? 1 : 0.6
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    Icon {
                                        text: device.modelData.icon.indexOf("headset") >= 0 || device.modelData.icon.indexOf("audio") >= 0 ? "headphones"
                                            : device.modelData.icon.indexOf("keyboard") >= 0 ? "keyboard"
                                            : device.modelData.icon.indexOf("mouse") >= 0 ? "mouse"
                                            : device.modelData.icon.indexOf("phone") >= 0 ? "smartphone" : "bluetooth"
                                        color: device.modelData.connected ? Theme.colors.secondaryContainerText : Theme.colors.surfaceVariantText
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: device.modelData.name
                                        color: device.modelData.connected ? Theme.colors.secondaryContainerText : Theme.colors.surfaceText
                                    }
                                    StyledText {
                                        visible: device.modelData.batteryAvailable
                                        text: Math.round(device.modelData.battery * 100) + "%"
                                        color: Theme.colors.surfaceVariantText
                                    }
                                    StyledText {
                                        text: device.modelData.connected ? "Connected" : "Connect"
                                        font.pixelSize: Theme.fontSize - 2
                                        color: Theme.colors.surfaceVariantText
                                    }
                                }
                            }
                        }
                    }

                    // Notifications
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: "Notifications"
                            font.weight: Font.DemiBold
                            color: Theme.colors.surfaceVariantText
                        }
                        IconButton {
                            icon: "clear_all"
                            onClicked: ShellState.clearNotifications()
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        visible: history.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        text: "Nothing new"
                        color: Theme.colors.outline
                    }
                    ListView {
                        id: history
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Theme.gap
                        model: ShellState.notifications ? Array.from(ShellState.notifications.values).reverse() : []

                        delegate: NotificationCard {
                            required property Notification modelData
                            notification: modelData
                            width: ListView.view.width
                        }
                    }
                }
            }
        }
    }
}
