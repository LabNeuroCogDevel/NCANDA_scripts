 #!/bin/sh


max_number_of_jobs=6

PREVIOUS_SUBJECT_ID="000"

if [ "$1" == 'new' ]; then
	listfile="subject_list_new.txt"
else
	listfile="02_preprocessAnat_list.txt"
fi


while read line; do 

	# FIRST LINE IS OFTEN 'subjectID'
	SUBJECT_ID=`echo $line | awk -F ' ' '{print $1}'`
	if [ $SUBJECT_ID == 'subjectID' ]; then
		continue
	fi
  	
  	# SUBJECT_ID AS LEFT PADDED NUMBER
    SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'`
    YEAR=`echo $line | awk -F ' ' '{print $2}'`

	if [ $SUBJECT_ID == ${PREVIOUS_SUBJECT_ID} ]; then
		continue
	fi
	
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]; do
		sleep 10
	done
	
	echo "PREPROCESS $SUBJECT_ID"
	
	# FOR LOOPING THROUGH DATAFILE_LIST.TXT - DON'T REPEAT SUBJECTS
	PREVIOUS_SUBJECT_ID=${SUBJECT_ID}

	MPRAGE_DIR="/Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}/mprage"

	# CONTINUE IF PROCESSING HAS ALREADY TAKEN PLACE
	#WHITE_MATTER_NIFTI=${MPRAGE_DIR}/${SUBJECT_ID}_mprage_bet_fast_wmseg.nii.gz
	#if [ -f ${WHITE_MATTER_NIFTI} ]; then
		#echo "$SUBJECT_ID YEAR ${YEAR} ALREADY PROCESSED"
		#continue
	#fi

	/Users/ncanda/Documents/Research/NCANDA/scripts/02_preprocessAnat.sh ${SUBJECT_ID} ${YEAR} &
	
done < $listfile # subject loop

wait

# THIS UPDATES THE DATA BASE AND MAKES NEW LISTS FOR THE FOLLOWING STEPS
python _update_db.py
python 00_make_processing_lists.py
