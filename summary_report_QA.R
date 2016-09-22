library(plyr)
library(stringr)
library(ggplot2)

df <- read.csv("/Users/ncanda/Documents/Research/NCANDA/summary_excluded_visits_grouped.txt", sep='\t', header=T)

df$visit_status_Count <- as.numeric(as.character(df$visit_status_Count))
df$year_mon <- paste(df$scan_year, str_pad(df$scan_month, 2, pad = "0"), sep="_")

sorted_df <- ddply(df, .(year_mon, visit_status), summarize, count=sum(visit_status_Count))

sorted_df$year_mon <- as.factor(sorted_df$year_mon)


pdf(file="/Users/ncanda/Documents/Research/NCANDA/summary_excluded_visits_grouped.pdf",
	height=4, width=8)
ggplot(sorted_df, aes(x=year_mon, y=count, group=visit_status)) +
	geom_line(aes(color=visit_status)) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Good & Excluded Visits by Month")
dev.off()

new_sorted <- cast(sorted_df,  year_mon ~ visit_status)
new_sorted[is.na(new_sorted)] <- 0
new_sorted$pcnt_excluded <- new_sorted$exclude_visit / (new_sorted$exclude_visit + new_sorted$good)
new_sorted$year_mon <- as.factor(new_sorted$year_mon)


plot(1:length(new_sorted$year_mon), new_sorted$pcnt_excluded, type='l')


