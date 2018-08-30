#!/usr/bin/env bash
cd $(dirname $0)
# 20161005 WF
##
#  1. merge output of epTiming_all.bash with scored eyedata files
#  2. parsing with patterns in 1dpattadd.txt
#  3. saving to txt/1D_cue/subj_year/event.1D: txt/1D_cue/A*_[0-4]/*.1D
#
# # 20180830 AQ WF 
# #  - can be run on rhea or ncanda (/Users/ncanda/Documents/Research/NCANDA/ exists on both)
# #  - change dirroot to save old files -- but running at all maybe unnecessary: finished in 2016?
##

## MEAT OF CALL ##
# epeye $s $yr $rn | timesofplus "$patt" $add >> $of
##

source 1dfuncs.bash

pattfile=1dpatt_sepcatch.txt
dirroot=txt/1D_cue_20180830 # dir root changed as to not remove old files


for f in txt/ep/onsets_6/A*_[1-9]_[1-4].txt; do
  ! [[ $f  =~ (A[0-9]{3})_([0-9])_([1-4]) ]] || continue
  # parse file for subj year and run
  read s yr rn < <(basename $f .txt | sed 's/_/ /g')

  # we need eye files
  ey=$(ls /Users/ncanda/Documents/Research/NCANDA/data_eye/$s/*y$yr*run$rn.trial.txt)
  [ -z "$ey" ] && continue

  # make sure we have output directory
  #dir=txt/1D_6/${s}_${yr}
  dir=$dirroot/${s}_${yr}
  [ ! -d $dir ] && mkdir -p $dir
  
  # run epeye join + timesofplus pattern parse
  # for every pattern we want to parse in 1dpattadd
  echo ${dir}_$rn
  #sed 's/#.*//;/^\s*$/d' 1dpattadd.txt | while read type patt add; do
  sed 's/#.*//;/^\s*$/d' $pattfile | while read type patt add; do
    of=$dir/$type.1D
    [ $rn -eq 1 -a -r "$of" ] && rm $of
    epeye $s $yr $rn | timesofplus "$patt" $add >> $of
  done
done 
