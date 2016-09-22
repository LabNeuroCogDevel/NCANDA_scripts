






import pymysql
import sys, os, glob, shutil, string, time, subprocess
import numpy as np
import pandas as pd
#from datetime import date
import calendar
import datetime

# SET UP SQL CONNECTION
conn = pymysql.connect(host='127.0.0.1', port=3306, user='root', database='NCANDA')
c = conn.cursor()

c.execute("USE NCANDA")


# SUMMARY OF EXCLUDED RUNS AND VISITS WITH REASONS
summary_excluded_runs = pd.io.sql.frame_query('''
	SELECT r.subjectID
		, r.year
		, v.scan_date
		, CASE WHEN v.`exclude_visit` = 1 THEN 'exclude_visit'
				ELSE 'good'
				END AS visit_status
		, r2.excluded_total
		, r.excluded_cnt
		, r.run_note
	FROM (
		SELECT subjectID, year, SUM(exclude_run) AS excluded_cnt, run_note
		FROM runs
		GROUP BY subjectID, year, run_note
		HAVING SUM(exclude_run) > 0
		) AS r
	JOIN visits v
		ON v.subjectID = r.subjectID
		AND v.year = r.year
	JOIN (
		SELECT subjectID, year, SUM(exclude_run) AS excluded_total
		FROM runs
		GROUP BY subjectID, year
		HAVING SUM(exclude_run) > 0
		) AS r2
		ON r2.subjectID = r.subjectID
		AND r2.year = r.year
	ORDER BY v.scan_date DESC
''', conn) 	
summary_excluded_runs.to_csv("/Users/ncanda/Documents/Research/NCANDA/summary_excluded_runs.txt", sep='\t', index=False) 


# SUMMARY OF EXCLUDED VISITS 
summary_excluded_visits = pd.io.sql.frame_query('''
	SELECT r.subjectID
		, r.year
		, v.scan_date
		, CASE WHEN v.`exclude_visit` = 1 THEN 'exclude_visit'
				ELSE 'good'
				END AS visit_status
		, r.counts
	FROM (
		SELECT subjectID, year, SUM(exclude_run) AS counts
		FROM runs
		GROUP BY subjectID, year
		) AS r
	JOIN visits v
		ON v.subjectID = r.subjectID
		AND v.year = r.year
	ORDER BY v.scan_date DESC
''', conn) 	
summary_excluded_visits.to_csv("/Users/ncanda/Documents/Research/NCANDA/summary_excluded_visits.txt", sep='\t', index=False) 


summary_excluded_visits['scan_date'] = pd.tseries.tools.to_datetime(summary_excluded_visits['scan_date'])
summary_excluded_visits['scan_year'] = pd.DatetimeIndex(summary_excluded_visits['scan_date']).year
summary_excluded_visits['scan_month'] = pd.DatetimeIndex(summary_excluded_visits['scan_date']).month


grouped = summary_excluded_visits[['scan_year', 'scan_month', 'visit_status', 
	'counts']].groupby(['scan_year', 'scan_month', 'visit_status']).count()

grouped2 = grouped.add_suffix('_Count').reset_index()
grouped2 = grouped2[['scan_year', 'scan_month', 'visit_status','visit_status_Count']]

grouped2.to_csv("/Users/ncanda/Documents/Research/NCANDA/summary_excluded_visits_grouped.txt", sep='\t', index=False) 


