# source docker helpers
. util/docker.sh

@test "Start Container" {
  start_container "test-single" "192.168.0.2"
}

@test "Configure" {
  # Run Hook
  run run_hook "test-single" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]

  # Verify portal configuration
  run docker exec test-single bash -c "[ -f /etc/portal/config.json ]"
  [ "$status" -eq 0 ]

  # Verify narc configuration
  run docker exec test-single bash -c "[ -f /opt/gomicro/etc/narc.conf ]"
  [ "$status" -eq 0 ]
}

@test "Start" {
  # Run hook
  run run_hook "test-single" "start" "{}"
  [ "$status" -eq 0 ]

  # Verify portal running
  run docker exec test-single bash -c "ps aux | grep [p]ortal"
  [ "$status" -eq 0 ]

  # Verify narc running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 0 ]

  # Verify portal listening
  until run docker exec test-single bash -c "nc -q 1 127.0.0.1 8444 < /dev/null"
  do
    sleep 1
  done
}

@test "Verify Service" {
  # Add a service
  run docker exec test-single bash -c "portal -i -t 123 add-service -O '127.0.0.3' -R 1234 -T 'tcp' -s 'rr' -e 0 -n ''"
  echo $output
  [ "$status" -eq 0 ]

  # Verify service isn't empty
  run docker exec test-single bash -c "portal -i -t 123 show-services"
  echo $output
  [ "$status" -eq 0 ]
  [ ! "$output" = "[]" ]
}

@test "Stop" {
  # Run hook
  run run_hook "test-single" "stop" "{}"
  [ "$status" -eq 0 ]

  # Test the double stop
  run run_hook "test-single" "stop" "{}"
  [ "$status" -eq 0 ]

  # Wait until services shut down
  while docker exec "test-single" bash -c "ps aux | grep [p]ortal"
  do
    sleep 1
  done

  # Verify portal is not running
  run docker exec test-single bash -c "ps aux | grep [p]ortal"
  [ "$status" -eq 1 ]

  # Verify narc is not running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 1 ]
}

@test "Stop Container" {
  stop_container "test-single"
}
