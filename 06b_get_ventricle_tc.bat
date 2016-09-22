#!/bin/sh

max_number_of_jobs=5

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
elif [ "$1" = 'temp' ]; then
	listfile="subject_list_tmp.txt"
else
	listfile="06b_get_ventricle_tc_list.txt"
fi

echo "Starting..."
while read line; do 

    SUBJECT_ID=`echo $line | awk -F ' ' '{print $1}'`
    YEAR=`echo $line | awk -F ' ' '{print $2}'`
    RUN=`echo $line | awk -F ' ' '{print $3}'`

     
    #echo "\n$line"
 	#echo ${YEAR}
#  	if [ ${YEAR} -ne 1 ]; then # -eq
#  		continue
#  	fi
		
	#wait here until number of jobs is <= max number
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 20
	done


	#echo "running $line"
	python 06b_get_ventricle_tc_clustr.py -s $SUBJECT_ID -y $YEAR -r $RUN &

done < $listfile  # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py


