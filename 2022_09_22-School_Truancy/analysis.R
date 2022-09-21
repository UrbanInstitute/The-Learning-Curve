#Load the necessary packages. If you do not yet have them installed, erase the '#' at the beginning of the lines below containing the install.packages codes. If you need to install the 'tidyverse' or 'readxl' packages, also run the first line of code below that begins with the 'options' function; otherwise you may encounter an error message.
#options('install.packages.compile.from.source'='never')
#install.packages('tidyverse')
#install.packages('readxl')
#install.packages('openxlsx')
#install.packages('usmap')
library(tidyverse)
library(readxl)
library(urbnthemes)
library(urbnmapr)
library(openxlsx)
library(httr)
library(jsonlite)
library(usmap)

#SET YOUR WORKING DIRECTORY#
#In the quotes below, write the file path to the folder where you saved the downloaded datasets

rm(list = ls())

cd = dirname(rstudioapi::getActiveDocumentContext()$path)
data = paste0(cd,"/data")
original_data = paste0(cd,"/original_data")
raw_data = paste0(data,"/raw_data") # raw downloads
int_data = paste0(data,"/int_data")# intermediate files
fin_data = paste0(data,"/fin_data")# final files
vis_data = paste0(data,"/vis_data")# visual files

try({zip::unzip(zipfile = paste0(original_data,".zip"),
                exdir = cd)})


for(x in c(data, raw_data, int_data, fin_data, vis_data)){
  if(!dir.exists(x)){
    print(paste("Creating Data Directory:", x))
    dir.create(x)
  }
}

setwd(data)

#~~~~Part 0 - Downloading Data~~~~#

data_download_urls = c(
  "https://nces.ed.gov/ccd/data/zip/ccd_sea_052_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/Data/zip/ccd_lea_029_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/data/zip/ccd_lea_052_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/data/zip/ccd_lea_059_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/data/zip/ccd_lea_2_89_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/data/zip/ccd_lea_141_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/data/zip/ccd_sch_052_1819_l_1a_091019.zip",
  "https://nces.ed.gov/ccd/Data/zip/sdf19_1a.zip",
  "https://nces.ed.gov/programs/edge/data/EDGE_GEOCODE_PUBLICSCH_1819.zip",
  "https://nces.ed.gov/programs/edge/data/EDGE_ACS_CWIFT2019.zip",
  "https://www2.census.gov/programs-surveys/saipe/datasets/2019/2019-school-districts/ussd19.txt"
)

data_zips = c(
  paste0(raw_data,"/ccd_sea_052_1819_l_1a_091019.zip"),
  paste0(raw_data,"/ccd_lea_029_1819_l_1a_091019.zip"),
  paste0(raw_data,"/ccd_lea_052_1819_l_1a_091019.zip"),
  paste0(raw_data,"/ccd_lea_059_1819_l_1a_091019.zip"),
  paste0(raw_data,"/ccd_lea_2_89_1819_l_1a_091019.zip"),
  paste0(raw_data,"/ccd_lea_141_1819_l_1a_091019.zip"),
  paste0(raw_data,"/ccd_sch_052_1819_l_1a_091019.zip"),
  paste0(raw_data,"/sdf19_1a.zip"),
  paste0(raw_data,"/EDGE_GEOCODE_PUBLICSCH_1819.zip"),
  paste0(raw_data,"/EDGE_ACS_CWIFT2019.zip"),
  paste0(raw_data,"/ussd19.txt")
)

data_files = c(
  paste0(raw_data,"/ccd_sea_052_1819_l_1a_091019.csv"), # 
  paste0(raw_data,"/ccd_lea_029_1819_l_1a_091019.csv"),
  paste0(raw_data,"/ccd_lea_052_1819_l_1a_091019.csv"),
  paste0(raw_data,"/ccd_lea_059_1819_l_1a_091019.csv"),
  paste0(raw_data,"/ccd_lea_2_89_1819_l_1a_091019.csv"),
  paste0(raw_data,"/ccd_lea_141_1819_l_1a_091019.csv"),
  paste0(raw_data,"/ccd_sch_052_1819_l_1a_091019.csv"),
  paste0(raw_data,"/sdf19_1a.txt"),
  paste0(raw_data,"/EDGE_GEOCODE_PUBLICSCH_1819.xlsx"),
  paste0(raw_data,"/EDGE_ACS_CWIFT2019/EDGE_ACS_CWIFT2019_LEA1920.txt"),
  paste0(raw_data,"/ussd19.txt")
)

for(i in 1:length(data_download_urls)){
  if(!file.exists(data_files[i])){
    download.file(url = data_download_urls[i],
                  destfile = data_zips[i])
    try({zip::unzip(zipfile = data_zips[i],
               exdir = raw_data)})
  }
}


#~~~~Part 1 - Creating Variables & Dataset~~~~#


#~~Teacher:Student Ratio~~#

#Load the NCES LEA Universe Survey Staff, Directory, and Membership files, as well as the NCES F33 LEA Fiscal Data file
staff<-read.csv(paste0(raw_data, "/ccd_lea_059_1819_l_1a_091019.csv"))%>%
  mutate(LEAID2 = ifelse(nchar(LEAID)==6, paste0("0",LEAID),LEAID))%>%
  select(!c(LEAID))%>%
  rename(LEAID=LEAID2)
directory<-read.csv(paste0(raw_data,"/ccd_lea_029_1819_w_1a_091019.csv"))%>%
  mutate(LEAID2 = ifelse(nchar(LEAID)==6, paste0("0",LEAID),LEAID))%>%
  select(!c(LEAID))%>%
  rename(LEAID=LEAID2)
membership<-read.csv(paste0(raw_data,"/ccd_lea_052_1819_l_1a_091019.csv"))%>%
  mutate(LEAID2 = ifelse(nchar(LEAID)==6, paste0("0",LEAID),LEAID))%>%
  select(!c(LEAID))%>%
  rename(LEAID=LEAID2)
f33<-read.delim(paste0(raw_data,"/sdf19_1a.txt"))

#Create dataset with one row per LEA that has the K-12 teacher count. This involves filtering the Staff file to include only teachers, then subtracting out pre-k teachers so that just K-12 teachers remain
tchrs = staff %>%
  group_by(LEAID) %>%
  select(LEAID, LEA_NAME, ST, STAFF, STAFF_COUNT)%>%
  spread(STAFF, STAFF_COUNT)%>%
  replace(is.na(.),0)%>%
  mutate(teachersk12 = `Teachers`-`Pre-kindergarten Teachers`)

#Merge the teacher dataset with selected columns of key LEA info from the Directory file
directory<-directory%>%
  select(LEAID,LEA_TYPE,LEA_TYPE_TEXT,
         CHARTER_LEA,CHARTER_LEA_TEXT,
         NOGRADES,G_PK_OFFERED)
tchrsdirect<-full_join(tchrs,directory,by="LEAID")

# Subtract pre-k enrollment counts from LEA total enrollment counts
# in the Membership file so that just K-12 enrollment remains

memberforjoin = membership %>%
  select(LEAID, GRADE, RACE_ETHNICITY,
         SEX, STUDENT_COUNT, TOTAL_INDICATOR) %>%
  group_by(LEAID, RACE_ETHNICITY, SEX) %>%
  spread(GRADE, STUDENT_COUNT)%>%
  filter(TOTAL_INDICATOR %in% c("Derived - Education Unit Total minus Adult Education Count",
                                "Subtotal 4 - By Grade"))%>%
  replace(is.na(.),0)%>%
  ungroup()%>%
  select(!c(RACE_ETHNICITY, SEX, TOTAL_INDICATOR))%>%
  group_by(LEAID)%>%
  summarise(across(.fns = sum))%>%
  rename(Total = `No Category Codes`)%>%
  mutate(studentcountk12 = `Total`- `Pre-Kindergarten`)

#Merge the K-12 enrollment dataset with the teacher + directory dataset
tdm<-left_join(tchrsdirect,memberforjoin,by="LEAID")

#Merge selected columns of key LEA info from the F33 file with the main dataset
f33forjoin<-f33%>%select(LEAID,V33,AGCHRT,CENFILE)
wksht<-left_join(tdm,f33forjoin,by="LEAID")
remove(f33forjoin,tdm)

#Filter out non-states (American Samoa, Guam, Puerto Rico, Virgin Islands)
wksht<-wksht%>%filter(!(ST %in% c('AS','GU','PR','VI')))%>%drop_na(ST)

#Non-traditional LEAs are filtered out below due to data quality issues with these LEA types; thus, looking only at traditional LEAs ensures the cleanest state comparisons
#Filter out non-traditional LEAs based on type; all types >=3 are non-traditional
wksht<-wksht%>%
  filter(LEA_TYPE<3)

#Filter out non-traditional LEAs that have CENFILE=0, another indicator of non-traditional LEAs
wksht<-wksht%>%
  filter(!(CENFILE==0 & ST!='CA' & ST!='NY' & ST!='OK' & ST!='VT' & ST!='ME'))%>%
  filter(!(CENFILE==0 & ST=='NY' & grepl('FREE|SPECIAL',LEA_NAME)))

#Filter out the remaining non-traditional LEAs
wksht<-wksht%>%
  filter(!(ST=='AZ' & grepl('Accommodation|Regional',LEA_NAME)))%>%
  filter(!(ST=='CA' & grepl('County Off|County Sup|County Dep',LEA_NAME)))%>%
  filter(!(ST=='DE' & grepl('POLYTECH|Technical',LEA_NAME)))%>%
  filter(!(ST=='IL' & grepl('Coop',LEA_NAME)))%>%
  filter(!(ST=='IN' & grepl('Career',LEA_NAME)))%>%
  filter(!(ST=='MA' & grepl('Tech|Agri',LEA_NAME)))%>%
  filter(!(ST=='ME' & grepl('Unorg',LEA_NAME)))%>%
  filter(!(ST=='MO' & grepl('SPEC',LEA_NAME)))%>%
  filter(!(ST=='ND' & grepl('CENTRAL ELEM|AFB',LEA_NAME)))%>%
  filter(!(ST=='NJ' & grepl('Serv|SERV|Joint',LEA_NAME)))%>%
  filter(!(ST=='PA' & grepl('Bryn',LEA_NAME)))

#Remove LEAs with missing teacher or student data
wksht = wksht%>%
  filter(teachersk12!=0,studentcountk12!=0)

#Create dataset that has the teacher:student ratio at state level
master<-wksht%>%
  group_by(ST)%>%
  summarise(teachers=sum(teachersk12),
            students=sum(studentcountk12))%>%
  mutate(ratio=students/teachers)%>%
  select(ST,ratio)%>%
  rename(tchrstudratio=ratio)


#~~Special Education Students~~#

#Load the NCES LEA Universe Survey Children With Disabilities dataset
special<-read.csv(paste0(raw_data,"/ccd_lea_2_89_1819_l_1a_091019.csv"))%>%
  mutate(LEAID2 = ifelse(nchar(LEAID)==6, paste0("0",LEAID),LEAID))%>%
  select(!c(LEAID))%>%
  rename(LEAID=LEAID2)%>%
  select(LEAID, ST, IDEA_COUNT)


#Reduce membership to one row per LEA - total students
membership<-membership%>%
  filter(TOTAL_INDICATOR=="Derived - Education Unit Total minus Adult Education Count")

#Join the two datasets
wksht<-full_join(special,membership,by=c('LEAID','ST'))

#Remove LEAs with missing special ed or total student counts
wksht<-wksht%>%drop_na(IDEA_COUNT)%>%filter(STUDENT_COUNT!=0)

#Get percentages of special ed students by state
wksht<-wksht%>%
  group_by(ST)%>%
  summarize(totalstud=sum(STUDENT_COUNT),
            totalspecialstud=sum(IDEA_COUNT))%>%
  mutate(specialshare=totalspecialstud/totalstud)%>%
  select(ST,specialshare)

#Merge with master file
master<-left_join(master,wksht,'ST')

#~~English Language Learner Students~~#

#Load the NCES LEA Universe Survey English Learners dataset
ell <- read.csv(paste0(raw_data,"/ccd_lea_141_1819_l_1a_091019.csv"))%>%
  mutate(LEAID2 = ifelse(nchar(LEAID)==6, paste0("0",LEAID),LEAID))%>%
  select(!c(LEAID))%>%
  rename(LEAID=LEAID2)%>%
  select(LEAID, LEP_COUNT)

#Join the ELL dataset with the Membership (total students only) dataset
wksht<-full_join(ell,membership,by='LEAID')
remove(ell,membership)

#Remove LEAs with missing ELL or total student counts
wksht<-wksht%>%
  drop_na(LEP_COUNT)%>%
  filter(STUDENT_COUNT!=0)

#Get percentages of ELL students by state
wksht<-wksht%>%
  group_by(ST)%>%
  summarize(totalstud=sum(STUDENT_COUNT),
            totalellstud=sum(LEP_COUNT))%>%
  mutate(ellshare=totalellstud/totalstud)%>%
  select(ST,ellshare)

#Merge with master file
master<-left_join(master,wksht,'ST')


#~~Revenue & Expenditures per Student~~#

#Load the NCES Comparable Wage Index dataset
cwi<-read_delim(
  paste0(raw_data,
         "/EDGE_ACS_CWIFT2019/EDGE_ACS_CWIFT2019_LEA1920.txt"))

#Remove missing values from F33 dataset
f33<-f33%>%
  filter(V33!=-3,V33!=-2,V33!=-1,V33!=0,
         TCURELSC!=-2,TCURELSC!=-1,TCURELSC!=0,
         TOTALREV!=-2,TOTALREV!=-1,TOTALREV!=0)

#Merge CWI with F33
f33cwi<-left_join(f33,cwi,by="LEAID")
remove(f33,cwi)

#Remove observations with no CWI
wksht<-f33cwi%>%drop_na(LEA_CWIFTEST)

#Perform the geographic dollar adjustment to total revenue and current expenditures
wksht<-mutate(wksht,revadjust=TOTALREV/LEA_CWIFTEST,
              expadjust=TCURELSC/LEA_CWIFTEST)

#Sum the student count, total revenues, and current expenditures for each state, then divide to get the per student figure by state
wksht<-wksht%>%
  group_by(STABBR)%>%
  summarise(totalstud=sum(V33),
            totalrevadjust=sum(revadjust),
            totalexpadjust=sum(expadjust))%>%
  mutate(revperstudadjust=totalrevadjust/totalstud,
         expperstudadjust=totalexpadjust/totalstud)%>%
  rename(ST=STABBR)%>%
  select(ST,revperstudadjust,expperstudadjust)

#Merge with master file
master<-left_join(master,wksht,'ST')


#~~Revenues & Expenditures per Student in Poverty~~#

#Load the U.S. Census Bureau's Small Area Income and Poverty Estimates (SAIPE) dataset
s1 = read_file(paste0(raw_data,"/ussd19.txt"))
s2 = strsplit(s1, "\\r\\n")
states = substr(s2[[1]], 1, 2)
ids = substr(s2[[1]],4,8)
s3 = gsub("\\s{2,}", "_BREAK_", s2[[1]])
s3 = gsub("^[0-9]{2} [0-9]{5} ", "", s3)
schoolnames = gsub("\\_.*", "", s3)
s4 = gsub("^.*?_","",s3)
s5 = paste0("_", s4)
s5 = gsub("\\W", "_BREAK_", s5)
s5 = strsplit(s5, "_BREAK_")
s6 = as.data.frame(do.call(rbind, s5))

saipe = cbind(s6, states, ids)%>%
  mutate(LEAID = paste0(states,ids))%>%
  select(!c(V1,V5, V6, V7, states, ids))%>%
  rename(total_population = V2,
         schoolpop = V3,
         pov = V4)%>%
  mutate(across(contains(c("pop","pov")), as.numeric))



#Remove missing values from SAIPE
saipe<-saipe%>%filter(schoolpop!=0)

#Convert LEAID to numeric in SAIPE and merge with F33 and CWI
wksht<-left_join(f33cwi,saipe,by="LEAID")

#Remove observations with no CWI or SAIPE
wksht<-wksht%>%drop_na(pov)

#Create per student revenue and expenditure variables by dividing total revenue and current expenditure by number of students
wksht<-mutate(wksht,perstudrev=TOTALREV/V33,perstudexp=TCURELSC/V33)

#Create variables with cost-adjusted per student revenue and expenditures
wksht<-wksht%>%
  mutate(perstudrevadj=perstudrev/LEA_CWIFTEST,
         perstudexpadj=perstudexp/LEA_CWIFTEST)

#Create the weighted revenue and expenditure variables based on the number of students in poverty per district
wksht<-wksht%>%
  mutate(povrate=pov/schoolpop,
         studpov=povrate*V33,
         revpov=studpov*perstudrevadj,
         exppov=studpov*perstudexpadj)

#Calculate the average revenue and expenditures per student in poverty in each state
wksht<-wksht%>%
  group_by(STABBR)%>%
  summarise(revpovt=sum(revpov),
            exppovt=sum(exppov),
            studpovt=sum(studpov))%>%
  mutate(revpovavg=revpovt/studpovt,
         exppovavg=exppovt/studpovt)%>%
  rename(ST=STABBR)%>%
  select(ST,revpovavg,exppovavg)

#Merge with master file
master<-left_join(master,wksht,'ST')


#~~Race/Ethnicity of K-12 Students~~#

#Load the NCES State Universe Survey Membership dataset
wksht<-read_csv(paste0(raw_data,"/ccd_sea_052_1819_l_1a_091019.csv"))

#Reduce the dataset to unique counts of K-12 students only
wksht<-wksht%>%
  filter(TOTAL_INDICATOR=='Category Set A - By Race/Ethnicity; Sex; Grade'&
           GRADE!='Adult Education'&
           GRADE!='Not Specified'&
           GRADE!='Pre-Kindergarten'&
           GRADE!='Ungraded'&
           GRADE!='Grade 13')
wksht$STUDENT_COUNT[is.na(wksht$STUDENT_COUNT)] = 0

#Calculate total students for each race/ethnicity by state
wksht<-wksht%>%
  group_by(ST,RACE_ETHNICITY)%>%
  summarise(students=sum(STUDENT_COUNT))

#Calculate percentages by state for each race/ethnicity
wksht<-wksht%>%
  pivot_wider(id_cols=ST,names_from=RACE_ETHNICITY,values_from=students)%>%
  select(-`Not Specified`)
wksht$totalstudents<-rowSums(wksht[c(2,3,4,5,6,7,8)])
wksht<-wksht%>%
  mutate(nativea=`American Indian or Alaska Native`/totalstudents,
         asian=Asian/totalstudents,
         black=`Black or African American`/totalstudents,
         hispanlatin=`Hispanic/Latino`/totalstudents,
         hpi=`Native Hawaiian or Other Pacific Islander`/totalstudents,
         multi=`Two or more races`/totalstudents,
         white=White/totalstudents)%>%
  select(ST,nativea,asian,black,hispanlatin,hpi,multi,white)

#Merge with master file
master<-left_join(master,wksht,'ST')


#~~School-Aged Child Poverty~~#

#Load the U.S. Census Bureau 2019 American Community Survey S1701 - Poverty Status in the Past 12 Months dataset
acs = fromJSON("https://api.census.gov/data/2019/acs/acs1/subject?get=NAME,S1701_C02_004E,S1701_C01_004E")
colnames(acs) = acs[1,] 
wksht = as.data.frame(acs)

#Remove row 1 - extraneous labels
wksht<-wksht[-1,]

#Calculate percentage of school-aged children (ages 5-17) in poverty
wksht$pov<-as.numeric(wksht$S1701_C02_004E)/as.numeric(wksht$S1701_C01_004E)

#Add state abbreviations column
wksht$ST<-c('AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY')[match(wksht$NAME,c('Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','District of Columbia','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia','Wisconsin','Wyoming'))]

#Select columns of interest and merge into master file
wksht<-wksht%>%select(ST,pov)
master<-left_join(master,wksht,'ST')


#~~Locales~~#

#Load the NCES School Locale Codes & Elementary and Secondary School Universe Survey Membership (school totals only) datasets
locale<-read_excel(paste0(raw_data,"/EDGE_GEOCODE_PUBLICSCH_1819.xlsx"))
membership<-read_delim(paste0(raw_data,"/ccd_sch_052_1819_l_1a_091019.csv"))%>%
  filter(TOTAL_INDICATOR == "Derived - Education Unit Total minus Adult Education Count")

#Merge Locales and Membership datasets
wksht<-full_join(locale,membership,by='NCESSCH')
remove(locale,membership)

#Remove schools with missing student counts, replace NAs with 0s
wksht<-wksht%>%
  drop_na(STUDENT_COUNT)

#Calculate percentages of students cities, suburbs, towns, and rural locales
wksht<-wksht%>%
  group_by(STATE,LOCALE)%>%
  summarise(students=sum(STUDENT_COUNT))%>%
  pivot_wider(id_cols=STATE,names_from=LOCALE,values_from=students)%>%
  replace(is.na(.),0)
wksht$totalstudents<-rowSums(wksht[c(2,3,4,5,6,7,8,9,10,11,12,13)])
wksht<-wksht%>%mutate(city=`11`+`12`+`13`,suburb=`21`+`22`+`23`,town=`31`+`32`+`33`,rural=`41`+`42`+`43`)%>%mutate(cityshare=city/totalstudents,suburbshare=suburb/totalstudents,townshare=town/totalstudents,ruralshare=rural/totalstudents)%>%rename(ST=STATE)%>%select(ST,cityshare,suburbshare,townshare,ruralshare)

#Remove Washington D.C. because they are not a state and their data skews results
# we can drop them at the end

#Merge with master file
master<-left_join(master,wksht,'ST')


#~~Chronic Absenteeism Indicator in ESSA~~#

#Load the ESSA Chronic Absenteeism Indicator dataset & merge with the master file
wksht<-read_excel(paste0(original_data,"/ESSA Chronic Absenteeism Indicator.xlsx"))
master<-left_join(master,wksht,'ST')


#~~Party Control of State Government~~#

#Load the Legislative Control dataset & merge with master file
wksht<-read_excel(paste0(original_data,"/Legislative Control Wksht.xlsx"))
master<-left_join(master,wksht,'ST')


#~~Truancy Data Availability~~#

#Load the author-constructed original dataset titled Truancy Data Availability & merge with master file
wksht<-read_excel(paste0(original_data,"/Truancy Data Availability.xlsx"))
master<-left_join(master,wksht,'ST')
rm(wksht)


#~~Export the Master Dataset to Excel~~#

#Export the file with all variables used in the analyses below to Excel
write.xlsx(master,paste0(fin_data,"/Full Dataset for Analyses.xlsx"))




#~~~~Part 2 - Analyses~~~~#


#~~2.1 - Truancy Data Availability Descriptive Analyses~~#

#Summary table showing the count of most detailed level of truancy data available in states
truancydataavail<-as.data.frame(table(master$dataavail))

#Counts of states that provide demographics, student-level data, and report data publicly
demstudentpublic<-master%>%summarise(`Include Demographic Information in Dataset`=sum(demographics),`Entertain Student-Level Data Requests`=sum(studentlevel),`Publicly Report Truancy Data`=sum(public))

#Export results to Excel files
write.xlsx(truancydataavail,paste0(fin_data,"/Truancy Data Availability - Summary Counts by Data Category.xlsx"))
write.xlsx(demstudentpublic,paste0(fin_data,"/Student Level, Demographic, and Public Availability of Truancy Data - Summary Counts.xlsx"))


#~~2.2 - State Characteristics by Truancy Data Availability~~#

#Full results table of characteristics of states with and without truancy data available

statecharresults<-master%>%
  group_by(truancyavail19)%>%
  summarise(`Total revenue per student`=mean(revperstudadjust),
            `Current expenditures per student`=mean(expperstudadjust),
            `Revenue per student in poverty`=mean(revpovavg),
            `Expenditures per student in poverty`=mean(exppovavg),
            `Teacher:student ratio`=mean(tchrstudratio),
            `ESSA chronic absenteeism indicator`=mean(essachronic),
            `American Indian/Alaska Native`=mean(nativea),
            Asian=mean(asian),
            `Black/African American`=mean(black),
            `Hispanic/Latinx`=mean(hispanlatin),
            `Native Hawaiian/Pacific Islander`=mean(hpi),
            White=mean(white),
            `Two or more races`=mean(multi),
            `School-aged child poverty`=mean(pov),
            `Special education`=mean(specialshare,na.rm=TRUE),
            `English language learners`=mean(ellshare,na.rm=TRUE),
            `# States controlled by Democrats`=sum(d),
            `# States controlled by Republicans`=sum(r),
            `# States w/ divided government control`=sum(split),
            `% Students in city schools`=mean(cityshare,na.rm=TRUE),
            `% Students in rural schools`=mean(ruralshare,na.rm=TRUE),
            `% Students in suburban schools`=mean(suburbshare,na.rm=TRUE),
            `% Students in town schools`=mean(townshare,na.rm=TRUE))%>%
  t()
statecharresults<-as.data.frame(statecharresults[,c(2,1)])
statecharresults<-statecharresults[-1,]
statecharresults<-statecharresults%>%rename(`States With Truancy Data`=V1,`States With No Truancy Data`=V2)

#Export results to Excel file
write.xlsx(statecharresults,
           paste0(fin_data,"/State Characteristics Results Table.xlsx"),
           rowNames=TRUE)





#~~~~Part 3 - Create the Map~~~~#

#Load U.S. map and merge with the master file
map<-get_urbn_map(map = "states", sf = TRUE)
map<-merge(map,master,
               by.x ="state_abbv", by.y = "ST")

map$mapcode = as.character(map$mapcode)

colors = data.frame(cbind(c(as.character(1:5)),c("#1696d2","#d2d2d2",
                                                 "#000000","#fdbf11",
                                                 "#ec008b")))

map2 = merge(map, colors, by.x = "mapcode",
                 by.y = "X1")

#Create the map & save as a PDF
pdf(paste0(vis_data,"/Truancy Policy & Data Availability Map.pdf"),width=12.43,height=6.31)
ggplot(map)+
  geom_sf(aes(fill = `mapcode`))+
  scale_fill_manual(
    values = c("#1696d2","#d2d2d2",
               "#000000","#fdbf11",
               "#ec008b"),
    labels=str_wrap(
      c("Does not have a statewide truancy policy and no truancy data are available",
        "Does not have a statewide truancy policy and truancy data are available",
        "Has a statewide truancy policy, but no truancy or unexcused absence data are available",
        "Has a statewide truancy policy and unexcused absence data are available. Truancy data are not available.",
        "Has a statewide truancy policy and truancy data are available"),
      width=50))
dev.off()
