#!/usr/bin/env bash

# WILL OVERWRITE 1D FILES
# without checking
# will leave '*' for missing runs
# might be a problem when both mr and timing DNE
# (e.g. no run4, but timing file has '*' on line 4)


# WF 20160922 
# init -- read individual run fsl files and make concat'ed run 1D files for afni

timinglist="01_rew_cue 02_rew_prep 03_rew_sac 04_neu_cue 05_neu_prep 06_neu_sac 7_combined_err 7_rew_err 8_neu_err 9_dropped"

for subjdir in ~/Documents/Research/NCANDA/data_eye/*/timing_*; do
  basename $(dirname $subjdir)
  for r in 1 2 3 4; do
    for timeid in $timinglist; do
      # what file are we using
      file=$(ls $subjdir/*run$r.$timeid.txt)
      dir=$subjdir/1D/

      outname=$dir/$timeid.1D
      #outname=$(basename $file .txt |cut -f2 -d. )

      outtxt=""

      if [ ! -r "$file" ]; then
         echo "missing $file" 
         outtxt="*"
      else
         [ -z "$outname" ] && echo "cannot get event type from '$file'" && continue

         outtxt=$(cut -d' ' -f1,2 "$file" | tr ' ' ':' | tr '\n' ' ')
      fi

      [ ! -d "$dir" ] && mkdir $dir
      
      # overwrite on the first run
      # append on all others
      if [ $r -eq 1 ]; then
        echo -e "\twritting $outname"
        echo "$outtxt" > $outname
      else
        echo "$outtxt" >> $outname
      fi
    done
  done
done
