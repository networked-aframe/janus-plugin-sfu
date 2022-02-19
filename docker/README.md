# Deployment with a docker image

If you previously installed janus on the host with systemd, stop it and disable it:

```
systemctl stop janus
systemctl disable janus
```

Be aware that ports 7088 (admin http with default janusoverlord password) and 8188 (ws) are exposed to the host network interface.
So be sure to change the password and configure your instance security group properly to not have access to
those ports externally and configure traefik or nginx for example in front that handle the TLS termination.

Those environment variables with default values are available:

```
ADMIN_SECRET=janusoverlord
DEBUG_LEVEL=4
SESSION_TIMEOUT=38
MAX_ROOM_SIZE=30
MAX_CCU=1000
MESSAGE_THREADS=0
```

The default values are defined at the beginning of the `start.sh` script.

## Using docker

create the docker image:

```
cd janus-docker
docker build --pull -t janus:latest .
```

If you previously built the image and want to rebuild with latest janus-plugin-sfu, be sure to increment the
version in Dockerfile for the janus-plugin-sfu RUN command to invalidate the cache of this layer
or add `--no-cache` option when building the image:

```
docker build --pull --no-cache -t janus:latest .
```

start the container:

```
docker run -d --restart always --net=host --name="janus" -e MAX_ROOM_SIZE=15 -e ADMIN_SECRET=YourOwnPassword janus:latest
```

If you secure the rooms with JWT, specify the public key like this:

```
docker run -d --restart always --net=host --name="janus" -e MAX_ROOM_SIZE=15 -e ADMIN_SECRET=YourOwnPassword -e AUTH_KEY=/keys/public.der -v $PWD/public.der:/keys/public.der:ro janus:latest
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

## Using docker-compose

create the docker image:

```
docker-compose build --pull
```

or

```
docker-compose build --pull --no-cache
```

to rebuild with latest janus-plugin-sfu changes.

configure environment variables in `.env`, example:

```
ADMIN_SECRET=YourOwnPassword
MAX_ROOM_SIZE=15
```

start the container:

```
docker-compose up -d
```

If you secure the rooms with JWT, uncomment the AUTH_KEY variable and volume in `docker-compose.yml`.

look at the logs:

```
docker-compose logs -f
```

stop and remove the container:

```
docker-compose down
```
