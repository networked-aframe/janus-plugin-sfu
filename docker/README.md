# Deployment with a docker image

This Dockerfile is based on the instructions of the
[Janus deployment on Ubuntu 20.04](https://github.com/networked-aframe/naf-janus-adapter/blob/master/docs/janus-deployment.md)
documentation in naf-janus-adapter repository. The janus-gateway version and
janus-plugin-sfu version used may slightly diverge though.

You can follow the steps in the above documentation to install a server, then
instead of following the "Build it", "Configure it" and "Start janus as a
service", use the docker image described below.

If you previously installed janus on the host with systemd, stop it and disable it:

```
systemctl stop janus
systemctl disable janus
```

Be aware that ports 7088 (admin http with default janusoverlord password) and 8188 (ws) are exposed to the host network interface.
So be sure to change the password and configure your instance security group properly to not have access to
those ports externally and configure nginx in front that handle the TLS termination.

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

[naf-janus-adapter 3.1.0](https://github.com/networked-aframe/naf-janus-adapter/releases/tag/v3.1.0) allows to specify the number of event loops you configured janus (generally the number of CPU you have on the server) and it will use the same event loop (thread) for the janus handle (RTCPeerConnection) when participants subscribe to a publisher, so the broadcasting of packets is on the same thread and avoid cpu context switching, this gives better CPU usage on a room with 30 users sending data/audio/video. See the [original janus PR that introduced these options](https://github.com/meetecho/janus-gateway/pull/2450) if you're curious.
In order to take advantage of this perf boost, you can set the following environment variables:

```
EVENT_LOOPS=8
ALLOW_LOOP_INDICATION=true
```

Here 8 in the number of cpus on the server.
You need to specify the same value with `adapter.setEventLoops(8)` when using naf-janus-adapter. Here is the relevant part (mic handling excluded):

```js
function genClientId() {
  return String(crypto.getRandomValues(new Uint32Array(1))[0]);
}
document.addEventListener("DOMContentLoaded", () => {
  const scene = document.querySelector("a-scene");
  scene.addEventListener("adapter-ready", ({ detail: adapter }) => {
    const clientId = genClientId();
    adapter.setClientId(clientId);
    adapter.setEventLoops(8);
    // ...
  });
});
```

The naf adapter is using `loop_index = parseInt(clientId) % loops` (only if you called `setEventLoops`) to set the
the loop index (0 to 7) to use for a publisher WebRTC connection and all their subscribers WebRTC connection.
The `clientId` generation is important here to have the users well distributed among the available loops.
The above `genClientId` function worked well enough in our tests.

## Installing docker

see https://docs.docker.com/engine/install/ubuntu/

## Using docker

create the docker image:

```
cd docker
docker build --pull -t janus:latest .
```

If you previously built the image and want to rebuild with latest janus-plugin-sfu,
in the Dockerfile on the RUN janus-plugin-sfu line be sure to increment the version
in the echo command so the layer cache of the RUN command is invalidated. This
is a trick so the rebuild is quicker if the base image didn't change.
Or simply add `--no-cache` option when building the image but it takes more time to
rebuild like it was the first time:

```
docker build --pull --no-cache -t janus:latest .
```

start the container:

```
docker run -d --restart unless-stopped --net=host --name="janus" -e MAX_ROOM_SIZE=15 -e ADMIN_SECRET=YourOwnPassword janus:latest
```

If you secure the rooms with JWT, specify the public key like this:

```
docker run -d --restart unless-stopped --net=host --name="janus" -e MAX_ROOM_SIZE=15 -e ADMIN_SECRET=YourOwnPassword -e AUTH_KEY=/keys/public.der -v $PWD/public.der:/keys/public.der:ro janus:latest
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

## Using docker compose

create the docker image:

```
docker compose build --pull
```

or

```
docker compose build --pull --no-cache
```

to rebuild with latest janus-plugin-sfu changes.

configure environment variables in `.env`, example:

```
ADMIN_SECRET=YourOwnPassword
MAX_ROOM_SIZE=15
```

start the container:

```
docker compose up -d
```

If you secure the rooms with JWT, uncomment the AUTH_KEY variable and volume in `docker-compose.yml`.

look at the logs:

```
docker compose logs -f
```

stop and remove the container:

```
docker compose down
```
