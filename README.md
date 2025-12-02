# sshtap

sshtap is a simple docker-based utility to build l2 tunnels using ssh connection.


## scheme

```
+-------------------+  ssh connection   +------------------+
| client1 container | ----------------> |                  |
+-------------------+                   | server container |
+-------------------+  ssh connection   |                  |
| client2 container | ----------------> |                  |
+-------------------+                   +------------------+
       ...
```

In each of the container (server or client) a bridge br0 is created and bridges are L2-connected via the ssh connection.

Both, server and client use the same docker image. If it will be run as a server or as a client will be decided according
to environment variables.

**Containers needs to be run in privileged mode to work properly.**

## environment variables

### Server variables:

    - `MODE` set to `server` to run in server mode
    - `AUTHORIZED_KEYS` list of ssh keys authorized to connect to the server container

### Client variables
    - `MODE` set to `client` to run in client mode
    - `PEER` set the peer to connect to in the form of `<host>[:<port>]`. If port is not given, default 22 is assumed
    - `SSH_KEY` the ssh key to be used for connection to the peer
    - `RESET_KNOWN_HOSTS` set to `yes` if you want to reset known hosts on startup, default `no`

## persistent storage

Persistent storage is used to keep:

* permanent ssh host keys on server
* known hosts on client

While it is not necessary mandatory to use persistent storage, it is recommended to use it. Just mount the directory `/persistent` to any
persistent storage and the given data will be kept.
