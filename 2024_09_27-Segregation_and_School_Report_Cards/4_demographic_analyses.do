/*
Student Demographic Analyses

*/

cap frame change default

global geos "county child county_sch lea"
global columns1 "Overall TPS Charter"

// School level dataset
use "${data}hb729_analysis_file_v0.dta", clear

// fig 1
foreach group in county county_sch lea glea child{
	//local group = "county"
	preserve
		if "`group'" == "county" local gp = "county"
		if "`group'" == "county_sch" local gp = "county"
		if "`group'" == "child" local gp = "county"
		if "`group'" == "lea" local gp = "leaid"
		if "`group'" == "glea" local gp = "gleaid"
		if "`group'" == "lea" drop if charter == 1
		drop `group'_p_*
		keep `gp' `group'_whit `group'_bkaa `group'_hisp `group'_asia `group'_aian `group'_all_other 
		collapse (first) `group'_* , by(`gp')
		collapse (sum) `group'_*
		//desc
		//ren `gp'_* *_`gp'
		gen grouping = "`group'"
		//desc
		reshape long `group'_ , i(grouping) j(race, string)
		ren `group'_ count
		list
		tempfile x_`group'
		save "`x_`group''", replace
	restore
}

preserve
	clear
	foreach group in county county_sch lea glea child{
		append using "`x_`group''"
	}
	order grouping race count
	egen pop = total(count), by (grouping)
	gen share_2 = count/pop
	sort grouping race
	tempfile counts
	save "`counts'"
restore

use "${data}hb729_analysis_file_v0.dta", clear

foreach group in county county_sch lea glea child{
	//local group = "county"
	preserve
		if "`group'" == "county" local gp = "county"
		if "`group'" == "county_sch" local gp = "county"
		if "`group'" == "child" local gp = "county"
		if "`group'" == "lea" local gp = "leaid"
		if "`group'" == "glea" local gp = "gleaid"
		if "`group'" == "lea" drop if charter == 1
		foreach race in whit bkaa aian asia all_other hisp{
			gen diff_`race' = sch_p_`race' - `group'_p_`race'
		}
		collapse (first) `group'_p_* (mean) diff_* , by(`gp')
		collapse (mean) `group'_p_* diff_*
		//desc
		//ren `gp'_* *_`gp'
		gen grouping = "`group'"
		//desc
		reshape long `group'_p_ diff_ , i(grouping) j(race, string)
		ren `group'_p_ share
		ren diff_ diff_mean
		list
		tempfile x_`group'
		save "`x_`group''", replace
	restore
}

preserve
	clear
	foreach group in county county_sch lea glea child{
		append using "`x_`group''"
	}
	order grouping race share
	sort grouping race
	merge 1:1 grouping race using "`counts'"
	drop _merge
	
	// Label Race variables for bar chart
	gen race_num = .
	replace race_num = 1 if race == "whit"
	replace race_num = 2 if race == "bkaa"
	replace race_num = 3 if race == "hisp"
	replace race_num = 4 if race == "asia"
	replace race_num = 5 if race == "aian"
	replace race_num = 6 if race == "all_other"
	
	label define race_label 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Native American" 6 "Other"
	label values race_num race_label
	
	gsort grouping race_num
	
	drop race
	rename race_num race
	
	// Rename Comparison variables for bar chart
	replace grouping = "Age 5-17" if grouping == "child"
	replace grouping = "County" if grouping == "county"
	replace grouping = "All Public Schools" if grouping == "county_sch"
	replace grouping = "Traditional Public Schools" if grouping == "lea"
	
	
	order grouping race share 
	list in 1/10
	export excel using "${wd}/TablesforLC.xlsx", sheetmodify sheet("Demographic Charts") firstrow(variables)

restore
