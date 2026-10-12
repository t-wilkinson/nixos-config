#!/usr/bin/env bash

# ntfy passes the arguments in the order we defined in the config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TITLE="$1"
MESSAGE="$2"
SOUND_FILE="$3"

notify-send "$TITLE" "$MESSAGE"

SOUNDS=("message.oga" "wilhelm.ogg")
ROLL=$((RANDOM % 100))
if ((ROLL < 80)); then
  SOUND=${SOUNDS[0]}
else
  SOUND=${SOUNDS[1]}
fi

paplay "$SCRIPT_DIR/$SOUND"

# if [ -n "$SOUND_FILE" ]; then
#   paplay "$SOUND_FILE"
# else
#   paplay ./message.oga
# fi

# You can add custom logic here later, such as filtering by title:
# if [[ "$TITLE" == *"Alert"* ]]; then
#     # do something specific for alerts
# fi
