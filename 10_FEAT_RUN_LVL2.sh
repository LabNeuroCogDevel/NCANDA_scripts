#!/bin/sh

if [ $# -lt 3 ]; then
    echo "MUST SPECIFY SUBJECTID, NUM_RUNS, \"RUN_LIST\""
    exit 0
fi


# DEFINE SUBJECT INFORMATION
SUBJECT_ID="$1"
# SUBJECT_ID AS LEFT PADDED NUMBER
SUBJECT_ID=`echo $SUBJECT_ID | awk -F ' ' '{ printf("%03d\n", $1) }'`
YEAR="$2"
NUM_RUNS=$3
RUN_LIST="$4"

RUN_LIST="${RUN_LIST%\"}" # remove end quote
RUN_LIST="${RUN_LIST#\"}" # remove front quote

#echo $RUN_LIST
# SET LINE INFO TO $RUN
set -- $RUN_LIST
RUN1_NUM=$1
RUN2_NUM=$2
RUN3_NUM=$3
RUN4_NUM=$4


# SET UP DIRECTORY AND TEMPLATE FILE VARIABLES
TEMPLATEDIR=/Users/ncanda/Documents/Research/NCANDA/scripts/FEAT_TEMPLATES
MR_DIR=`ls -d /Users/ncanda/Documents/Research/NCANDA/data_MR/A${SUBJECT_ID}_${YEAR}`
FSF_NAME=${MR_DIR}/FEAT_LVL2.fsf # WHERE THE FSF COPY WILL BE MADE


if [ -e "${MR_DIR}/FEAT_LVL2.gfeat/cope13.feat" ]; then
	echo "        Subject ${SUBJECT_ID} already ran. Skipping..."
	exit
fi



if [ $NUM_RUNS -eq 2 ]; then

	LVL2_TEMPLATE=FEAT_LVL2_2_RUNS.fsf # WHAT WILL BE COPIED
	cd ${TEMPLATEDIR}
	for i in ${LVL2_TEMPLATE}; do
	 sed -e 's@MR_DIR@'$MR_DIR'@g' \
		-e 's@SUBJECT_ID@'$SUBJECT_ID'@g' \
		-e 's@RUN1_NUM@'$RUN1_NUM'@g' \
		-e 's@RUN2_NUM@'$RUN2_NUM'@g'  <$i> ${FSF_NAME}
	done

elif [ $NUM_RUNS -eq 3 ]; then


	LVL2_TEMPLATE=FEAT_LVL2_3_RUNS.fsf # WHAT WILL BE COPIED
	cd ${TEMPLATEDIR}
	for i in ${LVL2_TEMPLATE}; do
	 sed -e 's@MR_DIR@'$MR_DIR'@g' \
		-e 's@SUBJECT_ID@'$SUBJECT_ID'@g' \
		-e 's@RUN1_NUM@'$RUN1_NUM'@g' \
		-e 's@RUN2_NUM@'$RUN2_NUM'@g' \
		-e 's@RUN3_NUM@'$RUN3_NUM'@g'  <$i> ${FSF_NAME}
	done

elif [ $NUM_RUNS -eq 4 ]; then

	LVL2_TEMPLATE=FEAT_LVL2_4_RUNS.fsf # WHAT WILL BE COPIED
	cd ${TEMPLATEDIR}
	for i in ${LVL2_TEMPLATE}; do
	 sed -e 's@MR_DIR@'$MR_DIR'@g' \
		-e 's@SUBJECT_ID@'$SUBJECT_ID'@g' \
		-e 's@RUN1_NUM@'$RUN1_NUM'@g' \
		-e 's@RUN2_NUM@'$RUN2_NUM'@g' \
		-e 's@RUN3_NUM@'$RUN3_NUM'@g' \
		-e 's@RUN4_NUM@'$RUN4_NUM'@g'  <$i> ${FSF_NAME}
	done

fi

if [ -e ${MR_DIR}/FEAT_LVL2.gfeat ]; then
	rm -R ${MR_DIR}/FEAT_LVL2.gfeat
fi

# RUN FEAT SCRIPT
feat ${FSF_NAME}
