******************************
* NSECE 2019 Cleaning
* 2.05.2021 - 2.08.2022
******************************


global data = "P:\8939\4001_Greenberg\NORC\Data"
global raw = "P:\8939\4001_Greenberg\NORC\Data\raw"
global review = "P:\8939\4001_Greenberg\NORC\Disclosure review\Files to review"
global build = "P:\8939\4001_Greenberg\NORC\Data\build"
global data19 = "P:\8939\4001_Greenberg\NORC\Data\Public Use Data\Data files\2019"
global output = "P:\8939\4001_Greenberg\NORC\Data\output"


******************************
* IMPORT PUBLIC-USE NSECE DATA
******************************

* 2019 center-based (CB) and workforce (wf) files
import excel "$data19\cb9_pu_jul1m_2021_07022021.xlsx", sheet("cb9_pu_jul1m_2021_07022021") firstrow clear
	rename *, lower
	rename cb9* cb*
	destring cb_meth_caseid, replace
save "$raw\cb_pu19", replace

import excel "$data19\wf9_pu_jan1m_2021.xlsx", sheet("wf9_pu_jan1m_2021") firstrow clear
	rename *, lower
	rename wf9* wf*
	rename cb9* cb*
	destring wf_meth_caseid, replace
save "$raw\wf_pu19", replace


***************************************
* IMPORT RESTRICTED-USE NSECE STATE IDS
***************************************

* import and save program IDs with their state identifiers
foreach x in cb wf {
	
	import delimited "$data\L2 Restricted Use Data\JAN1_2021\Greenberg_Sep1_2021_`x'_2019StateID", clear
	rename `x'9* `x'*
	
	* There are duplicates in the CB file
	duplicates tag *, gen(d)
	drop if d >0
	
	save "$raw\\`x'_stateid_19", replace
}


****************************************
* MERGE STATE ID & PUBLIC-USE NSECE DATA
****************************************


* merge state identifiers to public use data
foreach x in cb wf { 

	use "$raw\\`x'_pu19", clear
	merge 1:1 `x'_meth_caseid using "$raw\\`x'_stateid_19" //not all CB have a state ID

	drop _merge
	save "$raw\\`x'_state19", replace
}
	

/////////////////////////////
************************
* CREATE CB BUILD FILE
************************
/////////////////////////////
	
*** 2019 *** 

* load public use data
	use "$raw\wf_pu19", clear
	destring cb_meth_caseid, replace

* merge state ids, dropping if they don't have a state ID
	merge m:1 cb_meth_caseid using "$raw\\cb_state19"
	keep if _merge == 3
	drop _merge
	
*rename variables to match 2012
	rename wf_career_experience experience
	rename wf_char_race race
	rename wf_char_hisp hispanic
	rename wf_career_reason motivation
	
* replace don't know + none apply w/missing
	replace race = . if race == -1 | race == -8
	replace experience = . if experience == -1 | experience == -8
	replace hispanic = . if hispanic == -1 | hispanic == -8
	replace motivation = . if motivation == -1 | motivation == -8 | motivation == 8
	
	* Create program type
	g program_type = . 
	replace program_type = 1 if cb_rvnu_center_fund_combo ==1 // Only CCDF
	replace program_type = 2 if cb_rvnu_center_fund_combo ==2 // Only public pre-K
	replace program_type = 3 if cb_rvnu_center_fund_combo ==3 // Only Head Start 
	replace program_type = 1 if cb_rvnu_center_fund_combo ==8 // No funding from these three sources
	replace program_type = 2 if cb_rvnu_center_fund_combo ==6 & program_type == .  // PK & HS, labeled PK
	replace program_type = 1 if wf_c1_mostoften ==1 & cb_rvnu_center_fund_combo == 5 & program_type == . // CCDF & HS funding, serve infants/toddlers most
	replace program_type = 3 if wf_c1_mostoften ==2 & cb_rvnu_center_fund_combo == 5 & program_type == . // CCDF & HS , serve pre-k aged
	replace program_type = 2 if wf_c1_mostoften ==2 & cb_rvnu_center_fund_combo == 4 & program_type == . // PK & CCDF, serve pre-k aged
	replace program_type = 1 if wf_c1_mostoften ==1 & cb_rvnu_center_fund_combo == 4 & program_type == . // PK & CCDF, serve infants/toddlers
	replace program_type = 2 if wf_c1_mostoften ==2 & cb_rvnu_center_fund_combo == 7 & program_type == .  // all 3 sources, serve pre-k aged 
	replace program_type = 1 if wf_c1_mostoften ==1 & cb_rvnu_center_fund_combo == 7 & program_type == .  // all 3 sources, serve infants/toddlers 
	replace program_type = 2 if cb_rvnu_center_fund_combo == 4 & wf_c1_mostoften != 1 & wf_c1_mostoften != 2 & wf_c1_mostoften != 3 & program_type ==. // PK & CCDF, no info on age served
	replace program_type = 3 if cb_rvnu_center_fund_combo == 5 & wf_c1_mostoften != 1 & wf_c1_mostoften != 2 & wf_c1_mostoften != 3 & program_type == . // HS & CCDF, no info on age served 
	replace program_type = 2 if cb_rvnu_center_fund_combo == 7 & wf_c1_mostoften != 1 & wf_c1_mostoften != 2 & wf_c1_mostoften != 3 & program_type == . // All sources, no info on age served 
	replace program_type = 1 if program_type == . 

	* keep lead teachers only
	keep if wf_work_role == 2
	
* Inflation-adjust hourly wages to $2021 using CPI-U
	replace wf_work_wage = wf_work_wage*1.06

	save "$build\build19", replace
	
	
	
foreach y in 19 {
	
	use "$build\build`y'", clear
	
* clean variable names
	rename *l2_state_abbv state
	
* create year variable
	g year = 20`y'

	
*******************************
* CREATE VARIABLES OF INTEREST
*******************************

* ethnicity 
	replace hispanic = 0 if hispanic ==2
	
* race - done 

	g ofcolor = (race!=1)
	replace ofcolor = . if race==.

* motivation
	* generate additional motivation variables to match HB file in all years
	/*
	1/2/3 = 1 (Career/profession/step toward related career/personal calling, because HB 2012 groups them)
	6/7 = 2 (Way to help children/parents)
	4 = 3 (Earn money/job with a paycheck)
	5 = 4 (Work I can do while my own children are young/convenient work arrangement)
	*/	
	gen motivation1 = (motivation == 1 | motivation == 2 | motivation == 3) if motivation != .
	label var motivation1 "Career-related/personal calling"
	gen motivation2 = (motivation == 6 | motivation == 7) if motivation != .
	label var motivation2 "Help children/parents"
	gen motivation3 = (motivation == 4) if motivation != .
	label var motivation3 "Earn money"
	gen motivation4 = (motivation == 5) if motivation != .
	label var motivation4 "Convenient work arrangement"

* recode hourly wage variable
	g wageincome = wf_work_wage
	replace wageincome = . if wageincome < 0
	label var wageincome "CB hourly wage, HB child care income ($2022)"

* match training/education variable to our requirements database
	g education = . 	

* Less than HS diploma
	replace education = 8 if wf_char_educ == 1
* HS/GED
	replace education = 12 if wf_char_educ == 3 | wf_char_educ == 4 
* Some College
	replace education = 13 if wf_char_educ == 5
* AA
	replace education = 14 if wf_char_educ == 6
* BA
	replace education = 16 if wf_char_educ == 7 
* Graduate degree
	replace education = 18 if wf_char_educ == 8 
*DK 
	replace education = . if wf_char_educ == -1 | wf_char_educ == -4 | wf_char_educ == -8
	
* health insurance (conditioned on having health insurance)
 g emphins = 0 if wf_char_health == 4 | wf_char_health == 5 | wf_char_health == 6 | wf_char_health == 7 | wf_char_health == 8
 replace emphins = 1 if wf_char_health == 2 | wf_char_health == 3 
 replace emphins = . if wf_char_health == -1  // don't know/refused/no answer
 replace emphins =. if wf_char_health == 1 // no coverage of any type

	keep cb_meth_caseid state year program_type education experience hisp motivation* race wageincome ofcolor any* wf_meth_vpsu wf_meth_weight wf_meth_vstratum emphins
	order cb_meth_caseid state year program_type education experience hisp motivation* race ofcolor wageincome emphins
	
	
	* save file
	save "$build\center_foranalysis_20`y'.dta", replace
}
	


**************************************************************************
* MERGE NSECE AND STATE REQUIREMENTS DATA, CREATE FINAL FILES FOR ANALYSIS
**************************************************************************

foreach y in 2019 {  
* load center-based file
	use "$build\center_foranalysis_`y'.dta", clear 
* merge state qualifications database
	merge m:1 state year using "P:\8939\4001_Greenberg\NORC\Data\Uploaded materials\statedatabase_allyears.dta"
* drop other year
	drop if _merge == 2
	drop _merge

destring PKreq, replace

* create requirement variable
g requirement = .
replace requirement = CCreq if program_type == 1
replace requirement = PKreq if program_type == 2
replace requirement = HSreq if program_type == 3 



* create centers datatset
rename wf_meth_vpsu cb_meth_vpsu 
rename wf_meth_vstratum cb_meth_vstratum
rename wf_meth_weight cb_meth_weight

save "$build\cb_`y'_wreq", replace



* create pk dataset
preserve
	keep if program_type == 2
	
	rename cb_meth_vpsu pk_meth_vpsu
	rename cb_meth_vstratum pk_meth_vstratum
	rename cb_meth_weight pk_meth_weight

	save "$build\pk_`y'_wreq", replace
restore

}
