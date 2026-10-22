# Copyright (C) 2026 Sam Dornan
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# ==========================================
# STAGE 1: TESTING
# ==========================================
FROM debian:13 AS tester

RUN apt-get update && \
    apt-get install -y bats && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY monitor.sh .
COPY monitor.bats .
RUN chmod +x monitor.sh

RUN bats monitor.bats

# ==========================================
# STAGE 2: PRODUCTION
# ==========================================
# Pulling the mathematically verified, minimal base you just built
FROM ghcr.io/s-dornan/pve-prod-base@sha256:43714d70d81446deb73e6dfd5846c7fea62306686d9e63a88b0fc64e5f1d35db

# Add path to BusyBox
ENV PATH="/usr/bin:/bin:/busybox"

# Copy the AGPL-licensed script into the container and make it executable
COPY --chmod=755 monitor.sh /bin/monitor.sh

# Lock the container into running this specific script via the Distroless shell
ENTRYPOINT ["/busybox/sh", "/bin/monitor.sh"]