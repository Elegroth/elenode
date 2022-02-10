## Install Cardobot
mkdir -p ~/.ssh/
touch ~/.ssh/authorized_keys
sudo chmod 700 ~/.ssh/authorized_keys

echo -e "\nalias cardocheck='cardano-cli query tip --mainnet'" >> ~/.bash_profile

ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
cd ~/
ls -lah
git clone https://github.com/Elegroth/cardobot.git
cd ./cardobot
./INSTALL