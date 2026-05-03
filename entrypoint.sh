#!/bin/bash
###
 # @Author: taro etsy@live.com
 # @LastEditors: taro etsy@live.com
 # @LastEditTime: 2026-04-27 16:37:43
 # @Description: 
### 

# EasyTier Entrypoint Script

# 1. Setup Cron for Auto-update at 3:00 AM
# Export environment variables for cron
printenv | grep -E '^(GH_TOKEN|TZ|PATH|VER_API)=' > /etc/environment

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
    
    # 构建基础参数
    local ET_ARGS=()
    
    # 处理 Web 参数
    ET_ARGS+=("-w" "${ET_WEB:-udp://127.0.0.1:22020/${WEB_USER:-admin}}")
    # 处理 Machine ID 参数
    [ -n "$ET_MACHINE_ID" ] && ET_ARGS+=("--machine-id" "$ET_MACHINE_ID")
    
    easytier-core "${ET_ARGS[@]}" &
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
    if ! kill -0 "$CORE_PID" > /dev/null 2>&1; then
        echo "EasyTier Core stopped. Restarting..."
        start_core
    fi
    if [ -z "$ET_WEB" ]; then
        if ! kill -0 "$WEB_PID" > /dev/null 2>&1; then
            echo "EasyTier Web stopped. Restarting..."
            start_web
        fi
    fi
    sleep 10
done
