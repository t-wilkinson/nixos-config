#!/usr/bin/env bash
# symbolically links all configuration files to their necessary position

used=(config)
DOT=$(dirname $(realpath "$0"))
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}

if [[ $# != 0 ]]; then
	for config in $@; do
		ln -s "$DOT/$config" "$CONFIG_DIR/$config"
	done
fi

used+=('xmonad')
mkdir -p $HOME/.xmonad
ln -sf $DOT/xmonad/xmonad.hs $HOME/.xmonad

used+=('home')
for f in $DOT/home/*; do
	ln -sf $f "$HOME/.$(basename $f)"
done

used+=('zsh')
ZSH=${ZDOTDIR:-$HOME}
mkdir -p $ZSH/.zprezto/runcoms
for f in $DOT/zsh/*; do
	ln -sf "$f" "$ZSH/.$(basename $f)"
	ln -sf "$f" "$ZSH/.zprezto/runcoms/$(basename $f)"
done

used+=('vim')
mkdir -p $HOME/.vim
for f in $DOT/vim/*; do
	ln -sf $f "$HOME/.vim/$(basename $f)"
done

mkdir -p "$CONFIG_DIR"
for d in $DOT/*; do
	# ignore `used` folders
	grep -q $(basename $d) <<<${used[*]} && continue

	to="$CONFIG_DIR/$(basename $d)"
	[ ! -d $d ] && continue
	ln -sfn "$d" "$to"
done

for f in $DOT/config/*; do
	to="$CONFIG_DIR"
	ln -sf "$f" "$to"
done
