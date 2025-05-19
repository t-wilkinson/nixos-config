#!/usr/bin/env bash
# Search reading documents to open in zathura

reading=$HOME/reading

case $ROFI_RETV in
    0)
        for f in $reading/*; do
            echo $(basename $f)
        done
        ;;
    1)
        coproc (zathura "$reading/$1")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
