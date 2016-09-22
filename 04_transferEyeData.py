#! /usr/bin/env python
#
# This script can be called from anywhere. It requires arguments (subject, visit, run) which are used to determine
# source folder is assumed to be ""
# subjects are read from subject list "scored_datafile_list.txt*" for matching rundates
# verbalizations can be manually documented (copied and pasted from terminal window)


import sys, os, glob, shutil, string, time
import numpy as np
from optparse import OptionParser


# SET UP PARSER FOR PASSING IN SOURCE AND DESTINATION DIRECTORY OPTIONS
parser = OptionParser()
parser.add_option("-s", "--subject", dest="subject")
parser.add_option("-y", "--year", dest="year")
parser.add_option("-r", "--run", dest="run")
parser.add_option("-f", "--force", dest="force") # will force transfer and timing file construction even if subject is excluded
(options, args) = parser.parse_args()


if options.subject==None:
	raise NameError, "Must specify subject: -s #"
if options.year==None:
	raise NameError, "Must specify year: -y #"
if options.run==None:
	raise NameError, "Must specify run: -r #"


if options.subject == "subjectID":
	sys.exit()

subjectID = int(options.subject)
longSubjectID3 = "%03d" % (subjectID,)
longSubjectID5 = "%05d" % (subjectID,)
year = options.year
run = options.run



if options.force == "True":
	force = True
else:
	force = False


# CHECK AND SET PATH TO EYE DATA
originalEyeDataDir = "/Volumes/ns1/DeptShare/ClarkProjects/NCANDA/Data/Eye-trac Data/"

if not os.path.exists(originalEyeDataDir):
		cat("/Volumes/ns1/DeptShare/ClarkProjects/NCANDA/Data/Eye-trac Data/ not found!\n")
		sys.exit(1)



# infoFile = "/Users/ncanda/Documents/Research/NCANDA/scripts/scored_datafile_list.txt"
# # read in textfile as numpy array
# infoFile = "/Users/ncanda/Documents/Research/NCANDA/scripts/scored_datafile_list.txt"
# subjInfoArray = np.genfromtxt(infoFile, delimiter='\t', skip_header=1, 
# 	names=['subjectID', 'year', 'run'], #dtype=float,
# 	dtype=[('subjectID', 'S10'), ('year','S2'), ('run','S2')])

# SUBSET OF ARRAY IDENTIFYING SUBJECT
# subjInfoArray = np.array(subjInfoArray[subjInfoArray['subjectID'] == str(subjectID)])
# subjInfoArray = np.array(subjInfoArray[subjInfoArray['year'] == str(year)])
# subjInfoArray = np.array(subjInfoArray[subjInfoArray['run'] == str(run)])

# if (len(subjInfoArray) < 1):
# 	print "    Subject", subjectID, "run", run, "not found in list"
# 	sys.exit(1)
# 
# if (len(subjInfoArray) > 1):
# 	print "    Multiple entries in list for subject", subjectID, "run", run
# 	sys.exit(1)


# general directory
destinationDir = "/Users/ncanda/Documents/Research/NCANDA/data_eye/"
# subject specific target directory
currentEyeDir = os.path.join(destinationDir, ("A" + str(longSubjectID3)))


# for transferring e-prime and eye-tracking data if desired (needs editing for path)
#currentEyeRawSourceDir = os.path.join(eyeDataDir, str(subjectID), str(rundate), "Raw/EyeData/txt")

# see if there is a directory, make one if there isn't
if not os.path.exists(currentEyeDir):
	os.mkdir(currentEyeDir)

# COMMENTED OUT 12/16/2013 AT TRANSITION TO AUTOMATED EYE-SCORING
# currentEyeExcelSourceDir = glob.glob((scoredDataDir + "/*" + longSubjectID5 + "*"))[0]
# newFileName = (currentEyeDir + "/fs_" + str(longSubjectID3) + "_run" + str(run) + ".xls" )
# source_xls_file = currentEyeExcelSourceDir + "/" + subjInfoArray['score_file'][0]
# 
# if not os.path.exists(source_xls_file): # if the file doesn't exist
# 	print "    Subject", subjectID, "run", run, "does not have a score sheet"
# 	sys.exit(1)
# 
# 
# if not os.path.exists(newFileName): # if the file hasn't already been transferred
# 	shutil.copy(source_xls_file,  newFileName)
# 	print "\ttransferring xls"


#else:
#	print "    Subject", subjectID, "run", run, "Excel eye-scoring has already been transferred"

#######	END EXCEL TRANSFER




#######	BEGIN EPRIME TXT TRANSFER
# TIMING SHOULD NOT BE ASSUMED, BUT GENERATED FROM EPRIME TEXT FILES

need_renaming=False
currentEPRIMEeydSourceDir = glob.glob((originalEyeDataDir + "A" + longSubjectID3))
if len(currentEPRIMEeydSourceDir) != 1:
	print "    Subject", subjectID, "year", year, "run", run, " EYE DIRECTORY NOT FOUND\n    Checking \"NEW (needs to be renamed)\" DIRECTORY\n"
	currentEPRIMEeydSourceDir = glob.glob((originalEyeDataDir + "New*/" + str(int(longSubjectID3))))
	if len(currentEPRIMEeydSourceDir) != 1:
		print "    !!!Subject", subjectID, "year", year, "run", run, "ALTERNATE EYE DIRECTORY NOT FOUND!!!\n"
		sys.exit(0)
	else:
		need_renaming=True # subject directory hasn't been renamed yet
		currentEPRIMEeydSourceDir = currentEPRIMEeydSourceDir[0]
else:
	currentEPRIMEeydSourceDir = currentEPRIMEeydSourceDir[0]




# CHECK MAIN AND SUBDIRECTORIES FOR EPRIME TXT FILES (NAMING AND LOCATION IS INCONSISTENT)
# THROW ERROR AND ESCAPE IF 0 OR MORE THAN 1 EPRIME TXT FILES ARE FOUND
if need_renaming:
	listed_eyd_file = glob.glob( (currentEPRIMEeydSourceDir + "/" + str(int(longSubjectID3)) + "_" + str(run) + ".eyd") )
	listed_txt_file = glob.glob( (currentEPRIMEeydSourceDir + "/RING Chuck Rewards - v-" + str(int(longSubjectID3)) + "-" + str(run) + ".txt") )
else:
	listed_eyd_file = glob.glob( (currentEPRIMEeydSourceDir + "/A" + str(longSubjectID3) + "_y" + str(year) + "*_Eraw_" + str(run) + ".eyd") )
	listed_txt_file = glob.glob( (currentEPRIMEeydSourceDir + "/A" + str(longSubjectID3) + "_y" + str(year) + "*_RCR*_" + str(run) + ".txt") )

# TRANSFER TEXT FILES
if len(listed_eyd_file) == 0:
	listed_eyd_file = glob.glob( (currentEPRIMEeydSourceDir + "/*/A" + longSubjectID3 + "_y" + str(year) + "*_Eraw_" + str(run) + ".eyd") )
	if len(listed_eyd_file) == 0:
		print "    Subject", subjectID, "year", year, "run", run, "does not have a found EPRIME eyd file"
		sys.exit(1)
	elif len(listed_eyd_file) > 1:
		print "    Subject", subjectID, "year", year, "run", run, "has more than one EPRIME eyd file"
		sys.exit(1)
	else:
		eyd_file = listed_eyd_file[0]
elif len(listed_eyd_file) > 1:
	print "    Subject", subjectID, "year", year, "run", run, "has more than one EPRIME eyd file"
	sys.exit(1)
else:
	eyd_file = listed_eyd_file[0]

newEPRIMEeydFileName = (currentEyeDir + "/A" + str(longSubjectID3) + "_y" + str(year) + "_Eraw_run" + str(run) + ".eyd" )

if (not os.path.exists(newEPRIMEeydFileName)) | (force == True) : # if the file hasn't already been transferred
	shutil.copy(eyd_file,  newEPRIMEeydFileName)
	print "\ttransferring EPRIME eyd file"




# TRANSFER TXT FILES

if len(listed_txt_file) == 0:
	listed_txt_file = glob.glob( (currentEPRIMEeydSourceDir + "/*/A" + str(longSubjectID3) + "_y" + str(year) + "*_RCR*_" + str(run) + ".txt") )
	if len(listed_txt_file) == 0:
		print "    Subject", subjectID, "run", run, "does not have a found EPRIME txt file"
		sys.exit(1)
	elif len(listed_txt_file) > 1:
		print "    Subject", subjectID, "run", run, "has more than one EPRIME txt file"
		sys.exit(1)
	else:
		txt_file = listed_txt_file[0]
elif len(listed_txt_file) > 1:
	print "    Subject", subjectID, "run", run, "has more than one EPRIME txt file"
	sys.exit(1)
else:
	txt_file = listed_txt_file[0]

newEPRIMEtxtFileName = (currentEyeDir + "/A" + str(longSubjectID3) + "_y" + str(year) + "_Eprime_run" + str(run) + ".txt" )

if (not os.path.exists(newEPRIMEtxtFileName)) | (force == True) : # if the file hasn't already been transferred
	shutil.copy(txt_file,  newEPRIMEtxtFileName)
	print "\ttransferring EPRIME txt file"








