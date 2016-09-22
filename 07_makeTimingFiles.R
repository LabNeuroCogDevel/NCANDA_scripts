#!/usr/bin/Rscript
# USE COMMAND: Rscript 05_makeTimingFiles.R subjectID year run



args <- commandArgs(trailingOnly = TRUE)



subjectID <- formatC( as.numeric(as.character(args[1])) , width=3, format = "d", flag = "0")
year <- args[2]
run <- args[3]
overwrite <- args[4]

if (! is.na(overwrite)) { 
	if (overwrite != TRUE) {
		overwrite = FALSE
	}
} else { overwrite = FALSE}

if (length(args) < 3) {
stop("       Must specify subjectID, year, run, in that order")
}


# a dropped trial is one in which neither the saccade nor the hold were scored (lat & acc columns)
# an incorrect trial is one in which subject saccaded to the incorrect directions, whether or not they held it
# a correct rial is one in which either the saccade or the hold were rated as correct


setwd("/Users/ncanda/Documents/Research/NCANDA/scripts")
num_evs_per_run = 10 # this is how many EVs are to be expected. if more or less than this per run is found, script will overwrite

timing_error_file <- "/Users/ncanda/Documents/Research/NCANDA/scripts/timing_errors.txt"
destinationDir <- "/Users/ncanda/Documents/Research/NCANDA/data_eye"




eye_data_dir <- paste( c(destinationDir, "/A",subjectID), sep="", collapse="")
timing_dir <- paste( c(destinationDir, "/A", subjectID, "/timing_y", year), sep="", collapse="")

if (! file.exists(timing_dir)) {
	dir.create(timing_dir)
}

current_eye_file <- paste(c(eye_data_dir, "/", subjectID, "_y", year, "_run", run, ".trial.txt"), sep="", collapse="")

timing_pattern = paste(c("eventlist_", subjectID, "_y", year, "_run", run, ".txt"), sep="", collapse="") 
edited_timing_file <- dir(eye_data_dir, pattern=timing_pattern, full.names = T)

accuracy_output_file_name <- paste(c(eye_data_dir, "/accuracy.txt"), sep="", collapse="")
latency_output_file_name <- paste(c(eye_data_dir, "/latency.txt"), sep="", collapse="")
inconsistency_err_file_name <- paste(c(eye_data_dir, "/inconsistency_err_run", run ,".txt"), sep="", collapse="")

# quit if there are too many excel or timing files
if (! file.exists(current_eye_file)) {
	err_str1 <- paste( c("No eye ##trial.txt file for subject ", subjectID,  " year ", year, " run", run), sep="", collapse="")
	stop(err_str1)
}
if (length(edited_timing_file) < 1) {
	err_str1 <- paste( c("No timing file for subject ", subjectID,  " year ", year), sep="", collapse="")
	stop(err_str1)
}


# quit if there are too many excel or timing files
if (length(edited_timing_file) > 1) {
	err_str1 <- paste( c("More than one timing file for subject ", subjectID,  " year ", year), sep="", collapse="")
	stop(err_str1)
}




# DON'T SPEND TIME ON THIS PROCESS IF FILES HAVE ALREADY BEEN MADE		
if ( (length(list.files(timing_dir, pattern=paste(c("_stim_times_run", run), sep="", collapse=""))) == num_evs_per_run) & 
	(overwrite != TRUE) ) {
	write("    Files have already been made", stdout())
	quit()
}



info_txt <- paste(c("Subject:", subjectID, "Year:", year, "Run:", run), sep="", collapse=" ") 
write(info_txt, stdout())



# LOAD AUTO SCORED FILE
current_saccade_data <- read.delim(current_eye_file, header=T, sep="\t")[,-8] # don't load Description of why trial was dropped


# LOAD TIMING FILE
current_timing <- read.table(edited_timing_file, sep="\t", header=T)
current_timing$dropped <- 0 # start off assuming all trials are kept
current_timing$correct <- 1 # start off assuming all trials are correct

#### STOPPED HERE - CONTINUE LATER
correct_trials <- current_saccade_data[which(current_saccade_data$Count == 1),]$trial # latency limits are applied during automated rating

# DETERMINE AND MARK DROPPED TRIALS (previously implimented in the perl analog of the k loop)
dropped_trials <- current_saccade_data[which(current_saccade_data$Count == -1),]$trial


# DETERMINE AND MARK INCORRECT TRIALS (previously implimented in the perl cycling through trials)
incorrect_trials <- current_saccade_data[which(current_saccade_data$Count %in% c(0,2)),]$trial


# Only mark trial prep & saccade events as dropped, not cues. This was changed from previous method
current_timing$dropped[is.element(current_timing$trial, dropped_trials) & 
	((current_timing$stim == "sac") | (current_timing$stim == "prep")&
	(current_timing$catch == 0))] <- 1
# Mark dropped trials as incorrect as well - dropped trials will not be added to count of incorrect trials
current_timing$correct[is.element(current_timing$trial, dropped_trials) & 
	((current_timing$stim == "sac") | (current_timing$stim == "prep")&
	(current_timing$catch == 0))] <- 0
				
# Only mark trial prep & saccade events as incorrect, not cues. This was changed from previous method
current_timing$correct[is.element(current_timing$trial, incorrect_trials) & 
	((current_timing$stim == "sac") | (current_timing$stim == "prep")&
	(current_timing$catch == 0))] <- 0

#



# CHECK FOR CONSISTENCY IN TRIAL TYPE BETWEEN EXCEL FILE AND EPRIME OUTPUT FILE

# CREATE ONE LINE PER TRIAL INDICATING ACCURACY, STIM TYPE, DROP STATUS, TR, AND TIME
saccade_list <- current_timing[current_timing$stim == "sac",]

incorrect_rew <- saccade_list$trial[(saccade_list$cond == "reward") & (saccade_list$correct == 0) & saccade_list$dropped == 0]
correct_rew <- saccade_list$trial[(saccade_list$cond == "reward") & (saccade_list$correct == 1) & saccade_list$dropped == 0]
incorrect_neut <- saccade_list$trial[(saccade_list$cond == "neutral") & (saccade_list$correct == 0) & saccade_list$dropped == 0]
correct_neut <- saccade_list$trial[(saccade_list$cond == "neutral") & (saccade_list$correct == 1) & saccade_list$dropped == 0]




# WRITE/UPDATE ACCURACY FILE


if (file.exists(accuracy_output_file_name)) {
	accuracy_data <- as.data.frame(read.table(accuracy_output_file_name, header=T))
	accuracy_data <- accuracy_data[(accuracy_data$run != run | accuracy_data$year != year),]
	accuracy_data <- rbind(accuracy_data, c(as.numeric(as.character(subjectID)), year, run, length(dropped_trials),length(incorrect_trials),
		length(correct_trials),length(incorrect_rew), length(correct_rew), length(incorrect_neut),length(correct_neut),
		length(unique(saccade_list$trial)), round( (length(correct_trials) / (length(correct_trials) + length(incorrect_trials)) ), digits=3)
		))
	accuracy_data <- accuracy_data[order(accuracy_data$year, accuracy_data$run),]
	write.table(accuracy_data, 
	accuracy_output_file_name, append=F, row.names=F, col.names=T, quote=F)
} else {
	# WRITE ACCURACY OUTPUT
	write.table(data.frame(subjectID=as.numeric(as.character(subjectID)),
		year=year,
		run=run,
		dropped=length(dropped_trials), 
		incorrect=length(incorrect_trials), 
		correct=length(correct_trials), 
		rew_incorrect=length(incorrect_rew),
		rew_correct=length(correct_rew),
		neut_incorrect=length(incorrect_neut),
		neut_correct=length(correct_neut),
		total_trials=length(unique(saccade_list$trial)),
		total_accuracy=round( (length(correct_trials) / (length(correct_trials) + length(incorrect_trials)) ), digits=3)),
		accuracy_output_file_name, append=F, row.names=F, col.names=T, quote=F)
}


# MAKE A DATA FRAME OF LATENCY DATA
# DON'T INCLUDE DROPPED TRIALS
saccade_list_trial_cond_stim_lat <- current_saccade_data[(current_saccade_data$Count > -1), c("trial", "lat", "fstCorrect", "ErrCorr","AS","Count")]
names(saccade_list_trial_cond_stim_lat) <- c("Trial", "Latency", "correct", "errCorrect","condition","SaccadeCount")
saccade_list_trial_cond_stim_lat$subjectID <- as.numeric(as.character(subjectID))
saccade_list_trial_cond_stim_lat$year <- year
saccade_list_trial_cond_stim_lat$run <- run
# REORDER
saccade_list_trial_cond_stim_lat <- 
	saccade_list_trial_cond_stim_lat[,c("subjectID","year","run","Trial","condition","correct","errCorrect","Latency","SaccadeCount")]


# WRITE LATENCY OUTPUT
if (file.exists(latency_output_file_name)) {
	latency_data <- as.data.frame(read.table(latency_output_file_name, header=T))
	latency_data <- latency_data[(latency_data$run!=run | latency_data$year!=year),]
	latency_data <- rbind(latency_data, saccade_list_trial_cond_stim_lat)
	latency_data <- latency_data[order(latency_data$year, latency_data$run),]
	write.table(latency_data, 
		latency_output_file_name, append=F, row.names=F, col.names=T, quote=F)
} else {
	# WRITE LATENCY OUTPUT
	write.table(saccade_list_trial_cond_stim_lat,
		latency_output_file_name, append=F, row.names=F, col.names=T, quote=F)
}


# BEGIN WRITING FSL FORMAT 3-COLUMN EV FILES			



# reward cue
write.table(data.frame(
	time=current_timing$time[(current_timing$cond == "reward") & (current_timing$stim == "cue")],
	duration=1.5,
	weight=1),
	file=paste(c(timing_dir, "/", subjectID, "_y",year,"_stim_times_run", run, ".01_rew_cue.txt"), sep="", collapse=""),
	append=F, row.names=F, col.names=F, quote=F)

# reward prep
write.table(data.frame(
	time=current_timing$time[(current_timing$cond == "reward") & (current_timing$stim == "prep") & (current_timing$correct == 1)],
	duration=1.5,
	weight=1),
	file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".02_rew_prep.txt"), sep="", collapse=""),
	append=F, row.names=F, col.names=F, quote=F)


# reward sacc
write.table(data.frame(
	time=current_timing$time[(current_timing$cond == "reward") & (current_timing$stim == "sac") & (current_timing$correct == 1)],
	duration=1.5,
	weight=1),
	file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".03_rew_sac.txt"), sep="", collapse=""),
	append=F, row.names=F, col.names=F, quote=F)


# neutral cue
write.table(data.frame(
	time=current_timing$time[(current_timing$cond == "neutral") & (current_timing$stim == "cue")],
	duration=1.5,
	weight=1),
	file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".04_neu_cue.txt"), sep="", collapse=""),
	append=F, row.names=F, col.names=F, quote=F)

# neutral prep
write.table(data.frame(
	time=current_timing$time[(current_timing$cond == "neutral") & (current_timing$stim == "prep") & (current_timing$correct == 1)],
	duration=1.5,
	weight=1),
	file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".05_neu_prep.txt"), sep="", collapse=""),
	append=F, row.names=F, col.names=F, quote=F)

# neutral sacc
if ( length(current_timing$time[(current_timing$cond == "neutral") & (current_timing$stim == "sac") & (current_timing$correct == 1)] > 0 )) {
	write.table(data.frame(
		time=current_timing$time[(current_timing$cond == "neutral") & (current_timing$stim == "sac") & (current_timing$correct == 1)],
		duration=1.5,
		weight=1),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".06_neu_sac.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)
} else {
	write.table(data.frame(
		time=0,
		duration=0,
		weight=0),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".06_neu_sac.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)
}	




# reward error
reward_error_times <- current_timing$time[(current_timing$cond == "reward") & (current_timing$stim == "prep") & 
	(current_timing$dropped == 0) & (current_timing$correct == 0)]
if (length(reward_error_times) > 0) {
	write.table(data.frame(
		time=reward_error_times,
		duration=3,
		weight=1),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".7_rew_err.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)	
} else {
	write.table(data.frame(
		time=0,
		duration=0,
		weight=0),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".7_rew_err.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)					
}


# neutral error
neutral_error_times <- current_timing$time[(current_timing$cond == "neutral") & (current_timing$stim == "prep") & 
	(current_timing$dropped == 0) & (current_timing$correct == 0)]
if (length(neutral_error_times) > 0) {
	write.table(data.frame(
		time= neutral_error_times,
		duration=3,
		weight=1),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".8_neu_err.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)	
} else {
	write.table(data.frame(
		time=0,
		duration=0,
		weight=0),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".8_neu_err.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)					
}


# combined errors
combined_error_times <- current_timing$time[(current_timing$stim == "prep") & (current_timing$dropped == 0) & (current_timing$correct == 0)]
if (length(combined_error_times) > 0) { 
	write.table(data.frame(
		time=combined_error_times,
		duration=3,
		weight=1),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".7_combined_err.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)	
} else {
	write.table(data.frame(
		time=0,
		duration=0,
		weight=0),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".7_combined_err.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)					
}


# dropped trials
dropped_times <- current_timing$time[(current_timing$stim == "prep") & (current_timing$dropped == 1)]
if (length(dropped_times) > 0) { 
	write.table(data.frame(
		time=dropped_times,
		duration=3,
		weight=1),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".9_dropped.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)	
} else {
	write.table(data.frame(
		time=0,
		duration=0,
		weight=0),
		file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_run", run, ".9_dropped.txt"), sep="", collapse=""),
		append=F, row.names=F, col.names=F, quote=F)					
}


write("    FSL timing files made", stdout())

write.table(current_timing, 
	file=paste(c(timing_dir, "/", subjectID, "_y", year, "_stim_times_master_run", run, ".txt"), sep="", collapse=""),
	append=F, row.names=F, col.names=T, quote=F)

