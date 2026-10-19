#!/bin/sh

set -eu
set -x

for file in $IOCAINE_CONFIG_DEST_DIR/config.d/*.template; do
    # still need to check if the file is empty in the case of an empty glob
    # `${%}` is suffix-stripping syntax
    [ -f "$file" ] \
        && envsubst < "$file" > "${file%.template}"
done

# the caller of this script must pass the original entrypoint as args, and this executes it
exec "$@"
