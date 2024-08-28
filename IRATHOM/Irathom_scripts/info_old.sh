#!/bin/bash

#version="$Id: info.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# ___ Help _____________________________________________________________________

if [ $# -ne 1 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <Directory>

where
 Directory  the directory that contains the BSC cells lists (*.BSCCells) and
            the DOG generated log files (DT.*.BSC.*.DOG) about cells and
            relations in BSC node

Example:
 $This Logs

DESCRIPTION:
 Calulate informations from log files. Show the number of internal GSM cells,
 external GSM cells, external UTRAN cells and the Utran relations per internal
 GSM cells for the whole simulation and every BSC nodes.
 Example:
    GSM sim Sim01: Int=20, Ext=5(8), Utran=4(6), UtranRelsPerInt=[1(10); 2(10)]
      BSC BSC01: Int=10, Ext=4(4), Utran=3(3), UtranRelsPerInt=[1(10)]
      BSC BSC01: Int=10, Ext=4(4), Utran=3(3), UtranRelsPerInt=[2(10)]

 The numbers in parenthesises for Ext and Utran are the number of cell
 deinitions of external GSM and external UTRAN cells. These definitions can
 refer to the same cell. The numbers not in parenthesises are the number of
 different external GSM and external UTRAN cells.

 The UtranRelsPerInt shows how many internal GSM cells (in parenthesises) have
 how many utran relations (before parenthesises).

__END_OF_HELP__
exit 1
fi


# ___ Parameters _______________________________________________________________

# Parameters
Directory=$1


# ___ Main activity ____________________________________________________________

BSCCellPathes=`ls $Directory/*.BSCCells | grep "/[^.]*\.BSCCells$"`
BSCRelPathes=`ls $Directory/*.BSCRels | grep "/[^.]*\.BSCRels$"`

# Get simulation name
SimName=`cat $BSCCellPathes | egrep -v "^[ ]*(#.*)?$" | cut -d , -f 1 | sort -u`

# Calc number of cells
NumIG=`cat   $BSCCellPathes | grep ",celltype=INT,"   | cut -d , -f 5 | wc -l`
NumEG=`cat   $BSCCellPathes | grep ",celltype=EXT,"   | cut -d , -f 5 | sort -u | wc -l`
NumEGnu=`cat $BSCCellPathes | grep ",celltype=EXT,"   | cut -d , -f 5 | wc -l`
NumEU=`cat   $BSCCellPathes | grep ",celltype=UTRAN," | cut -d , -f 5 | sort -u | wc -l`
NumEUnu=`cat $BSCCellPathes | grep ",celltype=UTRAN," | cut -d , -f 5 | wc -l`

# Calc number of Utran relations
# From BSCRels files
Rels=`cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep -v ",CAND=" | 
        cut -d , -f 4 | sed "s/CELL=//g" |
        sort | uniq -c | sort | awk '{print $1}' | uniq -c |
        awk '{printf "%s(%s) ",$2,$1}' | sed "s/ $//g" | sed "s/ /; /g"`

# Write infos
echo "GSM sim $SimName: Int=$NumIG, Ext=$NumEG($NumEGnu), Utran=$NumEU($NumEUnu), UtranRelsPerInt=[$Rels]"

for BSCCellPath in $BSCCellPathes
do
    BSCName=`echo $BSCCellPath | sed "s/.*\///g" | sed "s/\.BSCCells//g" | grep "^[^.]*$"`
    BSCRelPath=`ls $Directory/$BSCName.BSCRels`

    # Calc number of cells
    NumIG=`grep   ",celltype=INT,"   $BSCCellPath | cut -d , -f 5 | wc -l`
    NumEG=`grep   ",celltype=EXT,"   $BSCCellPath | cut -d , -f 5 | sort -u | wc -l`
    NumEGnu=`grep ",celltype=EXT,"   $BSCCellPath | cut -d , -f 5 | wc -l`
    NumEU=`grep   ",celltype=UTRAN," $BSCCellPath | cut -d , -f 5 | sort -u | wc -l`
    NumEUnu=`grep ",celltype=UTRAN," $BSCCellPath | cut -d , -f 5 | wc -l`

    # Calc number of Utran relations
    Rels=`cat $BSCRelPath | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep -v ",CAND=" | 
            cut -d , -f 4 | sed "s/CELL=//g" |
            sort | uniq -c | sort | awk '{print $1}' | uniq -c |
            awk '{printf "%s(%s) ",$2,$1}' | sed "s/ $//g" | sed "s/ /; /g"`

    # Write infos
    echo "  BSC $BSCName: Int=$NumIG, Ext=$NumEG($NumEGnu), Utran=$NumEU($NumEUnu), UtranRelsPerInt=[$Rels]"
done

