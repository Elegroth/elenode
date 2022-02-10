#!/bin/bash
set -e

echo -e "\n-= Make ${USERNAME} owner of ${NODE_HOME} directory =-"
sudo chown -R ${USERNAME} ${NODE_HOME}

echo -e "\n-= Delete installation files in ${INSTALL_HOME}/setup =-"
sudo rm -rf /home/ec2-user/setup