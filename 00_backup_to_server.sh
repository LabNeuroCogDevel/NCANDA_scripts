#! /bin/sh

SCRIPTS_DIR="/Users/ncanda/Documents/Research/NCANDA/scripts"

cd ${SCRIPTS_DIR}

if [ -e /Volumes/ns1/MRIImages ]; then
	echo "ns1 server connected"
else
	echo "connecting to ns1 server"

	# MUST CREATE MOUNT POINT DIRECTORY IF IT DOES NOT EXIST
	# NOTE: CLOSING MOUNT THROUGH GUI DELETES MOUNT POINT DIRECTORY
	mkdir "/Volumes/ns1"
	
	# USE NAME AND PASSWORD TO LOG INTO PAARC SERVER
	${SCRIPTS_DIR}/mount_ns1.sh paulsendj upmcM@1l

	sleep 3
fi


if [ ! -e /Volumes/ns1/MRIImages ]; then
	echo "\n--Could not connect to ns1 server--\n"
	exit
fi


mkdir -p   /Volumes/ns1/PAARCProjects/SHARE/paulsen/
rsync -avHS /Users/ncanda/Documents/Research/NCANDA /Volumes/ns1/PAARCProjects/SHARE/paulsen/
