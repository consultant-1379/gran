#!/bin/bash

#version="$Id: $"

# ___ Help _____________________________________________________________________

if [ $# -lt 2 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <OutputDir> <SimulationName> [<SimulationName> ...]

where
 OutputDir         the directory of output list, log files, MML scripts
 SimulationName    simulation name

Example:
 $This UtranNetwork-GsmRelations.log UtranCellLacLogFile.log ./test/
       Simulation01 Simulation02

DESCRIPTION:
 List BSC cells from all simulation.

__END_OF_HELP__
exit 1
fi


# ___ Environment ______________________________________________________________

# NETSim installation directory
if [ "x" == "x$NETSimInstDirectory" ]
then
    export NETSimInstDirectory="$HOME/inst"
fi
# Absolute path
Path=`echo $0 | sed "s/[^\/]*$//g"`
if [ "1" == `echo $Path | grep "^/" | wc -l` ]
then
    AbsDir=$Path
else
    AbsDir=`\ls -1 $(pwd)/$0 | sed "s/[^\/]*$//g"`
fi


# ___ Parameters _______________________________________________________________

# Parameters
OutDir=$1
shift
SimNames=$@


# ___ Preprocessing ____________________________________________________________

WorkDir=$OutDir/work_data
ResultDir=$OutDir/result

# Delete temporary files
if [ -d "$OutDir" ]
then
    rm -r -f "$OutDir"
fi
mkdir -p "$OutDir"
mkdir -p "$WorkDir"
mkdir -p "$ResultDir"


# ___ Main activity ____________________________________________________________

echo ""
echo "--- Preparation ---------------------------------------------------------"
echo ""

# Preparation
Cells=""
BSCNames=""
for SimName in $SimNames
do
    SimWorkDir=$WorkDir/$SimName
    SimResultDir=$ResultDir/$SimName
    mkdir -p $SimWorkDir
    mkdir -p $SimResultDir
    echo "Simulation $SimName:"
    # List BSC names
    echo "  Fetch MSC-BSC relations from simulation $SimName ..."
    Rels=`$AbsDir/list_MSC_BSC_rels.sh $SimName | grep -v "^[ ]*$" | grep -v "^[ ]*#.*$"`

    # List BSC cells
    for Rel in $Rels
    do
        MSC=`echo $Rel | cut -d , -f 1`
        BSC=`echo $Rel | cut -d , -f 2`
        BSCNames="$BSCNames $BSC"
        echo "    MSC $MSC - BSC $BSC:"
        echo "      List cells into:     $SimWorkDir/$BSC.BSCCells ..."
        $AbsDir/list_BSC_cells.sh $SimName $MSC $BSC > $SimWorkDir/$BSC.BSCCells
        echo "      List relations into: $SimWorkDir/$BSC.BSCRels ..."
        $AbsDir/list_BSC_rels.sh $SimName $MSC $BSC > $SimWorkDir/$BSC.BSCRels
        echo "      Generate MML script to delete all relations ..."
        $AbsDir/delete_rels.sh $SimWorkDir/$BSC.BSCRels > $SimWorkDir/$BSC.rels.delete.mml
    done
    # BSCCells files
    Cells="$Cells `ls -1 $SimWorkDir/*.BSCCells`"
done

# Informations about simulations
echo ""
echo "--- Informations about simulations --------------------------------------"
echo ""
for SimName in $SimNames
do
    $AbsDir/info2.sh $WorkDir/$SimName > $WorkDir/${SimName}_info.csv
    Sums1=`grep -A 1 "# BSC name" $WorkDir/${SimName}_info.csv | tail -n 1 | cut -d , -f  2,3,4,7,9`
    Sums2=`grep -A 2 "# BSC name" $WorkDir/${SimName}_info.csv | tail -n 1 | cut -d , -f  7,9`
    NumIG=`echo $Sums1 | cut -d , -f 1`
    NumEG=`echo $Sums1 | cut -d , -f 2`
    NumEU=`echo $Sums1 | cut -d , -f 3`
    UtranPerInt1=`echo $Sums1 | cut -d , -f 4`
    UtranPerUtran1=`echo $Sums1 | cut -d , -f 5`
    UtranPerInt2=`echo $Sums2 | cut -d , -f 1`
    UtranPerUtran2=`echo $Sums2 | cut -d , -f 2`
    echo "GSM sim $SimName"
    echo "Cells: $NumIG INT cell, $NumEG EXT cell, $NumEU UTRAN cell"
    echo "Utran rels/INT   cell: $UtranPerInt2 $UtranPerInt1"
    echo "Utran rels/UTRAN cell: $UtranPerUtran2 $UtranPerUtran1"
    echo "BSC,Int,Ext,Utran,Utran rels/Int cell,Utran rels/Utran cells" | tr "," "\t"
    grep -v "^[ ]*$" $WorkDir/${SimName}_info.csv | grep -v "^[ ]*#.*$" | 
        cut -d , -f 1,2,3,4,7,9 | tr "," "\t"
done

# Done
echo ""

