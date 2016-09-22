#!/bin/sh 

export PATH=${PATH}:"/Users/ncanda/Documents/Research/NCANDA/functions/"

SUBJECT_ID=$1
YEAR=$2
RUN=$3


SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID if not already present



#echo $SUBJECT_ID $YEAR $RUN

MR_DIR=`ls -d /Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}`
MPRAGE_DIR=${MR_DIR}/mprage/${SUBJECT_ID}_mprage.nii.gz

RUN_DIR=${MR_DIR}/run${RUN}
FUNCFILE=${RUN_DIR}/${SUBJECT_ID}_run${RUN}.nii.gz

if [ ! -f ${FUNCFILE} ]; then
	echo "${FUNCFILE} was not found"
	exit
fi
if [ ! -f ${MR_DIR}/mprage/${SUBJECT_ID}_mprage.nii.gz ]; then
	echo "${MR_DIR}/mprage/${SUBJECT_ID}_mprage.nii.gz was not found"
	exit
fi



cd ${RUN_DIR}

/Users/ncanda/Documents/Research/NCANDA/functions/preprocessFunctional.sh -4d ${SUBJECT_ID}_run${RUN}.nii.gz \
-mprage_bet ../mprage/${SUBJECT_ID}_mprage_bet.nii.gz -warpcoef ../mprage/${SUBJECT_ID}_mprage_warpcoef.nii.gz \
-tr 1.5 -threshold 98_2 -hp_filter 80 -rescaling_method 10000_globalmedian -template_brain MNI_3mm -func_struc_dof 7 \
-slice_acquisition interleaved -motion_sinc y -warp_interpolation spline -constrain_to_template y -cleanup -startover -despike y \
-st_first && touch ".functional_complete" 

# looking for nfskmtd 

