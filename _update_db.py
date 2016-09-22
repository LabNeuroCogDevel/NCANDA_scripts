'''

When adding a new field, it is important add the field to the db first before trying to update.
This is most easily done with Sequel Pro, but can be done through pymysql as well.
Newly added fields to the db will need to be added to this script in the CREATE TABLE
section, the INITIALIZATION sections of the main (visit) or secondary (run) loop, and
to the INSERT INTO statements of the main and secondary loops. 

Errors can sometimes be fixed by opening '/usr/local/var/mysql' and removing the
following files:

			main.ibd
			runs.ibd
			visits.ibd

These files hold the data for the mysql table and in some instances that are not dropped
from the DB and cannot be overwritten. In these cases, there is a run of errors ending with
the following lines:

pymysql.err.InternalError: (1813, u"Tablespace for table '`ncanda`.`main`' exists. 
	Please DISCARD the tablespace before IMPORT.")

'''


import pymysql
import sys, os, glob, shutil, string, time, subprocess
import numpy as np
import pandas as pd
from datetime import date


debug = False

user_id='paulsendj'
user_pwd='upmcM@1l'

accuracy_cutoff = 0.5 # 
trials_per_run_cutoff = 3 # 
motion_cutoff = 1.5 #

# SET UP SQL CONNECTION
conn = pymysql.connect(host='127.0.0.1', port=3306, user='root', database='NCANDA')
c = conn.cursor()


if (not os.path.exists("/Volumes/ns1/MRIImages")) & (os.path.exists("/Volumes/ns1/")):
	print("ns1 exists but MRIImages directory is not accessible\n try remounting PAARC drive")
	sys.exit(1)


# ns1 SERVER NEEDS TO MOUNTED FOR THE UPDATING TO WORK
timeout = time.time() + 60 # set timeout to sixty seconds
while (not os.path.exists("/Volumes/ns1/MRIImages")) & (time.time() < timeout):
	os.mkdir("/Volumes/ns1") # needed for mounting via shell script
	with open(os.devnull, 'w') as f:
		subprocess.call("/Users/ncanda/Documents/Research/NCANDA/scripts/mount_ns1.sh {0} {1}".format(user_id, user_pwd), shell=True, stdout=f)
	time.sleep(5)

if not os.path.exists("/Volumes/ns1/MRIImages"):
	print("ns1 server cannot be connected to at this time")
	sys.exit(1)

# PULL ANY CHANGES MADE TO THE EXCLUDE COLUMNS BEFORE RECREATING DATABASE
# this allows interim notes entered by hand to be retained
visit_exclude_df = pd.read_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_exclude_table_current.txt", sep='\t') 
run_exclude_df = pd.read_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_exclude_table_current.txt", sep='\t') 

# CLEAR OLD TABLE AND INITIATE NEW ONE
c.execute("USE NCANDA")

# CHECK TO MAKE SURE TABLES EXIST BEFORE TRYING TO DELETE, OTHERWISE ERRORS GET THROWN
table_list = pd.io.sql.frame_query("SHOW TABLES IN NCANDA", conn)

if 'main' in table_list.values:
	c.execute("DROP TABLE main")

if 'runs' in table_list.values:
	c.execute("DROP TABLE runs")

if 'visits' in table_list.values:
	c.execute("DROP TABLE visits")

c.execute('''
	CREATE TABLE main
	(subjectID INTEGER (3) ZEROFILL PRIMARY KEY,
	DOB DATE);
	''' )

c.execute('''
	CREATE TABLE visits
	(subjectID INTEGER (3) ZEROFILL,
	year INTEGER (1),
	scan_date DATE,
	n_mprage INTEGER (1),
	n_func_scans INTEGER (1),
	n_eye_eyd INTEGER (1),
	n_eye_eyd_trans INTEGER (1),
	n_eye_txt INTEGER (1),
	n_eye_txt_trans INTEGER (1),
	n_anat_trans INTEGER (1),
	n_func_trans INTEGER (1),
	n_anat_procd INTEGER (1),
	n_func_procd INTEGER (1),
	n_func_feat_lvl1 INTEGER (1),
	feat_lvl2 INTEGER (1),
	n_runs_feat_lvl2 INTEGER (1),
	anat_reg_reviewed INTEGER (1),
	exclude_visit INTEGER (1),
	visit_note VARCHAR (200),
	visit_read_me VARCHAR (500)
	);''')
	
c.execute('''
	CREATE TABLE runs
	(subjectID INTEGER (3) ZEROFILL,
	year INTEGER (1),
	run INTEGER (1),
	func_trans INTEGER (1),
	func_procd INTEGER (1),
	func_feat INTEGER (1),
	func_reg_reviewed INTEGER (1),
	func_proc_reviewed INTEGER (1),
	eyd_trans INTEGER (1),
	eye_txt_trans INTEGER (1),
	eye_scored INTEGER (1),
	event_list INTEGER (1),
	timing_files INTEGER (1),
	timing_confound INTEGER (1),
	ventricle_tc INTEGER (1),
	max_rms FLOAT(6,3),
	n_dropped INTEGER (2),
	accuracy FLOAT(4,3),
	ASCor_lat FLOAT(5,1),
	ASErrCor_lat FLOAT(5,1),
	ASRewCor_lat FLOAT(5,1),
	ASNeuCor_lat FLOAT(5,1),
	ASRewErrCor_lat FLOAT(5,1),
	ASNeuErrCor_lat FLOAT(5,1),
	n_rew_crct_trials INTEGER (2),
	n_neut_crct_trials INTEGER (2),
	n_rew_err_crct_trials INTEGER (2),
	n_neu_err_crct_trials INTEGER (2),
	n_rew_incrct_trials INTEGER (2),
	n_neut_incrct_trials INTEGER (2),
	exclude_run  INTEGER (1),
	run_note VARCHAR (200),
	eye_note VARCHAR (200)
	);''')


conn.commit()

# GET LIST OF ALL RAW MR DIRECTORIES - INDICATING SUBJECTS THAT HAVE BEEN RUN, PLACE INTO SET TO REMOVE DUPLICATES, AND ORDER IN A LIST
raw_mr_dirs = glob.glob("/Volumes/ns1/MRIImages/raw_data/NCANDA/A*")
subjectID_set = set()
for i in range(0, len(raw_mr_dirs)):
	subjectID_set.add(raw_mr_dirs[i].split('/')[-1][1:4])

subjectID_list = list(subjectID_set)
subjectID_list.sort() # sorted list of subjectIDs that have a folder in the ns1 MR directory

# PUT ALL SUBJECTIDs INTO THE MAIN TABLE OF DB
for i in subjectID_list:
	c.execute("INSERT INTO main (subjectID) VALUES (%s)" % (i) )


# GET LIST OF ALL LOCAL MR DIRECTORIES - INDICATING FILES HAVE AT LEAST BEEN ATTEMPTED TO BE TRANSFERRED
converted_mr_dirs = glob.glob("/Users/ncanda/Documents/Research/NCANDA/data_MR/A*")
for i in range(0, len(converted_mr_dirs)):
	converted_mr_dirs[i] = os.path.split(converted_mr_dirs[i])[-1]

# GET LIST OF ALL REGISTRATION FILES THAT HAVE BEEN REVIEWED
reviewed_list = glob.glob("/Users/ncanda/Documents/Research/NCANDA/data_MR/_registration/_reviewed/*")
for i in range(0, len(reviewed_list)):
	reviewed_list[i] = os.path.split(reviewed_list[i])[-1]


if debug:
	print(converted_mr_dirs)


# LOOP THROUGH ALL SUBJECTS FOR WHICH THERE IS AN MR DIRECTORY
for i in range(0, len(raw_mr_dirs)):

	# FOLDER NAME AT TAIL OF RAW MR DIRECTORY (e.g. "A002_1")
	raw_dir = os.path.split(raw_mr_dirs[i])[-1]
	raw_dir = "_".join(raw_dir.split("_")[0:2]) # raw dir does not include _rescan directories

	if debug:
		print(raw_dir)

	# SKIP FILE IF DATA FOLDER IS INCORRECTLY NAMED
	if (len(raw_dir) < 5):
		continue # all subject MR directories should have the year appended to the subject number

	# GET SUBJECT AND YEAR INFO FROM MR DIRECTORY NAME
	subjectID = raw_dir.split('_')[0][1:4]
	longSubjectID5 = "%05d" % (int(subjectID),)
	year = raw_dir.split('_')[1]


	# INITIALIZATIONS
	n_mprage = "0"
	n_func_scans = "0"
	n_eye_eyd = "0"
	n_eye_eyd_trans = "0"
	n_eye_txt = "0"
	n_eye_txt_trans = "0"
	n_anat_trans = "0"
	n_func_trans = "0"
	n_anat_procd = "0"
	n_func_procd = "0"
	n_func_feat_lvl1 = "0"
	feat_lvl2 = "0"
	n_runs_feat_lvl2 = "0"
	anat_reg_reviewed = "0"
	exclude_visit = "0"
	visit_note = ""
	visit_read_me=""


	# LOOK FOR POSSIBLE READ ME FILE (WILL NOT READ .docx FILES
	read_me = glob.glob("/Volumes/ns1/MRIImages/raw_data/NCANDA/" + raw_dir + "/*ead*me*.txt")
	if (len(read_me) == 1):
		for line in open(read_me[0]).readlines():
			line = line.strip()
			visit_read_me = visit_read_me + ": " + line
		if (len(visit_read_me) > 499):
			visit_read_me = visit_read_me[0:499]
		s = "string. With. Punctuation?" # Sample string 
		visit_read_me = visit_read_me.translate(string.maketrans("",""), string.punctuation)
		if (debug):
			print(visit_read_me)	

	# CHECK FOR FULL SET OF MPRAGE DICOMS
	mprage_dir = glob.glob("/Volumes/ns1/MRIImages/raw_data/NCANDA/" + raw_dir + "/*" + longSubjectID5 + "*/ncanda-mprage*")
	if (len(mprage_dir) > 0):
		mprage_dir = mprage_dir[0]
		dicom_list = glob.glob(mprage_dir + "/MR*")
		if (len(dicom_list) == 160):
			n_mprage = 1
			scan_date = time.strftime("%Y-%m-%d", time.gmtime(os.path.getctime(dicom_list[0]))) # creation date formated to "YYYY-MM-DD"
		else:
			n_mprage = 0
			scan_date = "0000-00-00"
	else:
		n_mprage = 0
		scan_date = "0000-00-00"

	# GET COUNT OF FUNC SCANS, EYE EYD FILES, EYE TXT FILES (BOTH EYE FILES NEEDED FOR SCORING) ON SERVER
	rings_dirs = glob.glob("/Volumes/ns1/MRIImages/raw_data/NCANDA/" + raw_dir + "/*/*rewards*")
	n_func_scans = len(rings_dirs)
	n_eye_eyd = len(glob.glob("/Volumes/ns1/DeptShare/ClarkProjects/NCANDA/Data/Eye-trac Data/" + raw_dir[0:4] + "/" + raw_dir[0:4] + "_y" + str(year) + "*[0-9].eyd"))
	n_eye_txt = len(glob.glob("/Volumes/ns1/DeptShare/ClarkProjects/NCANDA/Data/Eye-trac Data/" + raw_dir[0:4] + "/" + raw_dir[0:4] + "_y" + str(year) + "*[0-9].txt"))

	# ATTEMPT TO GET VISIT NOTE - IF NOT PRESENT IndexError or KeyError will be raised, just skip
	try:
		data_row = visit_exclude_df.loc[(visit_exclude_df['subjectID']==int(subjectID)) & (visit_exclude_df['year']==int(year)),]
		visit_note = data_row['visit_note'].iloc[0]
		if visit_note != visit_note: # if visit_note is nan
			visit_note = ""
		exclude_visit = data_row['exclude_visit'].iloc[0]
		anat_reg_reviewed = data_row['anat_reg_reviewed'].iloc[0]
	except:
		pass

	registration_file = str(subjectID) + "_" + str(year) + "_registration.png"
	if (registration_file in reviewed_list):
		 anat_reg_reviewed = 1

	# GET COUNTS OF FILES LISTED IN LOCAL DIRECTORIES
	if debug:
		print(raw_dir)
		print('\r')

	if raw_dir in converted_mr_dirs:
		mr_dir = "/Users/ncanda/Documents/Research/NCANDA/data_MR/" + raw_dir
		n_anat_trans = len(glob.glob(mr_dir + "/mprage/" + subjectID + "_mprage.nii.gz"))
		n_anat_procd = len(glob.glob(mr_dir + "/mprage/" + subjectID + "_mprage_nonlinear_warp_MNI_FSL_2mm.nii.gz"))
		n_func_trans = len(glob.glob(mr_dir + "/run*/" + subjectID + "*.nii.gz"))
		n_func_procd = len(glob.glob(mr_dir + "/run*/nfswkmtd_" + subjectID + "*.nii.gz"))
		n_ventricle_tc = len(glob.glob(mr_dir + "/run*/ventr*_tc.txt"))
		n_func_feat_lvl1 = len(glob.glob(mr_dir + "/run*/FEAT.feat/stats/zstat13.nii.gz")) # using cope13 as reference since it is the last file made
		feat_lvl2 = len(glob.glob(mr_dir + "/FEAT_LVL2.gfeat/cope13.feat/stats/zstat1.nii.gz")) # using cope13 as reference since it is the last file made

		# READ NUMBER OF FILES IN LEVEL 2 ANALYSIS FROM design.grp file
		if feat_lvl2 == 1:
			try:
				n_runs_feat_lvl2 = open(mr_dir + "/FEAT_LVL2.gfeat/design.grp").readlines()[1].split('\t')[-1].strip()
			except IOError:
				print "Could not open ", (mr_dir + "/FEAT_LVL2.gfeat/design.grp")


		# CHECK LOCAL EYE DATA DIRECTORY FOR FILES AND FILE COUNTS
		eye_dir = "/Users/ncanda/Documents/Research/NCANDA/data_eye/A" + subjectID
		if os.path.exists(eye_dir):
			n_eye_eyd_trans = len(glob.glob(eye_dir + "/A" + subjectID + "_y" + year + "_Eraw*.eyd"))
			n_eye_txt_trans = len(glob.glob(eye_dir + "/A" + subjectID + "_y" + year + "_Eprime*.txt"))
			n_eye_scored = len(glob.glob(eye_dir + "/" + subjectID + "_y" + year + "_run*.trial.txt"))
			n_runs_timing = len(glob.glob(eye_dir + "/timing_y" + year + "/" + subjectID + "_y" + year + "_stim_times_run*.01_rew_cue.txt"))
	
		# OPEN ACCURACY FILE NAME IF PRESENT FOR USE IN RUN LOOPS BELOW
		# IF NOT PRESENT, TRY TO DELETE PREVIOUS ACCURACY DATA
		accuracy_file_name = eye_dir + "/accuracy.txt"
		if os.path.exists(accuracy_file_name):
			accuracy_df = pd.read_csv(accuracy_file_name, sep="\s")	
		else:
			try:
				del(accuracy_df)
			except:
				pass
	
		# CHECK ON EACH RUN
		for current_run_folder in glob.glob(mr_dir + "/run*"):
			
			if debug:
				print(current_run_folder)
			
			
			# RUN LEVEL INITIALIZATIONS
			func_trans = "0"
			func_procd = "0"
			func_feat = "0"
			func_reg_reviewed = "0"
			func_proc_reviewed = "0"
			
			eyd_trans = "0"
			eye_txt_trans = "0"
			eye_scored = "0"
			event_list = "0"
			timing_files = "0"
			timing_confound = "0"
			
			ventricle_tc = "0"
			max_rms = "NULL"
			n_dropped = "NULL"
			accuracy = "NULL"
			
			ASCor_lat = "NULL"
			ASErrCor_lat = "NULL"			
			ASRewCor_lat = "NULL"
			ASNeuCor_lat = "NULL"
			ASRewErrCor_lat = "NULL"
			ASNeuErrCor_lat = "NULL"
			
			n_rew_err_crct_trials = "NULL"
			n_neu_err_crct_trials = "NULL"
			n_rew_crct_trials = "NULL"
			n_neut_crct_trials = "NULL"
			n_rew_incrct_trials = "NULL"
			n_neut_incrct_trials = "NULL"
			exclude_run = "0"
			run_note = ""
			eye_note = ""
			
			current_confound_file = ""
			
			run = current_run_folder[-1]
			func_trans = 1*os.path.exists(current_run_folder + "/" + str(subjectID) + "_run" + str(run) + ".nii.gz")
			func_procd = 1*os.path.exists(current_run_folder + "/nfswkmtd_" + str(subjectID) + "_run" + str(run) + ".nii.gz")
			func_feat = 1*os.path.exists(current_run_folder + "/FEAT.feat/stats/zstat13.nii.gz")
			
			eyd_trans = 1*os.path.exists(eye_dir + "/A" + str(subjectID) + "_y" + str(year) + "_Eraw_run" + str(run) + ".eyd")
			eye_txt_trans = 1*os.path.exists(eye_dir + "/A" + str(subjectID) + "_y" + str(year) + "_Eprime_run" + str(run) + ".txt")
			eye_scored = 1*os.path.exists(eye_dir + "/" + str(subjectID) + "_y" + str(year) + "_run" + str(run) + ".trial.txt")
			event_list = 1*os.path.exists(eye_dir + "/eventlist_" + str(subjectID) + "_y" + str(year) + "_run" + str(run) + ".txt")
			timing_files = 1*os.path.exists(eye_dir + "/timing_y" + str(year) + "/" + str(subjectID) + "_y" + str(year) + "_stim_times_run" + str(run) + ".9_dropped.txt")
			
			# CHECK TO MAKE SURE THE CONFOUND FILE EXISTS AND HAS THE CORRECT NUMBER OF COLUMNS
			# 1 if exists and has correct number of columns, 0 if doesn't exist, -1 if exists and has incorrect number of columns
			current_confound_file = eye_dir + "/timing_y" + str(year) + "/" + str(subjectID) + "_y" + str(year) + "_confounds_run" + str(run) + ".txt"
			timing_confound = 1*os.path.exists(current_confound_file)
			if timing_confound:
				confounds = pd.read_csv(current_confound_file, sep='\s')
				if len(confounds.columns) < 9:
					timing_confound = -1
			
			ventricle_tc = 1*os.path.exists(current_run_folder + "/ventrical_tc.txt")
			
			func_rms_file = current_run_folder + "/mcplots_rel.rms"
			if os.path.exists(func_rms_file):
				current_rms_df = pd.read_csv(func_rms_file, sep='\s', header=None)
				max_rms = max(current_rms_df.ix[:][0])
				
			
			# ATTEMPT TO GET RUN NOTE AND REVIEWED STATUS - IF NOT PRESENT IndexError OR KeyError WILL BE RAISED, JUST SKIP
			try:
				data_row = run_exclude_df.loc[(run_exclude_df['subjectID']==int(subjectID)) & (run_exclude_df['year']==int(year)) & (run_exclude_df['run']==int(run)),]
				run_note = data_row['run_note'].iloc[0]
				if run_note != run_note: # if run_note is nan
					run_note = ""
				eye_note = data_row['eye_note'].iloc[0]
				if eye_note != eye_note: # if eye_note is nan
					eye_note = ""
				exclude_run = data_row['exclude_run'].iloc[0]
				func_reg_reviewed = data_row['func_reg_reviewed'].iloc[0]
				func_proc_reviewed = data_row['func_proc_reviewed'].iloc[0]
			except:
				pass
			
			
			
			# GET RUN LEVEL ACCURACY AND TRIAL COUNT STATS
			if 'accuracy_df' in locals(): # if accuracy_df is loaded
				accuracy_df = accuracy_df[(accuracy_df['subjectID']==int(subjectID)) & (accuracy_df['year']==int(year))] # select only rows from the current year
				if len(accuracy_df.index) > 0: # if there are no rows, skip
					try:
						accuracy = float(accuracy_df[accuracy_df['run']==int(run)]['total_accuracy'])
						if accuracy != accuracy: # this tests to see if accuracy is nan value
							accuracy = 0
						n_rew_crct_trials = int(accuracy_df[accuracy_df['run']==int(run)]['rew_correct'])
						n_neut_crct_trials = int(accuracy_df[accuracy_df['run']==int(run)]['neut_correct'])
						n_rew_incrct_trials = int(accuracy_df[accuracy_df['run']==int(run)]['rew_incorrect'])
						n_neut_incrct_trials = int(accuracy_df[accuracy_df['run']==int(run)]['neut_incorrect'])
						n_dropped = int(accuracy_df[accuracy_df['run']==int(run)]['dropped'])
					except:
						pass
		
			# GET RUN LEVEL LATENCY MEASURES
			latency_file = (eye_dir + "/" + str(subjectID) + "_y" + str(year) + "_run" + str(run) + ".summary.txt")
			if os.path.exists(latency_file):
				latency = pd.read_csv(latency_file, sep='\s')
				try:
					ASCor_lat = float(round(float(latency[latency['run']==int(run)]['AScor.lat']), 1))
					ASErrCor_lat = float(round(float(latency[latency['run']==int(run)]['ASErrCor.lat']), 1))
					if pd.isnull(ASCor_lat):
						ASCor_lat = "NULL"
					if pd.isnull(ASErrCor_lat):
						ASErrCor_lat = "NULL"
					
				except:
					pass
			
			### ADDED NOV 16, 2014
			# GET RUN LEVEL LATENCY MEASURES FOR EACH CONDITION 
			latency_file = (eye_dir + "/" + str(subjectID) + "_y" + str(year) + "_run" + str(run) + ".trial.txt")
			if os.path.exists(latency_file):
				latency = pd.read_csv(latency_file, sep='\t')
				try:
					latency_acc = latency.loc[latency["fstCorrect"] == True,:]
					grouped = latency_acc.groupby(['AS'])
					try:
						ASRewCor_lat = grouped.get_group('ASRew')['lat'].mean()
					except:
						ASRewCor_lat = "NULL"
					try:
						ASNeuCor_lat = grouped.get_group('ASNue')['lat'].mean()
					except:
						ASNeuCor_lat = "NULL"
				except:
					pass
				try:
					latency_correction = latency.loc[latency["ErrCorr"] == True,:]
					grouped = latency_correction.groupby(['AS'])
					try:
						ASRewErrCor_lat = grouped.get_group('ASRew')['lat'].mean()
						n_rew_err_crct_trials = grouped.get_group('ASRew')['lat'].count()
					except:
						ASRewErrCor_lat = "NULL"
					try:
						ASNeuErrCor_lat = grouped.get_group('ASNue')['lat'].mean()
						n_neu_err_crct_trials = grouped.get_group('ASNue')['lat'].count()
					except:
						ASNeuErrCor_lat = "NULL"
				except:
					pass
			
			
			# DETERMINE IF RUN SHOULD BE REJECTED
			if not accuracy == "NULL":
				run_note = run_note.replace("accuracy; ", "") # this is so that we don't iteratively add automated notes, but retain hand notes
				run_note = run_note.replace("too few rew trials; ", "")
				run_note = run_note.replace("too few neut trials; ", "")
				run_note = run_note.replace("excess motion; ", "")
				if accuracy < accuracy_cutoff:
					exclude_run = 1
					run_note = run_note + "accuracy; "
				if n_rew_crct_trials < trials_per_run_cutoff:
					exclude_run = 1
					run_note = run_note + "too few rew trials; "
				if n_neut_crct_trials < trials_per_run_cutoff:
					exclude_run = 1
					run_note = run_note + "too few neut trials; "
				if max_rms > motion_cutoff:
					exclude_run = 1
					run_note = run_note + "excess motion; "
			
			# ADD RUN LEVEL DATA INTO DB
			try:
				c.execute('''INSERT INTO runs
				(subjectID, year, run, func_trans, func_procd, func_feat, func_reg_reviewed, func_proc_reviewed, eyd_trans, eye_txt_trans,
				eye_scored, event_list, timing_files, timing_confound, ventricle_tc, max_rms, n_dropped, accuracy, ASCor_lat, ASErrCor_lat,
				ASRewCor_lat, ASNeuCor_lat, ASRewErrCor_lat, ASNeuErrCor_lat, n_rew_crct_trials, n_neut_crct_trials, n_rew_err_crct_trials, n_neu_err_crct_trials, n_rew_incrct_trials, n_neut_incrct_trials, exclude_run, run_note, eye_note)
				VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, '%s', '%s')
				''' % (subjectID, year, run, func_trans ,func_procd, func_feat, func_reg_reviewed, func_proc_reviewed, eyd_trans, eye_txt_trans,
					eye_scored, event_list, timing_files, timing_confound, ventricle_tc, max_rms, n_dropped, accuracy, ASCor_lat, ASErrCor_lat,
					ASRewCor_lat, ASNeuCor_lat, ASRewErrCor_lat, ASNeuErrCor_lat, n_rew_crct_trials, n_neut_crct_trials, n_rew_err_crct_trials, n_neu_err_crct_trials, n_rew_incrct_trials, n_neut_incrct_trials, 
					exclude_run, run_note, eye_note) )
				
				conn.commit()
			
			except:
				print "Error entering run data for subject %s, year %s, run %s" % (subjectID, year, run)
				print sys.exc_info()[0]
				print " subjectID " + str(subjectID)
				print " year " +str(year)
				print " run " +str(run)
				print " func_trans " + str(func_trans) 
				print " func_procd " + str(func_procd)
				print " func_feat " + str(func_feat)
				print " func_reg_reviewed " +str(func_reg_reviewed)
				print " func_proc_reviewed " + str(func_proc_reviewed)
				print " eyd_trans " + str(eye_txt_trans)
				print " eye_scored " + str(eye_scored)
				print " event_list " + str(event_list)
				print " timing_files " + str(timing_files)
				print " timing_confound " +str(timing_confound)
				print " ventricle_tc " +str(ventricle_tc)
				print " max_rms " +str(max_rms)
				print " n_dropped " +str(n_dropped)
				print " accuracy " +str(accuracy)
				print " ASCor_lat " +str(ASCor_lat)
				print " ASErrCor_lat " +str(ASErrCor_lat)
				print " ASRewCor_lat " +str(ASRewCor_lat)
				print " ASNeuCor_lat " +str(ASNeuCor_lat)
				print " ASRewErrCor_lat " +str(ASRewErrCor_lat)
				print " ASNeuErrCor_lat " +str(ASNeuErrCor_lat)
				print " n_rew_crct_trials " +str(n_rew_crct_trials)
				print " n_neut_crct_trials " +str(n_neut_crct_trials)
				print " n_rew_err_crct_trials " +str(n_rew_err_crct_trials)
				print " n_neu_err_crct_trials " +str(n_neu_err_crct_trials)
				print " n_rew_incrct_trials " + str(n_rew_incrct_trials)
				print " n_neut_incrct_trials " +str(n_neut_incrct_trials)
				print " exclude_run " + str(exclude_run)
				print " run_note " + str(run_note)
				print " eye_note " + str(eye_note)
				print "\n\n"
				pass


			
	# ADD VISIT LEVEL DATA INTO DB
	c.execute('''INSERT INTO visits
	(subjectID, year, scan_date, n_mprage, n_func_scans, n_eye_eyd, n_eye_eyd_trans, n_eye_txt, n_eye_txt_trans, n_anat_trans, 
	n_func_trans, n_anat_procd, n_func_procd, n_func_feat_lvl1, feat_lvl2, n_runs_feat_lvl2, anat_reg_reviewed, exclude_visit, visit_note, visit_read_me)
	VALUES(%s, %s, '%s', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, '%s', '%s')
	''' % (subjectID, year, scan_date, n_mprage, n_func_scans, n_eye_eyd, n_eye_eyd_trans, n_eye_txt, n_eye_txt_trans, n_anat_trans, 
		n_func_trans, n_anat_procd, n_func_procd, n_func_feat_lvl1, feat_lvl2, n_runs_feat_lvl2, anat_reg_reviewed, exclude_visit, visit_note, visit_read_me) )
	
	# COMMIT CHANGES TO DB
	conn.commit()



# UPDATE EXCLUDE VISITS BASED ON NUMBER OF GOOD RUNS (EXCLUDE IF < 2)
c.execute('''UPDATE visits AS visits
	INNER JOIN (SELECT subjectID, year, ( COUNT(exclude_run) - SUM(exclude_run)) AS good_runs 
	FROM runs
	WHERE n_dropped IS NOT NULL 
	GROUP BY subjectID, year
	HAVING good_runs < 2) AS runs_table
	ON (visits.subjectID = runs_table.subjectID AND visits.year = runs_table.year)
SET visits.exclude_visit = 1, visits.visit_note = CONCAT(REPLACE(visits.visit_note, '; too few runs', ''), '; too few runs')
''')

# COMMIT CHANGES TO DB
conn.commit()


# BEGIN DELETION OF BAD SUBJECTS: READ SUBJECTS INTO SET, DELETE, WRITE SUBJECTS INTO DOC
# Read from server list and local list - expects tab indent - place [id,year] pair into set
bad_subjects = set()
bad_subject_list_name1 = "/Volumes/ns1/DeptShare/PAARCProjects/SHARE/paulsen/subject_list_exclude.txt"
bad_subject_list_name2 = "/Users/ncanda/Documents/Research/NCANDA/scripts/subject_list_exclude.txt"
for fyle in [bad_subject_list_name1, bad_subject_list_name2]:
	for line in open(fyle, 'r').readlines()[1:]:
		line = line.strip().split("\t")[0].split("_") 
		if len(line) == 2:
			[current_subjectID, current_year] = line
		current_subjectID = current_subjectID[1:]
		bad_subjects.add((int(current_subjectID), int(current_year)))

delete_items_file = open("/Users/ncanda/Documents/Research/NCANDA/analysis/deleted_subjects_from_db.txt", 'w')
delete_items_file.write(
		'''Notes for these subjects in:
	local "/Users/ncanda/Documents/Research/NCANDA/scripts/subject_list_exclude.txt" and 
	server /Volumes/ns1/DeptShare/PAARCProjects/SHARE/paulsen/subject_list_exclude.txt"\n
subjectID	year\n''')

for [current_subjectID, current_year]  in bad_subjects:
	delete_items_file.write('{0}\t{1}\n'.format(current_subjectID, current_year))
	c.execute('''DELETE FROM runs
		WHERE subjectID = {} AND year = {}'''.format(current_subjectID, current_year))
	c.execute('''DELETE FROM visits
		WHERE subjectID = {} AND year = {}'''.format(current_subjectID, current_year))

conn.commit()



# COLLECT TABLES AS PANDAS DATAFRAMES AND SAVE AS TAB-DELIMITED TEXT FILES
# EACH TABLE WILL BE SAVED ONCE AS 'CURRENT' AND ONCE WITH THE CURRENT DATE
visit_table = pd.io.sql.frame_query('''SELECT * FROM visits''', conn) # from pandas
visit_table_name = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/_archive/visit_table" + date.today().strftime("%y_%m_%d") + ".txt"
visit_table_name_current = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_table_current.txt"
visit_table.to_csv(visit_table_name, sep='\t', index=False) 
visit_table.to_csv(visit_table_name_current, sep='\t', index=False) 

run_table = pd.io.sql.frame_query('''SELECT * FROM runs''', conn)
run_table_name = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/_archive/run_table" + date.today().strftime("%y_%m_%d") + ".txt"
run_table_name_current = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_table_current.txt"
run_table.to_csv(run_table_name, sep='\t', index=False) 
run_table.to_csv(run_table_name_current, sep='\t', index=False) 

visit_exclude_table = pd.io.sql.frame_query('''SELECT subjectID, year, anat_reg_reviewed, exclude_visit, visit_note FROM visits''', conn) # from pandas
visit_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/_archive/visit_exclude_table" + date.today().strftime("%y_%m_%d") + ".txt", sep='\t', index=False) 
visit_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_exclude_table_current.txt", sep='\t', index=False) 

run_exclude_table = pd.io.sql.frame_query('''SELECT subjectID, year, run, func_reg_reviewed, func_proc_reviewed, exclude_run, run_note FROM runs''', conn) # from pandas
run_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/_archive/run_exclude_table" + date.today().strftime("%y_%m_%d") + ".txt", sep='\t', index=False) 
run_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_exclude_table_current.txt", sep='\t', index=False) 


# CLOSE ALL SQL CONNECTIONS
c.close()
conn.close()






