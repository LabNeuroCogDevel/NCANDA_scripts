import pymysql
import sys, os, glob, shutil, string, time
import numpy as np
import pandas as pd
from datetime import date


# USED TO FORMAT STRINGS AND FLOATS FOR CONCATENATION IN FINDING FEAT_LVL2 SUBJECTS
def frmt(x):
	if x.__class__.__name__ in ['float64', 'float', 'int', 'int64']:
		return str(int(x))
	elif x.__class__.__name__ == 'str':
		return x





# SET UP SQL CONNECTION
conn = pymysql.connect(host='127.0.0.1', port=3306, user='root', database='NCANDA')
c = conn.cursor()

c.execute("USE NCANDA")


# SUBJECT YEAR WHERE THE NUMBER OF EYE FILES OR IMAGE FILES ARE NOT EQUAL TO WHAT IS EXPECTED
problem_subjects = pd.io.sql.frame_query('''
	SELECT subjectID, year, n_func_scans, n_eye_txt, n_eye_eyd FROM visits
	WHERE (n_mprage <> "1" OR n_func_scans <> "4" OR n_eye_txt <> "4" OR n_eye_eyd <> "4")
	AND exclude_visit <> "1"
''', conn) 	
problem_subjects.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/00_problem_subjects_list.txt", sep='\t', index=False) 


# SUBJECT YEAR FOR NEW SUBJECTS THAT HAVE THE EXPECTED DATA AND NEED TO BE TRANSFERRED
convert_dicom_table = pd.io.sql.frame_query('''
	SELECT subjectID, year FROM visits
	WHERE n_mprage = "1" AND n_func_scans > "1" AND n_eye_txt > "1" AND n_eye_eyd > "1"
	AND (n_anat_trans = "0" OR n_func_trans = "0") AND exclude_visit <> "1"
''', conn) 
convert_dicom_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/01_convert_dicoms_list.txt", sep=' ', index=False) 

# SUBJECT YEAR FOR SUBJECTS WITH TRANSFERRED ANAT DATA BUT NOTHING PROCESSED YET
process_anat_table = pd.io.sql.frame_query('''
	SELECT subjectID, year FROM visits
	WHERE n_anat_trans = "1" AND n_anat_procd = "0" AND exclude_visit <> "1"
''', conn) 
process_anat_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/02_preprocessAnat_list.txt", sep=' ', index=False) 

# SUBJECT YEAR FOR SUBJECTS WITH TRANSFERRED FUNC DATA BUT NOTHING PROCESSED YET
process_func_table = pd.io.sql.frame_query('''
	SELECT subjectID, year, run FROM runs
	WHERE func_trans = "1" AND func_procd = "0" AND exclude_run <> "1" AND run < 5
''', conn) 
process_func_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/03_preprocessFunc_list.txt", sep=' ', index=False) 



# SUBJECT YEAR FOR SUBJECTS WITH EYE DATA BUT NOTHING TRANSFERRED
# this compares number of eyd files to the number of eyd files transferred using
# an embedded query
trans_eye_table = pd.io.sql.frame_query('''
	SELECT subjectID, year 
	FROM visits 
	WHERE n_eye_eyd <> n_eye_eyd_trans
	AND n_eye_eyd < 5 AND n_eye_txt < 5
	AND exclude_visit <> "1"
''', conn) 
# WE GO THROUGH A COUPLE OF STEPS TO GET THE CARTESIAN PRODUCT
run_list = pd.DataFrame({'run':[1,2,3,4]})
run_list['ones'] = np.ones(len(run_list.index))
trans_eye_table['ones'] = np.ones(len(trans_eye_table.index))
trans_eye_table = pd.merge(trans_eye_table, run_list, left_on='ones', right_on='ones')
trans_eye_table = trans_eye_table[['subjectID','year','run']] 
trans_eye_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/04_transferEyeData_list.txt", sep=' ', index=False) 


# SUBJECT YEAR FOR SUBJECTS WITH EYE DATA BUT NOT SCORED
unscored_eye_table = pd.io.sql.frame_query('''
	SELECT subjectID, year, run FROM runs
	WHERE eyd_trans = "1" AND eye_txt_trans = "1" AND eye_scored = "0" AND exclude_run <> "1" AND run < 5
''', conn) 
unscored_eye_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/05_scoreOne_list.txt", sep=' ', index=False) 


# SUBJECT YEAR FOR SUBJECTS WITH EYE DATA BUT NO EVENT LIST MADE
event_list_table = pd.io.sql.frame_query('''
	SELECT subjectID, year, run FROM runs
	WHERE eyd_trans = "1" AND eye_txt_trans = "1" AND event_list = "0" AND exclude_run <> "1" AND run < 5
''', conn) 
event_list_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/06a_make_event_files_list.txt", sep=' ', index=False) 

# SUBJECT YEAR FOR SUBJECTS WITH PROCD FUNCTIONAL DATA BUT NO VENTRICLE TC
ventricle_list_table = pd.io.sql.frame_query('''
	SELECT subjectID, year, run FROM runs
	WHERE func_procd = "1" AND ventricle_tc = "0" AND exclude_run <> "1" AND run < 5
''', conn) 
ventricle_list_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/06b_get_ventricle_tc_list.txt", sep=' ', index=False) 


# SUBJECT YEAR FOR SUBJECTS WITH NO TIMING FILES
timing_list_table = pd.io.sql.frame_query('''
	SELECT subjectID, year, run FROM runs
	WHERE eye_scored = "1" AND (timing_files = "0" OR timing_confound = "0") AND exclude_run <> "1" AND run < 5
''', conn) 
timing_list_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/07_makeTimingFiles_list.txt", sep=' ', index=False) 


# SUBJECT YEAR FOR SUBJECTS WITH TIMING FILES BUT NO FIRST LEVEL FEAT
func_lvl1_table = pd.io.sql.frame_query('''
	SELECT subjectID, year, run FROM runs
	WHERE timing_files = "1" AND func_feat = "0" AND exclude_run <> "1" AND run < 5
''', conn) 
func_lvl1_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/08_FEAT_RUN_LVL1_list.txt", sep=' ', index=False) 

# SUBJECT YEAR FOR SUBJECTS FIRST LEVEL FEATS BUT NO SECOND LEVEL
func_lvl2_table = pd.io.sql.frame_query('''
	SELECT visits.subjectID, visits.year, runs.run 
	FROM visits, runs
	WHERE visits.subjectID = runs.subjectID AND visits.year = runs.year
	AND func_feat = "1" AND exclude_run <> "1" AND exclude_visit <> "1" 
	AND feat_lvl2 = "0"
''', conn) 
if (len(func_lvl2_table) > 0):
	func_lvl2_table = pd.pivot_table(func_lvl2_table, values='run', rows=['subjectID', 'year'], cols=['run'], aggfunc=np.sum)
	# replace nan values with empty string ""
	func_lvl2_table.fillna("", inplace=True) 
	# concatenate list of good runs
	func_lvl2_table = func_lvl2_table.apply(lambda x: '%s %s %s %s' % 
		(frmt(x[1]), frmt(x[2]), frmt(x[3]), frmt(x[4])), axis=1) 
	# replace leading, trailing, and extra whitespace; save as dataframe
	func_lvl2_table = pd.DataFrame(func_lvl2_table.apply(lambda x: x.strip().replace("  ", " ")))
	# name run_list column
	func_lvl2_table.columns = ['run_list']
	func_lvl2_table['n_runs'] = func_lvl2_table.apply(lambda x: (len(x['run_list']) + 1)/2, axis=1) # get number of runs
	func_lvl2_table = func_lvl2_table[['n_runs', 'run_list']] # change the order in which columns appear
	func_lvl2_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/10_FEAT_RUN_LVL2_list.txt", sep=' ', index=True, header=True) 
else:
	open("/Users/ncanda/Documents/Research/NCANDA/scripts/10_FEAT_RUN_LVL2_list.txt", 'w').write("subjectID year run")


# SUBJECT YEAR FOR SUBJECTS WITH TIMING FILES BUT NO FIRST LEVEL FEAT
func_lvl3_table = pd.io.sql.frame_query('''
	SELECT subjectID, year FROM visits
	WHERE feat_lvl2 = "1" AND exclude_visit <> "1"
	ORDER BY year, subjectID
''', conn) 
func_lvl3_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/scripts/11_FEAT_RUN_LVL3_list.txt", sep=' ', index=False) 




# CLOSE ALL SQL CONNECTIONS
c.close()
conn.close()






