/*
File: NAEPdatacleaning
Project: 
SubProject: 
Author: Rachel Lamb
Create Date: 04112022

*/
cap ssc install libjson

cap ssc install educationdata, replace


clear all
set more off 

//macros 

// Change line 20 to match what you need
global path "C:/Users/lrestrepo/Documents/github_repos/The-Learning-Curve/2022_12_02-Honesty_Gap"

global pathDO "${path}/DO file/" 
global pathData "${path}/data"
global pathraw "${pathData}/Raw Data"

global pathclean "${pathData}/Clean Data"
global pathout "${pathData}/Output/"

cap n mkdir "${pathData}"
cap n mkdir "${pathraw}"
cap n mkdir "${pathclean}"
cap n mkdir "${pathout}"

cd "${pathraw}"

cap n unzipfile "${path}/raw_data.zip", replace

do "${path}/datacleaning.do"
do "${path}/analysis.do"