#!/usr/bin/env bash

UV_NO_MODIFY_PATH=1
script_data=$HOME/dev/end-4/dots-hyprland
ILLOGICAL_IMPULSE_VIRTUAL_ENV=$HOME/.local/state/ags/.venv
mkdir -p $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)
# we need python 3.12 https://github.com/python-pillow/Pillow/issues/8089
uv venv --prompt .venv $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV) -p 3.12
source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
uv pip install -r $script_data/scriptdata/requirements.txt
deactivate # We don't need the virtual environment anymore
