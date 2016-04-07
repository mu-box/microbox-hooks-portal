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
  run run_hook "test-migrate-old" "start" "$(payload start)"
  [ "$status" -eq 0 ]
}

@test "Insert Service Data" {
  run docker exec "test-migrate-old" bash -c "portal -t 123 -P 8444 add-service -O '127.0.0.3' -R 1234 -T 'tcp' -s 'rr' -e 0 -n ''"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Start New Container" {
  start_container "test-migrate-new" "192.168.0.4"
}

@test "Configure New Portal" {
  run run_hook "test-migrate-new" "configure" "$(payload configure-new)"
  [ "$status" -eq 0 ]
}

@test "Prepare New Import" {
  run run_hook "test-migrate-new" "import-prep" "$(payload import-prep)"
  [ "$status" -eq 0 ]
}

@test "Export Live Data" {
  run run_hook "test-migrate-old" "export-live" "$(payload export-live)"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Stop Old Portal Service" {
  run run_hook "test-migrate-old" "stop" "$(payload stop)"
  [ "$status" -eq 0 ]
}

@test "Export Final Data" {
  run run_hook "test-migrate-old" "export-final" "$(payload export-final)"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Clean After Import" {
  run run_hook "test-migrate-new" "import-clean" "$(payload import-clean)"
  [ "$status" -eq 0 ]
}

@test "Start New Portal Service" {
  run run_hook "test-migrate-new" "start" "$(payload start)"
  [ "$status" -eq 0 ]
}

@test "Verify Data Transfered" {
  run docker exec "test-migrate-new" bash -c "portal -t 123 -P 8444 show-services"
  [ "$status" -eq 0 ]
  echo "$output"
  [ "$output" = "[{\"id\":\"tcp-127_0_0_3-1234\",\"host\":\"127.0.0.3\",\"port\":1234,\"type\":\"tcp\",\"scheduler\":\"rr\",\"persistence\":0,\"netmask\":\"\"},{\"id\":\"tcp-192_168_0_2-8443\",\"host\":\"192.168.0.2\",\"interface\":\"eth0\",\"port\":8443,\"type\":\"tcp\",\"scheduler\":\"rr\",\"persistence\":0,\"netmask\":\"\",\"servers\":[{\"id\":\"127_0_0_1-8444\",\"host\":\"127.0.0.1\",\"port\":8444,\"forwarder\":\"m\",\"weight\":5,\"upper_threshold\":0,\"lower_threshold\":0}]}]" ]
}

@test "Stop Old Container" {
  stop_container "test-migrate-old"
}

@test "Stop New Container" {
  stop_container "test-migrate-new"
}
