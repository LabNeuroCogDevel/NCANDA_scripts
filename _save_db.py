import pymysql
import sys, os, glob, shutil, string, time
import numpy as np
import pandas as pd
from datetime import date


# SET UP SQL CONNECTION
conn = pymysql.connect(host='127.0.0.1', port=3306, user='root', database='NCANDA')
c = conn.cursor()



# COLLECT TABLES AS PANDAS DATAFRAMES AND SAVE AS TAB-DELIMITED TEXT FILES
# EACH TABLE WILL BE SAVED ONCE AS 'CURRENT' AND ONCE WITH THE CURRENT DATE
visit_table = pd.io.sql.frame_query('''SELECT * FROM visits''', conn) # from pandas
visit_table_name = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_table" + date.today().strftime("%y_%m_%d") + ".txt"
visit_table_name_current = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_table_current.txt"
visit_table.to_csv(visit_table_name, sep='\t', index=False) 
visit_table.to_csv(visit_table_name_current, sep='\t', index=False) 

run_table = pd.io.sql.frame_query('''SELECT * FROM runs''', conn)
run_table_name = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_table" + date.today().strftime("%y_%m_%d") + ".txt"
run_table_name_current = "/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_table_current.txt"
run_table.to_csv(run_table_name, sep='\t', index=False) 
run_table.to_csv(run_table_name_current, sep='\t', index=False) 

visit_exclude_table = pd.io.sql.frame_query('''SELECT subjectID, year, anat_reg_reviewed, exclude_visit, visit_note FROM visits''', conn) # from pandas
visit_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_exclude_table" + date.today().strftime("%y_%m_%d") + ".txt", sep='\t', index=False) 
visit_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/visit_exclude_table_current.txt", sep='\t', index=False) 

run_exclude_table = pd.io.sql.frame_query('''SELECT subjectID, year, run, func_reg_reviewed, func_proc_reviewed, exclude_run, run_note FROM runs''', conn) # from pandas
run_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_exclude_table" + date.today().strftime("%y_%m_%d") + ".txt", sep='\t', index=False) 
run_exclude_table.to_csv("/Users/ncanda/Documents/Research/NCANDA/analysis/backup_db/run_exclude_table_current.txt", sep='\t', index=False) 


# CLOSE ALL SQL CONNECTIONS
c.close()
conn.close()






