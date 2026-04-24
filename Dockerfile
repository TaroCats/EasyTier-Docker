FROM debian:stable-slim

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    cron \
    tzdata \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Set Timezone to China
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Prepare directories
RUN mkdir -p /opt/easytier /var/log/easytier

# Copy scripts
COPY update.sh /usr/local/bin/update.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/update.sh /usr/local/bin/entrypoint.sh

# Initial installation of EasyTier binaries
# This will use the logic in update.sh to fetch the latest version during build
RUN /usr/local/bin/update.sh

# Expose ports
# Core listener (default 11010)
EXPOSE 11010/tcp 11010/udp
# Web API
EXPOSE 11211/tcp
# Web Config Portal (used internally by default, but exposed if needed)
EXPOSE 22020/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
