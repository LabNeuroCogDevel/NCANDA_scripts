
setwd("~/Documents/Research/NCANDA/scripts")

source("./autoeyescore/RingReward/RingReward.settings.R")
source("./autoeyescore/ScoreRun.R")

subjectID <- 005
year=1
run=2
trial=5

getSacs('~/Documents/Research/NCANDA/data_eye/010/010_y1_run1.txt', subjectID, run, 0, year, onlyontrials=trial, showplot=T, writetopdf=T)

