pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Screen brightness, per monitor. External monitors are set over DDC/CI with ddcutil (needs
// the i2c group, hosts/nixos/default.nix); monitors ddcutil doesn't find (a laptop's built-in
// screen) use brightnessctl.
//   scroll on the left half of the bar   that bar's monitor
//   qs ipc call brightness up|down       the focused monitor (brightness keys, keybinds.conf)
// Changes show in the OSD (Osd.qml).
Singleton {
    id: root

    readonly property real step: 0.05
    // Monitor name (DP-1) -> { bus: "4", value: 0..1 (-1 until read), max: 100, dirty: bool }
    property var ddc: ({})
    // Pending commands, run one at a time (DDC is slow and doesn't like overlapping commands)
    property var queue: []

    // value is 0..1
    signal adjusted(string monitor, real value)

    function adjust(monitor, delta) {
        const m = ddc[monitor];
        if (m === undefined) {
            // Not a DDC monitor: built-in screen
            const amount = Math.round(Math.abs(delta) * 100) + "%" + (delta > 0 ? "+" : "-");
            run(["brightnessctl", "-m", "set", amount], text => {
                // "intel_backlight,backlight,12000,50%,24000"
                const fields = text.trim().split("\n").pop().split(",");
                if (fields.length >= 4)
                    root.adjusted(monitor, parseInt(fields[3]) / 100);
            });
            return;
        }
        if (m.value < 0)
            return; // still reading the current value
        m.value = Math.max(0, Math.min(1, m.value + delta));
        m.dirty = true;
        adjusted(monitor, m.value);
        // Scrolling sends many small steps; only send the last one
        applyTimer.restart();
    }

    function adjustFocused(delta) {
        if (Hyprland.focusedMonitor !== null)
            adjust(Hyprland.focusedMonitor.name, delta);
    }

    function run(command, done) {
        queue.push({
            command: command,
            done: done
        });
        next();
    }

    function next() {
        if (proc.running || proc.job !== null || queue.length === 0)
            return;
        const job = queue.shift();
        proc.job = job;
        proc.command = job.command;
        proc.running = true;
    }

    function finish(text) {
        const job = proc.job;
        proc.job = null;
        if (job !== null && text !== null && job.done)
            job.done(text);
        next();
    }

    function detect() {
        run(["ddcutil", "detect", "--brief"], text => {
            const found = {};
            const monitors = Hyprland.monitors.values;
            for (const block of text.split(/\n\s*\n/)) {
                if (!/^Display \d+/.test(block.trim()))
                    continue; // "Invalid display": no DDC (often a laptop panel)
                const bus = (block.match(/I2C bus:\s*\/dev\/i2c-(\d+)/) || [])[1];
                if (!bus)
                    continue;
                // "DRM connector: card1-DP-1" (or DRM_connector) names the output directly...
                let name = (block.match(/DRM[ _]connector:\s*card\d+-(\S+)/) || [])[1];
                // ...otherwise match "Monitor: MFG:Model:Serial" against Hyprland's serials
                if (!name) {
                    const serial = ((block.match(/Monitor:\s*(.*)/) || [])[1] || "").split(":")[2];
                    const monitor = monitors.find(mon => serial && mon.lastIpcObject && mon.lastIpcObject.serial === serial);
                    name = monitor ? monitor.name : undefined;
                }
                if (name)
                    found[name] = {
                        bus: bus,
                        value: -1,
                        max: 100,
                        dirty: false
                    };
            }
            root.ddc = found;
            for (const name in found)
                root.read(name);
        });
    }

    function read(name) {
        const m = ddc[name];
        run(["ddcutil", "-b", m.bus, "getvcp", "10", "--brief"], text => {
            // "VCP 10 C 50 100": current, max
            const fields = text.trim().split("\n").pop().trim().split(/\s+/);
            const current = parseInt(fields[3]);
            const max = parseInt(fields[4]);
            if (!isNaN(current) && max > 0) {
                m.max = max;
                m.value = current / max;
            }
        });
    }

    Timer {
        id: applyTimer
        interval: 150
        onTriggered: {
            for (const name in root.ddc) {
                const m = root.ddc[name];
                if (!m.dirty)
                    continue;
                m.dirty = false;
                root.run(["ddcutil", "-b", m.bus, "setvcp", "10", String(Math.round(m.value * m.max)), "--noverify"], null);
            }
        }
    }

    Process {
        id: proc
        property var job: null
        stdout: StdioCollector {
            id: output
        }
        onExited: (code, status) => root.finish(code === 0 ? output.text : null)
        // Failed to start (ddcutil/brightnessctl missing): no exited signal
        onRunningChanged: {
            if (!running)
                Qt.callLater(() => {
                    if (!proc.running && proc.job !== null)
                        root.finish(null);
                });
        }
    }

    Component.onCompleted: detect()

    IpcHandler {
        target: "brightness"
        function up(): void {
            root.adjustFocused(root.step);
        }
        function down(): void {
            root.adjustFocused(-root.step);
        }
    }
}
