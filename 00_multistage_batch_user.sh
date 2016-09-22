#! /bin/sh

# This script runs through all the stages of preprocessing



cd /Users/ncanda/Documents/Research/NCANDA/scripts


if [ -e /Volumes/ns1/MRIImages ]; then
	echo "ns1 server connected"
else
	echo "connecting to ns1 server"

	# USE NAME AND PASSWORD TO LOG INTO PAARC SERVER
	/Users/ncanda/Documents/Research/NCANDA/scripts/mount_ns1.sh paulsendj upmcM@1l

	sleep 5
fi


python _update_db.py
python 00_make_processing_lists.py
./01_convert_dicoms.bat

python _update_db.py
python 00_make_processing_lists.py
./02_preprocessAnat.bat

python _update_db.py
python 00_make_processing_lists.py
./03_preprocessFunc.bat

python _update_db.py
python 00_make_processing_lists.py
./04_transferEyeData.bat

python _update_db.py
python 00_make_processing_lists.py
./05_scoreOne.bat

python _update_db.py
python 00_make_processing_lists.py
./06a_make_event_files.bat

python _update_db.py
python 00_make_processing_lists.py
./06b_get_ventricle_tc.bat

python _update_db.py
python 00_make_processing_lists.py
./07_makeTimingFiles.bat

python _update_db.py
python 00_make_processing_lists.py
./08_FEAT_RUN_LVL1.bat

python _update_db.py
python 00_make_processing_lists.py
./00_registration_overlays.bat


# ./02_preprocessAnat.bat new
# 
# ./03_preprocessFunc.bat new
# 
# ./06b_get_ventricle_tc.bat new
# 
# ./07_makeTimingFiles.bat new
# 
# ./08_FEAT_RUN_LVL1.bat new

