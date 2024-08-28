#!/bin/bash

#version="$Id: $"

# ___ Help _____________________________________________________________________

if [ $# -ne 4 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <InputDir> <SimulationName> <BSCName> <OutputDir>

where
 IntputDir
    The directory where generated MML script files are located.
 SimulationName
    NETSim simulation name.
 BSCName
    BSC node name in the simulations which the final MML scripts is needed to
    generate for.
 OutputDir
    The directory where the final MML script files will be placed.

Example:
 $This ./test/work_dir/Sim1/ Sim1 BSC01 ./test/result/Sim1/

DESCRIPTION:
 Merge the number of MML scripts of a single BSC node into a few final MML
 scripts. The result MML scripts can apply all the changes that are
 necessarry to configure the BSC to the succesfull handover between sides.

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
InputDir=$1
SimName=$2
BSCName=$3
OutputDir=$4


# ___ Main activity ____________________________________________________________

# Every execution is starting with deletion of relations. Extract this step into
# a separate MML script. With this first script we can delete the relations from
# the simulations. The result simulation can be saved for future use with second
# step.

# First pass of two pass runnning: delete all relations
cat >$OutputDir/$BSCName.rels.delete.mml <<__END_OF_CAT__ 
.open $SimName
.select $BSCName

.unix echo \\# Delete relations
`cat $InputDir/$BSCName.rels.delete.mml`

.select
__END_OF_CAT__

# Second step delete the unused cells, modify the used cells and set the
# realtions. What cells ar affected is dependes on input parameters so this part
# can be different. This depending part is the second step that we can execute
# on the result simulation of first step.

# Second pass of two pass runnning: Delete/set cells and set relations
cat >$OutputDir/$BSCName.cell_rels.update.mml <<__END_OF_CAT__ 
.open $SimName
.select $BSCName

.unix echo \\# Delete modified or not used internal GSM cells
`cat $InputDir/$BSCName.cells.INT.delete.mml`

.unix echo \\# Update used internal GSM cells
`cat $InputDir/$BSCName.cells.INT.update.mml`

.unix echo \\# Delete modified or not used external GSM cells
`cat $InputDir/$BSCName.cells.EXT.delete.mml`

.unix echo \\# Update used external GSM cells
`cat $InputDir/$BSCName.cells.EXT.update.mml`

.unix echo \\# Delete modified or not used external UTRAN cells
`cat $InputDir/$BSCName.cells.UTRAN.delete.mml`

.unix echo \\# Update used external UTRAN cells
`cat $InputDir/$BSCName.cells.UTRAN.update.mml`
.select $BSCName

.unix echo \\# Create relations between internal GSM and external UTRAN cells
`cat $InputDir/$BSCName.rels.update.mml`

.select
__END_OF_CAT__

# Execute the both step
# Delete all relations, delete not used cells,modify used cells and set
# realtions.

# Create single MML script from all parts
cat >$OutputDir/$BSCName.full.mml <<__END_OF_CAT__ 
.open $SimName
.select $BSCName

.unix echo \\# Delete relations
`cat $InputDir/$BSCName.rels.delete.mml`

.unix echo \\# Delete modified or not used internal GSM cells
`cat $InputDir/$BSCName.cells.INT.delete.mml`

.unix echo \\# Update used internal GSM cells
`cat $InputDir/$BSCName.cells.INT.update.mml`

.unix echo \\# Delete modified or not used external GSM cells
`cat $InputDir/$BSCName.cells.EXT.delete.mml`

.unix echo \\# Update used external GSM cells
`cat $InputDir/$BSCName.cells.EXT.update.mml`

.unix echo \\# Delete modified or not used external UTRAN cells
`cat $InputDir/$BSCName.cells.UTRAN.delete.mml`

.unix echo \\# Update used external UTRAN cells
`cat $InputDir/$BSCName.cells.UTRAN.update.mml`
.select $BSCName

.unix echo \\# Create relations between internal GSM and external UTRAN cells
`cat $InputDir/$BSCName.rels.update.mml`

.select
__END_OF_CAT__

