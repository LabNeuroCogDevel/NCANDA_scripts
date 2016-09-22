wmd_dir <- "~/Documents/Academics/Projects/NCANDA/WMD/"

library(foreign)


sav_file <- paste(c(wmd_dir, "docs/ID 19 BL AS 03-18-13.sav"), sep="", collapse="")
spssdata <- read.spss(sav_file)



sav_file <- paste(c(wmd_dir, "docs/WMD_15_clin_07-10-13_6mo_outcome.sav"), sep="", collapse="")
clin_outcome_data <- read.spss(sav_file)


attach(clin_outcome_data)
	
	top6outcomes <- as.data.frame(cbind(ID,round(WMD_age,2), ISEX_0, Alc_18_tot_1, Alc_18_tot_612, ALCCT_106, CANCT_106, can_18_tot_1, can_18_tot_612, DCQ1_106, DCQ2_106))

	top6outcomes$Alc_diff <- Alc_18_tot_1 - Alc_18_tot_612

detach(clin_outcome_data)



names(top6outcomes)[2] <- "Age"
outfile <- paste(c(wmd_dir, "docs/WMD_measures.txt"), sep="", collapse="")
write.table(top6outcomes, file=outfile, quote=F, sep=" ", row.names=F)



# Alc_18_tot_1
# Alc_18_tot_612

# plot.new()
# par(mfrow=c(3,2))
# for (column in 2:7) {
	# hist(top6outcomes[,column], main=colnames(top6outcomes)[column])	
# }


# cor(top6outcomes[,2:7])

# add covariates
# WMD_age
# sex
# severity of substance use


# WMD_age