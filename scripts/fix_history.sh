#!/bin/sh
# sometimes my ~/.zhistory would get corrupted
tmp=$(mktemp)
mv ~/.zhistory "$tmp"
strings "$tmp" >~/.zhistory
