#!/usr/bin/env bash
# WF 20160831
# put all eye trial data in one very large (long) sheet to be read in by R

# a randomf ile to get the header from
headerfile=/Users/ncanda/Documents/Research/NCANDA/data_eye/A137/137_y2_run4.trial.txt
# where to save our output
outfile=/Users/ncanda/Documents/Research/NCANDA/data_eye/summary_y12.txt

# first set the header
sed 1q $headerfile | sed 's/^/subj	visit	run	/' > $outfile
 
for f in /Users/ncanda/Documents/Research/NCANDA/data_eye/*/*_y[12]_*trial.txt; do 
 # file anme is subj_visit_run.trial.txt
 # our line prefix is tab sep subj,visit,run
 p="$(basename $f .trial.txt|sed 's/_/	/g')";
 
 # put our prefix into the start of every line
 sed "1d;s/^/$p	/" $f 

done >> $outfile

