#! /bin/sh

# DO NOT EDIT - THIS IS CALLED BY A CRON JOB

# This script runs through all the stages of preprocessing


SCRIPTS_DIR="/Users/ncanda/Documents/Research/NCANDA/scripts"

cd ${SCRIPTS_DIR}

if [ -e /Volumes/ns1/MRIImages ]; then
	echo "ns1 server connected"
else
	echo "connecting to ns1 server"

	# MUST CREATE MOUNT POINT DIRECTORY IF IT DOES NOT EXIST
	# NOTE: CLOSING MOUNT THROUGH GUI DELETES MOUNT POINT DIRECTORY
	mkdir "/Volumes/ns1"
	
	# USE NAME AND PASSWORD TO LOG INTO ns1 SERVER
	${SCRIPTS_DIR}/mount_ns1.sh paulsendj upmcM@1l

	sleep 3
fi


if [ ! -e /Volumes/ns1/MRIImages ]; then
	echo "\n--Could not connect to ns1 server--\n"
	exit
fi

python _update_db.py
python _make_processing_lists.py

${SCRIPTS_DIR}/01_convert_dicoms.bat

${SCRIPTS_DIR}/02_preprocessAnat.bat

${SCRIPTS_DIR}/03_preprocessFunc.bat

${SCRIPTS_DIR}/04_transferEyeData.bat

${SCRIPTS_DIR}/05_scoreOne.bat

${SCRIPTS_DIR}/06a_make_event_files.bat

${SCRIPTS_DIR}/06b_get_ventricle_tc.bat

${SCRIPTS_DIR}/07_makeTimingFiles.bat

${SCRIPTS_DIR}/08_FEAT_RUN_LVL1.bat

${SCRIPTS_DIR}/00_registration_overlays.bat
