#!/bin/bash

#version="$Id: $"

# ___ Help _____________________________________________________________________

if [ $# -ne 1 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <InputDir>

where
 InputDir
    The output directory of sim2script_gsm-utran.sh

Example:
 $This ./test/

DESCRIPTION:
 Convert attributes of GSM cells into a different format to support WRAN side
 configuration.

 All *.cells.INT.BSCCells files will be converted in all subdirectory in the
 work_data subdirectory of the InputDir directory.
 (<inputDir>/work_data/*/*.cells.INT.BSCCells)

 The converted file names have the ".wran" postfix and placed next to te
 original files.

__END_OF_HELP__
exit 1
fi


# ___ Parameters _______________________________________________________________

InputDir=$1


# ___ Main activity ____________________________________________________________

for CellsFile in `ls $InputDir/work_data/*/*.cells.INT.BSCCells`
do
    echo "$CellsFile"
    for Line in `grep -v "^[ ]*$" $CellsFile | grep -v "^[ ]*#.*$"`
    do
        for Field in `echo $Line | cut -d , -f 1- --output-delimiter=" "`
        do
            Name=`echo $Field | cut -d = -f 1`
            Value=`echo $Field | cut -d = -f 2`
            if [ "x$Name" == "xCGI" ]
            then
                MCC=`echo $Value | cut -d - -f 1`
                MNC=`echo $Value | cut -d - -f 2`
                MNCDigitHand=`echo -n $MNC | wc -c`
                LAC=`echo $Value | cut -d - -f 3`
                CID=`echo $Value | cut -d - -f 4`
                echo -n "MCC=$MCC;MNC=$MNC;BSC.MNCDIGITHAND=$MNCDigitHand;LAC=$LAC;CI=$CID;"
            elif [ "x$Name" == "xUTRANID" ]
            then
                MCC=`echo $Value | cut -d - -f 1`
                MNC=`echo $Value | cut -d - -f 2`
                MNCDigitHand=`echo -n $MNC | wc -c`
                LAC=`echo $Value | cut -d - -f 3`
                CID=`echo $Value | cut -d - -f 4`
                RNCID=`echo $Value | cut -d - -f 5`
                echo -n "mcc=$MCC;mnc=$MNC;mncLength=$MNCDigitHand;lac=$LAC;cid=$CID;"
            elif [ "x$Name" == "xBSIC" ]
            then
                NCC=`echo $Value | cut -c 1`
                BCC=`echo $Value | cut -c 2`
                echo -n "NCC=$NCC;BCC=$BCC;"
            elif [ "x$Name" == "xBCCHNO" ] || [ "x$Name" == "xCELL" ] || [ "x$Name" == "xCSYSTYPE" ]
            then
                echo -n "$Field;" |
                sed "s/^CELL=/CELL_NAME=/g" | sed "s/^CSYSTYPE=/C_SYS_TYPE=/g"
            fi 
        done | sed "s/;$//g"
        echo ""
    done > $CellsFile.wran
done
