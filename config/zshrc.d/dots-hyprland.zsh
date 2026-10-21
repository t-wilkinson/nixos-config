# Use the generated color scheme (matugen). Not inside Zellij: there the panes show the outer
# terminal's palette, which follows the wallpaper by itself (theme-terminals).
if [ -f ~/.local/state/theme/sequences.txt ] && [ -z "$ZELLIJ" ]; then
    cat ~/.local/state/theme/sequences.txt
fi
