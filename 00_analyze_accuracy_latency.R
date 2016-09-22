library(reshape)
library(lme4)
library(RColorBrewer) # load the brewer palettes



subjlist <- read.table("/Users/ncanda/Documents/Research/NCANDA/scripts/scored_datafile_list.txt", header=T)

subjlist <- unique(subjlist$subjectID)

subjlist <- formatC( as.numeric(as.character(subjlist)) , width=3, format = "d", flag = "0")

cmbd_accuracy <- data.frame()
latency_df <- data.frame()
for (i in 1:length(subjlist)) {

	current_subject <- subjlist[i]
	subject_eye_string <- paste(c("/Users/ncanda/Documents/Research/NCANDA/data_eye/", current_subject, "*"), sep="", collapse="")
	subject_eye_dir <- Sys.glob(subject_eye_string)
	current_accuracy_name <- paste(c(subject_eye_dir, "/accuracy.txt"), sep="", collapse="")
	current_accuracy <- read.table(current_accuracy_name, header=T)
	
	current_latency_name <- paste(c(subject_eye_dir, "/latency.txt"), sep="", collapse="")
	current_latency <- read.table(current_latency_name, header=T)
	latency_df <- rbind(latency_df, current_latency)	
	
	
	current_accuracy$rew_acc <- round(current_accuracy$rew_correct / (current_accuracy$rew_correct + current_accuracy$rew_incorrect), 4)
	current_accuracy$neut_acc <- round(current_accuracy$neut_correct / (current_accuracy$neut_correct + current_accuracy$neut_incorrect), 4)

	cmbd_accuracy <- rbind(cmbd_accuracy, current_accuracy)
}


#########	IT IS IMPORTANT THAT WE SUM CORRECT AND INCORRECT TRIALS ACROSS RUNS OF A VISIT FIRST, SINCE AVERAGING THE % ACCURACY WILL GIVE EQUAL
#########	WEIGHT TO EACH RUN (EG A RUN WITH 100% ACCURACY FOR 5 TRIALS WILL CONTRIBUTE 1/4 TOTAL ACCURACY, WHEN OTHER RUNS MAY HAVE 13 TRIALS)
# SUM ACCURACY DATA BY SUBJECT AND VISIT
sums_good_combined_acc_data <- aggregate(cmbd_accuracy[,-c(1,2,3,14)], by=list(cmbd_accuracy$subjectID, cmbd_accuracy$year), FUN=sum)
names(sums_good_combined_acc_data)[1:2] <- c("subjectID", "year")


attach(sums_good_combined_acc_data)
	sums_good_combined_acc_data$rew_acc <- rew_correct / (rew_correct + rew_incorrect)
	sums_good_combined_acc_data$neut_acc <- neut_correct / (neut_correct + neut_incorrect)
	sums_good_combined_acc_data$pun_acc <- pun_correct / (pun_correct + pun_incorrect)
detach(sums_good_combined_acc_data)


# EXCLUDE SUBJECTS BASED ON ACCURACY
sums_good_combined_acc_data$exclude <- 0
sums_good_combined_acc_data$exclude[sums_good_combined_acc_data$rew_acc < 0.5] <- 1
sums_good_combined_acc_data$exclude[sums_good_combined_acc_data$neut_acc < 0.5] <- 1
sums_good_combined_acc_data$exclude[sums_good_combined_acc_data$pun_acc < 0.5] <- 1
sum(sums_good_combined_acc_data$exclude)
# accuracy for all subjects > 0.58 - Feb20 2013
# after fixing error in script that counted missing/dropped trials as correct
# 	must now reject 10648 V1 and 10820 V1

# EXCLUDE SUBJECTS BASED ON TOTAL NUMBER OF CORRECT TRIALS
sums_good_combined_acc_data$exclude[sums_good_combined_acc_data$rew_correct < 20] <- 1
sums_good_combined_acc_data$exclude[sums_good_combined_acc_data$neut_correct < 20] <- 1
sums_good_combined_acc_data$exclude[sums_good_combined_acc_data$pun_correct < 20] <- 1
sum(sums_good_combined_acc_data$exclude)


###############################################################################################################################################




source("/Users/ncanda/Documents/Research/NCANDA/scripts/summarySE.R")
accuracy <- summarySE(cmbd_accuracy, measurevar="rew_acc", groupvars="subjectID")[,1:3]
accuracy <- merge(accuracy, summarySE(cmbd_accuracy, measurevar="neut_acc", groupvars="subjectID")[,1:3])
accuracy$ID <- apply(accuracy, 1, function(x) { substr(x[1], 1,5) })


accuracy <- merge(accuracy, top6outcomes)

accuracy$total <- rowMeans(accuracy[,c("rew_acc", "neut_acc")])

accuracy$rew_vs_neut <- accuracy$rew_acc - accuracy$neut_acc



individual_data <- summarySE(latency_df, measurevar="Latency", groupvars=c("subjectID", "condition"))[,c(1,2,4,6)]
group_means_table <- summarySE(individual_data, measurevar="Latency", groupvars="condition")
latency_means <- cast(group_means_table, ~ condition, mean, value="Latency")
latency_se <- cast(group_means_table, ~ condition, mean, value="se")

b1 <- barplot( as.matrix(rev(latency_means[,2:3])), 
	beside=T, ylim=c(0,500),
	ylab="Latency (ms)",
	xlab="Condition",
	main="Latency X Condition")
axis(1, at=c(1.5, 3.5 ), labels=c("Reward", "Neutral"))	
error.bar(b1, as.matrix(rev(latency_means[,2:3])), as.matrix(rev(latency_se[,2:3])))
box()




