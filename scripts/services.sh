## we use envsubst as non-sudo because the proper envvars are already loaded in the ec2-user profile
#!/bin/bash
set -e

echo -e "\n-= Create Relay Service =-"
envsubst < ${INSTALL_HOME}/setup/services/cardano-relay.service > ${INSTALL_HOME}/setup/services/cardano-relay.tmp
sudo mv ${INSTALL_HOME}/setup/services/cardano-relay.tmp /lib/systemd/system/cardano-relay.service
sudo chmod 644 /lib/systemd/system/cardano-relay.service