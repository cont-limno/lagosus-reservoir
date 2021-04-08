
getwd()
setwd("C:/Users/dimto/Downloads")
LAGOSUS_RSVR<-read.csv('LAGOSUS_RSVR_v1.1.csv')

library(ggplot2)

head(LAGOSUS_RSVR)

# Create new column that combines the text of both the target columns, then plot as above
LAGOSUS_RSVR$lake_rsvr_comboclassmethod <- with(LAGOSUS_RSVR, paste0(lake_rsvr_class, " ",lake_rsvr_classmethod))


ggplot(LAGOSUS_RSVR, aes(fill=lake_rsvr_comboclassmethod, y = frequency(lake_connectivity_class), x=lake_connectivity_class)) + 
  geom_bar(position="stack", stat="identity") + labs(x = "Lake Connectivity Class", y = "Frequency") + 
  theme_bw() + theme(axis.line = element_line(colour = "black"),
                     panel.grid.major = element_blank(),
                     panel.grid.minor = element_blank(),
                     panel.border = element_blank(),
                     panel.background = element_blank()) +
  scale_y_continuous(limits = c(0,60000), expand = c(0, 0)) +
  scale_fill_manual(values=c("#6695ed", "#2a3d61", "#ff4f14", "#a1320d"))
  

  