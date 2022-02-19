If you previously installed janus on the host with systemd, stop it and disable it:

```
systemctl stop janus
systemctl disable janus
```

create the docker image:

```
cd janus-docker
docker build --pull -t janus:latest .
```

start the container:

```
docker run -d --restart always --net=host --name="janus" janus:latest
```

Be aware that ports 7088 (admin http) and 8188 (ws) are exposed to the host network interface.
So be sure to configure your instance security group properly to not have access to
those ports externally and configure traefik or nginx for example in front that
handle the TLS termination.

Those environment variables with default values are available:

```
ADMIN_SECRET=janusoverlord
DEBUG_LEVEL=4
SESSION_TIMEOUT=38
MAX_ROOM_SIZE=30
MAX_CCU=1000
MESSAGE_THREADS=0
```

For example to limit rooms to 15 users:

```
docker run -d --restart always --net=host --name="janus" -e MAX_ROOM_SIZE=15 -e ADMIN_SECRET=YourOwnPassword janus:latest
```

If you secure the rooms with JWT, specify the public key like this:

```
-e AUTH_KEY=/keys/public.der -v ./public.der:/keys/public.der:ro
```

so:

```
docker run -d --restart always --net=host --name="janus" -e MAX_ROOM_SIZE=15 -e ADMIN_SECRET=YourOwnPassword -e AUTH_KEY=/keys/public.der -v ./public.der:/keys/public.der:ro janus:latest
```

look at the logs:

```
docker logs -f janus
```

stop and remove the container:

```
docker stop janus
docker rm janus
```
