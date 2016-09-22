#! /bin/bash

if [ "$#" -ne "2" ]; then
	echo "Must specify subject and year"
	exit
fi

SUBJECT_ID=$1
SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID if not already present
YEAR=$2

MR_DIR=`ls -d /Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}`
if [ "$MR_DIR" == "" ]; then
	echo "NO MR DIRECTORY FOUND FOR $SUBJECT_ID"
	exit
fi


RUN=1
FUNC_IMAGES=`ls ${MR_DIR}/*/nfswkmtd_${SUBJECT_ID}_run*.nii.gz`
for IMAGE in ${FUNC_IMAGES}; do

	if [ "${RUN}" == 1 ]; then
		COMBINE_TEXT="fslview ${IMAGE} "
	else
		COMBINE_TEXT="${COMBINE_TEXT} ${IMAGE} "
	fi
	RUN=$((RUN+1))
done


$COMBINE_TEXT





