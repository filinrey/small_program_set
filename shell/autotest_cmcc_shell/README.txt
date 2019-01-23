Firstly, you should install sshpass in your testpc in which run cmcc_test.sh

Testing step:
1. ./cmcc_test.sh -o 10.57.208.100

    10.57.208.100 is RACOAM IP.
    This step will downlaod SCF from OAM, parse to get all DUs from SCF;
                   modify NetworkPlanFile.xml, Rapsconfiguration.json;
                   copy .so in /root/duEmulator/ to /usr/lib64/;
                   copy *_fronthaul in /root/duEmulator/ to /etc/
    
    This step only run 1 time at first, except RACOAM is recreated.

2. ./cmcc_test.sh -b 1-10

    Reboot dedicated DUs, 1-10 means from DU-1 to DU-10.
    For exmpale:
        ./cmcc_test.sh -b 1
            Only reboot DU1.

        ./cmcc_tesh.sh -b 1-5
            Reboot DU-1, DU-2, DU-3, DU-4, DU-5.

3. ./cmcc_test.sh -s 1-10

    Run CellSetup procedure in DU.
    For example:
        ./cmcc_test.sh -s 1
            Only run DU-1.

        ./cmcc_test.sh -s 2-10
            Run DU-2, DU-3, DU-4, DU-5, DU-6, DU-7, DU-8, DU-9, DU-10.

    You can run this step again and again to run more DUs as you want.

Option 1: ./cmcc_test.sh -b 1-10 -s 1-10
    
    You can run -b and -s together.
    It will wait OAM and DU are all OK.

Option 2: ./cmcc_test.sh -f CU98_32DU_96CELL.xml -o 10.57.208.98
    
    CU98_32DU_96CELL.xml is your file.
    10.57.208.98 is OAM IP.
    This command will create a .new file with right DUs.

