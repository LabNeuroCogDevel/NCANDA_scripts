#!/bin/sh


echo "Starting part 1..."

for _COPE_ in $(seq 1 11); do 


	case ${_COPE_} in
		1 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_01rew_cue;;
		2 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_02rew_prep;;
		3 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_03rew_sacc;;
		4 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_04neut_cue;;
		5 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_05neut_prep;;
		6 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_06neut_sacc;;
		7 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_07rewgtneut_cue;;
		8 )
			continue;;																							
		9 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_09rewgtneut_prep;;
		10 )
			continue;;
		11 )
			_OUTPUT_DIR_=~/Documents/Academics/Projects/NCANDA/WMD/analysis/Diff_11rewltneut_sacc;;
	esac																							


	#wait here until number of jobs is <= max
	#set +x
	max_number_of_jobs=5
	while [ $(jobs | wc -l) -ge $max_number_of_jobs ]
	do
		sleep 20
	done


	FSF_NAME=${_OUTPUT_DIR_}.fsf
	TEMPLATE="/Users/dpaulsen/Documents/Academics/Projects/NCANDA/WMD/scripts/FEAT_TEMPLATES/FEAT_ALC_DIFF_RANK_template.fsf" # WHAT WILL BE COPIED
	for i in ${TEMPLATE}; do
	 sed -e 's@_OUTPUT_DIR_@'$_OUTPUT_DIR_'@g' \
		-e 's@_COPE_@'$_COPE_'@g' <$i> ${FSF_NAME}
	done

	#echo "running ${FSF_NAME}"
	feat ${FSF_NAME} &

	
	#set -x

done # subject loop



