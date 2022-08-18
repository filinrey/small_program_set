#!/bin/bash

#gnb_19A  gnb_19A_B2  gnb_19A_B3  gnb_19B_B1  gnb_19B_B2  gnb_19B_B3  gnb_19B_FDD  gnb_20A_B1  gnb_master
#mkdir -p gnb_19A
#cd gnb_19A
#git clone ssh://fenghxu@gerrit.ext.net.nokia.com:29418/MN/5G/NB/gnb.git
#git checkout rel/5G19A

branches=('rel/5G19A' 'rel/5G19A_B2' 'rel/5G19A_B3' 'rel/5G19B_B1' 'rel/5G19B_B2' 'rel/5G19B_B3' 'rel/5G19B_FDD' 'rel/5G20A_B1' 'master')
directories=('gnb_19A' 'gnb_19A_B2' 'gnb_19A_B3' 'gnb_19B_B1' 'gnb_19B_B2' 'gnb_19B_B3' 'gnb_19B_FDD' 'gnb_20A_B1' 'gnb_master')

i=0
for dir in ${directories[@]}
do
    mkdir -p $dir
    cd $dir
    git clone ssh://fenghxu@gerrit.ext.net.nokia.com:29418/MN/5G/NB/gnb.git
    cd gnb
    git checkout ${branches[$i]}
    cd ../../
    let i=i+1
done
