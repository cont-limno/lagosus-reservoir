

library(ggplot2)


class <- c(rep("NL", 2), rep("RSVR" , 2))
named <- rep(c("Named", "Unnamed"), 2)
# c(named nl, unnamed nl, named rsvr, unnamed rsvr)
count <- c(33879, 43789, 25393, 34406)
data_named <- data.frame(class, named, count)


ggplot(data_named, aes(x=class, y=count, fill = interaction(named,class))) +
  geom_bar(stat = "identity") +
  theme_bw() + theme(axis.line = element_line(colour = "black"),
                     panel.grid.major = element_blank(),
                     panel.grid.minor = element_blank(),
                     panel.border = element_blank(),
                     panel.background = element_blank()) +
  labs(x = "Lake RSVR Class", y = "Frequency") +
  scale_y_continuous(lim = c(0, 82000), expand = c(0, 0)) +
  geom_text(
    aes(label = stat(y), group = class),
    stat = 'summary', fun = sum, vjust = -0.5, size = 5) +
  scale_fill_manual(name = NULL, values=c("#6695ed", "#2a3d61", "#ff4f14", "#a1320d"))


#Download as a tiff file

tiff("name_rsvr_nl.tiff", width = 4, height = 4, units = "in", res = 600)

ggplot(data_named, aes(x=class, y=count, fill = interaction(named,class))) +
  geom_bar(stat = "identity") +
  theme_bw() + theme(axis.line = element_line(colour = "black"),
                     panel.grid.major = element_blank(),
                     panel.grid.minor = element_blank(),
                     panel.border = element_blank(),
                     panel.background = element_blank()) +
  labs(x = "Lake RSVR Class", y = "Frequency") +
  scale_y_continuous(lim = c(0, 82000), expand = c(0, 0)) +
  geom_text(
    aes(label = stat(y), group = class),
    stat = 'summary', fun = sum, vjust = -0.5, size = 5) +
  scale_fill_manual(name = NULL, values=c("#6695ed", "#2a3d61", "#ff4f14", "#a1320d"))

dev.off()
 
