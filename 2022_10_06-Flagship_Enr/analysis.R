###
### Leonardo Restrepo & Rachel Lamb

library(tidyverse)
library(ggplot2)
library(educationdata)
library(urbnthemes)
library(extrafont)
library(showtext)
library(scales)
library(gridExtra)
library(readxl)
font_add_google("Lato")
showtext_auto()
extrafont::loadfonts()

rm(list=ls())

cd = dirname(rstudioapi::getActiveDocumentContext()$path)
data = paste0(cd,"/data")
original_data = paste0(cd,"/original_data")
raw_data = paste0(data,"/raw_data") # raw downloads
int_data = paste0(data,"/int_data")# intermediate files
fin_data = paste0(data,"/fin_data")# final files
vis_data = paste0(data,"/vis_data")# visual files

setwd(cd)

# Creating folders where downloaded, intermediate, and final data is stored
for(x in c(data, raw_data, int_data, fin_data, vis_data)){
  if(!dir.exists(x)){
    print(paste("Creating Data Directory:", x))
    dir.create(x)
  }
}

# List of flagships
flagships = c(
  "100751", "102614", "104179",# U of Alabama, U of Alaska-Fairbanks, U of Arizona
  "106397", "110635", "126614",# U. of Arkansas, UC Berkeley, UColorado-Boulder
  "129020", "130943", "134130",# UConnecticut, UDelaware, UFlorida
  "139959", "141574", "142285",# UGeorgia, UHawaii-Manoa, UIDaho
  "145637", "151351", "153658",# UIllinois-Urban Champaign, Indiana U-Bloomington, UIowa
  "155317", "157085", "159391",# UKansas, UKentucky, Lousiana State University
  "161253", "163286", "166629",# UMaine, UMaryland, UMassaschusetts,
  "170976", "174066", "176017",# UMichigan, UMinnesota, UMississippi
  "178396", "180489", "181464",# UMissouri, UMontana, UNebraska,
  "182290", "183044", "186380",# UNevada, UNew Hampshire, Rutgers,
  "187985", "196088", "199120",# UNew Mexico, UBuffalo, UNC Chapel Hill,
  "200280", "204796", "207500",# UNorth Dakota, Ohia State, UOklahoma,
  "209551", "214777", "217484",# UOregon, Penn State, URhode Island,
  "218663", "219471", "221759",# USouth Carolina, USouth Dakota, UTennessee,
  "228778", "230764", "231174",# UTexas-Austin, UUtah, UVermont,
  "234076", "236948", "238032",# UVirginia, UWashington, West Virginia University,
  "240444", "240727") # UWisconsin-Madison, UWyoming

# list of selective schools from his data notes
selective = c("110635", "234076","134130",
              "139959", "145637","170976",
              "199120", "228778","240444",
              "163286")
# list of fast schools 
fast = c("100751","176017","106397",
         "182290","218663","219471",
         "129020","217484","238032",
         "110635")

# years we care about
years = 2000:2018

# Race labels
race_matrix = data.frame(matrix(c(
  "1","White",
  "2","Black",
  "3","Hispanic",
  "4","Asian",
  "5","American Indian",
  "6","Native Hawaiian",
  "7","Two or More Race",
  "8","Nonresident",
  "9","Unknown",
  "20","Other",
  "99","Total"
),byrow = T, ncol = 2))

colnames(race_matrix) = c("race_code", "race2")

# Loading in our full Data; faster than using API
dir = data.table::fread("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_directory.csv")%>%
  filter(year %in% years)%>%
  mutate(flagships = ifelse(unitid %in% flagships, 1, 0))

# Pulling in racial enrollment data, filtering for race breakdowns, pulling by
# year, reshaping to wide, easier to calculate/plot
for(i in years){
  #i = 2000 #always build a first example in forloop, comment out when ready
  di_x = unique(dir$unitid[dir$year==i])
  if(i == 2000){
    enr = data.table::fread(paste0("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_fall-enrollment-race_",
                                   i,
                                   ".csv"))%>%
      filter(ftpt == 99,         # Fluff that you don't want to double count
             sex == 99,
             level_of_study ==1,
             degree_seeking == 99,
             class_level == 99)%>%
      mutate(race = as.character(race),
             flagship = ifelse(unitid%in%flagships, 1, 0),
             titleIV = ifelse(unitid%in%di_x, 1, 0))
    enr = merge(enr, race_matrix,
                by.x = "race",
                by.y = "race_code",
                all.x = T)%>%
      select(-c(ftpt, sex, degree_seeking,
                class_level,race))%>%
      rename(race = race2)%>%
      group_by(unitid, year, level_of_study)%>%
      spread(key = "race", value = "enrollment_fall")
  }else{
    x = data.table::fread(paste0("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_fall-enrollment-race_",
                                 i,
                                 ".csv"))%>%
      filter(ftpt == 99,
             sex == 99,
             level_of_study ==1,
             degree_seeking == 99,
             class_level == 99)%>%
      mutate(race = as.character(race),
             flagship = ifelse(unitid%in%flagships, 1, 0),
             titleIV = ifelse(unitid%in%di_x, 1, 0))
    x = merge(x, race_matrix,
              by.x = "race",
              by.y = "race_code",
              all.x = T)%>%
      select(-c(ftpt, sex, degree_seeking,
                class_level,race))%>%
      rename(race = race2)%>%
      group_by(unitid, year, level_of_study)%>%
      spread(key = "race", value = "enrollment_fall")
    enr = bind_rows(enr, x)
  }
}

dist = data.table::fread("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_fall-res.csv")%>%
  filter(year %in% years,
         type_of_freshman != 1,
         !(state_of_residence%in%c(99,98,58,57)))%>%     # States that aren't actually state (total, total external, total US, etc) 
  mutate(enrollment_fall = ifelse(enrollment_fall<0, NA, enrollment_fall)) # cleaning for missing/encoded obs

# Collapse
dist2 = dist %>%
  group_by(unitid, year, fips)%>%
  summarise(in_state= sum(ifelse(fips == state_of_residence, enrollment_fall, 0), na.rm = T),
            total2= sum(enrollment_fall,na.rm = T))


dir_small = dir%>%
  select(unitid, year,
         inst_name, inst_system_name)

working_data = merge(dir_small, enr,
                     by = c("unitid", "year"), all = T)

# The Bible
working_data = merge(working_data, dist2,
                     by = c("unitid", "year", "fips"), all = T)%>%
  mutate(fastest = ifelse(unitid %in% fast,1,0),
         most_selective = ifelse(unitid %in% selective,1,0))
#T1
D1 = working_data %>%
  filter(flagship == 1)%>%
  group_by(year)%>%
  summarise(enr1 = sum(Total,na.rm = T),
            enr2 = sum(ifelse(most_selective==1,Total,0)),
            enr3 = sum(ifelse(fastest==1,Total,0)))
D1 = as.data.frame(t(as.matrix(D1)))
colnames(D1) = D1[1,]
D1 = D1[-c(1),]
for(i in 2001:2018){
  D1[[as.character(i)]] = 100*D1[[as.character(i)]]/D1[["2000"]]
}
D1[["2000"]] = 100
D1 = as.data.frame(t(as.matrix(D1)))
D1[["year"]] = as.numeric(row.names(D1))

urbnthemes::set_urbn_defaults()

plot1 = ggplot(D1)+
  geom_line(aes(x = year,
                y = enr1,
                colour = "All Public Flagships"))+
  geom_line(aes(x = year,
                y = enr2,
                colour = "Most Selective Flagships"))+
  geom_line(aes(x = year,
                y = enr3,
                colour = "Fastest Growing Flagships"))+
  ylab("Percent Growth since 2000")+
  xlab("Year")+
  scale_color_manual(name = "Y series",
                     values = c("All Public Flagships" = "#1696d2",
                                "Most Selective Flagships" = "black",
                                "Fastest Growing Flagships" = "#fdbf11"))+
  theme(legend.position = "bottom")

pdf(paste0(vis_data,"/table1.pdf"), width = 8, height = 6)
print(plot1)

plot1

dev.off()

#T2

#Civilian non-institutional characteristics

# Number of 20-24 year olds
# 2000 data = https://www.bls.gov/emp/tables/civilian-noninstitutional-population.htm
# 2018 data = https://www2.census.gov/programs-surveys/demo/tables/age-and-sex/2018/age-sex-composition/2018gender_table1.xls
mid_20s = 100*(21434000-18877000)/18877000

# Source: https://nces.ed.gov/programs/digest/d19/tables/dt19_219.20.asp
HS_grads = 100*(3310020-2553844)/2553844

# Fall enrollment change at TIV institutions
TIV = 100*(sum(working_data$Total[
  working_data$year == 2018&
    working_data$titleIV == 1], na.rm = T) -
    sum(working_data$Total[
      working_data$year == 2000&
        working_data$titleIV == 1], na.rm = T))/
  sum(working_data$Total[
    working_data$year == 2000&
      working_data$titleIV == 1], na.rm = T)

# Fall enrollment at degree granting institutions, 4 year institutions
# Source: https://nces.ed.gov/programs/digest/d19/tables/dt19_303.25.asp
yr_4 =  100*(13900710-9363858)/9363858


# Fall enrollment change at 50 flagships
flag = 100*(sum(working_data$Total[
  working_data$year == 2018&
    working_data$flagship == 1], na.rm = T) -
    sum(working_data$Total[
      working_data$year == 2000&
        working_data$flagship == 1], na.rm = T))/
  sum(working_data$Total[
    working_data$year == 2000&
      working_data$flagship == 1], na.rm = T)
D2 = data.frame(rbind(mid_20s, HS_grads, TIV, yr_4, flag))
D2$var = row.names(D2)
D2$Labels = c("Students 20-24", "Highschool Graduates",
              "All Title IV Eligible Schools", "All 4 Year Degree Programs",
              "All State Flagships")
colnames(D2) = c("perc", "Var", "Labels")

plot2 = ggplot(D2)+
  geom_col(aes(x = Labels, y = `perc`))+
  ylab("Percent Increase between 2000 and 2018")+
  xlab("")+
  ylim(0,60)
pdf(paste0(vis_data,"/table2.pdf"), width = 8, height = 6)
print(plot2)
dev.off()


#T3
D3 = working_data %>%
  filter(flagship == 1)%>%
  group_by(year)%>%
  summarise(ins1 = sum(in_state,na.rm = T),
            ins2 = sum(ifelse(most_selective==1,in_state,0),na.rm = T),
            ins3 = sum(ifelse(fastest==1,in_state,0),na.rm = T),
            enr1 = sum(total2,na.rm = T),
            enr2 = sum(ifelse(most_selective==1,total2,0),na.rm = T),
            enr3 = sum(ifelse(fastest==1,total2,0),na.rm = T),
            fin1 = (ins1/enr1)*100,
            fin2 = (ins2/enr2)*100,
            fin3 = (ins3/enr3)*100)%>%
  select(year,starts_with("fin"))

urbnthemes::set_urbn_defaults()

plot3 = ggplot(D3)+
  geom_line(aes(x = year,
                y = fin1,
                colour = "All Public Flagships"))+
  geom_line(aes(x = year,
                y = fin2,
                colour = "Most Selective Flagships"))+
  geom_line(aes(x = year,
                y = fin3,
                colour = "Fastest Growing Flagships"))+
  ylab("Percent instate enrollment")+
  xlab("Year")+
  ylim(0,100)+
  scale_color_manual(name = "Y series",
                     values = c("All Public Flagships" = "#1696d2",
                                "Most Selective Flagships" = "black",
                                "Fastest Growing Flagships" = "#fdbf11"))+
  theme(legend.position = "bottom")
plot3


#T4
races = c("White",
          "Black",
          "Hispanic",
          "Asian")
for(i in 1:length(races)){
#  i = 4
  D4 = working_data %>%
    filter(flagship == 1)%>%
    select(year, unitid, White, Black, Hispanic, Asian, `Two or More Race`, Unknown, Nonresident,`American Indian`, Total, most_selective,fastest,)%>%
    group_by(unitid, year)%>%
    summarise(across(contains(
      c("White", "Black", "Hispanic", "Asian",
        "Two or More Race", "Unknown", "American Indian",
        "Total", "Nonresident","most_selective", "fastest")), .fns = ~sum(., na.rm = T)))%>%
    rowwise()%>%
    mutate(Total2 = Total - (Nonresident+Unknown))%>%
    select(year, most_selective,fastest, races[i], Total2)%>%
    group_by(year)%>%
    summarise(across(starts_with(c("Total2", races[i])),
                     .fns = list(~sum(.,na.rm = T),
                                 ~sum(ifelse(most_selective==1,.,0),na.rm = T),
                                 ~sum(ifelse(fastest == 1,.,0),na.rm = T)
                     )
    ))%>%
    ungroup()
  D4[["fin1"]] = 100*D4[[paste0(races[i],"_1")]]/D4[["Total2_1"]]
  D4[["fin2"]] = 100*D4[[paste0(races[i],"_2")]]/D4[["Total2_2"]]
  D4[["fin3"]] = 100*D4[[paste0(races[i],"_3")]]/D4[["Total2_3"]]
  plotx = ggplot(D4)+
    geom_line(aes(x = year,
                  y = fin1,
                  colour = "All Public Flagships"))+
    geom_line(aes(x = year,
                  y = fin2,
                  colour = "Most Selective Flagships"))+
    geom_line(aes(x = year,
                  y = fin3,
                  colour = "Fastest Growing Flagships"))+
    ylab("Representation")+
    xlab("Year")+
    scale_color_manual(name = "Y series",
                       values = c("All Public Flagships" = "#1696d2",
                                  "Most Selective Flagships" = "black",
                                  "Fastest Growing Flagships" = "#fdbf11"))+
    theme(legend.position = "bottom")
  pdf(paste0(vis_data,"/table4_",races[i],".pdf"), width = 8, height = 6)
  print(plotx)
  dev.off()
}

# T5
# LEO-to-Rachel: Download the external data, likely excel files, and format them
# so that you can compare with the working_data dataframe


#Download 2000
download.file("https://nces.ed.gov/programs/digest/d02/tables/XLS/Tab105.xls",
              destfile = paste0(raw_data,"/nces_data.xls"), mode = "wb")

nces_data <- read_excel(paste0(raw_data,"/nces_data.xls"))
nces_data = nces_data[7:74,1:14]
nces_data[1,1] <- "State"
colnames(nces_data) = nces_data[1,]
nces_data = nces_data[-c(1),]
nces_data = nces_data[6:nrow(nces_data),]
nces_data = nces_data%>%
  select(-contains("|"))%>%
  filter(!is.na(`State`))
colnames(nces_data) = gsub("[[:punct:]]","", colnames(nces_data))
nces_data$`State` = gsub("[[:punct:]]","", nces_data$`State`)
nces_data$`State` = gsub("[0-9]","", nces_data$`State`)
nces_data <- rename(nces_data, Asian = Pacific)

#Missing data in Arizona, New Hampshire, South Carolina, Tennessee, Vermont, and Washington
#Washington and Arizona 2001-2002\
download.file("https://nces.ed.gov/programs/digest/d04/tables/xls/tabn104.xls",
              destfile = paste0(raw_data,"/nces_2001.xls"), mode = "wb")

nces_2001 <- read_excel(paste0(raw_data,"/nces_2001.xls"))
nces_2001 = nces_2001[5:74,1:14]
nces_2001[1,1] <- "State"
colnames(nces_2001) = nces_2001[1,]
nces_2001 = nces_2001[-c(1),]
nces_2001 = nces_2001[6:nrow(nces_2001),]
nces_2001 = nces_2001%>%
  select(-contains("|"))%>%
  filter(!is.na(`State`))
colnames(nces_2001) = gsub("[[:punct:]]","", colnames(nces_2001))
nces_2001$`State` = gsub("[[:punct:]]","", nces_2001$`State`)
nces_2001$`State` = gsub("[0-7]","", nces_2001$`State`)
nces_2001 <- rename(nces_2001, Indian = American)
Nces_ArizonaWash <- nces_2001[c(5,50),]

#Tennessee and Vermont 2003-2004
download.file("https://nces.ed.gov/programs/digest/d06/tables/xls/tabn102.xls",
              destfile = paste0(raw_data,"/nces_2003.xls"), mode = "wb")
nces_2003 <- read_excel(paste0(raw_data,"/nces_2003.xls"))
nces_2003 = nces_2003[1:75,1:8]
nces_2003 = nces_2003[-c(1),]
nces_2003 = nces_2003[,-c(3)]
nces_2003[1,1] <- "State"

header.true <- function(df) {
  names(df) <- as.character(unlist(df[1,]))
  df[-1,]
}

nces_2003 %>% header.true
colnames(nces_2003) = nces_2003[1,1:7]
nces_2003 = nces_2003[3:nrow(nces_2003),]
nces_2003 = nces_2003%>%
  filter(!is.na(`State`))
colnames(nces_2003) = gsub("[[:punct:]]","", colnames(nces_2003))
nces_2003$`State` = gsub("[[:punct:]]","", nces_2003$`State`)
nces_2003$`State` = gsub("[0-7]","", nces_2003$`State`)
nces_2003 = nces_2003[-c(1),]
colnames(nces_2003)[6] ="Asian"
colnames(nces_2003)[7] ="Indian"

Nces_TNVA <- nces_2003[c(43,46),]

#New Hampshire and South Carolina: 2006-2007
#https://nces.ed.gov/programs/digest/d09/tables/xls/tabn106.xls
download.file("https://nces.ed.gov/programs/digest/d09/tables/xls/tabn106.xls",
              destfile = paste0(raw_data,"/nces_2006.xls"), mode = "wb")

nces_2006 <- read_excel(paste0(raw_data,"/nces_2006.xls"))
nces_2006 = nces_2006[1:74,1:8]
nces_2006[2,1] <- "State"
colnames(nces_2006) = nces_2006[2,]
nces_2006 = nces_2006[-c(1),]
nces_2006 = nces_2006[3:nrow(nces_2006),]
nces_2006 = nces_2006[,-c(3)]
nces_2006 = nces_2006%>%
  filter(!is.na(`State`))
colnames(nces_2006) = gsub("[[:punct:]]","", colnames(nces_2006))
nces_2006$`State` = gsub("[[:punct:]]","", nces_2006$`State`)
nces_2006$`State` = gsub("[0-7]","", nces_2006$`State`)
colnames(nces_2006)[6] ="Asian"
colnames(nces_2006)[7] ="Indian"

Nces_NHSC <- nces_2006[c(31,42),]

#2000 Data
NcesAll_2000 <- rbind(nces_data, Nces_TNVA, Nces_NHSC, Nces_ArizonaWash)
NcesAll_2000 = NcesAll_2000[-c(1,4,10,31,42,44,47,49),]
NcesAll_2000 <- NcesAll_2000[order(NcesAll_2000$State),]

NcesAll_2000$State = tolower(NcesAll_2000$State)
NcesAll_2000 = NcesAll_2000%>%
  group_by(State)%>%
  mutate(across(.fns = as.numeric))

colnames(NcesAll_2000)[!(colnames(NcesAll_2000)%in%c("State"))] =
  paste0(colnames(NcesAll_2000)[
  !(colnames(NcesAll_2000)%in%c("State"))],"_nces")
NcesAll_2000$Total_2_nces = NcesAll_2000$White_nces+NcesAll_2000$Hispanic_nces+
  NcesAll_2000$Black_nces+NcesAll_2000$Asian_nces+NcesAll_2000$Indian_nces

NcesAll_2000$White_2000_HS = NcesAll_2000$White_nces/(NcesAll_2000$White_nces+NcesAll_2000$Black_nces+
                                                        NcesAll_2000$Hispanic_nces+NcesAll_2000$Asian_nces+NcesAll_2000$Indian_nces)
NcesAll_2000$Black_2000_HS = NcesAll_2000$Black_nces/(NcesAll_2000$White_nces+NcesAll_2000$Black_nces+
                                                        NcesAll_2000$Hispanic_nces+NcesAll_2000$Asian_nces+NcesAll_2000$Indian_nces)
NcesAll_2000$Hispanic_2000_HS = NcesAll_2000$Hispanic_nces/(NcesAll_2000$White_nces+NcesAll_2000$Black_nces+
                                                              NcesAll_2000$Hispanic_nces+NcesAll_2000$Asian_nces+NcesAll_2000$Indian_nces)
NcesAll_2000$Asian_2000_HS = NcesAll_2000$Asian_nces/(NcesAll_2000$White_nces+NcesAll_2000$Black_nces+
                                                        NcesAll_2000$Hispanic_nces+NcesAll_2000$Asian_nces+NcesAll_2000$Indian_nces)



#2018 Data

#Table 219.46. Public high school 4-year adjusted cohort graduation rate (ACGR
download.file("https://www2.ed.gov/about/inits/ed/edfacts/data-files/acgr-lea-sy2017-18.csv",
              destfile = paste0(raw_data,"/gc_2017.csv"), mode = "wb")

gc_2017 <- read.csv(paste0(raw_data,"/gc_2017.csv"))
gc_cohort <- aggregate(gc_2017[ ,c(6,8,10,12,14,16,18)], by = list(gc_2017$STNAM), FUN=sum, na.rm=TRUE)
gc_data <- gc_cohort %>% rename(
  State = Group.1,
  All = ALL_COHORT_1718, 
  Asian = MAS_COHORT_1718,
  Indian = MAM_COHORT_1718,
  Black = MBL_COHORT_1718,
  Hispanic = MHI_COHORT_1718, 
  Twomore = MTR_COHORT_1718, 
  White = MWH_COHORT_1718
)


gc_data$State = tolower(gc_data$State)
gc_data <- gc_data[, c(1,2,8,7,4,5,3,6)]
gc_data <- gc_data[-c(5,41),]


#Graduation Cohort Sizes by race in each state in 2017-2018
download.file("https://nces.ed.gov/programs/digest/d19/tables/xls/tabn219.46.xls",
              destfile = paste0(raw_data,"/acgr_2017.xls"), mode = "wb")

acgr_2017 <- read_excel("data/raw_data/acgr_2017.xls", 
                        col_names = FALSE)
acgr_2017 = acgr_2017[1:58,1:25]
acgr_2017 = acgr_2017[,-c(3:11)]
acgr_2017[4,3] = "All"
acgr_2017[4,1] = "State"
acgr_2017 = acgr_2017[-c(1:3),-c(13:16)]
acgr_2017 = acgr_2017[-c(2,3,4,13),-c(2,8,9,11)]
colnames(acgr_2017) = acgr_2017[1,]
acgr_2017 = acgr_2017[-c(1),]
acgr_2017 = acgr_2017%>%
  filter(!is.na(`State`))
colnames(acgr_2017) = gsub("[[:punct:]]","", colnames(acgr_2017))
acgr_2017$State = gsub("([[:punct:]])|([0-9])","",acgr_2017$State)
acgr_data <- acgr_2017 %>% rename(
  Asian = `AsianPacific Islander5`,
  Twomore = `Two or more races`
) 
colnames(acgr_data)[6] = "Asian"
colnames(acgr_data)[7] = "Indian"
acgr_data$State = tolower(acgr_data$State)
acgr_data = acgr_data%>%
  mutate(across(!contains("State"),.fns = ~gsub(">=","",.)))%>%
  mutate(across(!contains("State"),.fns = ~gsub("---",NA,.)))

## 2018 ACGR Graduates
D1 <- acgr_data

D1$All <- as.numeric(as.character(D1$All))/100
D1$White <- as.numeric(as.character(D1$White))/100
D1$Black <- as.numeric(as.character(D1$Black))/100
D1$Hispanic <- as.numeric(as.character(D1$Hispanic))/100
D1$Asian <- as.numeric(as.character(D1$Asian))/100
D1$Indian <- as.numeric(as.character(D1$Indian))/100
D1$Twomore <- as.numeric(as.character(D1$Twomore))/100

colnames(D1)[!(colnames(D1)%in%c("State"))] = paste0(colnames(D1)[
  !(colnames(D1)%in%c("State"))],"_coll")


D2<-gc_data

D2$All = as.numeric(as.character(D2$All))
D2$White = as.numeric(as.character(D2$White))
D2$Black = as.numeric(as.character(D2$Black))
D2$Hispanic = as.numeric(as.character(D2$Hispanic))
D2$Asian = as.numeric(as.character(D2$Asian))
D2$Twomore = as.numeric(as.character(D2$Twomore))
D2$Indian = as.numeric(as.character(D2$Indian))
colnames(D2)[!(colnames(D2)%in%c("State"))] = paste0(colnames(D2)[
  !(colnames(D2)%in%c("State"))],"_HS")

#Find 2018 ACGR Grad Count

nces_All_2018 <- merge(D1, D2, by.x = c("State"), by.y = c("State"), all = T)

nces_All_2018$All_2 <- nces_All_2018$All_HS*nces_All_2018$All_coll 
nces_All_2018$White_HS_2018 <- (nces_All_2018$White_HS*nces_All_2018$White_coll)/nces_All_2018$All_2
nces_All_2018$Black_HS_2018 <- (nces_All_2018$Black_HS*nces_All_2018$Black_coll)/nces_All_2018$All_2
nces_All_2018$Hispanic_HS_2018 <- (nces_All_2018$Hispanic_HS*nces_All_2018$Hispanic_coll)/nces_All_2018$All_2
nces_All_2018$Asian_HS_2018 <- (nces_All_2018$Asian_HS*nces_All_2018$Asian_coll)/nces_All_2018$All_2
nces_All_2018$Indian_HS_2018 <- (nces_All_2018$Indian_HS*nces_All_2018$Indian_coll)/nces_All_2018$All_2

##Racial makeup of flagships from Table 4
fips = maps::state.fips%>%
  select(fips, polyname, abb)%>%
  rename(State=polyname)
fips$State = gsub("\\:.*","", fips$State)
fips = unique(fips)
working_data = merge(fips, working_data, by = "fips", all = T)
working_data$State[working_data$fips == 2] = "alaska"
working_data$State[working_data$fips == 15] = "hawaii"
working_data$abb[working_data$fips == 2] = "AK"
working_data$abb[working_data$fips == 15] = "HI"

flagship2000 = working_data %>%
  filter(flagship == 1)%>%
  select(year, fips, State, abb, White, Black, Hispanic, Asian, `Two or More Race`, Unknown, `American Indian`, Nonresident, Total)%>%
  group_by(State, year, abb, fips)%>%
  summarise(across(contains(c("White", "Black", "Hispanic", "Asian", "Two or More Race", "Unknown", "American Indian", "Total", "Nonresident")), .fns = ~sum(., na.rm = T)))%>%
  rowwise()%>%
  mutate(Total_3 = Total - (Unknown+Nonresident))%>%
  filter(year == 2000)

Race2000 = flagship2000

for(i in 1:length(races)){
  Race2000[[paste0(races[i],"_2000")]] = Race2000[[paste0(races[i])]]/Race2000[["Total_3"]]
}
Race2000 = Race2000 %>%
  select(State, abb, ends_with("_2000"))

flagship2018 = working_data %>%
  filter(flagship == 1)%>%
  select(year, fips, State, abb, White, Black, Hispanic, Asian, `Two or More Race`, Unknown, Nonresident,`American Indian`, Total)%>%
  group_by(State, year, abb, fips)%>%
  summarise(across(contains(c("White", "Black", "Hispanic", "Asian", "Two or More Race", "Unknown", "American Indian", "Total", "Nonresident")), .fns = ~sum(., na.rm = T)))%>%
  rowwise()%>%
  mutate(Total_3 = Total - (Unknown+Nonresident))%>%
  filter(year == 2018) 

##2018 student cohort data
Race2018 = flagship2018

for(i in 1:length(races)){
  Race2018[[paste0(races[i],"_2018")]] = Race2018[[paste0(races[i])]]/Race2018[["Total_3"]]
}
Race2018 = Race2018 %>%
  ungroup()%>%
  select(State, ends_with("_2018"))


## Racial flagship Data and share of high school grads for 2000 and 2018

NcesAll_2000$State = trimws(NcesAll_2000$State)

x1 = NcesAll_2000 %>%
  select(State, contains("2000"))
x1$State = trimws(x1$State)
x2 = nces_All_2018 %>%
  select(State, contains("2018"))
x2$State = trimws(x2$State)
Data = merge(x1, x2, by = c("State"), all = T)
Data = merge(Data, Race2000, by = c("State"), all = T)
Data = merge(Data, Race2018, by = c("State"), all = T)
Data = Data %>%
  filter(State != "district of columbia")

for(i in 1:length(races)){
  Data[[paste0(races[i],"_dif_2000")]] = Data[[paste0(races[i],"_2000")]]-Data[[paste0(races[i],"_2000_HS")]]
  Data[[paste0(races[i],"_dif_2018")]] = Data[[paste0(races[i],"_2018")]]-Data[[paste0(races[i],"_HS_2018")]]
}

for(i in 1:length(races)){
#  i = 1
  Delta = Data %>%
    select(abb,contains(races[i]))%>%
    select(abb, ends_with(c("2000","2018")))%>%
    select(abb, contains(c("dif")))%>%
    group_by(abb)%>%
    gather(key = "Year", "Difference", contains("dif"))
  Delta$Year = gsub(paste0(races[i],"_dif_"),"", Delta$Year)
  plot_m = ggplot(Delta, aes(x = abb, y=Difference, fill = Year)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(x = "",
         y = "")+
    theme(legend.position = "bottom")
  pdf(paste0(vis_data,"/table5_",races[i],".pdf"), width = 12, height = 5)
  print(plot_m)
  dev.off()
}

