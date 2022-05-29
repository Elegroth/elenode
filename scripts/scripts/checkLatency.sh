#!/bin/bash

i=0

while [[ $i < 50 ]]; do
    time nc -zw30 relays-new.cardano-mainnet.iohk.io 3001
    i=$(($i + 1))
done