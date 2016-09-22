#! /bin/bash

if [ "$#" -ne "2" ]; then
	echo "Must specify subject and year"
	exit
fi

SUBJECT_ID=$1
SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'` # adds left padding to subjectID if not already present
YEAR=$2

cd /Users/ncanda/Documents/Research/NCANDA/data_MR/_registration_func

ref=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz

MR_DIR=`ls -d /Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}`
if [ "$MR_DIR" == "" ]; then
	echo "NO MR DIRECTORY FOUND FOR $SUBJECT_ID"
	exit
fi


RUN=1
FUNC_IMAGES=`ls ${MR_DIR}/*/nfswkmtd_${SUBJECT_ID}_run*.nii.gz`
for IMAGE in ${FUNC_IMAGES}; do

	# OUTLINE OF FUNC ON REF
	/usr/local/fsl/bin/slicer $ref $IMAGE -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
	/usr/local/fsl/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png REF_FUNC.png
	# OUTLINE OF REF ON FUNC
	/usr/local/fsl/bin/slicer $IMAGE $ref -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
	/usr/local/fsl/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png FUNC_REF.png
	/usr/local/fsl/bin/pngappend REF_FUNC.png - FUNC_REF.png FUNC_REG_${RUN}.png

	/bin/rm -f sl?.png
	
	if [ "${RUN}" == 1 ]; then
		COMBINE_TEXT="/usr/local/fsl/bin/pngappend FUNC_REG_${RUN}.png "
	else
		COMBINE_TEXT="${COMBINE_TEXT} - FUNC_REG_${RUN}.png "
	fi
	RUN=$((RUN+1))
done


COMBINE_TEXT="${COMBINE_TEXT} ${SUBJECT_ID}_${YEAR}_registration_func.png"
$COMBINE_TEXT

/bin/rm FUNC_REG_*.png




