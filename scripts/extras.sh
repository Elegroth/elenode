#!/bin/bash
set -e

echo -e "\n-= Install Google Authentication =-"
echo -e "-= (This needs to be manually setup once you start a server with this image) =-"
sudo yum -y install google-authenticator qrencode openssl openssh-server initscripts

echo -e "\n-= Setup MOTD =-"
sudo sh -c 'cat <<EOF > /etc/update-motd.d/30-banner
#!/bin/bash
echo "
  ______ _____ ___                                                              
 |  ____/ ____|__ \                                                             
 | |__ | |       ) |                                                            
 |  __|| |      / /  Amazon Linux 2 AMI                                                           
 | |___| |____ / /_                                                             
 |______\_____|____|___  _____          _   _  ____                __  __ _____ 
  / ____|   /\   |  __ \|  __ \   /\   | \ | |/ __ \         /\   |  \/  |_   _|
 | |       /  \  | |__) | |  | | /  \  |  \| | |  | |______ /  \  | \  / | | |  
 | |      / /\ \ |  _  /| |  | |/ /\ \ |     | |  | |______/ /\ \ | |\/| | | |  
 | |____ / ____ \| | \ \| |__| / ____ \| |\  | |__| |     / ____ \| |  | |_| |_ 
  \_____/_/    \_\_|  \_\_____/_/    \_\_| \_|\____/     /_/    \_\_|  |_|_____|
                      
EOF'

## Setup default user
mkdir -p ~/.ssh/

if [[ -z `ls ~/.ssh/authorized_keys` ]]; then
    touch ~/.ssh/authorized_keys
    chmod 700 ~/.ssh/authorized_keys
fi

cat ~/.ssh/authorized_keys

## Setup new admin
useradd --create-home -p $(openssl passwd -1 temppass123) -g root -G cardano admin
usermod --lock admin

echo -e "admin  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo -e "cardano  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ls -lah /usr/sbin

cat /etc/ssh/sshd_config

sed -i 's^PasswordAuthentication yes^PasswordAuthentication no^g' /etc/ssh/sshd_config
sed -i 's^#ClientAliveInterval 0^ClientAliveInterval 300^g' /etc/ssh/sshd_config

touch /root/.bash_profile
echo "export CARDANO_NODE_SOCKET_PATH=/cardano/ipc/node.socket" >> /root/.bash_profile
echo "export CARDANO_NODE_SOCKET_PATH=/cardano/ipc/node.socket" >> /home/admin/.bash_profile

mkdir /root/.cardobot

echo "export CARDO_HOME=/root/.cardobot" >> /root/.bash_profile
echo "alias cardoupdate='cd /home/admin/cardobot && git pull && rm -rf /usr/bin/cardobot && ./INSTALL && cd ~/'" >> /root/.bash_profile
echo "alias cardocheck='cardano-cli query tip --mainnet'" >> /root/.bash_profile

sudo ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
sudo ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
sudo ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key

chmod 600 /etc/ssh/ssh_host*
