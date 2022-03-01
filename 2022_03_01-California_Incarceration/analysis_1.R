# Getting the physical location of schools that have prison reintigration programs
yucel_crosswalk = read_xlsx("Data/Input_Data/yucel_colleges.xlsx")
yucel_cc = read_csv("Data/Input_Data/yucel_cc.csv")
madera = read_xlsx("Data/Input_Data/madera.xlsx",col_types = "text") # A school opened in 2019 that had yet to be added to the NCES

all_CA_schools <- get_education_data(level = "college-university",
                           source = "ipeds",
                           topic = "directory",
                           filters = list(year = 2020,
                                          fips = 6))
all_CA_enrollments <- get_education_data(level = "college-university",
                                     source = "ipeds",
                                     topic = "admissions-enrollment",
                                     filters = list(year = 2019,
                                                    fips = 6,
                                                    sex = 99))
all_CA_schools = merge(all_CA_schools,
                       all_CA_enrollments[c("unitid","number_enrolled_total")],
                       by = "unitid",
                       all = T)
all_CA_schools$has_prog = ifelse(all_CA_schools$unitid %in% unique(yucel_crosswalk$UNITID), 1, 0)
D1 = all_CA_schools %>%
  select(unitid, opeid,inst_name, address,
         state_abbr, fips, zip,
         county_name, has_prog,
         longitude, latitude,
         inst_control,
         institution_level,
         offering_highest_level, number_enrolled_total)%>%
  filter(inst_control %in% c(1,2),
         institution_level %in% c(2:4))
D1 = merge(D1, yucel_crosswalk[,c(2,3,4,6:14)],
           by.x = "unitid",
           by.y = "UNITID",
           all.x = T)%>%
  rename(program_name=`Type of reentry service on campus (club vs. program)`,
         program_type = `Type of Programs`)%>%
  mutate(across(.fns = as.character))
D1 = bind_rows(D1, madera)
D1$CC = ifelse(D1$inst_name%in%yucel_cc$`College Name`, 1, 0)
new_labs = data.frame(matrix(c("1","Public","2","Private, Nonprofit"),nrow = 2, byrow = T))
D1 = merge(D1, new_labs,
           by.x = "inst_control",
           by.y = "X1")%>%
  mutate(public_uni_flag = ifelse(grepl("((Sacramento)|(Humboldt)|(California)|(San Francisco)|(San Diego) State)|(University of California)",
                                       inst_name)&CC!=1&inst_control == 1,
                                 1,
                                 0))
D1$Classification = NA
D1$Classification[D1$CC == 1] = "Community College"
D1$Classification[D1$public_uni_flag == 1] = "UC or CSU public 4-year"
D1$Classification[D1$CC != 1&D1$public_uni_flag != 1] = "Private 4-year"
write.csv(D1, paste0(output_folder,"/yucel_final.csv"))