#!/bin/bash

#version="$Id: createUtranCell_INFO.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# Created by  : Fatih ONUR
# Created in  : 2010.12.10
##
### VERSION HISTORY
##################################################
# Ver1        : Created for Kornel Horvath (ekorhor)
# Purpose     : IRATHOM WRAN TO GRAN and vice versa (TERE: O.11.0)
# Description : Scripts outlines necessary attributes for GRAN sims from WRAN network
# Date        : 10 Dec 2010
# Who         : Fatih ONUR
##################################################

if [ "$#" -ne 2 ]
then
cat<<HELP

Usage: $0 <start_rnc_num> <end_rnc_num>

Example: $0 1 1

DESCRPTN: Creates UtranCell attrubutes report for WRAN to GRAN IRATHOM

HELP
 exit 1
fi



################################
# FUNCTIONS
################################

#
# get total num of cell per each RBS
#
getNumOfCell() # RNCCOUNT RBSCOUNT
{
RNCCOUNT=$1
RBSCOUNT=$2

#
# Num of cells per RBS for each band
#
BAND_A=3
BAND_B=6
BAND_C=9
BAND_D=12
DEFAULT=3


#
## Num of rbs per band
#
NUMOFRBS_TYPE_C_BAND_A=109  # 3 cells per RBS
NUMOFRBS_TYPE_C_BAND_B=78   # 6 cells per RBS
NUMOFRBS_TYPE_C_BAND_C=24   # 9 cells per RBS
NUMOFRBS_TYPE_C_BAND_D=21   # 12 cells per RBS

#
## Total num of cells per type
#
SWITCH_TO_BAND_A=1
SWITCH_TO_BAND_B=`expr $NUMOFRBS_TYPE_C_BAND_A + 1`
SWITCH_TO_BAND_C=`expr $NUMOFRBS_TYPE_C_BAND_A + 1`
SWITCH_TO_BAND_D=`expr $NUMOFRBS_TYPE_C_BAND_A + $NUMOFRBS_TYPE_C_BAND_C + 1`


#
## Switch check
#
if [ "$RNCCOUNT" -le 30 ]
then
  if [ "$RBSCOUNT" -ge "1" ]
  then
    TEMP=$BAND_A
  fi

  if [ "$RBSCOUNT" -ge "$SWITCH_TO_BAND_B" ]
  then
    TEMP=$BAND_B
  fi
fi

if [ "$RNCCOUNT" -ge 31 ] && [ "$RNCCOUNT" -le 32 ]
then
  if [ "$RBSCOUNT" -ge "1" ]
  then
    TEMP=$BAND_A
  fi

  if [ "$RBSCOUNT" -ge "$SWITCH_TO_BAND_C" ]
  then
    TEMP=$BAND_C
  fi

  if [ "$RBSCOUNT" -ge "$SWITCH_TO_BAND_D" ]
  then
    TEMP=$BAND_D
  fi
fi

if [ "$RNCCOUNT" -ge 33 ] && [ "$RNCCOUNT" -le 34 ]
then
  if [ "$RBSCOUNT" -ge "1" ]
  then
    TEMP=$BAND_A
  fi
fi

if [ "$RNCCOUNT" -ge 35 ]
then
  if [ "$RBSCOUNT" -ge "1" ]
  then
    TEMP=$BAND_A
  fi

  if [ "$RBSCOUNT" -ge "$SWITCH_TO_BAND_B" ]
  then
    TEMP=$BAND_B
  fi
fi

# NUMOFCELL
echo $TEMP
}


# Add leading zeros
zero() { # number, length
    # Need to remove leading 0, might cause the value to be 
    # interpreted as octal
    case "$1" in
	0) 
	    N="$1"
	    ;;
	0*)
	    N=`echo "$1"| cut -c2-`
	    ;;
	*) 
	    N="$1"
	    ;;
    esac
    case "$2" in
	2) 
         printf "%.2d" "$N"
	 ;;
	3) 
         printf "%.3d" "$N"
	 ;;
	*) 
         printf "%d" "$N"
	 ;;
    esac
}

rbs_name() # rncnumber rbsnumber
{
    echo "`rnc_name $1`RBS`zero $2 2`"
}
rxi_name() # rncnumber rxinumber
{
    echo "`rnc_name $1`RXI`zero $2 2`"
}
rnc_name() # rncnumber
{
    echo "RNC`zero $1 2`"
}
 
cell_name() # rncnumber rbsnumber cellnumber
{
    case  "$CELLNAME" in
	gsm) 
	   echo "`zero $1 2``zero $2 3`_$3"
	   ;;

	*)
           echo "`rnc_name $1`-$2-$3"
	   ;;
    esac
}

#
## get total numb of cells for defined num of RBS
#
getTotalCells() # NUMOFRBS
{
LIMIT=$1

NUMOFRNC_TYPE_C=32
NUMOFRNC_TYPE_F=2

#
# Num of cells per RBS for each band
#
BAND_A=3
BAND_B=6
BAND_C=9
BAND_D=12
DEFAULT=3

#
## Num of rbs per band
#
NUMOFRBS_TYPE_C_BAND_A=109  # 3 cells per RBS
NUMOFRBS_TYPE_C_BAND_B=78   # 6 cells per RBS
NUMOFRBS_TYPE_C_BAND_C=24   # 9 cells per RBS
NUMOFRBS_TYPE_C_BAND_D=21   # 12 cells per RBS

NUMOFRBS_TYPE_F_BAND_A=768 # 3 cells per RBS


#
## Total num of rbs per type
#
TOTALRBS_TYPE_C_V1=`expr $NUMOFRBS_TYPE_C_BAND_A + $NUMOFRBS_TYPE_C_BAND_B`
TOTALRBS_TYPE_C_V2=`expr $NUMOFRBS_TYPE_C_BAND_A + $NUMOFRBS_TYPE_C_BAND_C + $NUMOFRBS_TYPE_C_BAND_D`

TOTALRBS_TYPE_F_V1=$NUMOFRBS_TYPE_F_BAND_A

#
## Total num of cells per type
#
TOTALCELLS_TYPE_C_V1=`expr \( $NUMOFRBS_TYPE_C_BAND_A \* $BAND_A \) + \( $NUMOFRBS_TYPE_C_BAND_B \* $BAND_B \)`
TOTALCELLS_TYPE_C_V2=`expr \( $NUMOFRBS_TYPE_C_BAND_A \* $BAND_A \) + \( $NUMOFRBS_TYPE_C_BAND_C \* $BAND_C \) + \( $NUMOFRBS_TYPE_C_BAND_D \* $BAND_D \)`

TOTALCELLS_TYPE_F_V1=`expr \( $NUMOFRBS_TYPE_F_BAND_A \* $BAND_A \)`


case "$LIMIT"
in
  $TOTALRBS_TYPE_C_V1)  TOTALCELLS=$TOTALCELLS_TYPE_C_V1 ;;
  $TOTALRBS_TYPE_C_V2)  TOTALCELLS=$TOTALCELLS_TYPE_C_V2 ;;
  $TOTALRBS_TYPE_F_V1)  TOTALCELLS=$TOTALCELLS_TYPE_F_V1 ;;
  *)                    TOTALCELLS=`expr $LIMIT \* $DEFAULT`
esac

echo $TOTALCELLS
}


################################
# MAIN
################################

echo "# ...script started running at "`date`
echo ""

#########################################
# CREATE REPORT FOR IRATHOM
#########################################

echo ""
echo "# CREATING A REPORT FOR IRATHOM"
echo ""

RNCSTART=$1
RNCEND=$2
RCOUNT=$RNCSTART

while [ "$RCOUNT" -le "$RNCEND" ]
do

RNC=$RCOUNT

if [ "$RNC" -le 9 ]
then
  RNCNAME="RNC0"$RNC
  RNCCOUNT="0"$RNC
else
  RNCNAME="RNC"$RNC
  RNCCOUNT=$RNC
fi



################################
# ENVIRONMENT VALUES
################################

if [ "$RNCCOUNT" -eq 33 ] || [ "$RNCCOUNT" -eq 34 ]
then
NUMOFRBS=768
CELLNUM=3
elif [  "$RNCCOUNT" -eq 31 ] || [ "$RNCCOUNT" -eq 32 ]
then
NUMOFRBS=154
else
NUMOFRBS=187
CELLNUM=3
fi


COUNT=1
RBSCOUNT=1
CELLCOUNT=1

#########################################
#
# If Number of RBS = 187 then Number of UtranCell = 795 (109 x 3 Cell RBS, 78 x 6 Cell RBS)
# If Number of RBS = 768 then Number of UtranCell = 2,400 (736 x 3 Cell RBS, 32 x 6 Cell RBS)
# else Number of UtranCell = Number of RBS x 3
#
#########################################
TOTALCELLS=`getTotalCells $NUMOFRBS`

URAIDTEMP=`expr $RNCCOUNT \* 10`
URAIDSTART=`expr $URAIDTEMP - 9`
URAID=$URAIDSTART

########################
# LA, RA, SA
########################

REM=`expr $RNCCOUNT % 2`
DIV=`expr $RNCCOUNT / 2`

LASTART=`expr 15 \* \( $RNCCOUNT - 1 \) + 1`
SASTART=`expr $RNCCOUNT \* 795 - 794`
CIDSTART=`expr 795 \* $RNCCOUNT - 794`

if [ "$RNCCOUNT" -eq 34 ]
then
  LASTART=`expr 15 \* \( $RNCCOUNT - 1 \) + 13`
  SASTART=27763
  CIDSTART=27745
fi

RASTART=$LASTART # reverted back for reqId:3922

LA=$LASTART
RA=$RASTART
SA=$SASTART

CID=$CIDSTART

echo "###################################"
echo "# "$RNCNAME
echo "###################################"

while [ "$COUNT" -le "$TOTALCELLS" ]
do

  NUMOFCELL=`getNumOfCell $RNCCOUNT $RBSCOUNT`
  CELLSTOP=`expr $NUMOFCELL + 1`

  if [ "$CELLCOUNT" -eq "$CELLSTOP" ]
  then
    CELLCOUNT=1
    RBSCOUNT=`expr $RBSCOUNT + 1`
  fi

  UTRANCELLID=`cell_name $RNCCOUNT $RBSCOUNT $CELLCOUNT`
  

  URAREF="ManagedElement=1,RncFunction=1,Ura="$URAID
  UARFCNDL=`expr \( \( $RNCCOUNT \* $NUMOFRBS \) + $RBSCOUNT \) % 16384` 
  PRIMSCRCODE=`expr $COUNT % 512`
  PRIMARYCPICHPOWER=300
  QRXLEVMIN=-115
  QQUALMIN=-24
  SRATSEARCH=4
  MAXIMUMTRANSMISSIONPOWER=398

  USEDFREQTHRESH2DRSCP=-100
  USEDFREQTHRESH2DECNO=-12
  SRATSEARCH=4

  ###################################################
  #
  # According to your need modify output from below
  # START: OUTPUT
  ###################################################

  echo -n "RNCID="$RNCCOUNT",CID="$CID",USERLABEL="$UTRANCELLID",FDDARFCN="$UARFCNDL",SCRCODE="$PRIMSCRCODE",PRIMARYCPICHPOWER="$PRIMARYCPICHPOWER
  echo -n ",QQUALMIN="$QQUALMIN",LAC="$LA",QRXLEVMIN="$QRXLEVMIN",USEDFREQTHRESH2DECNO="$USEDFREQTHRESH2DECNO
  echo ",USEDFREQTHRESH2DRSCP="$USEDFREQTHRESH2DRSCP",SRATSEARCH="$SRATSEARCH
  # echo ""

  # END: OUTPUT
  ######################################################


  SA=`expr $SA + 1`
  CID=`expr $CID + 1`

  if [ "$RNCCOUNT" -ge 33 ]
  then
    REM=`expr \( $SA - $SASTART + 1 \) % 86`
  else
    REM=`expr \( $SA - $SASTART + 1 \) % 53`
  fi

  if [ "$REM" -eq 1 ]
  then
    LA=`expr $LA + 1`
    RA=`expr $RA + 1` # reverted back to original, modified for reqId:3922
  fi

  
  URAID=`expr $URAID + 1`
  if [ "$URAID" -gt "$URAIDTEMP" ]
  then
    URAID=$URAIDSTART
  fi 

  # For testing. To quit at required amount
  #if [ "$COUNT" -eq 3 ]
  #then
  #  break
  #  exit 1
  #fi

  CELLCOUNT=`expr $CELLCOUNT + 1`
  COUNT=`expr $COUNT + 1`
done

  RCOUNT=`expr $RCOUNT + 1`
done


echo "# ...script ended at "`date`
echo ""
