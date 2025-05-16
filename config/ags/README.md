# ags-cirnos

From https://github.com/end-4/dots-hyprland

look at:

- https://github.com/end-4/dots-hyprland/install.sh
- https://github.com/end-4/dots-hyprland/scriptdata/functions
- https://github.com/end-4/dots-hyprland/scriptdata/installers

This function runs to setup ags requirements

```bash
install-python-packages (){
  UV_NO_MODIFY_PATH=1
  ILLOGICAL_IMPULSE_VIRTUAL_ENV=$XDG_STATE_HOME/ags/.venv
  x mkdir -p $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)
  # we need python 3.12 https://github.com/python-pillow/Pillow/issues/8089
  x uv venv --prompt .venv $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV) -p 3.12
  x source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
  x uv pip install -r scriptdata/requirements.txt
  x deactivate # We don't need the virtual environment anymore
}
```
