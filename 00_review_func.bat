#!/bin/sh 
#set -xe


PREVIOUS_SUBJECT_ID="000"

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
else
	listfile="scored_datafile_list.txt"
fi



cat $listfile | while read line; do 

 	# FIRST LINE IS OFTEN 'subjectID'
	SUBJECT_ID=`echo $line | awk -F ' ' '{print $1}'`
	if [ $SUBJECT_ID == 'subjectID' ]; then
		continue
	fi

  	# SUBJECT_ID AS LEFT PADDED NUMBER
    SUBJECT_ID=`echo $line | awk -F ' ' '{ printf("%03d\n", $1) }'`
    YEAR=`echo $line | awk -F ' ' '{print $2}'`

	if [ $SUBJECT_ID == ${PREVIOUS_SUBJECT_ID} ]; then
		continue
	fi


	# FOR LOOPING THROUGH DATAFILE_LIST.TXT - DON'T REPEAT SUBJECTS
	PREVIOUS_SUBJECT_ID=${SUBJECT_ID}
	
	echo "$SUBJECT_ID $YEAR $RUN"
	/Users/ncanda/Documents/Research/NCANDA/scripts/00_review_func.sh ${SUBJECT_ID} ${YEAR}
	
done # subject loop

wait

