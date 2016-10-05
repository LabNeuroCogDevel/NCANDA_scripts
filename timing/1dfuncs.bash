##
# functions for parsing 1d files. eg.
#   epeye $s $yr $rn | timesof "$patt" $add
##

# 20161005WF
#
# NOTE: file paths are relative. expects to live and execute 
#       /Users/ncanda/Documents/Research/NCANDA/scripts/timing

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
