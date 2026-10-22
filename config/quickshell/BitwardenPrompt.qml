import QtQuick
import Quickshell
import Quickshell.Hyprland

// Brings Bitwarden to you when its SSH agent needs you (ssh, git push): to unlock the vault or
// to approve using a key. Bitwarden asks to be focused, which Hyprland ignores apart from
// marking the window urgent; without this, ssh sits waiting (up to 60 s) for a prompt on some
// other workspace.
//
// Bitwarden lives in the special workspace "bitwarden" (rules.conf), out of the way. When it
// asks for attention, that workspace opens over whatever you're doing, on the focused monitor.
// Focus anything else and it hides again. Ctrl+Super+B shows/hides it by hand.
Scope {
    id: root

    property string openOn: "" // monitor showing special:bitwarden, "" when hidden
    property string summoned: "" // Bitwarden's address while we're showing it for a request

    function norm(address) {
        return String(address).toLowerCase().replace(/^0x/, "");
    }
    function find(address) {
        return Hyprland.toplevels.values.find(t => root.norm(t.address) === address) || null;
    }
    function isBitwarden(toplevel) {
        const ipc = toplevel.lastIpcObject || {};
        const appId = toplevel.wayland ? toplevel.wayland.appId : "";
        return /bitwarden/i.test([ipc["class"] || "", appId || "", toplevel.title || ""].join(" "));
    }
    function focusedMonitor() {
        return Hyprland.focusedMonitor !== null ? Hyprland.focusedMonitor.name : "";
    }

    function summon(address) {
        // Wherever it is (moved by hand, or opened before the rule applied), put it in its
        // workspace, show that here and focus it
        Hyprland.dispatch("movetoworkspacesilent special:bitwarden,address:0x" + address);
        if (openOn !== focusedMonitor())
            Hyprland.dispatch("togglespecialworkspace bitwarden");
        Hyprland.dispatch("focuswindow address:0x" + address);
        summoned = address;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const data = event.data;
            if (event.name === "urgent") {
                const address = root.norm(data);
                const toplevel = root.find(address);
                if (toplevel !== null && root.isBitwarden(toplevel))
                    root.summon(address);
            } else if (event.name === "activespecial") {
                // "special:bitwarden,DP-1" when shown; ",DP-1" (or another name) when not
                const comma = data.lastIndexOf(",");
                const name = data.slice(0, comma);
                const monitor = data.slice(comma + 1);
                if (name === "special:bitwarden")
                    root.openOn = monitor;
                else if (root.openOn === monitor)
                    root.openOn = "";
            } else if (event.name === "activewindowv2" && root.summoned !== "" && root.norm(data) !== root.summoned) {
                // Done with Bitwarden: hide it again (after Hyprland has settled, in case
                // focusing elsewhere already closed it)
                root.summoned = "";
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: {
            if (root.openOn !== "" && root.openOn === root.focusedMonitor())
                Hyprland.dispatch("togglespecialworkspace bitwarden");
        }
    }
}
