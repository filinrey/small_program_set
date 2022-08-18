#!/bin/bash

function pick_out_files_dirs()
{
    for item in `ls $1`
    do
        owner=`stat --format=%U $1"/"$item`
        #echo "$1/$item -> $owner"
        if [[ -d $1"/"$item ]]; then
            if [[ "$owner" == "root" ]]; then
                echo "$1/$item -> $owner"
                #`sudo rm -rf "$1/$item"`
            else
                pick_out_files_dirs "$1/$item"
            fi
        else
            if [[ "$owner" == "root" ]]; then
                echo "$1/$item -> $owner"
                #`sudo rm -rf "$1/$item"`
            fi
        fi
    done
}

pick_out_files_dirs $1
