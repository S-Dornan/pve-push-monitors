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
FROM ghcr.io/s-dornan/pve-prod-base@sha256:689a7bf8c16d42b63ed3c5ea13d45f5acf06a6581e825c005bb54c673d5fce87

# Add path to BusyBox
ENV PATH="/usr/bin:/bin:/busybox"

# Copy the AGPL-licensed script into the container and make it executable
COPY --chmod=755 monitor.sh /bin/monitor.sh

# Lock the container into running this specific script via the Distroless shell
ENTRYPOINT ["/busybox/sh", "/bin/monitor.sh"]