#!/bin/bash

#version="$Id: $"

# ___ Help _____________________________________________________________________

if [ $# -lt 4 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
cat<<__END_OF_HELP__
Usage: $This <WRANRelsFile> <UtranAttrsFile> <OutputDir>
             <SimulationName> [<SimulationName> ...]

where
 WRANRelsFile
    The log file about expected relations between GSM cells and UTRAN cells
    from WRAN point of view.
 UtranAttrsFile
    The log file from the WRAN simulation that contains the CID, RNCID, LAC and
    any other required attribute values for UTRAN cells. It should be generated
    with the createUtranCell_INFO.sh script or a modification of it or must
    contain the attributes in the same format as this script generate these.
 OutputDir
    The directory of output list, log files, MML scripts.
 SimulationName
    NETSim simulation name.

Example:
 $This UtranNetwork-GsmRelations.log UtranCellLacLogFile.log ./test/
       Simulation01 Simulation02

DESCRIPTION:
 Convert expected relations log file into an internal CSV format. Use the log
 file about expected UTRAN cell attributes. These two file will be used for
 set realtions and UTRAN cell attributes.

 List BSC cells from all simulation.

 Show informations about expected amount of cells and relations based on 
 the relations log file.

 Show informations about the cells and relations in the simulations.

 Map the realtions and the cells from the expected relations to the real cells.
 Generate MML scripts that delete all relations, update cell identifiers and
 create realations between the corresponding cells.

 For more informations about steps see the scripts listed below.

ENVIRONMENT:
 Below variables needs to be set up:
  - NETSimInstDirectory
        The NETSim installation directory.
        Default is "\$HOME/inst".

 The following scripts must be in the same directory where this script is:
    create_expected_utran_rels.sh
    createUtranCell_INFO.sh
    info_exp.sh
    info.sh
    info2.sh
    delete_utran_rels.sh
    list_MSC_BSC_rels.sh
    list_BSC_names.sh
    list_BSC_cells.sh
    mod_BSC_cells.sh
    merge_scripts_gsm-utran.sh
    key_value.awk
    join_lines.awk
    join_rel_lines.awk

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
LogFile=$1
UtranParamsFile=$2
OutDir=$3
shift
shift
shift
SimNames=$@


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

echo ""
echo "--- Preparation ---------------------------------------------------------"
echo ""

# Convert UtranRealtions fog file into expected relations CSV format
echo "Convert UtranRealtions fog file into $OutDir/work_data/ExpRels.csv file ..."
$AbsDir/create_expected_utran_rels.sh $LogFile > $WorkDir/ExpRels.csv

# # Check the RNC nodes (RNCIDs) in the expected relations
# RelsRNCIDs=`grep -v "^[ ]*$" $WorkDir/ExpRels.csv | grep -v "^[ ]*#.*$" |
#             cut -d , -f 3 | sort -n -u`
# RelsMinRNCID=`echo $RelsRNCIDs | tr " " "\n" | head -n 1`
# RelsMaxRNCID=`echo $RelsRNCIDs | tr " " "\n" | tail -n 1`
# echo "RNC nodes in expected relations:     $RelsMinRNCID - $RelsMaxRNCID"

# Check the RNC nodes (RNCIDs) in the UTRAN cell attributes
cp $UtranParamsFile $WorkDir/UtranParams.csv
UtranParamsRNCIDs=`grep -v "^[ ]*$" $WorkDir/UtranParams.csv | grep -v "^[ ]*#.*$" |
                   grep -o "RNCID=[0-9]*" | cut -d = -f 2 | sed "s/^0*//g" |
                   sort -n -u`
UtranParamsMinRNCID=`echo $UtranParamsRNCIDs | tr " " "\n" | head -n 1`
UtranParamsMaxRNCID=`echo $UtranParamsRNCIDs | tr " " "\n" | tail -n 1`
echo "RNC nodes in UTRAN cells attributes: $UtranParamsMinRNCID - $UtranParamsMaxRNCID"

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
        $AbsDir/list_BSC_rels.sh $SimName $MSC $BSC > $SimWorkDir/$BSC.BSCRels.tmp
        $AbsDir/set_cellrtype.sh $SimWorkDir/$BSC.BSCCells $SimWorkDir/$BSC.BSCRels.tmp > $SimWorkDir/$BSC.BSCRels
        rm -f $SimWorkDir/$BSC.BSCRels.tmp
        echo "      Generate MML script to delete external Utran relations ..."
        $AbsDir/delete_rels.sh UTRAN $SimWorkDir/$BSC.BSCRels > $SimWorkDir/$BSC.rels.delete.mml
    done
    # BSCCells files
    Cells="$Cells `ls -1 $SimWorkDir/*.BSCCells`"
done

# Informations about simulations
echo ""
echo "--- Informations about expected realtinos and simulations ---------------"
echo ""
$AbsDir/info_exp.sh $LogFile
echo ""


# Informations about simulations
echo ""
echo "--- Informations about simulations --------------------------------------"
echo ""
for SimName in $SimNames
do
    $AbsDir/info.sh $WorkDir/$SimName > $WorkDir/${SimName}_info.csv
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


# Set utran realtaions, update cells and generate scripts
echo ""
echo "--- Set utran realtaions, update cells and generate scripts -------------"
echo ""
$AbsDir/mod_BSC_cells.sh set_utran_rels -expectedrels $WorkDir/ExpRels.csv -utranparams $WorkDir/UtranParams.csv -simnames $SimNames -cells $Cells -outputdir $WorkDir/


# Create final MML script
echo ""
echo "--- Create final MML scripts --------------------------------------------"
echo ""
for SimName in $SimNames
do
    SimWorkDir=$WorkDir/$SimName
    SimResultDir=$ResultDir/$SimName
    pushd $SimWorkDir > /dev/null
    BSCNames=`ls -1 *.BSCCells | sed "s/\.BSCCells$//g" | grep "^[^\.]*$"`
    popd > /dev/null
    for BSCName in $BSCNames
    do
        echo "$BSCName ..."
        $AbsDir/merge_scripts_gsm-utran.sh $SimWorkDir $SimName $BSCName $SimResultDir
    done
done

# Check cell update informations

# Create a simple script to execute all parts
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

