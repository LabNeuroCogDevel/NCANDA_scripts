#!/bin/sh 

export PATH=${PATH}:"/Users/ncanda/Documents/Research/NCANDA/functions/"

SUBJECT_ID=$1
YEAR=$2

SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID if not already present



#echo $SUBJECT_ID $YEAR $RUN

MPRAGE_DIR="/Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}/mprage"
MPRAGE_FILE=${MPRAGE_DIR}/${SUBJECT_ID}_mprage.nii.gz


if [ ! -f ${MPRAGE_FILE} ]; then
	echo "${MPRAGE_FILE} not found"
	exit
fi


# year1list="016 023 028 034 041 043 045 051 055 057 060 063 064 065 068 071 088 100 101"
# year2list="004"
# 
# [[ $year1list =~ "${SUBJECT_ID}" && "${YEAR}" == 1 ]] && RUN_NOISY_BET=TRUE || RUN_NOISY_BET=FALSE
# [[ $year2list =~ "${SUBJECT_ID}" && "${YEAR}" == 2 ]] && RUN_NOISY_BET=TRUE
# 
# 
# if [ ${RUN_NOISY_BET} == "TRUE" ]; then

# THIS WAS ORIGINALLY JUST A SELECTION, BUT WITH APPROX 10-20% ERRORS, USING SKULLSTRIP SHOULD BE STANDARD
	echo "Using skullstrip"
	if [ ! -d "${MPRAGE_DIR}/_skullstrip" ];then 
		mkdir "${MPRAGE_DIR}/_skullstrip"
	fi
	cd ${MPRAGE_DIR}/_skullstrip

	# make copy of mprage for skull strip
	cp ${MPRAGE_DIR}/${SUBJECT_ID}_mprage.nii.gz ${MPRAGE_DIR}/_skullstrip/${SUBJECT_ID}_mprage.nii.gz

	@NoisySkullStrip -input ${SUBJECT_ID}_mprage.nii.gz
	3dAFNItoNIFTI ${SUBJECT_ID}_mprage.nii.gz.ns+orig.HEAD # creates 045_mprage.nii.gz.ns
	# return new bet to mprage directory
	mv ${MPRAGE_DIR}/_skullstrip/${SUBJECT_ID}_mprage.nii.gz.ns ${MPRAGE_DIR}/${SUBJECT_ID}_mprage_bet.nii.gz
	# run preprocessing without bet
	cd ${MPRAGE_DIR}
	/Users/ncanda/Documents/Research/NCANDA/functions/preprocessMprage.sh -n ${MPRAGE_FILE} -s	
	
# else
# 	echo "no"
# 	cd ${MPRAGE_DIR}
# 	/Users/ncanda/Documents/Research/NCANDA/functions/preprocessMprage.sh -n ${MPRAGE_FILE}
# fi

# looking for nfskmtd 

