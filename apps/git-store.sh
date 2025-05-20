#!/bin/sh
# Uses `pass` to store github username and token
# To use this to store your credentials, run:
# `git config --global credential.helper $HOME/<location of git-store.sh>`

[ ! "$1" = 'get' ] && exit 0
pass ls "github.credentials.$(git config --get user.name)"
