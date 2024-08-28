#!/bin/bash

#version="$Id: list_BSC_cells.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# ___ Help _____________________________________________________________________

if [ $# -lt 3 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <SimulationName> <MSCName> <BSCName> [<BSCName> ...]

where
 SimulationName
    Name of NETSim simulation that contains the MSC and BSC NEs.
 MSCName
    Name of MSC NE that manage the BSC NEs.
 BSCName
    Name of BSC NE.

Example:
 $This Simulation01 MSC01 BSC0101 BSC0102

DESCRIPTION:
 List the internal-, external GSM cells and external UTRAN cells of the given
 BSC NEs in the given simulation. The MSC and BSC nodes in the simulation must
 be started.

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

# Get absolute path
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
MSCName=$2
shift
shift
BSCNames=$@     # BSCNames: name of BSC NEs in the simulation


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
# HostName
HostName=`hostname`


# ___ Main activity ____________________________________________________________

# List BSC cells for all BSC
echo "######################################################################"
echo "#### Host = $HostName"
echo "### Simulation = $SimName"
for BSCName in $BSCNames
do
    # Create script
    echo "RLDEP:CELL=ALL;" > $MmlScript
    echo ".unix echo ___MatchPoint1___" >> $MmlScript
    echo "RLDEP:CELL=ALL,EXT;" >> $MmlScript
    echo ".unix echo ___MatchPoint2___" >> $MmlScript
    echo "RLDEP:CELL=ALL,EXT,UTRAN;" >> $MmlScript
    # Run Script
    $NETSimInstDirectory/netsim_pipe -q -sim $SimName -ne $BSCName < $MmlScript > $MmlOutput
    # Find separator lines
    MatchPoint1=`grep -n "___MatchPoint1___$" $MmlOutput | cut -d : -f 1`
    MatchPoint2=`grep -n "___MatchPoint2___$" $MmlOutput | cut -d : -f 1`

    # List internal GSM cells
    echo "# Internal GSM cells"
    echo "# SimName, BSCName, CellType, CellName, MCC-MNC-LAC-CID, additional named attributes ..."
    LastLine=`echo $MatchPoint1 1 | awk '{R=$1-$2; print R}'`
    cat $MmlOutput | head -n $LastLine |
        grep -v "^[ ]*$" | grep -v "^CELL DESCRIPTION DATA$" | grep -v "^END$" |
        awk -f $AbsDir/key_value.awk | awk -v nGroupLines=3 -f $AbsDir/join_lines.awk |
        sed "s/^/sim=$SimName,msc=$MSCName,bsc=$BSCName,celltype=INT,/g"

    # List external GSM cells
    echo "# External GSM cells"
    echo "# SimName, BSCName, CellType, CellName, MCC-MNC-LAC-CID, additional named attributes ..."
    FirstLine=`echo $MatchPoint1 1 | awk '{R=$1+$2; print R}'`
    LastLine=`echo $MatchPoint2 1 | awk '{R=$1-$2; print R}'`
    cat $MmlOutput | head -n $LastLine | tail -n +$FirstLine | 
        grep -v "^[ ]*$" | grep -v "^CELL DESCRIPTION DATA$" | grep -v "^END$" |
        awk -f $AbsDir/key_value.awk | awk -v nGroupLines=3 -f $AbsDir/join_lines.awk |
        sed "s/^/sim=$SimName,msc=$MSCName,bsc=$BSCName,celltype=EXT,/g"

    # List external UTRAN cells
    echo "# External UTRAN cells"
    echo "# SimName, BSCName, CellType, CellName, MCC-MNC-LAC-CID-RNCID, additional named attributes ..."
    FirstLine=`echo $MatchPoint2 1 | awk '{R=$1+$2; print R}'`
    cat $MmlOutput | tail -n +$FirstLine | 
        grep -v "^[ ]*$" | grep -v "^CELL DESCRIPTION DATA$" | grep -v "^END$" |
        awk -f $AbsDir/key_value.awk | awk -v nGroupLines=2 -f $AbsDir/join_lines.awk | 
        sed "s/^/sim=$SimName,msc=$MSCName,bsc=$BSCName,celltype=UTRAN,/g"
done


# ___ Postprocessing ___________________________________________________________

# Delete temporary files
rm -r -f $TmpDir
