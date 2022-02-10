#!/bin/bash
set -e

. ${NODE_HOME}/scripts/.env

PGPASSFILE=${NODE_HOME}/config/pgpass-mainnet ${NODE_HOME}/scripts/cardano-db-sync \
  --config ${NODE_HOME}/config/db-sync-${NODE_CONFIG}-config.yaml \
  --socket-path ${CARDANO_NODE_SOCKET_PATH} \
  --state-dir ${NODE_HOME}/sync/ledger-state/mainnet \
  --schema-dir ${NODE_HOME}/sync/schema