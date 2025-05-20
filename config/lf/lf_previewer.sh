#!/usr/bin/env bash
file=$1
width=$2
height=$3
x=$4
y=$5

# if [[ "$( file -Lb --mime-type "$file")" =~ ^image ]]; then
#     kitty +kitten icat --silent --stdin no --transfer-mode file --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
#     exit 1
# fi

case "$file" in
*.tar*) tar tf "$file" ;;
*.zip) unzip -l "$file" ;;
*.rar) unrar l "$file" ;;
*.7z) 7z l "$file" ;;
*.pdf) pdftotext "$file" - ;;
*) bat --paging=never --style=numbers --terminal-width $(($2 - 5)) -f "$file" || true ;;
  #*) highlight -O ansi "$file" || true;;
esac
