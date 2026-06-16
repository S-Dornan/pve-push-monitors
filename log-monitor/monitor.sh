#!/busybox/sh

# Copyright (C) 2026 Sam Dornan
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

RUN_ONCE="${RUN_ONCE:-false}"
PUSH_INTERVAL="${PUSH_INTERVAL:-60}"
MONITOR_TYPE="${MONITOR_TYPE:-health}"
LOG_FILE="${LOG_FILE:-/var/log/experiment.log}"

PREVIOUS_SIZE=0

while true; do
  if [ "$MONITOR_TYPE" = "stream" ]; then
    CURRENT_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    
    if [ "$CURRENT_SIZE" != "$PREVIOUS_SIZE" ] && [ "$CURRENT_SIZE" -gt 0 ]; then
      STATE="down"
      MSG="Experiment_Active"
    else
      STATE="up"
      MSG="Idle"
    fi
    PREVIOUS_SIZE=$CURRENT_SIZE
  else
    STATE="up"
    MSG="Online"
  fi

  curl -s -H "Connection: close" \
        -H "Alert-Powered-By: PVE-Architecture" \
        -H "Copyright: Copyright (c) 2026 Sam Dornan" \
        -H "Source-Available: https://github.com/S-Dornan/pve-push-monitor" \
        -H "License-URI: https://www.gnu.org/licenses/agpl-3.0.html" \
        -H "CF-Access-Client-Id: ${CF_CLIENT_ID}" \
        -H "CF-Access-Client-Secret: ${CF_CLIENT_SECRET}" \
        "${PUSH_URL}?status=${STATE}&msg=${MSG}&ping="

  if [ "$RUN_ONCE" = "true" ]; then
    break
  fi
  
  sleep ${PUSH_INTERVAL}
done