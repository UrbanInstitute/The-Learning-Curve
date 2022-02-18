## Daniel J. Mallinson and Darrell Lovell
## Urban Institute Blog Analysis
## 2021-11-15

#####################################################
################ Data Preparation ###################
#####################################################

## Access Urban Institute API
# https://github.com/UrbanInstitute/education-data-package-r 
# https://educationdata.urban.org/documentation/#how_to_use

## Uncomment if you need to install dependent packages
#install.packages('devtools')
#devtools::install_github('UrbanInstitute/education-data-package-r') #update necessary packages (enter 1 when requested)
#install.packages(c("reshape2", "data.table", "psych", "zoo", "multicon", "tidyverse"))

library(educationdata)
library(reshape2)
library(data.table)
library(psych)
library(zoo)
library(multicon)
library(tidyverse)

#Clear R Workspace
rm(list = ls())

## Working directory for RStudio users
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

## Tuition
ys = 2004:2019

tuition = data.table::fread("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_ay_tuition_fees.csv")%>%
  filter(
    level_of_study==1,
    tuition_type==3,
    year%in%ys)%>%
  select(unitid, year, tuition_type, tuition_fees_ft)

#Directory
ys = 2004:2019

directory = data.table::fread("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_directory.csv")%>%
  filter(
    year%in%ys)%>%
  select("unitid", "year", "inst_name", 
         "address", "state_abbr", "zip","offering_highest_level",
         "region", "inst_control", "institution_level", 
         "sector", "fips", "hbcu")

#Enrollment
ys = 2004:2018

enroll = data.table::fread("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_admissions-enrollment.csv")%>%
  filter(
    year%in%ys,
    sex==99)%>%
  select("unitid", "year", "number_applied", "number_admitted", "number_enrolled_ft")

## SAT and ACT Scores
years = 2004:2018
testscores = data.table::fread("https://educationdata.urban.org/csv/ipeds/colleges_ipeds_admissions-requirements.csv")%>%
  filter(
    year%in%ys)%>%
  select("year", "unitid", "open_admissions_policy","sat_crit_read_75_pctl", "sat_math_75_pctl", "act_composite_75_pctl")

#set aside open enrollment
open <- testscores%>%
  select("year", "unitid", "open_admissions_policy")
open <- open[open$year==2018,]
testscores$open_admissions_policy <- NULL

## Merge data

data <- merge(directory, tuition, by=c("unitid", "year"), all=TRUE)
data <- merge(data, enroll, by=c("unitid", "year"), all=TRUE)
data <- merge(data, testscores, by=c("unitid", "year"), all = TRUE)

## Drop Private For-Profit Institutions
data <- data[!(data$unitid %in% data$unitid[data$inst_control==3]),]

## Interpolate and Copy for NAs

data$check_2 = rowSums(!is.na(data[,15:21]))>0

data1 = data %>%
  group_by(unitid)%>%
  mutate(check_1 = n()==16)%>%
  filter(check_1 == T,
         check_2 == T)

for(i in 1:length(unique(data$unitid))){
  usedata <- data1[which(data1$unitid==unique(data1$unitid)[i]),]
  usedata <- rbind(usedata, usedata[nrow(usedata),])
  usedata$year[nrow(usedata)] = 2020
  if(i==1){
    data1_a <- usedata
  }else{
    data1_a <- rbind(data1_a, usedata)
  }
}
data1 = data1_a%>%
  mutate(across(14:20,~na.approx(.,method="linear",rule = 2, na.rm=F)))%>%
  select(-c(check_1,check_2))
  
schools <- readr::read_csv("Data/Input_Data/schools.csv") #Read in adopters

data1$censor <- 0
data1$censor[!(data1$unitid %in% unique(schools$unitid))] <- 1

adopters <- data1[which(data1$censor==0),]

censored <- data1[data1$censor==1,]
censored <- censored[censored$year==2020,]

censored$school <- censored$permenant <- censored$temp_year <- censored$GPA <- censored$blind <- NA
censored$left_censor <- 0

adopters <- merge(adopters, schools, by=c("unitid", "year"), all = FALSE)

data2 <- rbind(adopters,censored)

#Remove schools with 0 and NA applications, admissions, tuition

data2 <- data2[which(data2$tuition_fees_ft > 0),]
data2 <- data2[which(data2$number_admitted > 0),]
data2 <- data2[which(data2$number_applied > 0),]
data2 <- data2[which(data2$number_enrolled_ft > 0),]

# Calculate selectivity

data2$selectivity <- data2$number_admitted/data2$number_applied*100

# Remove Open Enrollment Schools

data2 <- data2[!(data2$unitid %in% open$unitid[open$open_admissions_policy==1]),]

#Create indicator of COVID adoption
data2$covid <- 0
data2$covid[data2$year==2020 & data2$censor == 0] <- 1

#Create indicator of adoption anytime
data2$adopt <- 0
data2$adopt[data2$censor==0] <- 1

#Create labels for adopter categories
data2$label <- "Non-Adopter"
data2$label[data2$censor==0 & data2$covid==0] <- "Pre-COVID"
data2$label[data2$censor==0 & data2$covid==1] <- "COVID"

# Calculate tuition adjusted based on the Higher Education Price Index
#https://www.commonfund.org/higher-education-price-index

year <- c(2004:2020)
hepi.values <- c(231.7, 240.8, 253.1, 260.3, 273.2, 279.3, 281.8, 288.4, 293.2, 297.8, 
                 306.7, 312.9, 317.7, 327.4, 336.1, 346.0, 352.7)
hepi <- as.data.frame(cbind(year, hepi.values))

data2 <- merge(data2, hepi, by="year")
data2$tuition_real <- data2$tuition_fees_ft*352.7/data2$hepi.values #Calcualted in 2020 dollars

#####################################################
################# Data Analysis #####################
#####################################################

data <- data2

# Counts by category
nrow(data[which(data$label=="Pre-Covid"),])
nrow(data[which(data$label=="COVID"),])
nrow(data[which(data$label=="Non-Adopter"),])

# Generating the table on pg 1
data3 = data2 %>%
  group_by(label, adopt, inst_control)%>%
  summarise(enrollment = n())

data4 = data2 %>%
  group_by(label)%>%
  summarise(tuition = mean(tuition_real, na.rm=T))

data5_1 = data2 %>%
  group_by(label)%>%
  summarise(selectivity = mean(selectivity, na.rm=T))

library(car)

## Average Tuition

leveneTest(tuition_real ~ label, data=data)
oneway.test(tuition_real ~ label, data=data, var.equal=FALSE)

pairwise.t.test(data$tuition_real, data$label, p.adjust.method="BH", pool.sd=FALSE)

aggregate(data$tuition_real, list(data$label), FUN=mean, na.rm=TRUE, na.action=na.pass)

##Selectivity
#Admissions Rate

leveneTest(selectivity ~ label, data=data)
oneway.test(selectivity ~ label, data=data, var.equal=FALSE)

pairwise.t.test(data$selectivity, data$label, p.adjust.method="BH", pool.sd=FALSE)

aggregate(data$selectivity, list(data$label), FUN=mean, na.rm=TRUE, na.action=na.pass)

##HBCU
nrow(data[which(data$hbcu==1),]) #62
nrow(data[which(data$hbcu==1 & data$censor==0 & data$covid==0),]) #32
32/62
nrow(data[which(data$hbcu==1 & data$censor==0 & data$covid==1),]) #19
19/62
51/62
