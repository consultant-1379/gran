#!/bin/bash

#version="$Id: $"

# ___ Help _____________________________________________________________________

if [ $# -ne 1 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <WRANRelsFile>

where
 WRANRelsFile
    The log file about expected relations between internal GSM cells and
    external GSM/UTRAN cells from WRAN point of view.

Example:
 $This UtranNetwork-GsmRelations.log

DESCRIPTION:
 WRANRelsFile must contains lines like this:
 Example:
    UtranCell 1 (wran sim 1) has GsmRelations to ExtGsmCells 1-2 (gsm sim 1)
    UtranCell 2 (wran sim 1) has GsmRelations to ExtGsmCells 1-2 (gsm sim 1)
    UtranCell 3 (wran sim 1) has GsmRelations to ExtGsmCells 3-4 (gsm sim 1)
    UtranCell 4 (wran sim 1) has GsmRelations to ExtGsmCells 3-4 (gsm sim 1)
    ...

 This script fetch the external GSM cell index ranges and print a single line
 for every relations as it shown below:
    ######################################################################
    # Expected cell neighbour relations with indices
    # GsmSimIdx, GsmCellIdx, UtranSimIdx, UtranCellIdx
    1,1,1,1
    1,2,1,1
    1,1,1,2
    1,2,1,2
    1,3,1,3
    1,4,1,3
    1,3,1,4
    1,4,1,4
    ...
 where the colums are the followings:
    GsmSimIdx, GsmCellIdx, UtranSimIdx, UtranCellIdx

 Every line started with hashmark (#) is comment in the output.

__END_OF_HELP__
exit 1
fi


# ___ Parameters _______________________________________________________________

# Parameters
LogFile=$1


# ___ Main activity ____________________________________________________________

echo "######################################################################"
echo "# Expected cell neighbour relations with indices"
echo "# GsmSimIdx, GsmCellIdx, UtranSimIdx, UtranCellIdx"

# Without replacing GSM sim indices with real sim names
grep "^UtranCell" $LogFile | sed "s/)//g" | tr "-" " " |
    awk 'BEGIN{OFS=","} {for(i=$10; i<=$11; ++i) print $14,i,$5,$2}'

