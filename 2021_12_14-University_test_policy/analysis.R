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
years <- c(2004:2019)

for(i in 1:length(years)){
  df.temp <- get_education_data(level="college-university",
                                source = "ipeds",
                                topic="academic-year-tuition",
                                filters=list(year=years[i]),
                                add_labels=TRUE)
  df.temp <- df.temp[which(df.temp$level_of_study=="Undergraduate" & df.temp$tuition_type=="In state"),]
  df.temp <- df.temp[c("unitid", "year", "tuition_type", "tuition_fees_ft")]
  if(i == 1){
    tuition <- df.temp}
  else{tuition <- rbind(tuition, df.temp)}
}

#Directory
years <- c(2004:2019)

for(i in 1:length(years)){
  df.temp <- get_education_data(level="college-university",
                                source = "ipeds",
                                topic="directory",
                                filters=list(year=years[i]),
                                add_labels=TRUE)
  df.temp <- df.temp[c("unitid", "year", "inst_name", 
                       "address", "state_abbr", "zip","offering_highest_level",
                       "region", "inst_control", "institution_level", 
                       "sector", "fips", "hbcu")]
  if(i == 1){
    directory <- df.temp}
  else{directory <- rbind(directory , df.temp)}
  print(paste(years[i], "has been added to the Directory"))
}

#Enrollment
years <- c(2004:2018)

for(i in 1:length(years)){
  df.temp <- get_education_data(level="college-university",
                                source = "ipeds",
                                topic="admissions-enrollment",
                                filters=list(year=years[i]),
                                add_labels=TRUE)
  df.temp <- df.temp[which(df.temp$sex=="Total"),]
  df.temp <- df.temp[c("unitid", "year", "number_applied", "number_admitted", "number_enrolled_ft")]
  if(i == 1){
    enroll <- df.temp}
  else{enroll <- rbind(enroll, df.temp)}
}

## SAT and ACT Scores
years <- c(2004:2018)
for(i in 1:length(years)){
  df.temp <- get_education_data(level="college-university",
                                source = "ipeds",
                                topic="admissions-requirements",
                                filters=list(year=years[i]),
                                add_labels=TRUE)
  df.temp <- df.temp[c("year", "unitid", "open_admissions_policy","sat_crit_read_75_pctl", "sat_math_75_pctl", "act_composite_75_pctl")]
  df.temp$year <- years[i]
  if(i == 1){
    testscores <- df.temp}
  else{testscores <- rbind(testscores , df.temp)}
}

#set aside open enrollment
open <- testscores[c("year", "unitid", "open_admissions_policy")]
open <- open[which(open$year==2018),]
testscores$open_admissions_policy <- NULL

## Merge data

data <- merge(directory, tuition, by=c("unitid", "year"), all.x=TRUE, all.y=TRUE)
data <- merge(data, enroll, by=c("unitid", "year"), all.x=TRUE, all.y=TRUE)
data <- merge(data, testscores, by=c("unitid", "year"), all.x=TRUE, all.y=TRUE)

## Drop Private For-Profit Institutions
forprofit <- unique(data$unitid[data$inst_control=="Private for-profit"])

data <- data[!(data$unitid %in% forprofit),]

## Interpolate and Copy for NAs

data1 <- NULL

for(i in 1:length(unique(data$unitid))){
  usedata <- data[which(data$unitid==unique(data$unitid)[i]),]
  usedata <- rbind(usedata, usedata[nrow(usedata),])
  if(sum(!is.na(usedata[,15:21]))>0 & nrow(usedata[,15:21])==17){
    usedata$year[nrow(usedata)] <- 2020
    usedata[,15:21] <- na.approx(usedata[,15:21], method="linear", rule=2, na.rm=FALSE)
    if(i==1){
      data1 <- usedata
    }else{
      data1 <- rbind(data1, usedata)
    }}else{
      data1 <- data1
    }
}

schools <- read.csv("Data/Input_Data/schools.csv") #Read in adopters

data1$censor <- 0
data1$censor[!(data1$unitid %in% unique(schools$unitid))] <- 1

adopters <- data1[which(data1$censor==0),]
censored <- data1[which(data1$censor==1),]

censored <- censored[which(censored$year==2020),]
censored$school <- censored$permenant <- censored$temp_year <- censored$GPA <- censored$blind <- NA

adopters <- merge(adopters, schools, by=c("unitid", "year"), all.x=FALSE, all.y=FALSE)%>%
  rename(school = `ï..school`)

data2 <- rbind(adopters,censored)

#Remove schools with 0 and NA applications, admissions, tuition

data2 <- data2[which(data2$tuition_fees_ft > 0),]
data2 <- data2[which(data2$number_admitted > 0),]
data2 <- data2[which(data2$number_applied > 0),]
data2 <- data2[which(data2$number_enrolled_ft > 0),]

# Calculate selectivity

data2$selectivity <- data2$number_admitted/data2$number_applied*100

# Remove Open Enrollment Schools

data2 <- data2[!(data2$unitid %in% open$unitid[open$open_admissions_policy=="Yes"]),]

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

#####################################################
################# Data Analysis #####################
#####################################################

data <- data2

# Generating the table on pg 1
data3 = data2 %>%
  group_by(label, adopt, inst_control)%>%
  summarise(enrollment = n())

data4 = data2 %>%
  group_by(label)%>%
  summarise(enrollment = mean(tuition_fees_ft, na.rm=T))

data5_1 = data2 %>%
  group_by(label)%>%
  summarise(enrollment = mean(selectivity, na.rm=T))

library(car)

## Average Tuition

leveneTest(tuition_fees_ft ~ label, data=data)
oneway.test(tuition_fees_ft ~ label, data=data, var.equal=FALSE)

pairwise.t.test(data$tuition_fees_ft, data$label, p.adjust.method="BH", pool.sd=FALSE)

aggregate(data$tuition_fees_ft, list(data$label), FUN=mean, na.rm=TRUE, na.action=na.pass)

##Selectivity
#Admissions Rate

leveneTest(selectivity ~ label, data=data)
oneway.test(selectivity ~ label, data=data, var.equal=FALSE)

pairwise.t.test(data$selectivity, data$label, p.adjust.method="BH", pool.sd=FALSE)

aggregate(data$selectivity, list(data$label), FUN=mean, na.rm=TRUE, na.action=na.pass)

##HBCU
nrow(data[which(data$hbcu=="Yes"),]) #62
nrow(data[which(data$hbcu=="Yes" & data$censor==0 & data$covid==0),]) #1
1/62
nrow(data[which(data$hbcu=="Yes" & data$censor==0 & data$covid==1),]) #19
19/62
20/62