#!/bin/awk

#version="$Id: join_lines.awk,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# Preparation
BEGIN{
    nLine        = 0    # Actual line number
    GroupLine[0] = ""   # Lines in the group
}
# Process lines
{
    # Store actual line
    GroupLine[nLine%nGroupLines] = $0
    # If this line is the last in the grpoup then print the lines
    if(nLine%nGroupLines == nGroupLines-1) {
        for(i=0; i<nGroupLines; ++i)
            if(0==i) printf "%s",GroupLine[i]
            else printf ",%s",GroupLine[i]
        printf "\n"
    }
    # increase line number
    ++nLine
}
