library(educationdata)
library(data.table)
library(tidyverse)
library(urbnthemes)
library(grid)
library(gridExtra)

rm(list = ls())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

output_folder =  "Data/Output_Data"

if(!dir.exists(output_folder)){
  dir.create(file.path(getwd(),output_folder),recursive = T)
}

county_names = read_csv("Data/Review_Output/county_names.csv")
distinct_counties =levels(factor(county_names$County))

test_data = fread("https://educationdata.urban.org/csv/crdc/schools_crdc_ap_exams_2017.csv")
ap_enrl_data = fread("https://educationdata.urban.org/csv/crdc/schools_crdc_apib_enroll.csv")
lea_name_data = fread("https://educationdata.urban.org/csv/crdc/schools_crdc_school_characteristics.csv")
enrl_data = fread("https://educationdata.urban.org/csv/crdc/schools_crdc_enrollment_k12_2017.csv")
ccd_dir_data = fread("https://educationdata.urban.org/csv/ccd/schools_ccd_directory.csv")
crdc_dir_data = fread("https://educationdata.urban.org/csv/crdc/schools_crdc_school_characteristics.csv")

# This produces a list of high schools that are in 2017, solely in Florida
# schools containing "virtual", "cyber", "electronic", "internet", "online", or "distance"
# only regular schools
fl_ccd_dir_data = ccd_dir_data[ccd_dir_data$fips==12&
                                 ccd_dir_data$year==2017&
                                 !grepl(
                                   "([Vv][Ii][Rr][Tt][Uu][Aa][Ll])|
                               ([Cc][Yy][Bb][Ee][Rr])|
                               ([Ee][Ll][Ee][Cc][Tt][Rr][Oo][Nn][Ii][Cc])|
                               ([Ii][Nn][Tt][Ee][Rr][Nn][Ee][TT])|
                               ([Oo][Nn][Ll][Ii][Nn][Ee])|
                               ([Dd][Ii][Ss][Tt][Aa][Nn][Cc][Ee])",ccd_dir_data$school_name)&
                                 ccd_dir_data$virtual == 0&
                                 (ccd_dir_data$highest_grade_offered%in%c(11,12)|ccd_dir_data$lowest_grade_offered%in%c(11,12))&
                                 (ccd_dir_data$school_type%in%c(1)|is.na(ccd_dir_data$school_type)),]

conventional_high_schools = levels(factor(fl_ccd_dir_data$ncessch))

# This produces a list of schools that are in 2015, solely in Florida
# Only schools that offer either grade 11, grade 12, or both
# No alternative schools
fl_crdc_dir_data = crdc_dir_data[crdc_dir_data$fips==12&
                                   !grepl(
                                     "([Aa][Dd][Uu][Ll][Tt])|
                               ([Bb][Ee][Hh][Aa][Vv][Ii][Oo][Rr][Aa][Ll])|
                               ([Jj][Uu][Vv][Ee][Nn][Ii][Ll][Ee])|
                               ([Cc][Oo][Rr][Ee][Cc][Tt][Ii][Oo][Nn])",crdc_dir_data$school_name)&
                                   crdc_dir_data$year==2017&
                                   (crdc_dir_data$g12==1|crdc_dir_data$g11==1),]

non_special_schools = levels(factor(fl_crdc_dir_data$ncessch))

# Removing other breakdowns such as sex, disability, and lep from test taking dataset
fl_test_data = test_data[
                      test_data$sex==99&
                      test_data$disability==99&
                      test_data$lep==99,]%>%
  select(ncessch, leaid, fips, race, students_AP_exam_none)%>%
  mutate(across(.cols = c(ncessch, leaid, fips, race), .fns = as.character))

# Removing other breakdowns such as sex, disability, and lep from ap enrollment data set
fl_ap_enrl_data = ap_enrl_data[
                              ap_enrl_data$sex==99&
                              ap_enrl_data$disability==99&
                              ap_enrl_data$lep==99&
                              ap_enrl_data$year==2017,]%>%
  select(ncessch, leaid, fips, race, enrl_AP)%>%
  mutate(across(.cols = c(ncessch, leaid, fips, race), .fns = as.character))

# Adding the LEA Names from the CRDC Directory
fl_lea_data = lea_name_data[
                              lea_name_data$year==2017,]%>%
  select(school_name_crdc, ncessch, leaid, lea_name ,fips)%>%
  mutate(across(.cols = c(ncessch, leaid, fips, lea_name), .fns = as.character))

# Removing other breakdowns such as sex, disability, and lep from enrollment data set
fl_enrl_data = enrl_data[enrl_data$fips==12&
                                 enrl_data$sex==99&
                                 enrl_data$disability==99&
                                 enrl_data$lep==99,]%>%
  select(ncessch, leaid, fips, race, enrollment_crdc)%>%
  mutate(across(.cols = c(ncessch, leaid, fips, race), .fns = as.character))%>%
  rename(enrollment = enrollment_crdc)

# merging all of these tables
fl_data = merge(fl_lea_data,fl_test_data,
                by = c("ncessch", "leaid", "fips"),
                all = T)

fl_data = merge(fl_data,fl_enrl_data,
                by = c("ncessch", "leaid", "fips", "race"),
                all = T)

fl_data = merge(fl_data,fl_ap_enrl_data,
                by = c("ncessch", "leaid", "fips", "race"),
                all = T)

# Filtering for conventional high schools using the ccd list
fl_data = fl_data[((fl_data$ncessch %in% conventional_high_schools)&(fl_data$ncessch %in% non_special_schools))|fl_data$ncessch=="120108008599",]%>%
  filter(!grepl("[Vv][Ii][Rr][Tt][Uu][Aa][Ll]",lea_name))%>%
  filter(!(ncessch %in%c("120144008559","120039002137",
                         "120084000899","120114000799",
                         "120114003606")))

race_code = c(1:7, 99)
race_meaning = c("whit","bkaa","hisp", "asia",
                "aian",
                "nhpi", "2mor","totl")
race_full = c("White","Black","Hispanic", "Asian",
              "American Indian/\nAlaska Native",
              "Native Hawaiian/\nPacific Islander", "Two or more races",
              "Total")
race_table = cbind(race_meaning, race_full)
race_tables = vector(mode = 'list',length = length(race_code))

for(i in 1:length(race_code)){
  race_data = fl_data[fl_data$race==as.character(race_code[i]),]
  summary_row = race_data%>%
    select(enrollment, enrl_AP, students_AP_exam_none)%>%
    summarise(across(.fns = ~ sum(.x,na.rm = T)))%>%
    mutate(county = "FLORIDA")
  county_data = race_data %>%
    select(lea_name, enrollment, enrl_AP, students_AP_exam_none)%>%
    group_by(lea_name)%>%
    summarise(across(.fns = ~ sum(.x,na.rm = T)))%>%
    rename(county = lea_name)
  final_race_data = bind_rows(county_data,summary_row)%>%
    mutate(nTest = students_AP_exam_none/enrl_AP,
           nTest = ifelse(nTest>1,1, nTest),
           pcAP = enrl_AP/enrollment)%>%
    rename(enrl=enrollment,
           enAP=enrl_AP,
           noAP=students_AP_exam_none)
  colnames(final_race_data)[2:6] = paste(colnames(final_race_data)[2:6],
                                         race_meaning[i],
                                         sep = "_")
  race_tables[[i]] = final_race_data
}

# Merging all race tables by county name
final_data = race_tables %>% reduce(full_join, by = "county")%>%
  mutate(flag = ifelse(county %in% c("LAFAYETTE",
                                     "GULF",
                                     "GLADES",
                                     "MADISON"),
                       1,
                       0))
print(distinct_counties[!(distinct_counties%in%final_data$county)])

# Summary stats

# Page 1 stats
d1 = final_data%>%
  filter(county=="FLORIDA")%>%
  select(starts_with(c("enrl")))%>%
  group_by(enrl_totl)%>%
  gather("race", "enrollment",!contains("totl"))%>%
  mutate(percent = enrollment/enrl_totl)%>%
  ungroup()

mean(final_data$nTest_totl[final_data$enrl_totl>=10000], na.rm=T)
mean(final_data$nTest_totl[final_data$enrl_totl<10000&final_data$enrl_totl>=2000], na.rm=T)
mean(final_data$nTest_totl[final_data$enrl_totl<2000], na.rm=T)


plot_data_1 = final_data%>%
  filter(county == "FLORIDA")%>%
  select(starts_with("enrl"))%>%
  gather(key ="RACE", value = "enrollment",starts_with("enrl"))
plot_data_1$RACE = gsub("enrl_","",plot_data_1$RACE)
plot_data_1$EN_perc = plot_data_1$enrollment/plot_data_1$enrollment[plot_data_1$RACE=="totl"]

plot_data_2 = final_data%>%
  filter(county == "FLORIDA")%>%
  select(starts_with("enAP"))%>%
  gather(key ="RACE", value = "AP",starts_with("enAP"))
plot_data_2$RACE = gsub("enAP_","",plot_data_2$RACE)

plot_data = merge(plot_data_1, plot_data_2, by = "RACE")
plot_data = merge(plot_data, race_table, by.x = "RACE", by.y = "race_meaning")%>%
  mutate(AP_PERC_2 = `AP`/`AP`[`RACE`=="totl"])
plot_data$enrl_totl = plot_data$enrollment[plot_data$`RACE`=="totl"]
plot_data$AP_totl = plot_data$AP[plot_data$`RACE`=="totl"]
plot_data$prop_fact = (plot_data$AP/plot_data$AP_totl)/(plot_data$enrollment/plot_data$enrl_totl)
plot_data$AP_perc = plot_data$AP/plot_data$enrollment

set_urbn_defaults(style = "print")

plot_d2 = plot_data%>%
  select(race_full, EN_perc, AP_perc)%>%
  group_by(race_full)%>%
  gather("Type","Percent", `EN_perc`,`AP_perc`)%>%
  filter(race_full != "Total")
  

plot_1 = ggplot2::ggplot(data = plot_d2, mapping = aes(y = race_full))+
  geom_bar(aes(x = Percent, fill = Type),stat='identity',
           position = position_dodge())+
  geom_text(aes(x = Percent, label = paste0(round(Percent,3)*100,"%")),
            position = position_dodge(.9))+
  xlim(0,.6)+
  xlab("Share of students enrolled in AP classes,\nby race or ethnicity")+
  ggtitle("AP Enrollment in Florida, by Race or Ethnicity")+
  theme(axis.title.y = element_blank(),
        axis.text.y = element_text(size = 12))+
  remove_ticks()
# Page 2 stats


# Saving Output
setwd(output_folder)

write.csv(final_data, "county_level_data.csv", row.names = F)
write.csv(fl_data, "School_level_data.csv", row.names = F)
png("plot_1.png")
print(plot_1)
dev.off()