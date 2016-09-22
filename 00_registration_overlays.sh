#! /bin/bash

cd /Users/ncanda/Documents/Research/NCANDA/data_MR/_registration

ref=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz


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

NON_LIN=${MR_DIR}/mprage/${SUBJECT_ID}_mprage_nonlinear_warp_MNI_FSL_2mm.nii.gz
LIN=${MR_DIR}/mprage/${SUBJECT_ID}_mprage_warp_linear.nii.gz

if [ ! -e "$NON_LIN" ]; then
	echo "NON LINEAR FILE NOT FOUND"
	exit
fi
if [ ! -e "$LIN" ]; then
	echo "LINEAR FILE NOT FOUND"
	exit
fi


# OUTLINE OF LIN ON REF
/usr/local/fsl/bin/slicer $ref $LIN -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
/usr/local/fsl/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png Lin1.png
# OUTLINE OF REF ON LIN
/usr/local/fsl/bin/slicer $LIN $ref -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
/usr/local/fsl/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png Lin2.png
/usr/local/fsl/bin/pngappend Lin1.png - Lin2.png Lin.png


# OUTLINE OF NONLIN ON REF
/usr/local/fsl/bin/slicer $ref $NON_LIN -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
/usr/local/fsl/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png Nlin1.png
# OUTLINE OF REF ON NONLIN
/usr/local/fsl/bin/slicer $NON_LIN $ref -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png
/usr/local/fsl/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png Nlin2.png
/usr/local/fsl/bin/pngappend Nlin1.png - Nlin2.png Nlin.png

# COMBINE ALL IMAGES
/usr/local/fsl/bin/pngappend Lin.png - Nlin.png ${SUBJECT_ID}_${YEAR}_registration.png

/bin/rm -f sl?.png
/bin/rm *in*.png




