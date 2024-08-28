/*
School Level Analyses

*/


global geos "county child county_sch lea"
global columns1 "Overall TPS Charter"

// School level dataset
use "${data}hb729_analysis_file_v0.dta", clear

// Get the Total number of public schools
drop if charter > 1
qui count
local all_schools = `r(N)'
qui count if charter
local n_charters = `r(N)'
qui count if !charter
local n_tps = `r(N)'

// Counts of Schools per category and geography
foreach div in county child county_sch lea {
	preserve
		di "`div'"
		gen c = 1
		collapse (sum) c , by(`div'_prop_cat charter)
		drop if missing(`div'_prop_cat)
		reshape wide c, i(`div') j(charter)
		rename c0 TPS_`div'
		rename c1 Charter_`div'
		label variable TPS_`div' "TPS"
		label variable Charter_`div' "Charter"
		ren `div'_prop_cat cat
		gen Total_`div' = TPS_`div' + Charter_`div'
		tempfile t_`div'
		save "`t_`div''", replace
	restore
}

// Merge into a single file with counts and percentages by category
preserve
	clear
	use "`t_county'"
	foreach div in child county_sch lea{
		merge 1:1 cat using "`t_`div''", nogen
	}
label define cat_labels 1 "Highly Proportional" 2 "Proportional" 3 "Somewhat Disproportional" 4 "Highly Disproportional"
label values cat cat_labels

	export excel using "${wd}/TablesforLC.xlsx", sheetmodify sheet("N by Charter Status") firstrow(variables)

	foreach div in county county_sch child {
		gen p_tps_`div' = TPS_`div' / `n_tps'
		gen p_charter_`div' = Charter_`div' / `n_charters'
		gen p_all_public_`div' = Total_`div' / `all_schools'
	}
	keep cat p_*
	order cat p_all_public_county p_all_public_child p_all_public_county_sch p_tps_county p_tps_child p_tps_county_sch p_charter_county	p_charter_child p_charter_county_sch

	export excel using "${wd}/TablesforLC.xlsx", sheetmodify sheet("P by Charter Status") firstrow(variables)
restore

// Private and charter school county differences
use "${data}hb729_analysis_file_v0.dta", clear

gen county_enr_diff_whit = county_p_whit - sch_p_whit

bys charter: sum county_enr_diff_whit

preserve
	collapse (mean) county_enr_diff_whit (min) min_county_diff_whit = county_enr_diff_whit (max) max_county_diff_whit = county_enr_diff_whit, by(charter)
	gen category = ""
	replace category = "TPS" if charter == 0
	replace category = "Charter" if charter == 1
	replace category = "Private" if charter == 2
	drop charter
	order category
	export excel using "${wd}/TablesforLC.xlsx", sheetmodify sheet("Enrollment vs County") firstrow(variables)
restore

// Clean Up Excel Sheets
putexcel set "${wd}/TablesforLC.xlsx", modify sheet("N by Charter Status")

putexcel A1 = "Proportionality Category"
putexcel B1 = "TPS - County Comparison"
putexcel C1 = "Charter - County Comparison"
putexcel D1 = "Total - County Comparison"
putexcel E1 = "TPS - Age 5-17 Comparison"
putexcel F1 = "Charter - Age 5-17 Comparison"
putexcel G1 = "Total - Age 5-17 Comparison"
putexcel H1 = "TPS - Public School Comparison"
putexcel I1 = "Charter - Public School Comparison"
putexcel J1 = "Total - Public School Comparison"
putexcel K1 = "TPS - LEA Comparison"
putexcel (L1:M2) = ""


putexcel set "${wd}/TablesforLC.xlsx", modify sheet("P by Charter Status")

putexcel A1 = "Proportionality Category"
putexcel B1 = "Total - County Comparison"
putexcel C1 = "Total - Age 5-17 Comparison"
putexcel D1 = "Total - Public School Comparison"
putexcel E1 = "TPS - County Comparison"
putexcel F1 = "TPS - Age 5-17 Comparison"
putexcel G1 = "TPS - Public School Comparison"
putexcel H1 = "Charter - County Comparison"
putexcel I1 = "Charter - Age 5-17 Comparison"
putexcel J1 = "Charter - Public School Comparison"

putexcel set "${wd}/TablesforLC.xlsx", modify sheet("Enrollment vs County")

putexcel A1 = "Proportionality Category"
putexcel B1 = "County vs School Enrollment - Mean"
putexcel C1 = "County vs School Enrollment - Min"
putexcel D1 = "County vs School Enrollment - Max"
	
// School Districts that are less white than their county
preserve
	drop if charter > 1
	collapse (firstnm) county_p_* lea_p_*, by(leaid charter)
	gen county_lea_diff_whit = county_p_whit - lea_p_whit
	
	count if county_lea_diff_whit < 0 & charter == 0
	count if county_lea_diff_whit >= 0 & !missing(county_lea_diff_whit) & charter == 0
	
	bys charter: sum county_lea_diff_whit
	tab charter

restore
