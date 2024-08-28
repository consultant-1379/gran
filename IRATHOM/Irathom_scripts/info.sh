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
    The directory that contains the BSC cells lists (*.BSCCells) and the
    relations lists extended with related cell types (*.BSCRels).

Example:
 $This ./test/work_data/Sim1/

DESCRIPTION:
 Calulate informations from log files. Show the number of internal GSM cells,
 external GSM cells, external UTRAN cells, the number of mutual and single
 realtions, the deviation of number of relations and the average relations per
 cells and in the whole  simulation.

 The generated output is a comma separated file (CSV). It is highly recommended
 to view this file with a spreadsheet viewer/editor like MicroSoft Excel or
 OpenOffice.org Calc.

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

# ___ Preprocessing ____________________________________________________________

# Delete temporary files
if [ -d "$TmpDir" ]
then
    rm -r -f "$TmpDir"
fi
mkdir -p "$TmpDir"

IntPath="$TmpDir/int.txt"
ExtPath="$TmpDir/ext.txt"
UtranPath="$TmpDir/utran.txt"


# ___ Parameters _______________________________________________________________

# Parameters
Directory=$1


# ___ Main activity ____________________________________________________________

BSCNames=`cd $Directory ;
          ls -1 *.BSCRels | grep "[^.]*\.BSCRels$" | sed "s/\.BSCRels//g"`

BSCCellPathes=`for i in $BSCNames; do echo "$Directory/$i.BSCCells"; done`
BSCRelPathes=`for i in $BSCNames; do echo "$Directory/$i.BSCRels"; done`

# Get simulation name
SimName=`cat $BSCCellPathes | egrep -v "^[ ]*(#.*)?$" | cut -d , -f 1 | cut -d = -f 2 | head -n 1`

echo "#"
echo "# This is a CSV (Comma Separated Values) file."
echo "# It is highly recommended to view this file with a spreadsheet viewer/editor like MicroSoft Excel or OpenOffice Calc"
echo "# Field separator: comma"
echo ""
echo "# Ext cells:"
echo "# ----------"
echo "# Format: N(M)"
echo "# where"
echo "# N: number of GSM cells that has external GSM cell definitions in any BSC node"
echo "# M: total number of external GSM cell definitions in all BSC node"
echo "# "
echo "# Utran cells:"
echo "# ------------"
echo "# Format: N(M)"
echo "# where"
echo "# N: number of UTRAN cells that has external UTRAN cell definitions in any BSC node"
echo "# M: total number of external UTRAN cell definitions in all BSC node"
echo "#"
echo "# Type of reltions per type of cell:"
echo "# ----------------------------------"
echo "# Format: N(M); N(M); ..."
echo "# where"
echo "# N: number of relations"
echo "# M: number of cells that have N relations"
echo "# "
echo "# 3(20); 4(15) means there are 20 cells with 3 relation and 15 cells with 4 relations."
echo "# "
echo "# The list is sorted by the N value."
echo "# "
echo "# Mutual: number of bi-directional relations"
echo "# Single: number of single directionsl relations"
echo "# Avg: average nomber of relations per cell"
echo "#"
echo "#"
echo "# Simulation: $SimName"

# Calc number of cells
NumIG=`cat   $BSCCellPathes | grep ",celltype=INT,"   | cut -d , -f 5 | wc -l`
NumEG=`cat   $BSCCellPathes | grep ",celltype=EXT,"   | cut -d , -f 5 | sort -u | wc -l`
NumEGnu=`cat $BSCCellPathes | grep ",celltype=EXT,"   | cut -d , -f 5 | wc -l`
NumEU=`cat   $BSCCellPathes | grep ",celltype=UTRAN," | cut -d , -f 5 | sort -u | wc -l`
NumEUnu=`cat $BSCCellPathes | grep ",celltype=UTRAN," | cut -d , -f 5 | wc -l`


# CELL CELLR : INT INT
cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep ",cellrtype=INT," |
    cut -d , -f 4,6 | sed "s/CELL=//g" | sed "s/CELLR=//g" | tr "," " " |
    sort > $IntPath
# CELL CELLR : INT EXT
cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep ",cellrtype=EXT," |
    cut -d , -f 4,6 | sed "s/CELL=//g" | sed "s/CELLR=//g" | tr "," " " |
    sort > $ExtPath
# CELL CELLR : INT UTRAN
cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep ",cellrtype=UTRAN," |
    cut -d , -f 4,6 | sed "s/CELL=//g" | sed "s/CELLR=//g" | tr "," " " |
    sort > $UtranPath

# Int rels / INT
IntPerInt=`cat $IntPath | cut -d " " -f 1 | uniq -c | awk '{print $1}' |
    sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`
# Ext rels / INT
ExtPerInt=`cat $ExtPath | cut -d " " -f 1 | uniq -c | awk '{print $1}' |
    sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`
# Utran rels / INT
UtranPerInt=`cat $UtranPath | cut -d " " -f 1 | uniq -c | awk '{print $1}' |
    sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`
# Ext rels / EXT
ExtPerExt=`cat $ExtPath | cut -d " " -f 2 | sort | uniq -c | awk '{print $1}' |
    sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`
# Utran rels / UTRAN
UtranPerUtran=`cat $UtranPath | cut -d " " -f 2 | sort | uniq -c | awk '{print $1}' |
    sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`

# Write infos
echo "# BSC name,Int cells,Ext cells,Utran cells,Int rels / Int cell,Ext rels / Int cell,Utran rels / Int cell,Ext rels / Ext cell,Utran rels / Utran cell"
echo "# `echo $BSCNames | wc -w`,$NumIG,$NumEG($NumEGnu),$NumEU($NumEUnu),$IntPerInt,$ExtPerInt,$UtranPerInt,$ExtPerExt,$UtranPerUtran"

# Avg of Int rels / INT
AvgIntPerInt=`echo $IntPerInt | tr " " "\n" | tr "();" " " |
    awk 'BEGIN{R=0;C=0;}{R+=$1*$2; C+=$2;}END{if(C>0) print R/C; else print 0;}'`
# Avg of Ext rels / INT
AvgExtPerInt=`echo $ExtPerInt | tr " " "\n" | tr "();" " " |
    awk 'BEGIN{R=0;C=0;}{R+=$1*$2; C+=$2;}END{if(C>0) print R/C; else print 0;}'`
# Avg of Utran rels / INT
AvgUtranPerInt=`echo $UtranPerInt | tr " " "\n" | tr "();" " " |
    awk 'BEGIN{R=0;C=0;}{R+=$1*$2; C+=$2;}END{if(C>0) print R/C; else print 0;}'`
# Avg of Ext rels / EXT
AvgExtPerExt=`echo $ExtPerExt | tr " " "\n" | tr "();" " " |
    awk 'BEGIN{R=0;C=0;}{R+=$1*$2; C+=$2;}END{if(C>0) print R/C; else print 0;}'`
# Avg of Ext rels / EXT
AvgUtranPerUtran=`echo $UtranPerUtran | tr " " "\n" | tr "();" " " |
    awk 'BEGIN{R=0;C=0;}{R+=$1*$2; C+=$2;}END{if(C>0) print R/C; else print 0;}'`


# Total number of Int rels / INT
NumIntRels=`cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" | 
    grep ",cellrtype=INT," | cut -d , -f 4,6,7 |
    sed "s/CELL=//g" | sed "s/CELLR=//g" | sed "s/DIR=//g" | tr "," " " | 
    awk 'BEGIN{M=0; S=0;}{if("MUTUAL"==$3) M+=1; else S+=1;}END{printf "M=%d; S=%d", M,S;}'`
# Total number of Ext rels / INT
NumExtRels=`cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" | 
    grep ",cellrtype=EXT," | cut -d , -f 4,6,7 |
    sed "s/CELL=//g" | sed "s/CELLR=//g" | sed "s/DIR=//g" | tr "," " " | 
    awk 'BEGIN{M=0; S=0;}{if("MUTUAL"==$3) M+=1; else S+=1;}END{printf "M=%d; S=%d", M,S;}'`
# Total number of Utran rels / INT
NumUtranRels=`cat $BSCRelPathes | grep -v "^[ ]*$" | grep -v "^[ ]*#" |
    grep -c ",cellrtype=UTRAN," | sed "s/^/S=/g"`

# Write infos
echo "#,,,,$NumIntRels; Avg=$AvgIntPerInt,$NumExtRels; Avg=$AvgExtPerInt,$NumUtranRels; Avg=$AvgUtranPerInt,$NumExtRels; Avg=$AvgExtPerExt,$NumUtranRels; Avg=$AvgUtranPerUtran"


for BSCName in $BSCNames
do
    BSCCellPath=$Directory/$BSCName.BSCCells
    BSCRelPath=$Directory/$BSCName.BSCRels

    # Calc number of cells
    NumIG=`grep -c ",celltype=INT,"   $BSCCellPath`
    NumEG=`grep -c ",celltype=EXT,"   $BSCCellPath`
    NumEU=`grep -c ",celltype=UTRAN," $BSCCellPath`

    # CELL CELLR : INT INT
    cat $BSCRelPath | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep ",cellrtype=INT," |
    cut -d , -f 4,6 | sed "s/CELL=//g" | sed "s/CELLR=//g" | tr "," " " | sort > $IntPath

    # CELL CELLR : INT EXT
    cat $BSCRelPath | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep ",cellrtype=EXT," |
    cut -d , -f 4,6 | sed "s/CELL=//g" | sed "s/CELLR=//g" | tr "," " " | sort > $ExtPath

    # CELL CELLR : INT UTRAN
    cat $BSCRelPath | grep -v "^[ ]*$" | grep -v "^[ ]*#" | grep ",cellrtype=UTRAN," |
    cut -d , -f 4,6 | sed "s/CELL=//g" | sed "s/CELLR=//g" | tr "," " " | sort > $UtranPath

    # Int rels / INT
    IntPerInt=`cat $IntPath | cut -d " " -f 1 | uniq -c | awk '{print $1}' |
        sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`
    # Ext rels / INT
    ExtPerInt=`cat $ExtPath | cut -d " " -f 1 | uniq -c | awk '{print $1}' |
        sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`
    # Utran rels / INT
    UtranPerInt=`cat $UtranPath | cut -d " " -f 1 | uniq -c | awk '{print $1}' |
        sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`

    # Ext rels / EXT
    ExtPerExt=`cat $ExtPath | cut -d " " -f 2 | sort | uniq -c | awk '{print $1}' |
        sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`

    # Utran rels / UTRAN
    UtranPerUtran=`cat $UtranPath | cut -d " " -f 2 | sort | uniq -c | awk '{print $1}' |
        sort -n | uniq -c | awk '{printf "%s(%s); ",$2,$1}' | sed "s/; $//g"`

    # Write infos
    echo "\"$BSCName\",$NumIG,$NumEG,$NumEU,$IntPerInt,$ExtPerInt,$UtranPerInt,$ExtPerExt,$UtranPerUtran"
done

# ___ Postprocessing ___________________________________________________________

# Delete temporary files
rm -r -f $TmpDir
