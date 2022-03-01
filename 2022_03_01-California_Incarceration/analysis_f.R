# Counts of Program type prevalence
services_counts = D1%>%
  ungroup()%>%
  filter(!is.na(program_name))%>%
  gather(key = "service", "status",17:25)%>%
  filter(status == "Yes")%>%
  group_by(Classification,service)%>%
  summarise(count = n(),
            percent = count/86)%>%
  group_by(service)%>%
  mutate(serv_tot = sum(percent, na.rm = T))%>%
  ungroup()%>%
  mutate(sort_1 = rank(-serv_tot))
services_counts$service = gsub("\\_","\n",services_counts$service)
flevels_1 = unique(services_counts$service[order(services_counts$sort_1)])

urbnthemes::set_urbn_defaults()

# Add ordering
service_vis_2 = ggplot()+
  geom_bar(data = services_counts, aes(x = service,
                                       y = percent),
           stat = "identity",)+
  scale_x_discrete(limits=flevels_1)+
  ylab("Proportion")+
  xlab("Service Provided")+
  ggtitle("Services Provided at Campus Reentry Programs")+
  theme(axis.text.x = element_text(angle = 90,
                                           size = 11))
service_vis_2

# Generating Geometries, data, and and stats
cali_shapefiles = get_urbn_map("counties", sf = TRUE)%>%
  filter(state_fips =="06")%>% st_transform(4326)
colnames(cali_shapefiles) = toupper(colnames(cali_shapefiles))
st_geometry(cali_shapefiles) = "GEOMETRY"
county_programs = D1 %>%
  ungroup()%>%
  mutate(CC_prog = ifelse(CC == 1&has_prog == 1, 1, 0))%>%
  group_by(county_name, Classification)%>%
  summarise(programs = sum(as.numeric(has_prog), na.rm = T),
            community_colleges = sum(as.numeric(CC), na.rm = T),
            cc_progs = sum(as.numeric(CC_prog), na.rm = T),
            number_enrolled_total = sum(as.numeric(number_enrolled_total), na.rm = T),
            schools = n())%>%
  group_by(county_name)%>%
  mutate(total_schools = sum(schools, na.rm = T),
    total_students = sum(as.numeric(number_enrolled_total), na.rm = T),
                               county_name = paste0(county_name, ", California"))
D4 = merge(county_programs, D3,
           by.x = "county_name",
           by.y = "NAME",
           all = T)%>%
  mutate(COUNTY_FIPS = paste0("06",COUNTY))
D5 = left_join(D4,cali_shapefiles[c("COUNTY_FIPS")],
               by = "COUNTY_FIPS")
projcrs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
School = st_as_sf(x = D1,                         
                  coords = c("longitude", "latitude"),
                  crs = projcrs)
D5$parolee_rate = (D5$parolees/as.numeric(D5$POP))*(10^5)


# Map 1: Map of Schools
schools_map = ggplot()+
  geom_sf(data = D5, mapping = aes(geometry = GEOMETRY), fill = "#1696d2")+
  geom_point(data=D1[D1$has_prog==1,], mapping = aes(x = as.numeric(longitude),
                                    y = as.numeric(latitude),
                                    color = as.character(Classification)),
             alpha = .65)+
  scale_colour_manual(name = "College Type",
                      labels = levels(as.factor(D1$Classification)),
                      values = c("#000000", "#fdbf11", "#ec008b")) +
  ggtitle("Reentry Services on College Campuses in California")+
  theme_void()
schools_map

#Map 2: Map of schools and parole rates 
parole_rate_map = ggplot()+
  geom_sf(data = D5, mapping = aes(fill = parolee_rate, geometry = GEOMETRY))+
  labs(fill = "Parolee rate (per 100k people)")+
  geom_point(data=D1[D1$has_prog==1,],
             mapping = aes(x = as.numeric(longitude),
                           y = as.numeric(latitude),
                           color = Classification),
             alpha = .65)+
  scale_colour_manual(name = "College Type",
                      labels = levels(as.factor(D1$Classification)),
                      values = c("#000000", "#fdbf11", "#ec008b")) +
  ggtitle("Parolee frequencies and Prisoner Reentry Services")+
  theme_void()
parole_rate_map

# Figure 3: Barplot of results
D5_A = D5 %>%
  select(county_name,county, Classification, programs, community_colleges, cc_progs,
         total_schools, POP, parolees, parolee_rate,total_students)%>%
  mutate(across(!contains(c("county","Class")),as.numeric))%>%
  mutate(programs_perc_1 = programs/community_colleges,
         programs_perc_2 = programs/total_schools,
         programs_perc_3 = cc_progs/community_colleges)%>%
  mutate(sort_6 = rank(-total_students, na.last = T))

# Top 10 counties by number of students
flevels_6 = unique(D5_A$county_name[order(D5_A$sort_6)])



# Stacked Barplots, by county and school classification, ordered by
# number of students
fig_3_F = ggplot(data = D5_A[D5_A$county_name%in%flevels_6[1:10],])+
  geom_bar(mapping = aes(x = county_name,
                         y = programs_perc_2,
                         fill = Classification),
           position = "stack",
           stat = "identity")+
  scale_x_discrete(limits=flevels_6[1:10])+
  scale_fill_manual(name = "College Type",
                      labels = levels(as.factor(D5_A$Classification)),
                      values = c("#000000", "#fdbf11", "#ec008b"))+
  ggtitle("Proportion of Institutions that have Campus Reentry Programs, by County")+
  ylab("Proportion")+
  theme(axis.title.x = element_blank(),
        axis.title.y = element_text(size = 11),
        axis.text.x = element_text(angle = 90,
                                   size = 11),
        axis.text.y = element_text(size = 11))
fig_3_F


write.csv(D5_A, paste0(output_folder,"/yucel_final_county.csv"))

png("map_1.png")
print(schools_map)
dev.off()

png("map_2.png")
print(parole_rate_map)
dev.off()

png("fig_3_students.png")
print(fig_3_F)
dev.off()

png("fig_4_services.png")
print(service_vis_2)
dev.off()