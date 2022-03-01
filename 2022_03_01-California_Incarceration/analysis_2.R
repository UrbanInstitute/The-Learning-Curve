# Downloading and restructuring census data from the Census API
census_data_api = "https://api.census.gov/data/2019/pep/population?get=COUNTY,DENSITY,POP,NAME,STATE,REGION&for=COUNTY:*"
CENSUS_API = as.data.frame(fromJSON(census_data_api))
colnames(CENSUS_API) = CENSUS_API[1,]
CENSUS_API = CENSUS_API %>%
  filter(COUNTY != "COUNTY",
         STATE == "06")
