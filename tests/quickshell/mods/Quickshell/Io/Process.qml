import QtQuick
// Runs nothing: answers known commands with canned output (like ddcutil and brightnessctl
// would), so code that parses output gets exercised. Each command is logged.
QtObject {
    id: p
    property var command: []
    property bool running: false
    property QtObject stdout
    property var environment: ({})
    signal exited(int exitCode, int exitStatus)
    signal started()

    function output(cmd) {
        const c = cmd.join(" ");
        if (c === "ddcutil detect --brief")
            return "Display 1\n   I2C bus:  /dev/i2c-4\n   DRM connector:           card1-DP-1\n   Monitor:                 DEL:DELL U2720Q:ABC123\n\n"
                + "Invalid display\n   I2C bus:  /dev/i2c-7\n   DRM connector:           card1-eDP-1\n";
        if (c.startsWith("ddcutil") && c.indexOf("getvcp") >= 0)
            return "VCP 10 C 40 100\n";
        if (c.startsWith("brightnessctl"))
            return "intel_backlight,backlight,12000,55%,24000\n";
        return "";
    }

    onRunningChanged: if (running) timer.start()
    property Timer timer: Timer {
        interval: 10
        onTriggered: {
            console.log("HARNESS: process " + p.command.join(" "));
            if (p.stdout)
                p.stdout.text = p.output(p.command);
            p.running = false;
            p.exited(0, 0);
        }
    }
}
