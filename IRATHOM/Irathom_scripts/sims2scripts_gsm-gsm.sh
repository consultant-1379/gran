#!/bin/bash

#version="$Id: $"

# ___ Help _____________________________________________________________________


if [ $# -ne 4 ] || ! ([ "xforward" == "x$1" ]) # || [ "xnew" != "x$1" ])
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <RelationMode> <OutputDir>
        "<SimulationName> [<SimulationName> ...]"
        "<SimulationName> [<SimulationName> ...]"

where
 RelationMode
    There are two mode to connect the two side to each other with external GSM
    relations.
     - 'forward': Modify the existing external GSM relations to forward those
        to the other side. The number of external GSM relations will not
        change.
     - 'new': Leave the original relations unchanged and add new external GSM
        relations to the other side based on the original realtions. The number
        of external GSM relations will be doubled.
        NOTE: This option is not supported yet.
 OutputDir
    The directory where all generated files (lists, maps, MML scripts, schell
    scripts) will be placed. This directory will contain all necessarry file
    to update the simulations.
 SimulationName
    NETSim simulation name.

Example:
 $This forward ./test/ "Side1Sim1 Side1Sim2" "Side2Sim1 Side2Sim2"

DESCRIPTION:
 The two side must built up from twin simulations and the two list of
 simulation names must contain the twin simulations in the same order.
 (See example above.)
 Two simulation are twin simulations if those were be generated from the same
 ".dog" and ".dogprofile" file except the different "msc_start_index" in the
 ".dogprofile" files. This difference is required to ensure the uniquness of
 MSC, BSC and GSM cell names within twin simulations.
 The MSC, BSC and GSM cell names must unique within all simulations. It is
 possible to ensure with the carfully choosed "mnc_start_index" values
 for different simulations. It require this start index must different for
 all simulation.
 
ENVIRONMENT:
 Below variables needs to be set up:
  - NETSimInstDirectory
        The NETSim installation directory.
        Default is "\$HOME/inst".

 The following scripts must be in the same directory where this script is:


__END_OF_HELP__
exit 1
fi


# ___ Parameters _______________________________________________________________

# Parameters
RelationMode=$1
OutDir=$2
Side1SimNames=$3
Side2SimNames=$4


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


# ___ Preprocessing ____________________________________________________________

# Check if the output directory is valir or not
CurrDir=`pwd`
pushd $AbsDir > /dev/null
SrcDir=`pwd`
popd > /dev/null
mkdir -p "$OutDir"
pushd $OutDir > /dev/null
DstDir=`pwd`
popd > /dev/null

IsSubDir=`echo "$CurrDir" | grep -c "^$DstDir"`
if [ $IsSubDir -gt 1 ] || [ "x$CurrDir" == "x$DstDir" ]
then
    echo "ERROR: The output directory must not be the current directory or a parent of it!"
    exit 1
fi
IsSubDir=`echo "$SrcDir" | grep -c "^$DstDir"`
if [ $IsSubDir -gt 0 ] || [ "x$SrcDir" == "x$DstDir" ]
then
    echo "ERROR: The output directory must not be the source directory or a parent of it!"
    exit 1
fi

# Set directory pathes
SimNames="$Side1SimNames $Side2SimNames"
WorkDir=$OutDir/work_data
ResultDir=$OutDir/result

# Prepare output directory
if [ -d "$OutDir" ]
then
    rm -r -f "$OutDir"
fi
mkdir -p "$OutDir"
mkdir -p "$WorkDir"
mkdir -p "$ResultDir"


# ___ Main activity ____________________________________________________________

echo "External GSM relation configuration mode: $RelationMode"
echo "Output directory: $OutDir"
echo "Simulations on side 1: $Side1SimNames"
echo "Simulations on side 1: $Side2SimNames"

echo ""
echo "--- Preparation ---------------------------------------------------------"
echo ""

# Preparation: list cells and relations
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
        echo "    MSC $MSC - BSC $BSC:"
        echo "      List cells into:     $SimWorkDir/$BSC.BSCCells ..."
        $AbsDir/list_BSC_cells.sh $SimName $MSC $BSC > $SimWorkDir/$BSC.BSCCells
        echo "      List relations into: $SimWorkDir/$BSC.BSCRels ..."
        $AbsDir/list_BSC_rels.sh $SimName $MSC $BSC > $SimWorkDir/$BSC.BSCRels.tmp
        $AbsDir/set_cellrtype.sh $SimWorkDir/$BSC.BSCCells $SimWorkDir/$BSC.BSCRels.tmp > $SimWorkDir/$BSC.BSCRels
        rm -f $SimWorkDir/$BSC.BSCRels.tmp
    done
done

# Get the cells and rels files
Side1Cells=`for i in $Side1SimNames; do ls -1 $WorkDir/$i/*.BSCCells; done`
Side2Cells=`for i in $Side2SimNames; do ls -1 $WorkDir/$i/*.BSCCells; done`
Side1Rels=`for i in $Side1SimNames; do ls -1 $WorkDir/$i/*.BSCRels; done`
Side2Rels=`for i in $Side2SimNames; do ls -1 $WorkDir/$i/*.BSCRels; done`

echo $Side1Cells | tr " " "\n" > $WorkDir/cellspathes.side1.txt
echo $Side2Cells | tr " " "\n" > $WorkDir/cellspathes.side2.txt
echo $Side1Rels | tr " " "\n" > $WorkDir/relspathes.side1.txt
echo $Side2Rels | tr " " "\n" > $WorkDir/relspathes.side2.txt

# Informations about simulations
echo ""
echo "--- Informations about simulations --------------------------------------"
echo ""
for SimName in $SimNames
do
    $AbsDir/info.sh $WorkDir/$SimName > $WorkDir/${SimName}_info.csv
    Sums1=`grep -A 1 "# BSC name" $WorkDir/${SimName}_info.csv | tail -n 1 | cut -d , -f  2,3,4,6,8`
    Sums2=`grep -A 2 "# BSC name" $WorkDir/${SimName}_info.csv | tail -n 1 | cut -d , -f  6,8`
    NumIG=`echo $Sums1 | cut -d , -f 1`
    NumEG=`echo $Sums1 | cut -d , -f 2`
    NumEU=`echo $Sums1 | cut -d , -f 3`
    ExtPerInt1=`echo $Sums1 | cut -d , -f 4`
    ExtPerExt1=`echo $Sums1 | cut -d , -f 5`
    ExtPerInt2=`echo $Sums2 | cut -d , -f 1`
    ExtPerExt2=`echo $Sums2 | cut -d , -f 2`
    echo "GSM sim $SimName"
    echo "Cells: $NumIG INT cell, $NumEG EXT cell, $NumEU UTRAN cell"
    echo "External gsm rels/INT cell: $ExtPerInt2 $ExtPerInt1"
    echo "External gsm rels/EXT cell: $ExtPerExt2 $ExtPerExt1"
    echo "BSC,Int,Ext,Utran,Ext rels/Int cell,Ext rels/Ext cells" | tr "," "\t"
    grep -v "^[ ]*$" $WorkDir/${SimName}_info.csv | grep -v "^[ ]*#.*$" | 
        cut -d , -f 1,2,3,4,6,8 | tr "," "\t"
    echo ""
done


echo ""
echo "--- Map external GSM cell names and CGI values --------------------------"
echo ""

# Map GSM cells from side 1 to the twin cells on side 2
$AbsDir/gen_gsm_map.sh $WorkDir $WorkDir/cells.EXT.side1.map.csv $WorkDir/cells.INT.side2.map.csv $WorkDir/cells.EXT.side2.map.csv "$Side1Cells" "$Side2Cells"
if [ "$?" -ne "0" ]; then
    echo "SCRIPT TERMINATED BY AN ERROR"
    exit 1
fi

# Generate MML scripts to update simulations
echo ""
if [ "xforward" == "x$RelationMode" ]
then
    echo "--- Forward external GSM relations to the other side --------------------"
    # Delete actual external GSM relations
    for RelsPath in $Side1Rels $Side2Rels
    do
        MMLPath=`echo $RelsPath | sed "s/\.BSCRels$/.rels.EXT.delete.mml/g"`
        $AbsDir/delete_rels.sh EXT $RelsPath > $MMLPath
    done
    # Modify MNC vanues of intrenal cells on side 2
    # Modify extrenal cells to refer the cells on the other side
    $AbsDir/update_cells_gsm-gsm.sh $RelationMode $WorkDir/cells.EXT.side1.map.csv $WorkDir/cells.INT.side2.map.csv $WorkDir/cells.EXT.side2.map.csv "$Side1Cells" "$Side2Cells"
    # Create again the deleted external GSM relations now toward cells on the other side
    $AbsDir/update_rels_gsm-gsm.sh $RelationMode $WorkDir/cells.EXT.side1.map.csv $WorkDir/cells.EXT.side2.map.csv "$Side1Rels" "$Side2Rels"
# else
#     echo "--- Create new external GSM relations to the other side -----------------"
#     # Modify extrenal cells to refer the cells on the other side
#     $AbsDir/update_cells_gsm-gsm.sh $RelationMode $WorkDir/cells.EXT.side1.map.csv $WorkDir/cells.INT.side2.map.csv $WorkDir/cells.EXT.side2.map.csv "$Side1Cells" "$Side2Cells"
#     # Add new external GSM cells that refer to the cells on the other side
#     #$AbsDir/add_cells_gsm-gsm.sh $WorkDir/cells.EXT.side1.map.csv $WorkDir/cells.EXT.side2.map.csv "$Side1Cells" "$Side2Cells"
#     # Create new extrernal GSM relations toward cells on the oter side
#     #$AbsDir/add_rels_gsm-gsm.sh $WorkDir/cells.EXT.side1.map.csv $WorkDir/cells.EXT.side2.map.csv "$Side1Rels" "$Side2Rels"
fi
echo ""


# Create final MML script
echo ""
echo "--- Create final MML scripts --------------------------------------------"
echo ""
for SimName in $SimNames
do
    SimWorkDir=$WorkDir/$SimName
    SimResultDir=$ResultDir/$SimName
    pushd $SimWorkDir > /dev/null
    BSCNames=`ls -1 *.BSCRels | sed "s/\.BSCRels$//g" | grep "^[^\.]*$"`
    popd > /dev/null
    for BSCName in $BSCNames
    do
        echo "$BSCName"
        $AbsDir/merge_scripts_gsm-gsm.sh $SimWorkDir $SimName $BSCName $SimResultDir
    done
done
echo ""

echo "Generate batch scripts"
# Create a simple script to execute all parts
echo "  $ResultDir/rels.delete.sh"
cat > $ResultDir/rels.delete.sh <<__END_OF_CAT__
#!/bin/bash

# Create a simple script to execute the MML scripts
time for MMLPath in \`ls ./*/*.rels.delete.mml\`
do
    echo "\$MMLPath (\`date\`)"
    echo "" > \$MMLPath.log
    xterm -geometry 120x60+0+0 -e "less +F \$MMLPath.log" &
    XtermPid=\$!
    $NETSimInstDirectory/netsim_shell < \$MMLPath >> \$MMLPath.log
    kill \$XtermPid
    echo "Errors: \`egrep -c -i --color "(NOT ACCEPTED|fault|error|exception)" \$MMLPath.log\`"
    egrep -i --color "(NOT ACCEPTED|fault|error|exception)" \$MMLPath.log
    echo ""
done | tee \$0.log
echo "# End time: \`date\`"

__END_OF_CAT__

# Create a simple script to execute all parts
echo "  $ResultDir/cell_rels.update.sh"
cat > $ResultDir/cell_rels.update.sh <<__END_OF_CAT__
#!/bin/bash

# Create a simple script to execute the MML scripts
time for MMLPath in \`ls ./*/*.cell_rels.update.mml\`
do
    echo "\$MMLPath (\`date\`)"
    echo "" > \$MMLPath.log
    xterm -geometry 120x60+0+0 -e "less +F \$MMLPath.log" &
    XtermPid=\$!
    $NETSimInstDirectory/netsim_shell < \$MMLPath >> \$MMLPath.log
    kill \$XtermPid
    echo "Errors: \`egrep -c -i --color "(NOT ACCEPTED|fault|error|exception)" \$MMLPath.log\`"
    egrep -i --color "(NOT ACCEPTED|fault|error|exception)" \$MMLPath.log
    echo ""
done | tee \$0.log
echo "# End time: \`date\`"

__END_OF_CAT__

# Create a simple script to execute all parts
echo "  $ResultDir/full.sh"
cat > $ResultDir/full.sh <<__END_OF_CAT__
#!/bin/bash

# Create a simple script to execute the MML scripts
time for MMLPath in \`ls ./*/*.full.mml\`
do
    echo "\$MMLPath (\`date\`)"
    echo "" > \$MMLPath.log
    xterm -geometry 120x60+0+0 -e "less +F \$MMLPath.log" &
    XtermPid=\$!
    $NETSimInstDirectory/netsim_shell < \$MMLPath >> \$MMLPath.log
    kill \$XtermPid
    echo "Errors: \`egrep -c -i --color "(NOT ACCEPTED|fault|error|exception)" \$MMLPath.log\`"
    egrep -i --color "(NOT ACCEPTED|fault|error|exception)" \$MMLPath.log
    echo ""
done | tee \$0.log
echo "# End time: \`date\`"

__END_OF_CAT__

# Done
echo ""

