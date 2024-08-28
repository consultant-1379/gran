#!/bin/bash

#version="$Id: mod_BSC_cells.sh,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# ___ Environment ______________________________________________________________

# NETSim installation directory
if [ "x" == "x$NETSimInstDirectory" ]
then
    export NETSimInstDirectory="$HOME/inst"
fi

Path=`echo $0 | sed "s/[^\/]*$//g"`
if [ "1" == `echo $Path | grep "^/" | wc -l` ]
then
    AbsDir=$Path
else
    AbsDir=`\ls -1 $(pwd)/$0 | sed "s/[^\/]*$//g"`
fi

# ___ Help _____________________________________________________________________

if [ $# -le 1 ]
then
    This=`echo $0 | sed "s/^.*\///g"`
    $NETSimInstDirectory/platf_indep_otp/linux/bin/escript $AbsDir/mod_BSC_cells.erl $@
cat<<__END_OF_HELP__
ENVIRONMENT:
 Below variables needs to be set up:
  NETSimInstDirectory: The NETSim installation directory.
        Default is "\$HOME/inst".

__END_OF_HELP__
exit 1
fi


# ___ Main activity ____________________________________________________________

$NETSimInstDirectory/platf_indep_otp/linux/bin/escript $AbsDir/mod_BSC_cells.erl $@
