#!/bin/bash

#version="$Id: info_exp.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# ___ Help _____________________________________________________________________

if [ $# -ne 1 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <WRANRelsFile>

where
 WRANRelsFile    Log file about expected relations between internal GSM cells
                 and external GSM/UTRAN cells from WRAN point of view

Example:
 $This UtranNetwork-GsmRelations3.log

DESCRIPTION:
 Calulate informations from log files.
 Example:
    UtranCell 1 (wran sim 1) has GsmRelations to ExtGsmCells 1-2 (gsm sim 1)
    UtranCell 2 (wran sim 1) has GsmRelations to ExtGsmCells 1-2 (gsm sim 1)
    UtranCell 3 (wran sim 1) has GsmRelations to ExtGsmCells 3-4 (gsm sim 1)
    UtranCell 4 (wran sim 1) has GsmRelations to ExtGsmCells 3-4 (gsm sim 1)
    ...

 Show the number of internal GSM cells and utran relations per internal GSM
 cells for GSM simulations. And also show the number of external UTRAN cells
 and gsm relations per external UTRAN cells for UTRAN simulations.
 Example:
    GSM sim 1: Int=4992(1-4992), UtranRelsPerInt=[13(4992)]
    GSM sim 2: Int=7007(5001-12007), UtranRelsPerInt=[13(7007)]
    UTRAN sim 1: Utran=793(1-793), GsmRelsPerUtran=[13(793)]
    UTRAN sim 2: Utran=793(796-1588), GsmRelsPerUtran=[13(793)]
    ...

 The UtranRelsPerInt/GsmRelsPerUtran shows how many internal GSM/external UTRAN
 cells (in parenthesises) have how many utran/gsm relations (before
 parenthesises).

__END_OF_HELP__
exit 1
fi


# ___ Environment ______________________________________________________________

# Temporary directory where you have write permission
if [ "x" == "x$TmpBaseDir" ]
then
    TmpBaseDir=`pwd`
fi
TmpDir="$TmpBaseDir/`echo $0 | sed "s/^.*\///g"`.`whoami`.tmpdir"


# ___ Parameters _______________________________________________________________

# Parameters
LogFile=$1


# ___ Preprocessing ____________________________________________________________

# Delete temporary files
if [ -d "$TmpDir" ]
then
    rm -r -f "$TmpDir"
fi
mkdir -p "$TmpDir"

RelsPath="$TmpDir/rels"

# ___ Main activity ____________________________________________________________


# UtranCell 1 (wran sim 1) has GsmRelations to ExtGsmCells 1-13 (gsm sim 1)
# UtranCell 1 wran sim 1 has GsmRelations to ExtGsmCells 1 13 gsm sim 1

grep "^UtranCell" $LogFile | sed "s/)//g" | tr "-" " " |
    awk 'BEGIN{OFS=","} {for(i=$10; i<=$11; ++i) print $14,i,$5,$2}' > $RelsPath

# GSM simulations
for GSimIdx in `cat $RelsPath | cut -d , -f 1 | sort -n -u`
do
    IGIdxs=`grep "^$GSimIdx," $RelsPath | cut -d , -f 2 | sort -n -u`
    MinIGIdx=`echo $IGIdxs | tr " " "\n" | head -n 1`
    MaxIGIdx=`echo $IGIdxs | tr " " "\n" | tail -n 1`
    NumIG=`echo $IGIdxs | wc -w`
    
    Rels=`grep "^$GSimIdx," $RelsPath | cut -d , -f 2 | sort | uniq -c | sort |
            awk '{print $1}' | uniq -c | awk '{printf "%s(%s) ",$2,$1}' | 
            sed "s/ $//g" | sed "s/ /; /g"`

    # Write infos
    echo "GSM sim $GSimIdx: Int=$NumIG($MinIGIdx-$MaxIGIdx), UtranRelsPerInt=[$Rels]"
done

# UTRAN simulations
for USimIdx in `cat $RelsPath | cut -d , -f 3 | sort -n -u`
do
    EUIdxs=`egrep ",$USimIdx,[0-9]+$" $RelsPath | cut -d , -f 4 | sort -n -u`
    MinEUIdx=`echo $EUIdxs | tr " " "\n" | head -n 1`
    MaxEUIdx=`echo $EUIdxs | tr " " "\n" | tail -n 1`
    NumEU=`echo $EUIdxs | wc -w`
    
    Rels=`egrep ",$USimIdx,[0-9]+$" $RelsPath | cut -d , -f 4 | sort | uniq -c | sort |
            awk '{print $1}' | uniq -c | awk '{printf "%s(%s) ",$2,$1}' | 
            sed "s/ $//g" | sed "s/ /; /g"`

    # Write infos
    echo "UTRAN sim $USimIdx: Utran=$NumEU($MinEUIdx-$MaxEUIdx), GsmRelsPerUtran=[$Rels]"
done


# ___ Postprocessing ___________________________________________________________

# Delete temporary files
rm -r -f $TmpDir
