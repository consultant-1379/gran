#!/bin/bash

#version="$Id: list_BSC_cells_by_BSC.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# ___ Help _____________________________________________________________________

if [ $# -ne 2 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <SimulationName> <OutputDir>

where
 SimulationName
    Name of NETSim simulatin that contains the MSC and BSC NEs.
 OutputDir
    The directory of output BSC cells lists.

Example:
 $This Simulation01 Simulation01_logs

DESCRIPTION:
 List the internal-, external GSM cells and external UTRAN cells of every
 BSC NEs in the given simulation into seperate files (<BSCName>.BSCCells).

ENVIRONMENT:
 Below variables needs to be set up:
  NETSimInstDirectory: The NETSim installation directory.
        Default is "\$HOME/inst".

 The list_BSC_names.sh and list_BSC_cells.sh must be in the same directory
 where this script is.

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
SimName=$1      # SimName: simulation name
OutDir=$2       # OutDir: output directory


# ___ Main activity ____________________________________________________________

# # List BSC names
# echo "Fetch BSC names from simulation $SimName ..."
# BSCNames=`$AbsDir/list_BSC_names.sh $SimName`

# # List BSC cells
# for BSCName in $BSCNames
# do
#     echo "List BSC cells from BSC $BSCName into $BSCName.BSCCells file ..."
#     $AbsDir/list_BSC_cells.sh $SimName $BSCName > $OutDir/$BSCName.BSCCells
# done

# List BSC names
echo "Fetch MSC-BSC relations from simulation $SimName ..."
Rels=`$AbsDir/list_MSC_BSC_rels.sh $SimName | grep -v "^[ ]*$" | grep -v "^[ ]*#.*$"`

# List BSC cells
for Rel in $Rels
do
    MSC=`echo $Rel | cut -d , -f 1`
    BSC=`echo $Rel | cut -d , -f 2`
    echo "List BSC cells from MSC $MSC - BSC $BSC into $BSC.BSCCells file ..."
    $AbsDir/list_BSC_cells.sh $SimName $MSC $BSC > $OutDir/$BSC.BSCCells
done
