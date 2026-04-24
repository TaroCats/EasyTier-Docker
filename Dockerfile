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

# Use build arguments to pass binaries from host (GitHub Action)
ARG TARGETARCH
ARG TARGETVARIANT

# Copy pre-downloaded binaries based on architecture
# Expected structure in build context:
# dist/amd64/easytier-core ...
# dist/arm64/easytier-core ...
# dist/armv7/easytier-core ...
COPY dist/${TARGETARCH}${TARGETVARIANT}/* /usr/local/bin/
RUN chmod +x /usr/local/bin/easytier-core /usr/local/bin/easytier-cli /usr/local/bin/easytier-web-embed || true

# Expose ports
# Core listener (default 11010)
EXPOSE 11010/tcp 11010/udp
# Web API
EXPOSE 11211/tcp
# Web Config Portal (used internally by default, but exposed if needed)
EXPOSE 22020/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
