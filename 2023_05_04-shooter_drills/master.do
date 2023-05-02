qui {
cap log close
clear all
set matsize 11000
snapshot erase _all
eststo clear
version 15
}

// Set project directory. 
glob projDir "C:/Users/lrestrepo/Documents/github_repos/The-Learning-Curve/2023_05_04-shooter_drills"

glob data "${projDir}/data"
glob clean_data "${data}/clean_data"
glob log_data "${data}/log_data"
glob vis_data "${data}/vis_data"
glob out_data "${data}/out_data"

foreach y in "$data" "$clean_data" "$log_data" "$vis_data" "$out_data"{
	cap n mkdir "`y'"
}

cap n ssc install gtools
cap n ssc install ftools
cap n ssc install reghdfe 

net install urbanschemes, replace from("https://urbaninstitute.github.io/urbanschemes/")

set scheme urbanschemes
graph set window fontface "Lato"

cd "${projDir}"

cap n unzipfile "${projDir}/analysis.zip"

/*===============================================================================================
This is the master do-file for running do-files for The Learning Curve essay on school-shooter drills. 

Author: Elc Estrera

Modified: 
	
Created: 4/24/23
===============================================================================================*/

// Recover summary stats on schools. 
do "${projDir}/su_school_sumstats"		

// Determine test-taker exposure to shooter drills.
do "${projDir}/su_testersNearDrills"	

// Show proficiency rates by timing of test relative to shooter drill. 
do "${projDir}/fig_profRates_drillTiming"		

// Run regression to estimate effect of active-shooter drill on attendance. 
do "${projDir}/reg_attendanceRate_drills"