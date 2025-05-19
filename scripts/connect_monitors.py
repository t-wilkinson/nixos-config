#!/usr/bin/env python3
import subprocess


def get_screens():
    output = [l for l in subprocess.check_output(
        ["xrandr"]).decode("utf-8").splitlines()]
    screens = [l.split()[0] for l in output if " connected " in l]
    screens.sort()
    return screens


subprocess.run(['xrandr', '--auto'])
screens = get_screens()
subprocess.run(['xrandr', '--output', screens[1],
                '--below', screens[0], '--primary'])
