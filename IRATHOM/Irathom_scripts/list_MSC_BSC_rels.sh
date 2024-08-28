#!/bin/bash

#version="$Id: list_MSC_BSC_rels.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# ___ Help _____________________________________________________________________

if [ $# -ne 1 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <SimulationName>

where
 SimulationName
    Name of NETSim simulatin that contains the MSC and BSC NEs.

Example:
 $This Simulation01

DESCRIPTION:
 List name of MSC and BSC parent-child relations in the given simulation.

ENVIRONMENT:
 Below variables needs to be set up:
  NETSimInstDirectory: The NETSim installation directory.
        Default is "\$HOME/inst".
  TmpBaseDir: The base directory of temporary files.
        Default is the current directory.
        The "${This}.<userid>.tmpdir" subdirectory will be used to store
        temporary files.

__END_OF_HELP__
exit 1
fi


# ___ Environment ______________________________________________________________

# NETSim installation directory
if [ "x" == "x$NETSimInstDirectory" ]
then
    export NETSimInstDirectory="$HOME/inst"
fi

# Temporary directory where you have write permission
if [ "x" == "x$TmpBaseDir" ]
then
    TmpBaseDir=`pwd`
fi
TmpDir="$TmpBaseDir/`echo $0 | sed "s/^.*\///g"`.`whoami`.tmpdir"


# ___ Parameters _______________________________________________________________

# Parameters
SimName=$1      # SimName: simulation name


# ___ Preprocessing ____________________________________________________________

# Delete temporary files
if [ -d "$TmpDir" ]
then
    rm -r -f "$TmpDir"
fi
mkdir -p "$TmpDir"

# MmlScript: a writeable file path for MML script
MmlScript="$TmpDir/mml"
# MmlScript: a writeable file path for the output of MML script
MmlOutput="$TmpDir/mmlout"


# ___ Main activity ____________________________________________________________

# Open simulation and list NEs
cat > $MmlScript <<__END_OF_CAT__
.unix echo ___MatchPoint1___
.show simnes
.unix echo ___MatchPoint2___
.show relations
.unix echo ___MatchPoint3___
__END_OF_CAT__

# Run script
$NETSimInstDirectory/netsim_pipe -q -sim $SimName < $MmlScript > $MmlOutput

# Calc the first and last line number
MatchPoint1=`grep -n "^___MatchPoint1___$" $MmlOutput | cut -d : -f 1`
MatchPoint2=`grep -n "^___MatchPoint2___$" $MmlOutput | cut -d : -f 1`
MatchPoint3=`grep -n "^___MatchPoint3___$" $MmlOutput | cut -d : -f 1`
LineNum1=`echo $MatchPoint1 3 | awk '{R=$1+$2; print R}'`
LineNum2=`echo $MatchPoint2 2 | awk '{R=$1-$2; print R}'`

# Find BSC NEs
LineNum1=`echo $MatchPoint1 3 | awk '{R=$1+$2; print R}'`
LineNum2=`echo $MatchPoint2 2 | awk '{R=$1-$2; print R}'`
BSCs=`cat $MmlOutput | head -n $LineNum2 | tail -n +$LineNum1 | sed "s/  */./g" |
        grep ".GSM.BSC." | cut -d "." -f 1 --output-delimiter " "`
# Find MSC NEs
LineNum1=`echo $MatchPoint1 3 | awk '{R=$1+$2; print R}'`
LineNum2=`echo $MatchPoint2 2 | awk '{R=$1-$2; print R}'`
MSCs=`cat $MmlOutput | head -n $LineNum2 | tail -n +$LineNum1 | sed "s/  */./g" |
        grep ".GSM.MSC." | cut -d "." -f 1 --output-delimiter " "`
# Find MSC NEs
LineNum1=`echo $MatchPoint2 2 | awk '{R=$1+$2; print R}'`
LineNum2=`echo $MatchPoint3 1 | awk '{R=$1-$2; print R}'`
Rels=`cat $MmlOutput | head -n $LineNum2 | tail -n +$LineNum1 | grep -v "^[ ]*$"`

# Find MSC-BSC parent-child relations
echo "# MSC name, BSC name"
for MSC in $MSCs
do
    for BSC in $BSCs
    do
        IsRel=`echo $Rels | tr " " "\n" | grep "^${MSC}_${BSC}$" | wc -l`
        if [ 0 -lt "$IsRel" ]
        then
            echo "$MSC,$BSC"
        fi
    done
done


# ___ Postprocessing ___________________________________________________________

# Delete temporary files
rm -r -f $TmpDir
