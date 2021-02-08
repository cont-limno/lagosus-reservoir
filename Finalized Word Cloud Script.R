#Patrick Hanly, Marcella Domka, Kath Webster collaboration
#RSVR and NL Word Clouds for Primary Names
#Last Updated: February 8th, 2021 by Marcella Domka

#read in data
wc_data <- read.csv("lagos data.csv")

#inspect the head of the data
head(wc_data)

#install the necessary packages (there are quite a few!)

install.packages("wordcloud")
install.packages("ggrepel")
install.packages("MASS")
install.packages("scale")
install.packages("psych")
install.packages("rgeos")
install.packages("maptools")
install.packages("sf")
install.packages("rgdal")
install.packages("leaflet")
install.packages("readxl")
install.packages("ggwordcloud")
install.packages("webshot")
install.packages("htmlwidgets")
install.packages("repr")
install.packages("wordcloud2")
install.packages("ggforce")
install.packages("tidyverse")
install.packages("magrittr")
install.packages("dplyr")

#Call packages using library argument

library(wordcloud)
library(ggrepel)
library(MASS)
library(scales)
library(psych)
library(rgeos)
library(maptools)
library(sf)
library(rgdal)
library(leaflet)
library(readxl)
library(webshot)
library(htmlwidgets)
library(ggwordcloud)
library(repr)
library(wordcloud2)
library(ggforce)
library(tidyverse)
library(magrittr)
library(dplyr)

options(scipen=999)

#assign csv to name wc_data (Word Cloud data)

wc_data <- read.csv("lagos data.csv") %>%
  rename(name = lake_namelagos, state=lake_centroidstate)

#Create df with JUST named
lakes <- wc_data %>% 
  filter(!is.na(name)) %>%
  filter(!name == "noname") %>%
  filter(!name == "NULL")

#Helpful function (needed for script below)
'%!in%' <- Negate('%in%')

#Create operator that negates %in%

#Want to keep spring as leftname if is followed by other wbtype
spring_nm <- c("Spring Lake", "Spring Lakes", "Spring Tank", "Spring Reservoir", "Spring Pond")

tx_str <- c("soil conservation service site")  

#549 lakes in TX start with Soil Conservation Service Site

#Use this for lake names that don't start with Soil Conservation....
tx_sub <- lakes %>% 
  #filter(str_detect(name, "Soil Conservation Service Site")==T)
  filter(state=="TX") %>% 
  mutate(state = "TX_sub") %>% 
  filter(str_detect(name, "Soil Conservation Service Site")==F)


#https://stringr.tidyverse.org/reference/modifiers.html
#Check length of words leftname and leftname_cap
#Rewrote tokens to extract leftname_cap first then convert to leftname
#Otherwise extracted wb words in middle of words incorrectly (e.g. black-> bk)

#All Names From Nicole plus extras
#leftname_cap has words with capitals for ease in selection
#Note -- tests in order so need longer words first, e.g., lakes before lake
#Removal of descriptive adjectives upon recommendation from Kath Webster (i.e. flowage, river, etc., all stopwords can be seend below in the code)

stop_words <- c('lakes', 'lake', 'pond', 'ponds', 'reservoir', 'reservoirs ',
                'creek ', 'slough ','tank', 'tanks', 'spring', 'springs', 
                'impoundment', 'impoundments', 'millpond', 'lac', 'flowage', 'river')
query <- paste(stop_words, collapse = '|')

stop_words_cap <- c('Lakes', 'Lake',  'Ponds', 'Pond',  'Reservoirs', 'Reservoir',
                    'Creek',  'Slough','Impoundments', 'Impoundment', 
                    'Tanks', 'Tank',  'Springs', 'Spring',  'Lac', 'Millpond', 'flowage', 'river')
query_cap <- paste(stop_words_cap, collapse = '|')

stop_words_cap_in <- c(' Lakes ', ' Lake ', ' Ponds ', ' Pond ', ' Reservoir ', ' Reservoirs ',
                       ' Creek ',  ' Slough ',' Impoundments ', ' Impoundment ', 
                       ' Tank', ' Tanks ', ' Springs ', ' Spring ',  ' Lac ', ' Millpond ', 'flowage', 'river')
query_cap_in <- paste(stop_words_cap_in, collapse = '|')

#These are exclusions from deleting Spring
spring <- c('Spring Lake', 'Spring Pond', 'Spring Tank', 'Spring Lakes', 'Spring Reservoir')
query_spring  <- paste(spring, collapse = '|')

#This gets rid of lake, pond, etc but maintains all spring lake(s), pond tank, etc
#See old version of tokens at bottom of this file
#This one prevents removal of interior strings from words by using capitalized words

#Revision of tokens on 23 JN 19
library(dplyr)
library(magrittr)
tokens <- lakes %>%  
  #This first part looks at first and last words to see if lake, pond, etc is there.  
  #The final wb_type prioritizes a last over a first occurrence of a wb_type
  mutate(word_first = word(name, 1)) %>% 
  mutate(word_last = word(name, -1)) %>% 
  mutate(last_wb = ifelse(word_last %in% stop_words_cap|word_last=="Bog", "Y", "N")) %>%
  mutate(first_wb = ifelse(word_first %in% stop_words_cap, "Y", "N")) %>%
  mutate(wb_type_all= ifelse(last_wb=="Y", word_last,    #Chooses last wb in priority over first wb
                             ifelse(first_wb=="Y", word_first, ""))) %>% 
  mutate(wb_type = ifelse(wb_type_all %in% c("Lake", "Lakes"), "Lake(s)",
                          ifelse(wb_type_all %in% c("Pond", "Ponds"), "Pond(s)",
                                 ifelse(wb_type_all %in% c("Tank", "Tanks"), "Tank(s)",
                                        ifelse(wb_type_all %in% c("Reservoir", "Reservoirs"), "Reservoir(s)",
                                               ifelse(wb_type_all %in% c("Spring", "Springs"), "Spring(s)", wb_type_all)))))) %>%
  
  #The following identifies names with internal Lake, Pond, etc and then merges them into wb_type for completeness
  mutate(wb_int = ifelse(wb_type=="" & str_detect(str_trim(name), query_cap_in), "Y", "N")) %>%
  mutate(wb_type_in = ifelse(wb_int=="Y" & str_detect(str_trim(name)," Lake "), "Lake(s)",
                             ifelse(wb_int=="Y" & str_detect(str_trim(name)," Lakes "), "Lake(s)",
                                    ifelse(wb_int=="Y" & str_detect(str_trim(name), " Pond "), "Pond(s)",
                                           ifelse(wb_int=="Y" & str_detect(str_trim(name), " Reservoir"), "Reservoir(s)",
                                                  ifelse(wb_int=="Y" & str_detect(str_trim(name)," Spring"), "Spring(s)",
                                                         ifelse(wb_int=="Y" & str_detect(str_trim(name)," Tank"), "Tank(s)",
                                                                ifelse(wb_int=="Y" & str_detect(str_trim(name)," Impoundment "), "Impoundment",
                                                                       ifelse(wb_int=="Y" & str_detect(str_trim(name)," Impoundments "), "Impoundment",
                                                                              ifelse(wb_int=="Y" & str_detect(str_trim(name)," Slough "), "Slough",
                                                                                     ifelse(wb_int=="Y" & str_detect(str_trim(name)," Lac "), "Lac",
                                                                                            ifelse(wb_int=="Y" & str_detect(str_trim(name)," Millpond "), "Millpond",
                                                                                                   "")))))))))))) %>% 
  mutate(wb_type_in = ifelse(wb_type_in=="" & wb_int=="Y" & str_detect(str_trim(name)," Creek"), "Creek", wb_type_in)) %>% 
  mutate(wb_type= ifelse(wb_int=="Y", wb_type_in, wb_type)) %>% 
  #Create short names after removing the stopwords, keeping Spring as leftname (eg shortenend) for lake, pond, etc.
  mutate(leftname_cap = ifelse(name %!in% spring, str_trim(str_replace_all(name, query_cap, '')), "Spring")) %>%
  mutate(leftname_cap = ifelse(word_last=="Bog", str_trim(str_replace_all(name, " Bog", '')), leftname_cap)) %>%
  mutate(leftname = tolower(leftname_cap)) 

#These are lower case for wordmaps


#Run this to create a file for easy searching for lakeline ms stats on name length, etc.
lake_search <- tokens %>% 
  select(state, name, lake_rsvr_class, leftname, leftname_cap, word_first,                    
         word_last, wb_type_all, wb_type, wb_int, wb_type_in) %>% 
  mutate(name_nohyp = str_replace_all(name, "-", " ")) %>% 
  mutate(wordmax= map_chr(strsplit(name_nohyp, " "), ~ .[which.max(nchar(.))])) %>%   #Longest word in name
  mutate(namemax_n = str_length(name)) %>%                                           #63 characters/spaces
  mutate(wordmax_n = str_length(wordmax)) %>%                                         #18 characters
  mutate(word_n = str_count(name_nohyp, pattern = " ")+1)                           

#This looks at lakes that have no leftname as are combos of query terms lake, tank, etc etc
noleftname <- tokens %>%
  filter((str_squish(leftname)== "")) %>% 
  count(name, sort=TRUE)

#unique lake names after lopping off end...
numnames <- tokens %>% 
  count(leftname, sort=TRUE) %>%
  ungroup() %>%
  filter((str_squish(leftname)!= "")) 

#unique lake names including lake, spring, reservoir, etc.
numnames_all <- lakes %>%   
  count(name, sort=TRUE) %>%
  ungroup() %>%
  filter((str_squish(name)!= "")) %>% 
  summarise(n_obs = n())

#How many lakes are called noname = 589; most oknoname with a number following
noname <- tokens %>% 
  filter(str_detect(leftname, "noname")==TRUE) %>% 
  group_by(leftname) %>%
  count(leftname, sort=TRUE) 
noname_tot <- noname %>% 
  ungroup() %>% 
  summarise(n_noname=sum(n))

#How many lakes include soil conservation service n=559, 144 unique names
scs <- tokens %>%
  filter(str_detect(leftname, "soil conservation service")==TRUE) %>% 
  group_by(state, leftname) %>%
  count(leftname, sort=TRUE)
scs_tot <- scs %>% 
  ungroup() %>% 
  summarise(n_scs =sum(n))

#Number of Mud Pond and lakes
#WB named Mud = 894; 676 Lake(s), 210 Pond(s), 3 Reservoirs, 3 Sloughs, 2 Tanks
mud <- tokens %>% 
  filter(leftname=="mud") %>% 
  group_by(leftname) %>% 
  #group_by(wb_type) %>% 
  count(wb_type, sort=TRUE)

mud_total <- tokens %>% 
  filter(leftname=="mud") %>% 
  count(leftname)

##########
#List of top 250 leftnames for NL-- save this
names_250_NL <- tokens %>%  
  filter((str_squish(leftname)!= "")) %>% 
  filter(lake_rsvr_class == "NL") %>% 
  group_by(leftname) %>%
  count(leftname, sort=TRUE) %>% 
  ungroup() %>% 
  top_n(25)

write_csv(names_250_NL, "names_250_NL.csv")

#List of top 250 leftnames for RSVR-- save this
names_250_RSVR <- tokens %>%  
  filter((str_squish(leftname)!= "")) %>% 
  filter(lake_rsvr_class == "RSVR") %>% 
  group_by(leftname) %>%
  count(leftname, sort=TRUE) %>% 
  ungroup() %>% 
  top_n(25)

write_csv(names_250_RSVR, "names_250_RSVR.csv")

#####################################
#Figure 4 wordcloud

#Create a wordcloud for all lakes, top 100 names except for soil conservation service
#Note that wordcloud2 needs a file with cols word and freq to make cloud
#This deletes all the texas lakes with soil conservation service in the name

wc_NL_100 <- tokens %>%
  filter(lake_rsvr_class == "NL") %>% 
  filter(str_detect(leftname, "soil conservation service site")==FALSE) %>% 
  filter((str_squish(leftname)!= "")) %>% 
  group_by(leftname) %>%
  count(leftname, sort=TRUE) %>%
  arrange(desc(n)) %>% 
  #top_n(25) %>% 
  #summarise(n=sum(n)) #%>% 
  ungroup() %>% 
  slice(1:25) %>% 
  ungroup() %>% 
  mutate(freq=n/sum(n)) %>% 
  mutate(word=leftname) 

# Make the graph (Natural Lakes)

NL_graph <- wordcloud2(wc_NL_100, size=1, shape="circle", shuffle=FALSE, color="random-dark")
NL_graph

wc_RSVR_100 <- tokens %>%
  filter(lake_rsvr_class == "RSVR") %>%
  filter(str_detect(leftname, "soil conservation service site")==FALSE) %>%
  filter((str_squish(leftname)!= "")) %>%
  group_by(leftname) %>%
  count(leftname, sort=TRUE) %>%
  arrange(desc(n)) %>%
  #top_n(250) %>%
  #summarise(n=sum(n)) #%>%
  ungroup() %>%
  slice(1:26) %>%
  ungroup() %>%
  mutate(freq=n/sum(n)) %>%
  mutate(word=leftname)

wc_RSVR_100 <- wc_RSVR_100[wc_RSVR_100$word!="big", ] 

# Make the graph (Reservoirs)

RSVR_graph <- wordcloud2(wc_RSVR_100, size=1, shape="circle", shuffle=FALSE, color="random-dark")
RSVR_graph


#number of words can be changed with the "slice" term
#big shows up in top 25 for RSVR cloud, do we want to code it as a stopword?

#NOTE: this isn't relevant as word cloud does not support exporting as TIFF file!

tiff("NL_graph.tiff", width = 4, height = 4, units = "in", res = 600)

wc_NL_100 <- tokens %>%
  filter(lake_rsvr_class == "NL") %>% 
  filter(str_detect(leftname, "soil conservation service site")==FALSE) %>% 
  filter((str_squish(leftname)!= "")) %>% 
  group_by(leftname) %>%
  count(leftname, sort=TRUE) %>%
  arrange(desc(n)) %>% 
  #top_n(25) %>% 
  #summarise(n=sum(n)) #%>% 
  ungroup() %>% 
  slice(1:25) %>% 
  ungroup() %>% 
  mutate(freq=n/sum(n)) %>% 
  mutate(word=leftname)

NL_graph <- wordcloud2(wc_NL_100, size=1, shape="circle", shuffle=FALSE, color="random-dark")
NL_graph

dev.off()

#NOTE: this isn't relevant as word cloud does not support exporting as TIFF file!

tiff("RSVR_graph.tiff", width = 4, height = 4, units = "in", res = 600)

wc_RSVR_100 <- tokens %>%
  filter(lake_rsvr_class == "RSVR") %>%
  filter(str_detect(leftname, "soil conservation service site")==FALSE) %>%
  filter((str_squish(leftname)!= "")) %>%
  group_by(leftname) %>%
  count(leftname, sort=TRUE) %>%
  arrange(desc(n)) %>%
  #top_n(250) %>%
  #summarise(n=sum(n)) #%>%
  ungroup() %>%
  slice(1:26) %>%
  ungroup() %>%
  mutate(freq=n/sum(n)) %>%
  mutate(word=leftname)

wc_RSVR_100 <- wc_RSVR_100[wc_RSVR_100$word!="big", ]

RSVR_graph <- wordcloud2(wc_RSVR_100, size=1, shape="circle", shuffle=FALSE, color="random-dark")
RSVR_graph

dev.off()



