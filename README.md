# elenode

This docker image has the ability to automatically sync up and down a backup of the Cardano DB. For now just through an S3 bucket, but looking into using the official weekly backups from IOHK.

## Install:

Install Docker to get started:

https://docs.docker.com/get-started/


```
docker pull elegroth/elenode:0.2.0
docker run -d elegroth/elenode:0.2.0
```

You can find the compiled image on Docker Hub:

https://hub.docker.com/r/elegroth/elenode

## Components:

- ssh daemon
- exposed cardano-node via socat
- support for Nami custom node via payment tx api
- cardobot pre-installed
- automatic backups to S3 for wallets and DB
- dbsync w/ connection to remote postgres db

## Environment Variables:
### Optional Variables:
```
  - AWS_SYNC_ENABLED (whether or not to sync DB and wallets to S3)
    true/false
    
  - EFS_ENABLED (Whether or not to utilize a mounted EFS volume, mainly for use with ECS or EKS)
    true/false

  - MASTER_NODE (whether or not the DB state in S3 is based on this node or not, only do this for one node)
    true/false

  - DB_SYNC_ENABLED (whether or not to run dbsync at startup)
    true/false

  - RESTORE_DB_SYNC_SNAPSHOT (whether or not to download the latest DB sync snapshot from IOHK)
    true/false

  - DB_BUCKET_NAME (name of the S3 bucket to pull the synced Cardano DB from)
    string

  - WALLET_BUCKET_NAME (name of the S3 bucket to backup wallets to)
    string
```  
### SSH Variables (required if you need to log into the container remotely)
```
  - ROOT_SSH_KEY (only needed if you need to ssh into the server directly as root, illadvised)
    string
    
  - ADMIN_SSH_KEY (needed to ssh directly into the server to run cardobot commands)
    string
```
### AWS Variables (required if using private S3 buckets):
```
  - AWS_ACCESS_KEY_ID (IAM user's access key for your account)
    string

  - AWS_SECRET_ACCESS_KEY (IAM user's secret key for your account)
    string

  - AWS_DEFAULT_REGION (region your S3 buckets live in)
    string
```
### Postgres Variables (required if using db sync)
```
  - POSTGRES_HOST (hostname or IP of your postgres DB)
    string

  - POSTGRES_PORT (port being used by your postgres DB)
    int

  - POSTGRES_DB (database name used by your dbsync, needs to be already created)
    string

  - POSTGRES_USER (user to login to postgres with)
    string

  - POSTGRES_PASS (password for the postgres user, recommend using secrets manager variables if using ECS)
    string
```
