#!/usr/bin/env python3
import sexpdata
import sys

def walk_bmarks(bmarks, level=0):
    output = ''
    wroteTitle = False
    for j in bmarks:
        if isinstance(j, list):
            output = output + walk_bmarks(j, level + 1)
        elif isinstance(j, str):
            if not wroteTitle:
                output = output + "BookmarkBegin\nBookmarkTitle: %s\nBookmarkLevel: %d\n" % (j, level)
                wroteTitle = True 
            else:    
                output = output + "BookmarkPageNumber: %s\n" % j.split('#')[1]
                wroteTitle = False
        else:
            pass
    return output

fn = sys.argv[1]
data = sexpdata.load(open(fn))
pdfbmarks = walk_bmarks(data)

print(pdfbmarks)