#!/bin/bash
###
 # @Author: taro etsy@live.com
 # @LastEditors: taro etsy@live.com
 # @LastEditTime: 2026-05-06 08:52:13
 # @Description: 
### 

# EasyTier Log Cleanup Script
LOG_DIR="/opt/easytier"

echo "$(date): Starting log cleanup in $LOG_DIR"

# 1. Delete rotated log files like .log.1, .log.2, etc.
# Using regex to match .log followed by digits
find "$LOG_DIR" -type f -regex ".*\.log\.[0-9]+" -delete

# 2. Truncate .log files to last 100 lines
for log_file in "$LOG_DIR"/*.log; do
    if [ -f "$log_file" ]; then
        echo "Truncating $log_file to 100 lines"
        # Use a temporary file to safely truncate
        tail -n 100 "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"
    fi
done

echo "$(date): Log cleanup finished"
