#!/bin/sh

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
elif [ "$1" = 'temp' ]; then
	listfile="subject_list_tmp.txt"
else
	listfile="04_transferEyeData_list.txt"
fi


while read line; do 



    SUBJECT_ID=`echo $line | awk -F ' ' '{print $1}'`
    YEAR=`echo $line | awk -F ' ' '{print $2}'`
    RUN=`echo $line | awk -F ' ' '{print $3}'`

	if [ $YEAR == 'year' ]; then
		continue
	fi

	
	echo ""
	echo "$SUBJECT_ID $RUN"
	python 04_transferEyeData.py -s $SUBJECT_ID -y $YEAR -r $RUN -f True

done < $listfile  # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py


