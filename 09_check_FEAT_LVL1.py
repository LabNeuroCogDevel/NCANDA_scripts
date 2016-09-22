#! /usr/bin/env python

model_name = "FEAT"
reference_cope = str(13)
#print '\n\n'"Checking for cope " + reference_cope + " in run folders where %s.fsf files were created" % (model_name)



import sys, os, glob, string

# 
def pair_subject_run(file_list, visit):
	paired_list = list()
	for i in range(0, len(file_list)):
		current_sub=str.split(file_list[i],"/")[5]
		current_run=str.split(file_list[i],"/")[6][-1]
		paired_list.append("_".join([current_sub,str(visit),current_run]))
	return paired_list




SubjectListFileName = 'scored_datafile_list.txt'
print '\n\n'"Checking for cope " + reference_cope + " for all subjects & runs listed in: \n\t%s \nfor model %s\n" % (os.path.split(SubjectListFileName)[-1], model_name)

not_run_list = list()
run_list = list()
confounds_list = list()
for line in open(SubjectListFileName, 'r').readlines()[1:]:
	line_strip = line.strip().split("\t")
	subjectID = line_strip[0]
	subjectID = "%03d" % (int(subjectID),)
	year = line_strip[1]
	run = line_strip[2]
	mr_dir = glob.glob("/Users/ncanda/Documents/Research/NCANDA/data_MR/A" + subjectID + "_" + year)
	cope_file = "%s/run%s/%s.feat/stats/cope%s.nii.gz" % (mr_dir[0], run, model_name, reference_cope)
	if (not os.path.exists(cope_file)):
		not_run_list.append(line.strip())
	else:
		run_list.append(line.strip())
		design_mat = "%s/run%s/%s.feat/design.mat" % (mr_dir[0], run, model_name)
		num_columns = int(open(design_mat, 'r').readlines()[0].strip().split("\t")[1])
		if num_columns != 23:
			confounds_list.append(line.strip())
	
print 'N finished %s: %d' % (model_name, len(run_list))

print '\n\nnot completed or run'
for line in not_run_list:
	print line

print '\n\ndid not use full confound EVs: %d' % len(confounds_list)
for line in confounds_list:
	print line

