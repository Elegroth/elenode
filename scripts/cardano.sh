#!/bin/bash
set -e


## Using the latest links can lead to odd behavior because the newest available build may not be compatible with what is on chain
## It's safer to just lock to a version
## These are the links to the newest available builds
## Cardano: https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux/latest/download/1
## DB-Sync: https://hydra.iohk.io/job/Cardano/cardano-db-sync/cardano-db-sync-linux/latest/download/1

echo -e "\n-= Download latest cardano binares from https://hydra.iohk.io/build/9928700/download/1/cardano-node-1.32.1-linux.tar.gz =-"
mkdir ${INSTALL_HOME}/setup/cardano -p
cd ${INSTALL_HOME}/setup/cardano
curl -L -o cardano.tar.gz https://hydra.iohk.io/build/9928700/download/1/cardano-node-1.32.1-linux.tar.gz
tar -xvf cardano.tar.gz --directory ${NODE_HOME}/scripts --exclude configuration

echo -e "\n-= Download latest cardano-db-sync binares from https://hydra.iohk.io/build/12650290/download/1/cardano-db-sync-12.0.1-linux.tar.gz =-"
curl -L -o cardano-db-sync.tar.gz https://hydra.iohk.io/build/12650290/download/1/cardano-db-sync-12.0.1-linux.tar.gz
tar -xvf cardano-db-sync.tar.gz --directory ${NODE_HOME}/scripts --exclude configuration

echo -e "\n-= Clone cardano-db-sync repository to get latest configuration and schema =-"
git clone https://github.com/input-output-hk/cardano-db-sync.git
cd cardano-db-sync
#git checkout 12.0.0
cp ./config/${NODE_CONFIG}-config.yaml ${NODE_HOME}/config/db-sync-${NODE_CONFIG}-config.yaml
cp ./schema/*.* ${NODE_HOME}/sync/schema
rm -rf ${NODE_HOME}/sync/schema/migration-2-0009-20220207.sql

echo -e "\n-= Download Configuration Files =-"
# NODE_BUILD_NUM=$(curl --silent https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')
DOWNLOAD_URL=https://hydra.iohk.io/build/7654130/download/1

cd ${NODE_HOME}/config
curl -O ${DOWNLOAD_URL}/${NODE_CONFIG}-byron-genesis.json \
  -O ${DOWNLOAD_URL}/${NODE_CONFIG}-topology.json \
  -O ${DOWNLOAD_URL}/${NODE_CONFIG}-shelley-genesis.json \
  -O ${DOWNLOAD_URL}/${NODE_CONFIG}-alonzo-genesis.json \
  -O ${DOWNLOAD_URL}/${NODE_CONFIG}-config.json

echo -e "\n-= Rewriting ${NODE_CONFIG}-config.json =-"
jq ".defaultScribes += [[\"FileSK\"",\"${NODE_HOME}/logs/node/node\"]] ${NODE_CONFIG}-config.json | sponge ${NODE_CONFIG}-config.json
jq ".setupScribes += [{\"scFormat\":\"ScJson\", \"scKind\":\"FileSK\", \"scName\": \"${NODE_HOME}/logs/node/node\", \"scRotation\":null}]" ${NODE_CONFIG}-config.json | sponge ${NODE_CONFIG}-config.json
## Enable block fetch decisions if you want
# jq ".TraceBlockFetchDecisions = true" ${NODE_CONFIG}-config.json | sponge ${NODE_CONFIG}-config.json

echo -e "\n-= Rewriting db-sync-mainnet-config.yaml =-"
yq '.NodeConfigFile = "./mainnet-config.json"' db-sync-${NODE_CONFIG}-config.yaml -y | sponge db-sync-${NODE_CONFIG}-config.yaml
yq ".defaultScribes += [[\"FileSK\"",\"${NODE_HOME}/logs/sync/sync\"]] db-sync-${NODE_CONFIG}-config.yaml -y | sponge db-sync-${NODE_CONFIG}-config.yaml
yq ".setupScribes += [{\"scFormat\":\"ScJson\", \"scKind\":\"FileSK\", \"scName\": \"${NODE_HOME}/logs/sync/sync\", \"scRotation\":null}]" db-sync-${NODE_CONFIG}-config.yaml -y | sponge db-sync-${NODE_CONFIG}-config.yaml

echo -e "\n-= Create Relay Startup Script =-"
envsubst '${NODE_HOME}' < ${INSTALL_HOME}/setup/scripts/start-relay.sh > ${INSTALL_HOME}/setup/scripts/start-relay.tmp
mv ${INSTALL_HOME}/setup/scripts/start-relay.tmp ${NODE_HOME}/scripts/start-relay.sh
cat ${NODE_HOME}/scripts/start-relay.sh

echo -e "\n-= Create Db-Sync Startup Script =-"
envsubst '${NODE_HOME}' < ${INSTALL_HOME}/setup/scripts/start-db-sync.sh > ${INSTALL_HOME}/setup/scripts/start-db-sync.tmp
mv ${INSTALL_HOME}/setup/scripts/start-db-sync.tmp ${NODE_HOME}/scripts/start-db-sync.sh
cat ${NODE_HOME}/scripts/start-db-sync.sh

echo -e "\n-= Mark ${NODE_HOME}/scripts/*.sh as executable =-"
chmod -R +x ${NODE_HOME}/scripts/*.sh

echo -e "\n-= Symlinking scripts in ${NODE_HOME}/scripts/ =-"
sudo ln -sfL ${NODE_HOME}/scripts/* /usr/local/bin/

echo -e "\n-= Check Cardano is working =-"
cardano-cli version
cardano-node version