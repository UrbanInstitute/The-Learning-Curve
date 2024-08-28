library(jsonlite)
library(dplyr)
try(library(tidyr))
library(httr)

# Clear the environment
rm(list = ls())

# setting directory to wherever this is saved
dir = dirname(rstudioapi::getActiveDocumentContext()$path)
data_files = paste0(dir,
                    "/data_files")

# Create the data directory
try({
  dir.create(data_files)
})

# 
lead = "B01001" # ACS detailed data table I want to pull

race = c("","A","B","C", "D", # total, white, black, american indian, asian
         "E","F","G","H","I") # NHPI, other, two or more, white non hispanic, hispanic

# ACS data points
qs = c(1,    #Total
       3:7,  # Male data points 
       18:31) # Female Data points
# Formatting
qs = paste0("_",sprintf("%03.0f", qs),"E")

# Creating a grid of every possible combination of race and ACS data point
qs2 = apply(expand.grid(lead,race,qs),1,paste, collapse = "")

qs2a = paste(qs2[1:40], collapse = ",")
qs2b = paste(qs2[41:80], collapse = ",")
qs2c = paste(qs2[81:110], collapse = ",")
qs2d = paste(qs2[111:150], collapse = ",")
qs2e = paste(qs2[151:190], collapse = ",")
qs2f = paste(qs2[191:200], collapse = ",")

qs3a = paste("NAME", qs2a, sep = ",")
qs3b = paste("NAME", qs2b, sep = ",")
qs3c = paste("NAME", qs2c, sep = ",")
qs3d = paste("NAME", qs2d, sep = ",")
qs3e = paste("NAME", qs2e, sep = ",")
qs3f = paste("NAME", qs2f, sep = ",")

x = paste0("https://api.census.gov/data/2021/acs/acs5?get=",qs3a,"&for=county:*&in=state:37")
y = paste0("https://api.census.gov/data/2021/acs/acs5?get=",qs3b,"&for=county:*&in=state:37")
z = paste0("https://api.census.gov/data/2021/acs/acs5?get=",qs3c,"&for=county:*&in=state:37")
x1 = paste0("https://api.census.gov/data/2021/acs/acs5?get=",qs3d,"&for=county:*&in=state:37")
y1 = paste0("https://api.census.gov/data/2021/acs/acs5?get=",qs3e,"&for=county:*&in=state:37")
z1 = paste0("https://api.census.gov/data/2021/acs/acs5?get=",qs3f,"&for=county:*&in=state:37")
w1 = paste0("https://api.census.gov/data/2021/acs/acs5?get=NAME,",
            "B03002_003E,",
            "B03002_004E,",
            "B03002_005E,",
            "B03002_006E,",
            "B03002_007E,",
            "B03002_008E,",
            "B03002_009E,",
            "B03002_012E",
            "&for=county:*&in=state:37")

gr = GET(x)
D1 = fromJSON(rawToChar(gr$content))

gr = GET(y)
D2 = fromJSON(rawToChar(gr$content))

gr = GET(z)
D3 = fromJSON(rawToChar(gr$content))


gr = GET(x1)
D1_2 = fromJSON(rawToChar(gr$content))

gr = GET(y1)
D2_2 = fromJSON(rawToChar(gr$content))

gr = GET(z1)
D3_2 = fromJSON(rawToChar(gr$content))

gr = GET(w1)
D3_3 = fromJSON(rawToChar(gr$content))

colnames(D1) = D1[1,]
D1 = data.frame(D1[-c(1),])

colnames(D2) = D2[1,]
D2 = data.frame(D2[-c(1),])

colnames(D3) = D3[1,]
D3 = data.frame(D3[-c(1),])

colnames(D1_2) = D1_2[1,]
D1_2 = data.frame(D1_2[-c(1),])

colnames(D2_2) = D2_2[1,]
D2_2 = data.frame(D2_2[-c(1),])

colnames(D3_2) = D3_2[1,]
D3_2 = data.frame(D3_2[-c(1),])

colnames(D3_3) = D3_3[1,]
D3_3 = data.frame(D3_3[-c(1),])

DATA = merge(D1, D2, by = c("NAME", "state", "county"))
DATA = merge(DATA, D3, by = c("NAME", "state", "county"))
DATA = merge(DATA, D1_2, by = c("NAME", "state", "county"))
DATA = merge(DATA, D2_2, by = c("NAME", "state", "county"))
DATA = merge(DATA, D3_2, by = c("NAME", "state", "county"))
DATA = merge(DATA, D3_3, by = c("NAME", "state", "county"))%>%
  mutate(across(starts_with(c("B01001","B03002")),as.numeric))

DATA$child_totl = 
  DATA$B01001_004E + DATA$B01001_005E + # males 5-9; males 10-14
  DATA$B01001_006E +                    # males 15-17
  DATA$B01001_028E + DATA$B01001_029E + # females 5-9; females 10-14
  DATA$B01001_030E                      # females 15-17

# White, non-hispanic
DATA$child_whit = 
  DATA$B01001H_004E + DATA$B01001H_005E +  # males 5-9; males 10-14
  DATA$B01001H_006E +                      # males 15-17
  DATA$B01001H_019E + DATA$B01001H_020E +  # females 5-9; females 10-14
  DATA$B01001H_021E                        # females 15-17

# Black African American
DATA$child_bkaa = 
  DATA$B01001B_004E + DATA$B01001B_005E +
  DATA$B01001B_006E +
  DATA$B01001B_019E + DATA$B01001B_020E +
  DATA$B01001B_021E 

# American Indian or Native American
DATA$child_aian = 
  DATA$B01001C_004E + DATA$B01001C_005E +
  DATA$B01001C_006E + 
  DATA$B01001C_019E + DATA$B01001C_020E +
  DATA$B01001C_021E 

# East Asian
DATA$child_asia = 
  DATA$B01001D_004E + DATA$B01001D_005E +
  DATA$B01001D_006E + 
  DATA$B01001D_019E + DATA$B01001D_020E +
  DATA$B01001D_021E

# Native Hawaiian or Pacific Islander
DATA$child_nhpi = 
  DATA$B01001E_004E + DATA$B01001E_005E +
  DATA$B01001E_006E +
  DATA$B01001E_019E + DATA$B01001E_020E +
  DATA$B01001E_021E 

# Other Race
DATA$child_othr = 
  DATA$B01001F_004E + DATA$B01001F_005E +
  DATA$B01001F_006E + 
  DATA$B01001F_019E + DATA$B01001F_020E +
  DATA$B01001F_021E

# Two or more races
DATA$child_twom = 
  DATA$B01001G_004E + DATA$B01001G_005E +
  DATA$B01001G_006E +
  DATA$B01001G_019E + DATA$B01001G_020E +
  DATA$B01001G_021E

# Hispanic children
DATA$child_hisp = 
  DATA$B01001I_004E + DATA$B01001I_005E +
  DATA$B01001I_006E+ 
  DATA$B01001I_019E + DATA$B01001I_020E +
  DATA$B01001I_021E

# White (no accounting of hispanicity)
DATA$child_whit2 = 
  DATA$B01001A_004E + DATA$B01001A_005E +
  DATA$B01001A_006E + 
  DATA$B01001A_019E + DATA$B01001A_020E +
  DATA$B01001A_021E 

# Checking that sum of county level survey items = total county 
# should be 100
sum(DATA$B01001_001E == 
      DATA$B01001A_001E+ #whit2
      DATA$B01001B_001E+ #bkaa
      DATA$B01001C_001E+ #aian
      DATA$B01001D_001E+ #asia
      DATA$B01001E_001E+ #nhpi
      DATA$B01001F_001E+ #othr
      DATA$B01001G_001E, #twom
    na.rm = T)

# This is county level estimates for racial characteristics, after accounting
# for hispanicity
sum(DATA$B01001_001E == 
      DATA$B03002_003E+ #whit2
      DATA$B03002_004E+ #bkaa
      DATA$B03002_005E+ #aian
      DATA$B03002_006E+ #asia
      DATA$B03002_007E+ #nhpi
      DATA$B03002_008E+ #othr
      DATA$B03002_009E+ #twom
      DATA$B03002_012E,  # hispanic
    na.rm = T)

# Checking that sum of county children by race = total county children
# should be 100
sum(DATA$child_totl == 
      DATA$child_whit2+
      DATA$child_bkaa+
      DATA$child_aian+
      DATA$child_asia+
      DATA$child_nhpi+
      DATA$child_othr+
      DATA$child_twom,
    na.rm = T)

# Unfortunately, hispanicity isn't accounted for within ACS, so this doesn't
# add up for most counties
# adds up to only 1
sum(DATA$child_totl == 
      DATA$child_whit+
      DATA$child_hisp+
      DATA$child_bkaa+
      DATA$child_aian+
      DATA$child_asia+
      DATA$child_nhpi+
      DATA$child_othr+
      DATA$child_twom,
    na.rm = T)

# Writing to a stata dta
haven::write_dta(DATA,
                 paste0(
                   data_files,
                   "/schoolcountyrace2.dta"))