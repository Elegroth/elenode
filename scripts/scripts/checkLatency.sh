#!/bin/bash

i=0

while [ $i -le 50 ]; do
    time nc -zw30 relays-new.cardano-mainnet.iohk.io 3001
    sleep 1
    i=$(($i + 1))
done