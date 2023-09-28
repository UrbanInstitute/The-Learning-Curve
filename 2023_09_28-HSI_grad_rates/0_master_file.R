library(urbnthemes)
library(tidyverse)
library(educationdata)

# Clear data

rm(list =ls())

dire = dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(dire)

if(!require("educationdata")){
  install.packages("educationdata")
}else{
  update.packages("educationdata")
}

unzip("_analysis.zip")

# Downloading the Less than 2-year IPEDS data
source("1_download_gr_l2.R")
# Downloading the +2 year IPEDS graduation rate data
source("2_download_gr.R")
# Reshaping data for analysis
source("3_reshape_merge.R")
# Analysis file
source("4_analysis.R")