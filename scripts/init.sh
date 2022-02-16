#!/bin/bash
set -e

echo -e "\n-= Update existing packages =-"
yum install sudo coreutils -y
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum update -y
sudo yum install -y jq moreutils git python3 passwd gettext tar ssh bc which socat cronie awscli s3fs-fuse nfs-utils postgresql wget
sudo -H pip3 install yq 

echo -e "\n-= Create ${USERNAME} user account"
sudo adduser ${USERNAME} -m -s /bin/bash
sudo passwd -d ${USERNAME}

echo -e "\n-= Create ${NODE_HOME} directory =-"
sudo mkdir ${NODE_HOME} -p

echo -e "\n-= Create ${NODE_HOME} subdirectories =-"
mkdir ${NODE_HOME}/scripts -p
mkdir ${NODE_HOME}/snapshots -p
mkdir ${NODE_HOME}/keys -p
mkdir ${NODE_HOME}/config -p
mkdir ${NODE_HOME}/db -p
mkdir ${NODE_HOME}/ipc -p
mkdir ${NODE_HOME}/logs -p
mkdir ${NODE_HOME}/sync/schema -p

echo -e "\n-= Create dummy PGPASS file =-"
cp ${INSTALL_HOME}/setup/config/pgpass-mainnet ${NODE_HOME}/config/pgpass-mainnet
chmod 600 ${NODE_HOME}/config/pgpass-mainnet

echo -e "\n-= Create submit api config file =-"
cp ${INSTALL_HOME}/setup/config/tx-submit-mainnet-config.yaml ${NODE_HOME}/config/tx-submit-mainnet-config.yaml
chmod 600 ${NODE_HOME}/config/tx-submit-mainnet-config.yaml

echo -e "\n-= Create .env Script =-"
envsubst '${NODE_HOME} ${NODE_CONFIG}' < ${INSTALL_HOME}/setup/scripts/.env > ${NODE_HOME}/scripts/.env.tmp
mv ${NODE_HOME}/scripts/.env.tmp ${NODE_HOME}/scripts/.env
chmod +x ${NODE_HOME}/scripts/.env