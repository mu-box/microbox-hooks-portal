# source docker helpers
. util/docker.sh

@test "Start Old Container" {
  start_container "test-migrate-old" "192.168.0.2"
}

@test "Configure Old Portal" {
  # Run Hook
  run run_hook "test-migrate-old" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]
}

@test "Start Portal On Old" {
  run run_hook "test-migrate-old" "start" "{}"
  [ "$status" -eq 0 ]
}

@test "Insert Service Data" {
  run docker exec "test-migrate-old" bash -c "portal -t 123 add-service -O '127.0.0.3' -R 1234 -T 'tcp' -s 'rr' -e 0 -n ''"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Start New Container" {
  start_container "test-migrate-new" "192.168.0.3"
}

@test "Configure New Portal" {
  run run_hook "test-migrate-new" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]
}

@test "Prepare New Import" {
  run run_hook "test-migrate-new" "import-prep" "{}"
  [ "$status" -eq 0 ]
}

@test "Export Live Data" {
  run run_hook "test-migrate-old" "export-live" "$(payload export-live)"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Stop Old Portal Service" {
  run run_hook "test-migrate-old" "stop" "{}"
  [ "$status" -eq 0 ]
}

@test "Export Final Data" {
  run run_hook "test-migrate-old" "export-final" "$(payload export-final)"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Clean After Import" {
  run run_hook "test-migrate-new" "import-clean" "{}"
  [ "$status" -eq 0 ]
}

@test "Start New Portal Service" {
  run run_hook "test-migrate-new" "start" "{}"
  [ "$status" -eq 0 ]
}

@test "Verify Data Transfered" {
  run docker exec "test-migrate-new" bash -c "portal -t 123 show-services"
  [ "$status" -eq 0 ]
  echo "$output"
  [ "$output" = "[{\"id\":\"tcp-127_0_0_3-1234\",\"host\":\"127.0.0.3\",\"port\":1234,\"type\":\"tcp\",\"scheduler\":\"rr\",\"persistence\":0,\"netmask\":\"\"}]" ]
}

@test "Stop Old Container" {
  stop_container "test-migrate-old"
}

@test "Stop New Container" {
  stop_container "test-migrate-new"
}
