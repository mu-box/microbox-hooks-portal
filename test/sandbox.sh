#!/bin/bash
#
# Launch a container and console into it

test_dir="$(dirname $(readlink -f $BASH_SOURCE))"
payload_dir="$(readlink -f ${test_dir}/payloads)"
hookit_dir="$(readlink -f ${test_dir}/../src)"

docker run \
  --name=test-console \
  -d \
  --privileged \
  --net=microbox \
  --ip=192.168.0.55 \
  --volume=${hookit_dir}/:/opt/microbox/hooks \
  --volume=${payload_dir}/:/payloads \
  mubox/portal

docker exec -it test-console bash

docker stop test-console
docker rm test-console
