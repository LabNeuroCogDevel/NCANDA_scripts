#!/bin/sh

max_number_of_jobs=20

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
elif [ "$1" = 'temp' ]; then
	listfile="subject_list_tmp.txt"
elif [ "$1" = 'all' ]; then
	listfile="/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_table_current.txt"
else
	listfile="07_makeTimingFiles_list.txt"
fi


while read line; do 
	
    SUBJECT_ID=`echo $line | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID
    YEAR=`echo $line | awk -F ' ' '{print $2}'`
    RUN=`echo $line | awk -F ' ' '{print $3}'`
    
    
    if [ $YEAR == "year" ]; then
    	continue
    fi
    
	
	#wait here until number of jobs is <= 14
	#set +x
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 5
	done


	echo "running $SUBJECT_ID $VISIT $RUN "
	Rscript 07_makeTimingFiles.R $SUBJECT_ID $YEAR $RUN TRUE
	Rscript 07_makeTimingFilesConfounds.R $SUBJECT_ID $YEAR $RUN 
	
	#set -x


done < $listfile # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py

