#! /usr/bin/env python

# make sure mprage "/4/" contains 176 dicoms
# make sure number of folders with 202 dicoms matches number of scored run excel sheets
# convert mprage dicoms to nifti format (if not already done) 
#	change name to subjectID_mprage.nii.gz
# convert rings dicoms to nifti format (if not already done) 





import sys, os, glob, shutil, string, time
import numpy as np
from optparse import OptionParser
# for finding the dcm2nii function
sys.path.append("\"/Users/ncanda/Documents/Research/NCANDA/scripts\"")
sys.path.append("\"/Users/ncanda/Documents/Research/NCANDA/functions\"")

# SET UP PARSER FOR PASSING IN SOURCE AND DESTINATION DIRECTORY OPTIONS
parser = OptionParser()
parser.add_option("-s", "--subject", dest="subject")
parser.add_option("-y", "--year", dest="year")
parser.add_option("-f", "--force", dest="force")
(options, args) = parser.parse_args()


if options.subject==None:
	raise NameError, "Must specify subject: -s #"
if options.year==None:
	raise NameError, "Must specify subject: -y #"


	
subjectID = int(options.subject)
longSubjectID3 = "%03d" % (subjectID,)
longSubjectID5 = "%05d" % (subjectID,)
year = int(options.year)
if options.force==None:
	force=False
else:
	force = options.force

# check server connection
if not os.path.exists("/Volumes/ns1"):
	print "ns1 volume not mounted"
	sys.exit(1)

# GET NAME OF DIRECTORIES FOR SUBJECT (WILD CARD IS USED BECAUSE FOLDERS CAN HAVE DIFFERENT PREFIXES)
mr_dir = glob.glob("/Volumes/ns1/MRIImages/raw_data/NCANDA/A" + longSubjectID3 + "_" + str(year))


# QUIT IF NO MR DIRECTORY (DATA HAS NOT BEEN TRANSFERRED)
if (mr_dir == []):
	print "MR directory for subject", subjectID, ", year", year, "not found"
	sys.exit(1)
else:
	mr_dir = mr_dir[0]
	output_dir = "/Users/ncanda/Documents/Research/NCANDA/data_MR/" + os.path.split(mr_dir)[-1]




# INFORMATION FILE LISTING THE RUNS TO USE FOR EACH SUBJECT
# infoFile = "/Users/ncanda/Documents/Research/NCANDA/scripts/scored_datafile_list.txt"
# subjInfoArray = np.genfromtxt(infoFile, delimiter='\t', skip_header=1, 
# 	names=['subjectID', 'year', 'run'], #dtype=float,
# 	dtype=[('subjectID', 'S10'), ('year','S2'), ('run','S2')])
# 
# # SUBSET OF ARRAY IDENTIFYING SUBJECT
# subjInfoArray = np.array(subjInfoArray[subjInfoArray['subjectID'] == str(subjectID)])
# subjInfoArray = np.array(subjInfoArray[subjInfoArray['year'] == str(year)])



# CHECK TO MAKE SURE RUNS ARE LISTED
# if len(subjInfoArray) == 0:
# 	print "Subject", subjectID, "has no runs listed in", infoFile
# 	print "quitting"
# 	sys.exit(1)
# if len(subjInfoArray) < 2:
# 	print "Subject", subjectID, "has less than 2 runs listed in", infoFile
# 	print "This means there are fewer than two usable runs or that the info list has not been updated"
# 	print "quitting"
# 	sys.exit(1)


if not os.path.exists(output_dir):
	os.makedirs(output_dir)

# note - * was added to 'A-' because subjectID 104 had an folder id with 6 digits instead of 5
mprage_dir = glob.glob(mr_dir + "/A*" + longSubjectID5 + "*/ncanda-mprage*")[0]


if (len(glob.glob(mprage_dir + "/MR*")) == 160):
	os.chdir(mprage_dir)
	dcm_cmd = "Dimon -infile_patter \"MR*\" -GERT_Reco -quit -dicom_org -sort_by_acq_time -gert_write_as_nifti -gert_create_dataset -gert_to3d_prefix " + longSubjectID3 + "_mprage"
	mprage_output_filename = output_dir + "/mprage/" + longSubjectID3 + "_mprage.nii"
	if (os.path.exists(mprage_output_filename + ".gz") & (force!=True)):
		print longSubjectID3 + " mprage dicoms have already been converted\n skipping...\n"
	else:	
		if not os.path.exists(output_dir + "/mprage"):
			os.makedirs(output_dir + "/mprage")
		os.system(dcm_cmd) # run command to covert dicoms to nifti
	
		dimon_files = glob.glob("dimon.files*")
		gert_files = glob.glob("GERT_Reco_dicom*")
		for i in dimon_files + gert_files:
			os.unlink(i) # remove excess files
	
		shutil.move(longSubjectID3 + "_mprage.nii", mprage_output_filename) # transfer file to local dir
		os.chdir(output_dir + "/mprage") # move to local dir
		os.system("gzip -f " + mprage_output_filename) # gunzip .nii file; -f force overwrite
		os.system("3dresample -overwrite -orient LPI -prefix " + longSubjectID3 + "_mprage.nii.gz -inset " + longSubjectID3 + "_mprage.nii.gz") # reorient to LPI
else:
	print "mprage dicoms not equal to 160"
	print "make sure all data has been completely transferred"

# LIST OF MR RINGS SUBDIRECTORIES THAT CONTAIN 202 DICOM FILES
mr_subdirs = [ name for name in glob.glob(mr_dir + "/A*" + longSubjectID5 + "*/*rewards*") if 
	(os.path.isdir(os.path.join(mr_dir, name)) & 
	(len(glob.glob(os.path.join(mr_dir, name) + "/MR*")) == 202) ) ]


#print(mr_subdirs)

txt_output = open(output_dir + "/conversion_log.txt", 'w')
new_mr_subdir_names = []

for i in range(0,len(mr_subdirs)):
	new_mr_subdir_names.append( "run" + str(i+1))
	txt_output.write(os.path.split(mr_subdirs[i])[-1] + " to run " + str(i+1) + "\n")




# txt_output.write(str(len(subjInfoArray['run'])) + " runs listed\n")
# print len(subjInfoArray['run']), "runs listed\n"


for i in range(0,len(mr_subdirs)):
	# SKIP PROCESS IF NIFTI HAS ALREADY BEEN MADE
	current_output_filename = output_dir + "/" + new_mr_subdir_names[i] + "/" + longSubjectID3 + "_" + new_mr_subdir_names[i] + ".nii"
	if (os.path.exists(current_output_filename + ".gz") & (force!=True)):
		print new_mr_subdir_names[i] + " dicoms have already been converted\n skipping...\n"
		continue
	if not os.path.exists(output_dir + "/" + new_mr_subdir_names[i] + "/"):
		os.makedirs(output_dir + "/" + new_mr_subdir_names[i] + "/")
	os.chdir(mr_subdirs[i])
	dcm_cmd = "Dimon -infile_patter \"MR*\" -GERT_Reco -quit -dicom_org -sort_by_acq_time -gert_write_as_nifti -gert_create_dataset -gert_to3d_prefix " + longSubjectID3 + "_" + new_mr_subdir_names[i]
	os.system(dcm_cmd) # run command to covert dicoms to nifti
	dimon_files = glob.glob("dimon.files*")
	gert_files = glob.glob("GERT_Reco_dicom*")
	for j in dimon_files + gert_files:
		os.unlink(j) # remove excess files
	
	shutil.move(longSubjectID3 + "_" + new_mr_subdir_names[i] + ".nii", current_output_filename) # transfer file to local dir
	os.chdir(output_dir + "/" + new_mr_subdir_names[i] + "/") # move to local dir
	os.system("gzip -f " + current_output_filename) # gunzip .nii file; -f force overwrite
	os.system("3dresample -overwrite -orient LPI -prefix " + longSubjectID3 + "_" + new_mr_subdir_names[i] + ".nii.gz -inset " + longSubjectID3 + "_" + new_mr_subdir_names[i] + ".nii.gz") # reorient to LPI
else:
	if not os.path.exists(output_dir + "/" + new_mr_subdir_names[i]): # make output directory if it doesn't exist
		os.makedirs(output_dir + "/" + new_mr_subdir_names[i])
	os.system(dcm_cmd)



txt_output.close()

