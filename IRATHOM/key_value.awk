#!/bin/awk

#version="$Id: key_value.awk,v 1.1 2011/01/10 17:00:38 ekorhor Exp $"

# Preparation
BEGIN{
    FS         = "" # Break up command line by charactes instead words
    nLine      = 1  # Actual line number
    nFields    = 0  # Number of fields in the actual header/value line pair
    Field[0,0] = 0  # Field properties: begin/end of field, key word
}
# Process lines
{
    if(1 == nLine%2) {
        # Header line with key words
        chLast     = "x"    # Previous character
        iWordBegin = 1      # Word head position in the line
        iWordEnd   = -1     # Word end position in the line
        nFields    = 0      # Number of fields in the actual header line
        for(i=1; i<=NF; ++i) {
            if(" "==chLast && " "!=$(i)) {
                # Head of a word
                # save last field
                Field[nFields,0] = iWordBegin
                Field[nFields,1] = i-1
                Field[nFields,2] = substr($0, iWordBegin, iWordEnd-iWordBegin+1)
                ++nFields
                # start new field
                iWordBegin = i
            }
            else if(" "!=chLast && " "==$(i)) {
                # End of a word
                iWordEnd = i-1
            }
            chLast=$(i)
        }
        # Save last field
        if(iWordEnd < iWordBegin)
            iWordEnd = NF
        Field[nFields,0] = iWordBegin
        Field[nFields,1] = iWordEnd
        Field[nFields,2] = substr($0, iWordBegin, iWordEnd-iWordBegin+1)
        ++nFields
    }
    else {
        # Value line
        # Get values from the line and print the key value pairs
        for(i=0; i<nFields; ++i) {
            if(i<nFields-1) {
                Value = substr($0, Field[i,0], Field[i,1]-Field[i,0]+1)
                gsub(/^ */, "", Value)
                gsub(/ *$/, "", Value)
                printf "%s=%s,",Field[i,2],Value
            }
            else {
                Value = substr($0, Field[i,0])
                gsub(/^ */, "", Value)
                gsub(/ *$/, "", Value)
                printf "%s=%s\n",Field[i,2],Value
            }
        }
    }
    # increase line number
    ++nLine
}
