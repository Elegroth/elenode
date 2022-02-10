#!/bin/bash
set -e

. ${NODE_HOME}/scripts/.env

/usr/local/bin/cardano-node run \
  --topology ${NODE_HOME}/config/${NODE_CONFIG}-topology.json \
  --database-path ${CARDANO_DB_PATH} \
  --socket-path ${CARDANO_NODE_SOCKET_PATH} \
  --host-addr 0.0.0.0 \
  --port ${NODE_PORT} \
  --config ${NODE_HOME}/config/${NODE_CONFIG}-config.json