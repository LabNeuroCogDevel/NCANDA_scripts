#!/bin/sh 
#set -xe

max_number_of_jobs=1



listfile="10_FEAT_RUN_LVL2_list.txt"

echo "Starting..."
while read line; do 

 

    SUBJECT_ID=`echo $line | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID
    YEAR=`echo $line | awk -F ' ' '{print $2}'`
 	
	if [ $YEAR == 'year' ]; then
		continue
	fi

	
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 10
	done
	
	echo "$SUBJECT_ID $YEAR $RUN"
	/Users/ncanda/Documents/Research/NCANDA/scripts/00_registration_overlays.sh ${SUBJECT_ID} ${YEAR}
	
done < $listfile # subject loop

wait

