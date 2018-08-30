#!/usr/bin/env bash

# add 1.5 seconds to all values in a file
add1p5() {
 perl -slane 'print join " ", map {$_+1.5} @F' $1
}

# sort columns of a file line by line individulaly
# works on standard input
linesort() {
  perl -slane '{print join " " , sort {$a<=>$b} @F}'
}

# put all files together sort by line and handle previously or currently empty runs
combine1ds() {
 paste $@ | linesort | sed 's/\* //g;s/ \+/ /g' | sed 's/^$/*/'
}


combineallindir() {
  # collapse nt and reward into one file
  outdir=ntrw_comb 
  [ ! -d $outdir ] && mkdir $outdir
  
  for event in cue prep resp; do
   for resp in cr ec dp; do
     # find all files that match event and response type
     files=( $(find . -maxdepth 1 -type f -iname "${event}_*${resp}.1D") )
  
     # add er to drop
     [ $resp == 'dp' ] && \
      files=(${files[@]} $(find . -maxdepth 1 -type f -iname "${event}_*er.1D") )
  
     # skip if we have nothing
     [ ${#files[@]} -eq 0 ] && echo "no files for $event $resp ($(pwd))" &&  continue
  
     # write out
     filename=ntrw_comb/${event}_${resp}.1D
     combine1ds ${files[@]} > $filename
   done
  done

  # update cue and prep correct to include catch trials
  combine1ds ctch_*.1D cue_*cr.1D  > $outdir/cue_cr.1D
  combine1ds <(add1p5 ctch_long.1D) prep_*cr.1D  > $outdir/prep_cr.1D
}


for oneddir in /Volumes/NCANDA/scripts/timing/txt/1D_6/*; do
  cd $oneddir
  combineallindir
  echo $oneddir/ntrw_comb
done
