#!/usr/bin/env bash
# A wrapper for pywal inside the virtual env
source $(eval echo $AGS_VIRTUAL_ENV)/bin/activate
#wal "$@"
wal $*
deactivate
