#!/bin/bash

set -e

run_server() {
    mkdir -p /persistent/etc/ssh

    ssh-keygen -A -f /persistent

    if [ -n "$AUTHORIZED_KEYS" ]; then
        echo "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
        chmod 0600 /root/.ssh/authorized_keys
    else
        echo "Warning: AUTHORIZED_KEYS variable not set, nobody is authorized" 1>&2
        rm -f /root/.ssh/authorized_keys
    fi

    echo "Starting server"

    exec /usr/sbin/sshd -D
}

finish_client_config() {
    ip link set dev tap0 master br0 up
}

parse_bool() {
    if [ "$1" = "yes" -o "$1" = 1 -o "$1" = true ]; then
        echo 1
    elif [ "$1" = "no" -o "$1" = 0 -o "$1" = false ]; then
        echo 0
    elif [ "$1" = "" ]; then
        echo "$2"
    fi
}

run_client() {
    if [ -z "$PEER" ]; then
        echo "Error: missing PEER variable in client mode" 1>&2
        return 1
    fi
    if [ -z "$SSH_KEY" ]; then
        echo "Error: missing SSH_KEY variable in client mode" 1>&2
        return 1
    fi
    RESET_KNOWN_HOSTS="`parse_bool "$RESET_KNOWN_HOSTS" "0"`"
    if [ -z "$RESET_KNOWN_HOSTS" ]; then
        echo "Error: invalid value for RESET_KNOWN_HOSTS, use either values 'yes' or 'no'" 1>&2
        return 1
    fi
    if echo "$PEER" | grep -q ':[0-9]\+$'; then
        export PORT="`echo "$PEER" | sed 's/^.*:\([0-9]\+\)$/\1/'`"
        export PEER="`echo "$PEER" | sed 's/:[0-9]\+$//'`"
    else
        export PORT=22
    fi

    if [ "$RESET_KNOWN_HOSTS" = 1 ]; then
        rm -f /persistent/known_hosts
    fi
    touch /persistent/known_hosts
    rm -f /root/.ssh/known_hosts
    ln -s /persistent/known_hosts /root/.ssh/known_hosts

    touch /root/.ssh/key
    chmod go-rwx /root/.ssh/key
    echo "$SSH_KEY" > /root/.ssh/key
    ssh-keygen -f /root/.ssh/key -y > /root/.ssh/key.pub
    finished=""

    sleep 2

    echo "Starting client"

    ssh -i /root/.ssh/key -p "$PORT" -o "StrictHostKeyChecking=accept-new" -o "Tunnel=ethernet" -w 0:any root@"$PEER" 2>&1 | while read line; do
        if [ -z "$finished" ] && echo "$line" | grep -q 'connected to server'; then
            finish_client_config
            finished=1
        fi
        echo "$line"
    done
}

ip link add name br0 type bridge
ip link set dev br0 up

if [ -z "$MODE" ]; then
    if [ -z "$PEER" ]; then
        export MODE="server"
    else
        export MODE="client"
    fi
fi

if [ "$MODE" = "server" -o "$MODE" = "master" ]; then
    run_server
elif [ "$MODE" = "client" -o "$MODE" = "slave" ]; then
    run_client
else
    echo "Error: invalid MODE: '$MODE'" 1>&2
    exit 1
fi
