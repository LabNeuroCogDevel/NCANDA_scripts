#!/bin/sh

max_number_of_jobs=5

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
elif [ "$1" = 'temp' ]; then
	listfile="subject_list_tmp.txt"
else
	listfile="10_FEAT_RUN_LVL2_list.txt"
fi


echo "Starting..."
while read line; do 

    SUBJECT_ID=`echo $line | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID
    YEAR=`echo $line | awk -F ' ' '{print $2}'`
    NRUNS=`echo $line | awk -F ' ' '{print $3}'`
    RUNS=`echo $line | cut -f4-12 -d " "`
    
    #echo $SUBJECT_ID $YEAR $NRUNS $RUNS
	
	if [ $YEAR == "year" ]; then
    	continue
    fi
	
	#max_number_of_jobs=`cat max_num_jobs.txt`
	#wait here until number of jobs is <= max number
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 20
	done


	echo "running $line"
	./10_FEAT_RUN_LVL2.sh $SUBJECT_ID $YEAR $NRUNS "$RUNS" &

done < $listfile # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py


