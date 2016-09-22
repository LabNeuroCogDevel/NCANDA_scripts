
args <- commandArgs(trailingOnly = TRUE)

current_subject <- formatC( as.numeric(as.character(args[1])) , width=3, format = "d", flag = "0")
current_year <- args[2]
current_run <- args[3]

if (length(args) < 2) {
stop("       Must specify subjectID, run, in that order")
}

suppressMessages(library(fmri, warn.conflicts = F, quietly=T, verbose=F))



# scored_data <- "~/Documents/Academics/Projects/NCANDA/WMD/scripts/scored_datafile_list.txt"
# scored_data <- read.table(scored_data, header=T)
# for (i in 1:nrow(scored_data)) {
	
	# current_subject <- as.character(scored_data[i,1])
	# current_run <- scored_data[i,2]

ventricle_motion <- T

	
	data_dir <- paste(c('/Users/ncanda/Documents/Research/NCANDA/data_MR/A', current_subject, "_", current_year,
		'/run', current_run, '/'), sep="", collapse="")
	timing_dir <- paste(c('/Users/ncanda/Documents/Research/NCANDA/data_eye/A', current_subject, '/timing_y', current_year, '/'), sep="", collapse="")
	
	motion_data_file <- paste(c(data_dir, 'mcplots.par'), collapse="")
	motion_data <- read.table(motion_data_file)



	
		
	dropped_trials_file <- paste(c(timing_dir, current_subject, '_y', current_year, '_stim_times_run', current_run, '.9_dropped.txt'), collapse="")
	#print(dropped_trials_file)
	if (! file.exists(dropped_trials_file)) {
		print(paste(c(dropped_trials_file, "not found")))
		#stop()
	}
	
	dropped_trials_data <- read.table(dropped_trials_file)
	if (nrow(dropped_trials_data) > 0) {
		# FSL SETTINGS: DELAY1 = 6, DELAY2 = 15, SIGMA1 = 2.449, SIGMA2 = 4, SCALE = 6 (SCALE NOT USED, TESTED CC=0.1 by trial & error)
		alpha1 <- 6*6/(2.449*2.449)
		beta1 <- 2.449^2 / 6
		alpha2 <- 16^2 / 4^2
		beta2 <- 4^2 / 16
		convolved_dropped_trials <- fmri.stimulus(scans=202, 
			duration=rep(3, times=nrow(dropped_trials_data)), 
			rt=1.5, 
			times=dropped_trials_data[,1], 
			a1=alpha1, b1=beta1, a2=alpha2, b2=beta2, cc=.1) / 3.2
		confound_data <- data.frame(motion_data, convolved_dropped_trials)
	} else {
		confound_data <- motion_data
	}

	# add ventricle data if declared and if we have it
	if (ventricle_motion) {
		ventricle_data_file <- paste(c(data_dir, 'ventrical_tc.txt'), collapse="")
		if (file.exists(ventricle_data_file)) {
			ventricle_data <- read.table(ventricle_data_file)
			confound_data <- cbind(confound_data, ventricle_data)
		} else {
			cat(paste(c(current_subject,current_year,current_run, "ventricle data requested but not found\n\n"), sep="", collapse=" "))
		}
	}

	confound_data_file <- paste(c(timing_dir, current_subject, '_y', current_year, '_confounds_run', current_run, '.txt'), sep="",collapse="")
	write.table(confound_data, file=confound_data_file, append=F, col.names=F, row.names=F, sep=" ")
	

#}


