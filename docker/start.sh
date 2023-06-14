#!/bin/bash

ADMIN_SECRET=${ADMIN_SECRET:-janusoverlord}
DEBUG_LEVEL=${DEBUG_LEVEL:-4}
SESSION_TIMEOUT=${SESSION_TIMEOUT:-38}
MIN_NACK_QUEUE=${MIN_NACK_QUEUE:-200}

if [ -z "$NETWORK_INTERFACE" ]; then
    # if NETWORK_INTERFACE is empty then we are on k8s
    NETWORK_INTERFACE=$(ip -br link|grep " UP "|head -1|awk '{print $1}')
    # There is no other way to know the external node ip.
    # See https://github.com/kubernetes/kubernetes/issues/73760
    PUBLIC_IP=$(curl --silent https://ipinfo.io/ip)
    if [ -z "$PUBLIC_IP" ]; then
        echo "Couldn't get the node public ip"
        exit 1
    fi
fi

if [ ! -z "$NETWORK_INTERFACE" ]; then
    sed -i \
        -e "s|#ice_enforce_list =.*|ice_enforce_list = \"${NETWORK_INTERFACE}\"|" \
         /usr/etc/janus/janus.jcfg
fi
if [ ! -z "$PUBLIC_IP" ]; then
#        -e 's|#stun_server =.*|stun_server = "stun1.l.google.com"|' \
#        -e 's|#stun_port =.*|stun_port = 19302|' \
    sed -i \
        -e "s|#nat_1_1_mapping =.*|nat_1_1_mapping = \"${PUBLIC_IP}\"|" \
        -e "s|debug_level =.*|debug_level = \"${DEBUG_LEVEL}\"|" \
        /usr/etc/janus/janus.jcfg
fi
sed -i \
    -e "s|admin_secret =.*|admin_secret = \"${ADMIN_SECRET}\"|" \
    -e "s|#session_timeout = 60|session_timeout = ${SESSION_TIMEOUT}|" \
    -e "s|#min_nack_queue =.*|min_nack_queue = ${MIN_NACK_QUEUE}|" \
    /usr/etc/janus/janus.jcfg


if [ ! -z "$AUTH_KEY" ]; then
    sed -i \
        -e "s|.*auth_key =.*|auth_key = \"${AUTH_KEY}\"|" \
        /usr/etc/janus/janus.plugin.sfu.cfg
fi

if [ ! -z "$EVENT_LOOPS" ]; then
    sed -i \
        -e "s|#event_loops =.*|event_loops = ${EVENT_LOOPS}|" \
        /usr/etc/janus/janus.jcfg
fi

if [ ! -z "$ALLOW_LOOP_INDICATION" ]; then
    sed -i \
        -e "s|#allow_loop_indication =.*|allow_loop_indication = ${ALLOW_LOOP_INDICATION}|" \
        /usr/etc/janus/janus.cfg
fi

MAX_ROOM_SIZE=${MAX_ROOM_SIZE:-30}
MAX_CCU=${MAX_CCU:-1000}
MESSAGE_THREADS=${MESSAGE_THREADS:-0}
sed -i \
    -e "s|max_room_size =.*|max_room_size = ${MAX_ROOM_SIZE}|" \
    -e "s|max_ccu =.*|max_ccu = ${MAX_CCU}|" \
    -e "s|message_threads =.*|message_threads = ${MESSAGE_THREADS}|" \
    /usr/etc/janus/janus.plugin.sfu.cfg

exec "$@"
