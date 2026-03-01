#!/bin/bash

# Define the menu options
options="Coding\nDevelopment\nCommunication\nGaming"

# Pipe the options into Rofi and store the result in a variable
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Select Layout:")

# Logic for window placement
case "$chosen" in
"Coding")
  # Switch to workspace 1 and open a development environment
  hyprctl dispatch workspace 1
  hyprctl dispatch exec "[tile] kitty nvim"
  hyprctl dispatch exec "[tile] kitty"
  ;;
"Development")
  # Specialized layout: a main browser window and a floating terminal
  hyprctl dispatch workspace 3
  hyprctl dispatch exec "[tile] firefox"
  hyprctl dispatch exec "[float; size 40% 40%; move 55% 5%] kitty"
  ;;
"Communication")
  # Launch apps on a specific workspace silently
  hyprctl dispatch workspace 10
  hyprctl dispatch exec "discord"
  hyprctl dispatch exec "slack"
  ;;
"Gaming")
  hyprctl dispatch workspace 5
  hyprctl dispatch exec "steam"
  ;;
*)
  # Default case: exit if no valid option is picked (e.g., pressing Esc)
  exit 0
  ;;
esac
