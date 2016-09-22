#!/bin/sh

max_number_of_jobs=6

PREVIOUS_SUBJECT_ID="000"

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
else
	listfile="01_convert_dicoms_list.txt"
fi

while read line; do 

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

	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 10
	done


	echo "CONVERT DICOMS $SUBJECT_ID"
	# FOR LOOPING THROUGH DATAFILE_LIST.TXT - DON'T REPEAT SUBJECTS
	PREVIOUS_SUBJECT_ID=${SUBJECT_ID}	
	
	python 01_convert_dicoms.py -s ${SUBJECT_ID} -y ${YEAR} -f True &


done < $listfile # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py

