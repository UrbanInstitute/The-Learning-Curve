
**********************
*** MASTER DO FILE ***
**********************

// Environment Initialization
clear all
set more off 
loc n = 3

// Only run after having created the necessary data directories and saved the ACS data

// n=3 if Cody
if `n' ==3 {
	// Change line 14 to reflect the intended working directory, or "my_dir" as specified in the instructions
	gl dir "******"
	gl data "${dir}Data/raw data/"
	gl intermediate "${dir}Data/work data/"
	gl programs = "${dir}analysis_2/"
	gl output = "${dir}Output/"
} 
cd "${dir}"

cap n unzipfile "${dir}analysis.zip", replace

cd "${data}"

foreach d1 in scorecard ipeds zips{
	cap n mkdir "${data}`d1'"
}

cap n mkdir "${intermediate}"
cap n mkdir "${output}"

cap n ssc install payper
cap n ssc install nmissing
cap n net install grc1leg2

// helps with setting up urban style visuals
net install urbanschemes, replace from("https://urbaninstitute.github.io/urbanschemes/")

// 1. Load scorecard data (2014-15 to 2019-20)
do "${programs}01 load scorecard variables.do"

// 2. Generate unique lists of program titles and college names from scorecard data
do "${programs}01 scorecard list of program and college names.do"

// 3. ipeds inst char file (2014-15 to 2019-20)
do "${programs}01 load ipeds inst char.do"

// 4. ACS earnings data
do "${programs}01 load ACS earnings data.do"

// 5. IPEDS program level completers data
do "${programs}01 load ipeds program level completers data.do"

// 6. IPEDS finance data
do "${programs}01 load ipeds finance data.do"

// 7. IPEDS 12-mn FTE enrollment data
do "${programs}01 load ipeds 12mn enrollment data.do"

// 8. Generate analysis sample
do "${programs}02 generate analysis sample.do"

// 9. Conduct Descriptive Analysis
do "${programs}03 analysis.do"