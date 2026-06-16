#!/usr/bin/env bats

# Copyright (C) 2026 Sam Dornan
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# monitor.bats

setup() {
  # 1. Create a temporary directory for our mock binaries
  export MOCK_DIR="$(mktemp -d)"
  
  # 2. Prepend our mock directory to the PATH
  export PATH="${MOCK_DIR}:${PATH}"

  # 3. Setup dummy environment variables required by the script
  export CF_CLIENT_ID="dummy_id"
  export CF_CLIENT_SECRET="dummy_secret"
  export PUSH_URL="http://dummy-kuma.local/api/push"
  export PUSH_INTERVAL="1"
  
  # 4. Use the internal flag to ensure the test doesn't loop forever
  export RUN_ONCE="true"

  # 5. Point to a temporary log file for our stream size tests
  export LOG_FILE="${MOCK_DIR}/experiment-telemetry.log"

  # 6. Mock 'curl' to log its arguments to a file so we can inspect them
  export CURL_LOG="${MOCK_DIR}/curl.log"
  echo '#!/bin/sh' > "${MOCK_DIR}/curl"
  echo 'echo "$@" > "${CURL_LOG}"' >> "${MOCK_DIR}/curl"
  chmod +x "${MOCK_DIR}/curl"

  # 7. Mock 'sleep' just in case RUN_ONCE fails (safety net)
  echo '#!/bin/sh' > "${MOCK_DIR}/sleep"
  echo 'exit 0' >> "${MOCK_DIR}/sleep"
  chmod +x "${MOCK_DIR}/sleep"
}

teardown() {
  # Clean up the temporary directory after each test
  rm -rf "${MOCK_DIR}"
}

@test "Health Monitor: Reports Up/Online by default" {
  export MONITOR_TYPE="health"
  run ./monitor.sh

  # Assert the script exited successfully
  [ "$status" -eq 0 ]
  [ -f "${CURL_LOG}" ]

  # Verify the payload defaults to standard health metrics
  run grep -q "status=up" "${CURL_LOG}"
  [ "$status" -eq 0 ]
  
  run grep -q "msg=Online" "${CURL_LOG}"
  [ "$status" -eq 0 ]
}

@test "Stream Monitor: Reports Up/Idle when telemetry file is missing or empty" {
  export MONITOR_TYPE="stream"
  
  # We deliberately DO NOT create the log file here to test the fallback '|| echo 0' logic
  run ./monitor.sh

  [ "$status" -eq 0 ]
  [ -f "${CURL_LOG}" ]

  # Verify it registers as idle
  run grep -q "status=up" "${CURL_LOG}"
  [ "$status" -eq 0 ]
  
  run grep -q "msg=Idle" "${CURL_LOG}"
  [ "$status" -eq 0 ]
}

@test "Stream Monitor: Reports Down/Experiment_Active when telemetry file has data" {
  export MONITOR_TYPE="stream"
  
  # Mock an active data stream by writing dummy bytes into the target file
  echo "fuzzer_data_stream_active" > "${LOG_FILE}"
  
  run ./monitor.sh

  [ "$status" -eq 0 ]
  [ -f "${CURL_LOG}" ]

  # Since PREVIOUS_SIZE=0, any existing data > 0 bytes should immediately trip the alert
  run grep -q "status=down" "${CURL_LOG}"
  [ "$status" -eq 0 ]
  
  run grep -q "msg=Experiment_Active" "${CURL_LOG}"
  [ "$status" -eq 0 ]
}