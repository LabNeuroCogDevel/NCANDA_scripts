#!/bin/sh 
#set -xe

max_number_of_jobs=4

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
elif [ "$1" = 'temp' ]; then
	listfile="subject_list_tmp.txt"
else
	listfile="03_preprocessFunc_list.txt"
fi


while read line; do 

 

    SUBJECT_ID=`echo $line | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID
    YEAR=`echo $line | awk -F ' ' '{print $2}'`
    RUN=`echo $line | awk -F ' ' '{print $3}'`
	
	
	if [ $YEAR == 'year' ]; then
		continue
	fi

	MR_DIR=`ls -d /Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}/`
# 	if [ -f "${MR_DIR}/run${RUN}/.preprocessfunctional_complete" ]; then
# 		echo "$SUBJECT_ID $RUN already finished"
# 		continue
# 	fi

	
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 10
	done
	
	echo "$SUBJECT_ID $YEAR $RUN"
	/Users/ncanda/Documents/Research/NCANDA/scripts/03_preprocessFunc.sh ${SUBJECT_ID} ${YEAR} ${RUN} &
	
done < $listfile  # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py

