library(tidyverse)
library(educationdata)
library(jsonlite)
library(readxl)
library(pdftools)
library(tigris)
library(stringdist)
library(sf)
library(urbnmapr)

rm(list = ls())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Creating directories as needed
output_folder =  "Data/Output_Data"
downloads_folder =  "Data/Downloaded"

if(!dir.exists(downloads_folder)){
  dir.create(file.path(getwd(),downloads_folder),recursive = T)
}

if(!dir.exists(output_folder)){
  dir.create(file.path(getwd(),output_folder),recursive = T)
}

source("analysis_1.R") # Getting the physical location of the 87 schools that offer reintigration
source("analysis_2.R") # Getting the Census API poopulation data for all 58 counties 
source("analysis_3.R") # Getting the number of parolees per county and merging county populations
source("analysis_f.R") # Generating figures, plots, and stats in report


