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
sys.path.append("/Users/ncanda/Documents/Research/NCANDA/scripts")




# SET UP PARSER FOR PASSING IN SOURCE AND DESTINATION DIRECTORY OPTIONS
parser = OptionParser()
parser.add_option("-s", "--subject", dest="subject")
parser.add_option("-y", "--year", dest="year")
parser.add_option("-r", "--run", dest="run")
parser.add_option("-f", "--force", dest="force") # will force transfer and timing file construction even if subject is excluded
(options, args) = parser.parse_args()


if options.run==None:
	raise NameError, "Must specify run: -r #"
if options.subject==None:
	raise NameError, "Must specify subject: -s #"
if options.year==None:
	raise NameError, "Must specify year: -y #"


subjectID = options.subject
subjectID = "%03d" % (int(subjectID),)

year = options.year
run = options.run

if options.force == "True":
	force = True
else:
	force = False




# general directory
EyeDir = "/Users/ncanda/Documents/Research/NCANDA/data_eye/"
# subject specific eye data directory
#currentEyeDir = os.path.join(EyeDir, "A" + str(subjectID) + "y" + str(year))
currentEyeDir = os.path.join(EyeDir, ("A" + str(subjectID)))


# check server connection
if not os.path.exists(EyeDir):
	print EyeDir, "volume not mounted"
	sys.exit(1)


current_EPRIME_txt_file = os.path.join(currentEyeDir, ("A" + subjectID + "_y" + year + "_Eprime_run" + str(run) + ".txt") )

if not os.path.exists(current_EPRIME_txt_file):
	print current_EPRIME_txt_file, "file does not exist"
	sys.exit(1)


current_event_file = os.path.join(currentEyeDir, ("eventlist_" + subjectID + "_y" + year+ "_run" + str(run) + ".txt") )
output = open(current_event_file, 'w')
output.write("condition\tstim\tcatch\ttime\ttrial\tTR\n")

currentTime = 0
currentTrial = 0
TR = 1
for line in open(current_EPRIME_txt_file, 'r').readlines():
	line = line.strip().split(": ")
	if line[0] == "Procedure":
		if line[1] == "rewardCatch1":
			#print "reward_cue", currentTime, currentTrial, TR
			output.write("reward\tcue\t1\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
			#print "reward_prep", currentTime, currentTrial, TR
			output.write("reward\tprep\t1\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
		elif line[1] == "rewardCatch2":
			#print "reward_cue", currentTime, currentTrial, TR
			output.write("reward\tcue\t1\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
		elif line[1] == "neutralCatch1":
			#print "neutral_cue", currentTime, currentTrial, TR
			output.write("neutral\tcue\t1\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
			#print "neutral_prep", currentTime, currentTrial, TR
			output.write("neutral\tprep\t1\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
		elif line[1] == "neutralCatch2":
			#print "neutral_cue", currentTime, currentTrial, TR
			output.write("neutral\tcue\t1\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
		elif line[1] == "fix":
			#print "fix", currentTime, currentTrial, TR
			output.write("fix\tfix\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
			currentTime = currentTime + 1.5; TR = TR + 1
		elif len(line[1]) > 7:
			if (line[1][0:6] == "reward") & (line[1] != "rewardtask"):# final event is rewardtask
				currentTrial = currentTrial + 1	# only full trials are considered trials in score sheet	
				#print "reward_cue", currentTime, currentTrial, TR
				output.write("reward\tcue\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
				currentTime = currentTime + 1.5; TR = TR + 1
				#print "reward_prep", currentTime, currentTrial, TR
				output.write("reward\tprep\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
				currentTime = currentTime + 1.5; TR = TR + 1
				#print "reward_sac", currentTime, currentTrial, TR
				output.write("reward\tsac\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
				currentTime = currentTime + 1.5; TR = TR + 1
			elif line[1][0:7] == "neutral":
				currentTrial = currentTrial + 1 # only full trials are considered trials in score sheet
				#print "neutral_cue", currentTime, currentTrial, TR
				output.write("neutral\tcue\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
				currentTime = currentTime + 1.5; TR = TR + 1
				#print "neutral_prep", currentTime, currentTrial, TR
				output.write("neutral\tprep\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
				currentTime = currentTime + 1.5; TR = TR + 1
				#print "neutral_sac", currentTime, currentTrial, TR
				output.write("neutral\tsac\t0\t" + str(currentTime) + "\t" + str(currentTrial) + "\t" + str(TR) + "\n")
				currentTime = currentTime + 1.5; TR = TR + 1				

output.close()

if TR != 203:
	print "\tTR does not add to 202\n\tCheck Timing File for", subjectID, "run", run



