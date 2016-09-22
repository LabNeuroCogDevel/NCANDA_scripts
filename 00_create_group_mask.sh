#! /bin/bash



mask_list=`ls ../data_MR/*/*/subject_mask.nii.gz`


# fslmerge -t ../analysis/all_masks_4D.nii.gz ${mask_list}
# fslmaths ../analysis/all_masks_4D.nii.gz -Tmean ../analysis/all_masks_mean.nii.gz
# fslmaths ../analysis/all_masks_mean.nii.gz -thr 1 ../analysis/all_masks_mean_thresh.nii.gz


outfile_list="../analysis/all_masks_list.txt"
rm ${outfile_list}
touch ${outfile_list}
volume=0
for i in `echo ${mask_list}`; do
	echo -n "$volume " >> ${outfile_list} # don't print newline
	echo $i | awk -F "/" '{print $3" "$4}' >> ${outfile_list}
	let volume++
done




