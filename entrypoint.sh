#!/bin/bash

# EasyTier Entrypoint Script

# 1. Setup Cron for Auto-update at 3:00 AM
# Export environment variables for cron
printenv | grep -E '^(GH_TOKEN|TZ|PATH)=' > /etc/environment

echo "0 3 * * * . /etc/environment; /usr/local/bin/update.sh >> /var/log/easytier_update.log 2>&1" > /etc/cron.d/easytier-update
chmod 0644 /etc/cron.d/easytier-update
crontab /etc/cron.d/easytier-update
cron

# 2. Setup Working Directory
echo "Setting up working directory..."
mkdir -p /opt/easytier
cd /opt/easytier

# 3. Function to start core
start_core() {
    echo "Starting EasyTier Core..."
    if [ -n "$ET_WEB" ]; then
        easytier-core -w "$ET_WEB" &
    else
        easytier-core -w udp://127.0.0.1:22020/taro &
    fi
    CORE_PID=$!
}

# 4. Function to start web
start_web() {
    echo "Starting EasyTier Web Embed..."
    easytier-web-embed \
        --api-server-port 11211 \
        --api-host "http://127.0.0.1:11211" \
        --config-server-port 22020 \
        --config-server-protocol udp &
    WEB_PID=$!
}

# Initial start
start_core
if [ -z "$ET_WEB" ]; then
    start_web
fi

# Monitor processes
while true; do
    if ! kill -0 $CORE_PID > /dev/null 2>&1; then
        echo "EasyTier Core stopped. Restarting..."
        start_core
    fi
    if [ -z "$ET_WEB" ]; then
        if ! kill -0 $WEB_PID > /dev/null 2>&1; then
            echo "EasyTier Web stopped. Restarting..."
            start_web
        fi
    fi
    sleep 10
done
