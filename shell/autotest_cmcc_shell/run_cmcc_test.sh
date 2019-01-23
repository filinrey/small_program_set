#!/bin/bash

NUM_PARALLEL=1
NUM_DU=`ls -a .dus/.scf/ | grep ".du" | wc -l`
DU_ID_START=$1
DU_ID_LAST=$2
if [[ $DU_ID_LAST -lt $DU_ID_START ]]; then
    echo "DU ID range is wrong."
    exit
fi
REAL_NUM_DU=$((DU_ID_LAST - DU_ID_START + 1))
if [[ $REAL_NUM_DU -gt $NUM_DU ]]; then
    echo "DU ID range is too big, only have $NUM_DU DUs."
    exit
fi

NUM_CIRCLE=$((REAL_NUM_DU / NUM_PARALLEL))
echo "Total $REAL_NUM_DU DUs, run them one by one from DU-$DU_ID_START to DU-$DU_ID_LAST"

for(( i=$DU_ID_START;i<=$DU_ID_LAST;i++ ))
do
    ./cmcc_test.sh -s $i
done
