/******************************************************************************
	This is the master do-file for Libassi & Mabel's Learning Curve Policy 
	Brief: "A Closer Look at College Affordability: The Link Between Living 
	Allowances and Student Debt." 
	
	It runs the following three do-files in one fell swoop:
	
	(1) EDP_Pulls.do - downloads and saves the raw data files from the EDP
	(2) construct_analytic_file.do - processes the raw data files and constructs and 
								  saves the institution-level analytic file 
								 (la_analysis_file.dta) 
	(3) table_and_figure_construction_for_publication.do - runs the analyses included
														in the final brief
	
	Other input files necessary to run code cleanly:
	(a) bea_rpp.xlsx -- this is the Bureau of Economic Analysis' regional price parities.
					    Place the attached file in the same folder where the raw
						data pulled from the EDP is stored. It is called in the 
						construct_analytic_file.do on line 350
	
	Authors: Zack Mabel & CJ Libassi
	Date Created: 6.13.22
*******************************************************************************/

clear
set more off

*installing necessary dependencies
cap n ssc install gtools renvarlab

* Set folder directories - Change this line prior to running code
global wd			"C:/Users/lrestrepo/Documents/Github_repos/The-Learning-Curve/2022_07_07-NonTuit_Expenses" 		  	  // where copies of do-files are saved

glo wd_anal "${wd}/analysis"

global code "${wd_anal}/code"
global data "${wd_anal}/data"

cd "${wd}"

unzipfile "${wd}/analysis.zip"

global raw  		"${data}/raw" 		  // where raw data pulled from EDP will be saved
global intermediate "${data}/intermediate" // where intermediate file edp_clean.dta will be saved
global clean 		"${data}/clean" 		  // where analytic file la_analysis_file.dta will be saved
global output 		"${data}/output" 			  // where tables and figures will be saved

cap n mkdir "${data}"
cap n mkdir "${raw}"
cap n mkdir "${intermediate}"
cap n mkdir "${clean}"
cap n mkdir "${output}"

* Run do-files
do "${code}/EDP_Pulls.do"
do "${code}/construct_analytic_file.do"
do "${code}/table_and_figure_construction_for_publication.do"
