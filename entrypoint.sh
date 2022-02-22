#!/bin/bash

chmod 600 -R /etc/ssh/

export CARDANO_NODE_SOCKET_PATH='/cardano/ipc/node.socket'

if [[ ! -z `ls /cardano/db/ledger/*` ]]; then
    FIRST_RUN=false
else
    FIRST_RUN=true
fi

if [[ ! $FIRST_RUN == 'false' ]]; then

    touch /var/log/cron.log
    touch /var/log/sshd.log
    touch /var/log/socat.log

    echo "$ROOT_SSH_KEY" >> /root/.ssh/authorized_keys
    echo "$ROOT_SSH_KEY" >> /home/admin/.ssh/authorized_keys
    echo "$ADMIN_SSH_KEY" >> /home/admin/.ssh/authorized_keys

    cat /home/admin/.ssh/authorized_keys
    cat /root/.ssh/authorized_keys

    echo "*/5 * * * * source /root/.bash_profile && chmod 777 $CARDANO_NODE_SOCKET_PATH &>>/var/log/cron.log" > /var/spool/cron/root

    nohup /usr/sbin/sshd -D -o ListenAddress=0.0.0.0 -p 22 >>/var/log/sshd.log 2>&1 &

    if [[ ! $ONLY_DB_SYNC == 'true' ]]; then
        nohup crond >>/var/log/cron.log 2>&1 &
        nohup socat TCP-LISTEN:3333,fork,reuseaddr, UNIX-CONNECT:$CARDANO_NODE_SOCKET_PATH >>/var/log/socat.log 2>&1 &
        nohup cardano-submit-api --mainnet --socket-path $CARDANO_NODE_SOCKET_PATH --config /cardano/config/tx-submit-mainnet-config.yaml --port 8090 --listen-address 0.0.0.0 &
    elif [[ $ONLY_DB_SYNC == 'true' ]]; then
        nohup crond >>/var/log/cron.log 2>&1 &
        nohup socat UNIX-LISTEN:$CARDANO_NODE_SOCKET_PATH,fork,reuseaddr,unlink-early, TCP:$REMOTE_NODE_SERVER:$REMOTE_NODE_PORT >>/var/log/socat.log 2>&1 &
        nohup cardano-submit-api --mainnet --socket-path $CARDANO_NODE_SOCKET_PATH --config /cardano/config/tx-submit-mainnet-config.yaml --port 8090 --listen-address 0.0.0.0 &
    fi

    if [[ $AWS_SYNC_ENABLED == 'true' ]]; then

        echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> /root/.bash_profile
        echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /root/.bash_profile
        echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> /root/.bash_profile

        echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> /home/admin/.bash_profile
        echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /home/admin/.bash_profile
        echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> /home/admin/.bash_profile
        
        if [[ ! $ONLY_DB_SYNC == 'true' ]]; then

            if [[ $EFS_ENABLED == 'true' ]]; then

                if [[ $TESTNET_ENABLED == 'true' ]]; then

                    mkdir /cardano/db/$HOSTNAME/
                    cp -R /cardano/db/testnet/* /cardano/db/$HOSTNAME/
                    sed -i "s^/cardano/db^/cardano/db/$HOSTNAME^g" /cardano/scripts/.env 

                    echo "export TESTNET_ENABLED=true" >> /root/.bash_profile
                    echo "export TESTNET_ENABLED=true" >> /home/admin/.bash_profile

                else

                    mkdir /cardano/db/$HOSTNAME/
                    cp -R /cardano/db/source/* /cardano/db/$HOSTNAME/
                    sed -i "s^/cardano/db^/cardano/db/$HOSTNAME^g" /cardano/scripts/.env 

                fi

            else

                if [[ ! $REMOTE_URL_SYNC == 'true' ]]; then
                    if [[ $TESTNET_ENABLED == 'true' ]]; then
                        aws s3 sync s3://$DB_BUCKET_NAME/testnet/ /cardano/db/
                    else
                        aws s3 sync s3://$DB_BUCKET_NAME/ /cardano/db/
                    fi
                fi
            
            fi
        
        fi

        echo "#0 */1 * * * source /root/.bash_profile && aws s3 sync s3://$WALLET_BUCKET_NAME/$HOSTNAME/ /home/admin/.cardobot/wallets/ &>>/var/log/cron.log" >> /var/spool/cron/root
        echo "15 */1 * * * source /root/.bash_profile && aws s3 sync /home/admin/.cardobot/wallets/ s3://$WALLET_BUCKET_NAME/$HOSTNAME/ &>>/var/log/cron.log" >> /var/spool/cron/root

        if [[ ! $ONLY_DB_SYNC == 'true' ]]; then
            if [[ $MASTER_NODE == 'true' ]]; then
                if [[ $EFS_ENABLED == 'true' ]]; then
                    if [[ $TESTNET_ENABLED == 'true' ]]; then
                        echo "0 0 * * * source /root/.bash_profile && aws s3 sync /cardano/db/$HOSTNAME/ s3://$DB_BUCKET_NAME/testnet/ --delete &>>/var/log/cron.log" >> /var/spool/cron/root
                        echo "0 15 * * * source /root/.bash_profile && rm -rf /cardano/db/testnet/ && mkdir /cardano/db/testnet/ && cp -R /cardano/db/$HOSTNAME/* /cardano/db/testnet/ &>>/var/log/cron.log" >> /var/spool/cron/root
                    else
                        echo "0 0 * * * source /root/.bash_profile && aws s3 sync /cardano/db/$HOSTNAME/ s3://$DB_BUCKET_NAME/ --delete &>>/var/log/cron.log" >> /var/spool/cron/root
                        echo "0 15 * * * source /root/.bash_profile && rm -rf /cardano/db/source/ && mkdir /cardano/db/source/ && cp -R /cardano/db/$HOSTNAME/* /cardano/db/source/ &>>/var/log/cron.log" >> /var/spool/cron/root
                    fi
                else
                    if [[ $TESTNET_ENABLED == 'true' ]]; then
                        echo "0 0 * * * source /root/.bash_profile && aws s3 sync /cardano/db/ s3://$DB_BUCKET_NAME/testnet/ --delete &>>/var/log/cron.log" >> /var/spool/cron/root
                    else
                        echo "0 0 * * * source /root/.bash_profile && aws s3 sync /cardano/db/ s3://$DB_BUCKET_NAME/ --delete &>>/var/log/cron.log" >> /var/spool/cron/root
                    fi
                fi
            fi
        fi
    fi

    if [[ ! $ONLY_DB_SYNC == 'true' ]]; then

        if [[ $REMOTE_URL_SYNC == 'true' ]]; then

            curl -L -o ./db_archive.tar.gz $REMOTE_DB_URL
            tar -xvf ./db_archive.tar.gz --directory ${NODE_HOME}/db/
            rm -rf ./db_archive.tar.gz

        fi

    fi

    if [[ $DB_SYNC_ENABLED == 'true' ]]; then

        echo -e "\n-= Updating Postgres DB Files =-"
        sed -i "s^hostname^${POSTGRES_HOST}^g" /cardano/config/pgpass-mainnet
        sed -i "s^port^${POSTGRES_PORT}^g" /cardano/config/pgpass-mainnet
        sed -i "s^database^${POSTGRES_DB}^g" /cardano/config/pgpass-mainnet
        sed -i "s^username^${POSTGRES_USER}^g" /cardano/config/pgpass-mainnet
        sed -i "s^password^${POSTGRES_PASS}^g" /cardano/config/pgpass-mainnet

        cp /cardano/config/pgpass-mainnet /home/admin/.pgpass
        chown admin /home/admin/.pgpass
        chmod 600 /home/admin/.pgpass

        cp /cardano/config/pgpass-mainnet /root/.pgpass
        chown root /root/.pgpass
        chmod 600 /root/.pgpass

        if [[ ! $SEPARATE_DB_SYNC == 'true' ]]; then

            if [[ $MASTER_NODE == 'true' ]]; then

                if [[ $RESTORE_DB_SYNC_SNAPSHOT == 'true' ]]; then

                    echo -e "\n-= Download most recent cardano-db-sync snapshot"
                    curl -L -o cardano-snapshot.tgz https://update-cardano-mainnet.iohk.io/cardano-db-sync/12/db-sync-snapshot-schema-12-block-6850499-x86_64.tgz
                    tar -xvf cardano-snapshot.tgz --directory /cardano/snapshots --exclude configuration
                    rm -rf cardano-snapshot.tgz
                    
                    db_snap_name=$(ls /cardano/snapshots/db*)
                    mkdir -p /cardano/sync/ledger-state/mainnet

                    PGPASSFILE=/cardano/config/pgpass-mainnet /cardano/scripts/postgresql-setup.sh --restore-snapshot ${db_snap_name} /cardano/sync/ledger-state/mainnet

                    rm -rf ${db_snap_name}

                fi

            fi

        fi

        if [[ $MASTER_NODE == 'true' ]]; then
            if [[ ! $SEPARATE_DB_SYNC == 'true' ]]; then
                if [[ ! $ONLY_DB_SYNC == 'true' ]]; then
                    nohup bash -c '/cardano/scripts/start-db-sync.sh' >>/var/log/dbsync.log 2>&1 &
                fi
            fi
        fi

        echo "export DB_SYNC_ENABLED=true" >> /root/.bash_profile
        echo "export DB_SYNC_ENABLED=true" >> /home/admin/.bash_profile

    fi

else

    nohup /usr/sbin/sshd -D -o ListenAddress=0.0.0.0 -p 22 >>/var/log/sshd.log 2>&1 &

    if [[ ! $ONLY_DB_SYNC == 'true' ]]; then
        nohup crond >>/var/log/cron.log 2>&1 &
        nohup socat TCP-LISTEN:3333,fork,reuseaddr, UNIX-CONNECT:$CARDANO_NODE_SOCKET_PATH >>/var/log/socat.log 2>&1 &
        nohup cardano-submit-api --mainnet --socket-path $CARDANO_NODE_SOCKET_PATH --config /cardano/config/tx-submit-mainnet-config.yaml --port 8090 --listen-address 0.0.0.0 &
    elif [[ $ONLY_DB_SYNC == 'true' ]]; then
        nohup crond >>/var/log/cron.log 2>&1 &
        nohup socat UNIX-LISTEN:$CARDANO_NODE_SOCKET_PATH,fork,reuseaddr,unlink-early, TCP:$REMOTE_NODE_SERVER:$REMOTE_NODE_PORT >>/var/log/socat.log 2>&1 &
        nohup cardano-submit-api --mainnet --socket-path $CARDANO_NODE_SOCKET_PATH --config /cardano/config/tx-submit-mainnet-config.yaml --port 8090 --listen-address 0.0.0.0 &
    fi

    if [[ $MASTER_NODE == 'true' ]]; then
        if [[ ! $SEPARATE_DB_SYNC == 'true' ]]; then
            if [[ ! $ONLY_DB_SYNC == 'true' ]]; then
                nohup bash -c '/cardano/scripts/start-db-sync.sh' >>/var/log/dbsync.log 2>&1 &
            fi
        fi
    fi

fi

cd /home/admin/cardobot && git pull && ./INSTALL && cd ~/
chown admin -R /home/admin/.cardobot/wallets/

if [[ $ONLY_DB_SYNC == 'true' ]]; then

    bash -c '/cardano/scripts/start-db-sync.sh'

else

    bash -c '/cardano/scripts/start-relay.sh'

fi
