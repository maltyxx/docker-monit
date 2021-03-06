#!/bin/sh

TZ=${TZ:-UTC}

# TimeZone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

LOCK=/run/lock/entrypoint.lock

if [ ! -f "$LOCK" ]; then
    if [ -d /entrypoint.d ]; then
        for f in /entrypoint.d/*; do
            echo "Launch $f..."
            [ -x "$f" ] && . "$f"
        done
        unset f
    fi

    echo "Lock creation..."
    touch $LOCK
fi

echo "Launch monit..."
exec "$@"
