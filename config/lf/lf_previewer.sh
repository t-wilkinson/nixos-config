#!/usr/bin/env bash

case "$1" in
*.tar*) tar tf "$1" ;;
*.zip) unzip -l "$1" ;;
*.rar) unrar l "$1" ;;
*.7z) 7z l "$1" ;;
*.pdf) pdftotext "$1" - ;;
*) bat --paging=never --style=numbers --terminal-width $(($2 - 5)) -f "$1" || true ;;
  #*) highlight -O ansi "$1" || true;;
esac

# MIME=$(mimetype --all --brief "$1")
# #echo "$MIME"
#
# case "$MIME" in
# # .pdf
# *application/pdf*)
#   pdftotext "$1" -
#   ;;
# # .7z
# *application/x-7z-compressed*)
#   7z l "$1"
#   ;;
# # .tar .tar.Z
# *application/x-tar*)
#   tar -tvf "$1"
#   ;;
# # .tar.*
# *application/x-compressed-tar* | *application/x-*-compressed-tar*)
#   tar -tvf "$1"
#   ;;
# # .rar
# *application/vnd.rar*)
#   unrar l "$1"
#   ;;
# # .zip
# *application/zip*)
#   unzip -l "$1"
#   ;;
# # any plain text file that doesn't have a specific handler
# *text/plain*)
#   # return false to always repaint, in case terminal size changes
#   bat --force-colorization --paging=never --style=changes,numbers \
#     --terminal-width $(($2 - 3)) "$1" && false
#   ;;
# *)
#   echo "unknown format"
#   ;;
# esac
