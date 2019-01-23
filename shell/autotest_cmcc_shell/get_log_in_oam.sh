#!/bin/bash

sudo ssh oam-0.local "journalctl -b --output=short-precise > /mnt/export/backup/cu_oam.log"
sudo ssh cpnb-0.local "journalctl -b --output=short-precise > /mnt/export/backup/cu_cpnb.log"
sudo ssh cpif-0.local "journalctl -b --output=short-precise > /mnt/export/backup/cu_cpif.log"
sudo ssh cpue-0.local "journalctl -b --output=short-precise > /mnt/export/backup/cu_cpue.log"
sudo ssh cpcl-0.local "journalctl -b --output=short-precise > /mnt/export/backup/cu_cpcl.log"
sudo ssh upue-0.local "journalctl -b --output=short-precise > /mnt/export/backup/cu_upue.log"
