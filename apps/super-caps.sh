#!/bin/sh

xmodmap -e "clear Lock"
xmodmap -e "keycode 66 = Control_L"
xmodmap -e "add Control = Control_L"
xmodmap -e "keysym Escape = Caps_Lock"
# xmodmap -e "add Lock = Caps_Lock"
xmodmap -e "keycode 999 = Escape"

# Map Esc to "`" and "~". Completely remove caps lock, as I never use it
xmodmap -e "clear Lock"
xmodmap -e "keysym Caps_Lock = grave asciitilde"
# xmodmap -e "keysym Caps_Lock = grave"
# xmodmap -e "keysym grave = grave asciitilde"

xcape -e 'Control_L=Escape'
