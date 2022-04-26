#!/bin/bash

#output=`cat $2 | sed -nr "/NRDU-$1/{:a;N;/managedObject>$/{s/.*\ operation(.*)managedObject/\1/p;q};ba}"`

cur_dir=$1
if [[ ! -d $cur_dir ]]; then
    echo "$cur_dir is not exists"
    return
fi

file_list=(`grep -rlwE 'CELL|CELLGROUP|NRCELLGROUP|CELLCONFIG' $cur_dir`)
echo "totally find ${#file_list[*]} files"
#echo "${file_list[@]}"
for file in ${file_list[@]}
do
    echo "$file"
    sed -ri 's/_ptr<CELL>/_ptr<cell_config::ICellForUeThread>/g' $file
    sed -ri 's/_ptr<CELLCONFIG>/_ptr<cell_config::ICellConfigForUeThread>/g' $file
    sed -ri 's/_ptr<NRCELLGROUP>/_ptr<cell_config::INrCellGroupForUeThread>/g' $file
    sed -ri 's/_ptr<CELLGROUP>/_ptr<cell_config::INrCellGroupForUeThread>/g' $file
    sed -ri '/^\s*template\ [cs].+<.+ICell.*>\;$//g' $file
    sed -ri '/^\s*template\ [cs].+<.+INrCellGroup.*>\;$//g' $file
    sed -ri '/^\s*template\ [cs].+<.+ICellConfig.*>\;$//g' $file
    sed -ri '/^\s*template\ [cs].+<.+ICellForUeThread.*>\;$//g' $file
    sed -ri '/^\s*template\ [cs].+<.+INrCellGroupForUeThread.*>\;$//g' $file
    sed -ri '/^\s*template\ [cs].+<.+ICellConfigForUeThread.*>\;$//g' $file

    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICell.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroup.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfig.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellForUeThread.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroupForUeThread.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfigForUeThread.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICell.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroup.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfig.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellForUeThread.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroupForUeThread.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfigForUeThread.*>\;$//g;/>\;$/!ba}' $file
    # run 2nd time
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICell.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroup.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfig.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellForUeThread.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroupForUeThread.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfigForUeThread.+\)\;$//g;/\)\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICell.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroup.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfig.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellForUeThread.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+INrCellGroupForUeThread.*>\;$//g;/>\;$/!ba}' $file
    sed -ri '/^\s*template\ [a-zA-Z]/{:a;N;s/^\s*template.+ICellConfigForUeThread.*>\;$//g;/>\;$/!ba}' $file

    sed -ri '/^\s*template\ <.*[typenameCELLCONFIGNRGROUP\ ]{13,}.*>$/{:label; s/(<)typename\ [CELLCONFIGNRGROUP]{4,11}[,]{0,1}[\ ]{0,1}/\1/g;}; s/,[\ ]{0,1}typename\ [CELLCONFIGNRGROUP]{4,11}//g; s/^\s*template\ <>//g; t label;' $file
    sed -ri 's/<[CELLCONFIGNRGROUP,\ ]{4,30}>//g' $file
    sed -ri 's/CELLCONFIG/cell_config::ICellConfigForUeThread/g' $file
    sed -ri 's/NRCELLGROUP/cell_config::INrCellGroupForUeThread/g' $file
    sed -ri 's/\bCELLGROUP\b/cell_config::INrCellGroupForUeThread/g' $file
    sed -ri 's/\bCELL\b/cell_config::ICellForUeThread/g' $file
    sed -ri '/^\s*$/{N;/^\s*$/D;}' $file
done
sed -ri 's/class ICell;/class ICellForUeThread;/g' `grep -rlw "class ICell;" $cur_dir`
sed -ri 's/class ICellConfig;/class ICellConfigForUeThread;/g' `grep -rlw "class ICellConfig;" $cur_dir`
sed -ri 's/class INrCellGroup;/class INrCellGroupForUeThread;/g' `grep -rlw "class INrCellGroup;" $cur_dir`
