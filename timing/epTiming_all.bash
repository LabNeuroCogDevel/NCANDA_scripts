#!/usr/bin/env bash

# get infom from
# /Users/ncanda/Documents/Research/NCANDA/data_eye/A004/A004_y2_Eprime_run1.txt
[ ! -r txt/ep ] && mkdir -p txt/ep/{onsets_6,starttime}

basepath=/Users/ncanda/Documents/Research/
#[ ! -d $basepath ] && basepath=/Volumes/
for f in $basepath/NCANDA/data_eye/*/*_Eprime_run*.txt; do
  fname=$(basename $f)
  ! [[ $fname =~ (A[0-9]{3})_y?([0-9]).*run([0-9]) ]] && echo "bad file name (no id year run): '$f'" >&2 && continue
  id=${BASH_REMATCH[1]}
  year=${BASH_REMATCH[2]}
  run=${BASH_REMATCH[3]}

  echo $id $year $run

  onsets=txt/ep/onsets_6/${id}_${year}_${run}.txt
  starttime=txt/ep/starttime/${id}_${year}_${run}.txt
  [ -r $onsets -a -r $starttime ] && continue

  ../timing_from_eprimelog.pl <  $f > $onsets;

  # get SessionDate and SessionTime from eprime log file and reparse
  perl -slane  '
    last if $#a>0;chomp;                                     # done when we have date and time
    push @a,$2 if /^(SessionDate|SessionTime): ([0-9:-]+)/;  # add date or time to array (date comes 1st in file)
    END{@d=split/-/,$a[0];                                   # split date b/c order is wonky
        print "$d[2]-$d[0]-$d[1] $a[1]"                      # print like 04-13-2013 14:24:44
    }' $f > $starttime

done
