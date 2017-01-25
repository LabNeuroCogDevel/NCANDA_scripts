#!/usr/bin/env bash
warn() {
 echo $@ >&2
}
first=1
for f in ../data_eye/*/*.trial.txt; do 
  ! [[ $f =~ y[0-9]_run([0-4]) ]] && warn "no year or run in file $f" && continue;
  #st=$(grep SessionTime $(find $(dirname $f) -maxdepth 1 -type f -iname "*${BASH_REMATCH//_/*Eprime*}.txt")|sed 's/SessionTime: (\.*)$/\1/;1d'); 
  run=${BASH_REMATCH[1]}
  [ -z "$run" ] && warn "no run!" && continue


  epfile=$(find $(dirname $f) -maxdepth 1 -type f -iname "*${BASH_REMATCH//_/*Eprime*}.txt"|tail -n1)
  [ -z "$epfile" ] && warn "missing epfile for $f" >&2 && continue 
  st=$(perl -lne 'if(m/SessionTime: ([0-9:]+)/){print $1;exit(0)}' $epfile)
  sd=$(perl -lne 'if(m|SessionDate: ([0-9:/-]+)|){print $1;exit(0)}' $epfile)

  [ -z "$st" ] && warn "no sessionTime in '$epfile'" >&2 && continue 


  whattodowithfirst='1d'
  if [ $first == 1 ]; then
    first=2
    whattodowithfirst='1,1 s/^/runinfo	epfile	date	sessionTime	run	/'
  fi
  # add sessiontime and file columns
  sed "
   $whattodowithfirst;
   2,\$ s|^|$(basename $f .trial.txt)	$(basename $epfile .txt)	${sd}	${st}	$run	|" $f;
done  > eyedata_all.txt
