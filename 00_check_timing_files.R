


subjectList <- "/Volumes/MacBack/WMD/scripts/scored_datafile_list.txt"
subjectList <- read.table(subjectList, header=T)


bad_timing_subjects <- data.frame(subjectID=character(), run=character())
for (i in 1:nrow(subjectList)) {

subjectID <- as.character(subjectList$subjectID[i])
run <- as.character(subjectList$run[i])

timing_dir <- paste(c("/Volumes/MacBack/WMD/data_eye/", subjectID, "/timing"), sep="", collapse="")

rewCue <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".01_rew_cue.txt"), sep="", collapse=""))	
rewPrep <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".02_rew_prep.txt"), sep="", collapse=""))	
rewSac <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".03_rew_sac.txt"), sep="", collapse=""))
neuCue <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".04_neu_cue.txt"), sep="", collapse=""))
neuPrep <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".05_neu_prep.txt"), sep="", collapse=""))
neuSac <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".06_neu_sac.txt"), sep="", collapse=""))
err <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".7_combined_err.txt"), sep="", collapse=""))
dropped <- read.table(paste(c(timing_dir, "/", subjectID, "_stim_times_run", run, ".9_dropped.txt"), sep="", collapse=""))

rewCue <- rewCue[rewCue$V2 != 0,]
rewPrep <- rewPrep[rewPrep$V2 != 0,]
rewSac <- rewSac[rewSac$V2 != 0,]
neuCue <- neuCue[neuCue$V2 != 0,]
neuPrep <- neuPrep[neuPrep$V2 != 0,]
neuSac <- neuSac[neuSac$V2 != 0,]
err <- err[err$V2 != 0,]
dropped <- dropped[dropped$V2 != 0,]


bad_timing_counts <- FALSE
if (nrow(rewCue) + nrow(neuCue) != 40) {
	bad_timing_counts <- TRUE	
}
if (nrow(rewPrep) + nrow(neuPrep) + nrow(err) + nrow(dropped)  != 34) {
	bad_timing_counts <- TRUE	
}
if (nrow(rewSac) + nrow(neuSac) + nrow(err) + nrow(dropped)  != 28) {
	bad_timing_counts <- TRUE	
}

if (bad_timing_counts == TRUE) {
	bad_timing_subjects <- rbind(bad_timing_subjects, data.frame(subjectID=subjectID, run=run))
}	
	
	
	
}

if (nrow(bad_timing_subjects) > 0) {
	cat("Subjects/Runs with bad timing\n")
	print(bad_timing_subjects)
} else {
	cat("Timing files are alright.\n")
}






