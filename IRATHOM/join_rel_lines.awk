#!/bin/awk

#version="$Id: join_rel_lines.awk,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# Preparation
BEGIN{
    Cell = ""
    nRel = 1
}
# Process lines
{
    if("CELL=" == substr($0, 1, 5)) {
        Cell = $0
    }
    else if("CELLR=" == substr($0, 1, 6)) {
        if(1<nRel)
            printf "\n%s,%s",Cell,$0
        else
            printf "%s,%s",Cell,$0
        ++nRel
    }
    else {
        printf ",%s",$0
    }
}
END {
    printf "\n"
}
