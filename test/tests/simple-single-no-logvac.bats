# source docker helpers
. util/docker.sh

@test "Start Container" {
  start_container "simple-single-no-logvac" "192.168.0.2"
}

@test "Configure" {
  # Run Hook
  run run_hook "simple-single-no-logvac" "configure" "$(payload configure-no-logvac)"
  [ "$status" -eq 0 ]

  # Verify portal configuration
  run docker exec simple-single-no-logvac bash -c "[ -f /etc/portal/config.json ]"
  [ "$status" -eq 0 ]

  # Verify narc configuration
  run docker exec simple-single-no-logvac bash -c "[ -f /opt/gomicro/etc/narc.conf ]"
  [ "$status" -eq 1 ]
}

@test "Start" {
  # Run hook
  run run_hook "simple-single-no-logvac" "start" "{}"
  [ "$status" -eq 0 ]

  # Verify portal running
  run docker exec simple-single-no-logvac bash -c "ps aux | grep [p]ortal"
  [ "$status" -eq 0 ]

  # Verify narc running
  run docker exec simple-single-no-logvac bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 1 ]

  # Verify portal listening
  until run docker exec simple-single-no-logvac bash -c "nc -q 1 127.0.0.1 8444 < /dev/null"
  do
    sleep 1
  done
}

@test "Verify Service" {
  # Add a service
  run docker exec simple-single-no-logvac bash -c "portal -i -t 123 add-service -O '127.0.0.3' -R 1234 -T 'tcp' -s 'rr' -e 0 -n ''"
  echo $output
  [ "$status" -eq 0 ]

  # Verify service isn't empty
  run docker exec simple-single-no-logvac bash -c "portal -i -t 123 show-services"
  echo $output
  [ "$status" -eq 0 ]
  [ ! "$output" = "[]" ]
}

@test "Stop" {
  # Run hook
  run run_hook "simple-single-no-logvac" "stop" "{}"
  [ "$status" -eq 0 ]

  # Test the double stop
  run run_hook "simple-single-no-logvac" "stop" "{}"
  [ "$status" -eq 0 ]

  # Wait until services shut down
  while docker exec "simple-single-no-logvac" bash -c "ps aux | grep [p]ortal"
  do
    sleep 1
  done

  # Verify portal is not running
  run docker exec simple-single-no-logvac bash -c "ps aux | grep [p]ortal"
  [ "$status" -eq 1 ]

  # Verify narc is not running
  run docker exec simple-single-no-logvac bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 1 ]
}

@test "Stop Container" {
  stop_container "simple-single-no-logvac"
}
