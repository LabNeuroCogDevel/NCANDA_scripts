#!/usr/bin/env bash

# 20161005 WF
##
#  1. merge output of epTiming_all.bash with scored eyedata files
#  2. parsing with patterns in 1dpattadd.txt
#  3. saving to txt/1D/subj_year/event.1D
##


#
# merge the onsets parsed from eprime log with epTiming_all.bash
# with the scored eye tracking data from scoreAll.R
#
epeye() {
 read id year run < <(echo $@)

 ep="txt/ep/onsets/${id}_${year}_$run.txt"
 ey=$(ls /Users/ncanda/Documents/Research/NCANDA/data_eye/$id/*y$year*run$run.trial.txt)

 # if niether file exist, its not a big deal
 [ ! -r "$ep" -a ! -r "$ey" ] && return 0
 # if only one doesn't, it is a big deal
 for v in ep ey; do [ ! -r "${!v}" ] && echo "no $v file: ${!v}!" >&2 && return 1; done

 join -1 2 -2 1 $ep <(cut -f1,7 $ey|sed 1d)
}

# give a pattern to search for (patt)
# and a number to add to the time that is found
# expects to work on a txt stream from epeye like
#   1 4.5 4.5 neutral 2
#   2 13.5 4.5 reward 1
#   3 31.5 4.5 reward 1
# and will return someting like
#   37.5 163.5 175.5 282
timesofplus(){
 patt="$1" add="$2" perl -slane 'push @a,$F[1]+$ENV{add} if /$ENV{patt}/; END{push @a,"*" if $#a<0; print "@a"}'
}

# dont add anything. just get the times
timesof(){
 timesofplus "$1" 0
}


for f in txt/ep/onsets/A*_[1-9]_[1-4].txt; do
  ! [[ $f  =~ (A[0-9]{3})_([0-9])_(1-4]) ]] || continue
  # parse file for subj year and run
  read s yr rn < <(basename $f .txt | sed 's/_/ /g')

  # we need eye files
  ey=$(ls /Users/ncanda/Documents/Research/NCANDA/data_eye/$s/*y$yr*run$rn.trial.txt)
  [ -z "$ey" ] && continue

  # make sure we have output directory
  dir=txt/1D/${s}_${yr}
  [ ! -d $dir ] && mkdir -p $dir
  
  # run epeye join + timesofplus pattern parse
  # for every pattern we want to parse in 1dpattadd
  echo ${dir}_$rn
  sed 's/#.*//;/^\s*$/d' 1dpattadd.txt | while read type patt add; do
    of=$dir/$type.1D
    [ $rn -eq 1 -a -r "$of" ] && rm $of
    epeye $s $yr $rn | timesofplus "$patt" $add >> $of
  done
done 
