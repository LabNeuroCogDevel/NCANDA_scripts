#!/bin/sh

SUBJECT_ID=$1
YEAR=$2
RUN_NUM=$3

if [ $# -lt 3 ]; then
    echo "MUST SPECIFY SUBJECTID, YEAR, RUN_NUM"
    exit 0
fi

SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID if not already present




# SET UP DIRECTORY AND TEMPLATE FILE VARIABLES

	MR_DIR="/Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}"
	RUN_DIR=${MR_DIR}/run${RUN_NUM}

	if [ ! -e ${RUN_DIR}/nfswkmtd_${SUBJECT_ID}_run${RUN_NUM}.nii.gz ]; then
    	echo "nfswkmtd_${SUBJECT_ID} data not found" >> FEAT_errs_nodata.txt
	    echo "nfswkmtd_${SUBJECT_ID} data not found"
	    exit 0
	else
		FUNC_DATA=${RUN_DIR}/nfswkmtd_${SUBJECT_ID}_run${RUN_NUM}.nii.gz
	fi



# remove old feat directory
if [ -e ${RUN_DIR}/FEAT.feat ]; then
	rm -R ${RUN_DIR}/FEAT.feat
fi

TEMPLATEDIR=/Users/ncanda/Documents/Research/NCANDA/scripts/FEAT_TEMPLATES
FEAT_OUTPUT_DIR=${RUN_DIR}/FEAT.feat # WHERE THE FEAT OUTPUT WILL GO

# TEMPLATE AND SUBJECT/RUN FSF 
LVL1_TEMPLATE=FEAT_LVL1.fsf # WHAT WILL BE COPIED
FSF_NAME=${RUN_DIR}/FEAT.fsf # WHERE THE FSF COPY WILL BE MADE



cd ${TEMPLATEDIR}
for i in ${LVL1_TEMPLATE}; do
 sed -e 's@SUBJECT_ID@'$SUBJECT_ID'@g' \
 -e 's@RUN_DIR@'$RUN_DIR'@g' \
 -e 's@YEAR@'$YEAR'@g' \
 -e 's@FUNC_DATA@'$FUNC_DATA'@g' \
 -e 's@RUN_NUM@'$RUN_NUM'@g' <$i> ${FSF_NAME}
done

# RUN FEAT SCRIPT
feat ${FSF_NAME} 

# CHECK TO MAKE SURE FEAT COMPLETED, REMOVE LARGE UNNECESSARY FILES
if [ -e ${FEAT_OUTPUT_DIR}/stats/corrections.nii.gz ]; then
	rm ${FEAT_OUTPUT_DIR}/stats/corrections.nii.gz # approx 120Mb
	#rm ${FEAT_OUTPUT_DIR}/stats/res4d.nii.gz # approx 90Mb
else
    echo "${SUBJECT_ID} ${RUN_NUM} FEAT DID NOT COMPLETE" >> FEAT_errs_incomplete.txt
    echo "${SUBJECT_ID} ${RUN_NUM} FEAT DID NOT COMPLETE"
    exit 0
fi

# UPSAMPLE COPE AND VARCOPE IMAGES
#featregapply ${FEAT_OUTPUT_DIR}




