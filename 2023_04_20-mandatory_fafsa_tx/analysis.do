* 4/5/2023
* "How a Mandatory FAFSA Completion Policy in Texas Could Improve College Access"
* Sie Won Kim (siewon.kim@ttu.edu)

* 1) Specify project directory `path' in line 19
* 2) Create folder: `path'/data/ 
* 3) Move the data file (fafsa_tx_2019_2022.dta) to `path'/data/ 
* 4) Create folder: `path'/data/derived/
* 5) Create folder: `path'/output/figures/
* 6) Run the do file

* Input: 	fafsa_tx_2019_2022.dta		in 		`path'/data/
* Output: 	derived data files			in		`path'/data/derived/
* 			figures 					in		`path'/output/figures/

clear

//project directory
glo path = "******"

glo data = "${path}/data"
glo der_data = "${data}/derived"
glo int_data = "${data}/int_data"
glo fin_data = "${data}/fin_data"
glo vis_data = "${data}/vis_data"

local endash = ustrunescape("\u2013")


foreach y in "${data}" "${der_data}" "${int_data}" "${fin_data}" "${vis_data}" {
	cap n mkdir "`y'"
}

cd "${der_data}"


// Urban Institute Education Data Portal
cap n ssc install libjson
cap n ssc install educationdata
cap n ssc install carryforward
cap n net install urbanschemes, replace from("https://urbaninstitute.github.io/urbanschemes/")

set scheme urbanschemes
graph set window fontface "Lato"

*----------------------------------------------
*
* MEPS from Urban Institute Education Data Portal
*
*----------------------------------------------

cap n confirm file "${der_data}/meps_2018.dta"
if _rc == 601{
	copy "https://educationdata.urban.org/csv/meps/schools_meps.csv" "${der_data}/raw_meps.csv", replace
	import delimited "${der_data}/raw_meps.csv", clear varnames(1)
	keep if year  == 2018 & fips == 48
	keep ncessch ncessch_num meps_poverty_pct meps_poverty_se meps_mod_poverty_pct meps_poverty_ptl meps_mod_poverty_ptl
	tostring ncessch, replace format("%12.0f")
	save		 "${der_data}/meps_2018.dta", replace
}


*----------------------------------------------
* 
* CCD enrollment from Urban Institute Education Data Portal
*
*----------------------------------------------

//2021-2022 will be updated
foreach yr of numlist 2018/2021{		   
	cap n confirm file "${der_data}/ccd_enroll_`yr'.dta"
	if _rc == 601{
		//loc yr 2021
		if `yr' < 2021{
			copy "https://educationdata.urban.org/csv/ccd/schools_ccd_enrollment_`yr'.csv" "${der_data}/raw_ccd_enr_`yr'.csv", replace
			import delimited "${der_data}/raw_ccd_enr_`yr'.csv", clear varnames(1)
		}
		if `yr' == 2021{ // downloading code from stata2, will be updated once data is on portal
			use "//stata2/EDI/education_data_portal/ccd/data/_for_db_upload/enrollment_grade_sex_race_2021.dta", clear
		}
		keep if grade == 12 & fips == 48 & sex == 99
		cap n tostring ncessch, replace format("%12.0f")
		rename		year 	year_ccd
		gen			year = 	year_ccd + 1
		reshape wide enrollment, i(ncessch) j(race)
		
		/*
		Race/ethnicity
		1—White
		2—Black
		3—Hispanic
		99—Total
		*/		
	
		gen		share_white = enrollment1/enrollment99
		gen		share_black	= enrollment2/enrollment99
		gen		share_hisp	= enrollment3/enrollment99
		
		keep	ncessch year 	ncessch_num 	enrollment*	share*
		save		 "${der_data}/ccd_enroll_`yr'.dta", replace
	}
}
*

use "${der_data}/ccd_enroll_2021.dta", clear
append using "${der_data}/ccd_enroll_2018.dta"
append using "${der_data}/ccd_enroll_2019.dta"
append using "${der_data}/ccd_enroll_2020.dta"
save "${der_data}/ccd_enroll.dta", replace




*----------------------------------------------
*
* FAFASA data: Office of Federal Student Aid
*
*----------------------------------------------
// Downloading, creating stata files, and naming them accordingly

cap n copy "https://studentaid.gov/sites/default/files/HS_ARCHIVE09302019.xls" "${der_data}/fafsa_2019.xls"
forval y = 2020/2022{
	if `y'> 2020 loc endd = "xls"
	if `y'==2020 loc endd = "xlsx"
	cap n copy "https://studentaid.gov/sites/default/files/fsawg/datacenter/library/fafsabyhs/HS_ARCHIVE0930`y'.`endd'" "${der_data}/fafsa_`y'.`endd'"
}

clear
forval y = 2019/2022{
	if `y'!=2020 loc endd = "xls"
	if `y'==2020 loc endd = "xlsx"
	if `y' == 2019 loc row = 27998
	if `y' == 2020 loc row = 27938
	if `y' == 2021 loc row = 27700
	if `y' == 2022 loc row = 27654
	import excel "${der_data}/fafsa_`y'.`endd'", sheet("School Level Data") clear
	keep if _n >= 4
	keep A B C D E
	rename (A B C D E) (school_name city_location state submit complete)
	keep if state == "TX"
	gen year = `y'
	save "${der_data}/fsa_tx_`y'.dta", replace
}
clear
forval y = 2019/2022{
	append using "${der_data}/fsa_tx_`y'.dta", force 
}
// Adding the School ids from the State level files
preserve
cap n copy "https://studentaid.gov/sites/default/files/fsawg/datacenter/library/fafsabyhs/TX.xls" "${der_data}/fafsa_tx.xls"
import excel "${der_data}/fafsa_tx.xls", clear
keep if _n> 4
keep A B C
rename (A B C) (ncessch school_name city_location)
save "${der_data}/FSA_TX_CW.dta", replace
restore


reshape wide submit complete, i(school_name city_location state) j(year)
merge m:1 school_name city_location using "FSA_TX_CW.dta", force
sort school_name city_location
drop if _merge != 3
save "${der_data}/fafsa_tx_2019_2022_2.dta", replace

use	"${der_data}/fafsa_tx_2019_2022_2.dta", clear

//bottom-code less than 5 category "<5" to 5
foreach var in submit2019 submit2020 submit2021 submit2022 complete2019 complete2020 complete2021 complete2022 { 

		replace `var' = "5" 		if `var' == "<5"
		destring `var', replace
}
*


*----------------------------------------------
*
* merge with CCD and MEPS data
*
*----------------------------------------------
drop _merge

collapse (sum) submit* complete* (firstnm) school_name, by(ncessch)
merge 1:1 ncessch using "${der_data}/meps_2018.dta", update
ren _merge meps_merge

reshape long submit complete, i(ncessch meps_merge) j(year)
destring submit complete, replace


merge 1:1 year ncessch using "${der_data}/ccd_enroll.dta"

ren _merge ccd_merge

tostring meps_merge, gen(meps_merge_2)
tostring ccd_merge, gen(ccd_merge_2)
gen merge_cat = meps_merge_2 + "_" + ccd_merge_2

keep if merge_cat == "3_3"

drop if enrollment99 == .


// drop submission rate > 1 & completion rate > 1
gen submit_rate		= submit/enrollment99
gen complete_rate	= complete/enrollment99

gen 	submit_rate_over_1 		= 0
replace submit_rate_over_1 		= 1 			if submit_rate > 1 &!missing(submit_rate)

gen 	complete_rate_over_1	= 0
replace	complete_rate_over_1 	= 1 			if complete_rate > 1 &!missing(complete_rate)
				
bys ncessch: egen count_submit_rate_over_1 	 	= total(submit_rate_over_1)
bys ncessch: egen count_complete_rate_over_1		= total(complete_rate_over_1)

tab count_submit_rate_over_1 count_complete_rate_over_1

tab count_submit_rate_over_1 year

tab count_complete_rate_over_1 year
				
drop		if count_submit_rate_over_1 > 0 | count_complete_rate_over_1 > 0




*-----------------------------------------
*
* By fafsa submission rate at baseline year 2018
*
*-----------------------------------------

preserve
	sort ncessch  year 
	
	gen		submit_rate_2019		= submit_rate 		if year == 2019
		
	by ncessch (year): carryforward submit_rate_2019, replace
	
	su		submit_rate_2019		, detail
	
	local p25 = round(100*r(p25), 0.1)
	local p50 = round(100*r(p50), 0.1)
	local p75 = round(100*r(p75), 0.1)

	xtile 	submit_rate_quart_2019 = submit_rate_2019			, nq(4)
	table 	submit_rate_quart_2019 year							, statistic(mean submit) statistic(mean complete) statistic(mean enrollment99)

	collapse (sum) submit  complete  enrollment99, by(submit_rate_quart_2019 	year)

	drop if submit_rate_quart_2019 == .

	sort year submit_rate_quart_2019
	bysort year: gen total_submit 		= sum(submit)	
	bysort year: gen total_complete 	= sum(complete)
	bysort year: gen total_enroll	 	= sum(enrollment)

	gen submit_rate		= submit/enrollment99
	gen complete_rate	= complete/enrollment99

	gen total_submit_rate		= total_submit/total_enroll
	gen total_complete_rate		= total_complete/total_enroll

	
	*---------------------------------------------------------------------
	*
	* Figure 1: 
	*
	*---------------------------------------------------------------------

	twoway (connected  total_submit_rate year 	if submit_rate_quart_2019 == 4)	///			
			(connected  total_complete_rate year if submit_rate_quart_2019 == 4), ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA application rates") ///
			legend(order(1 "FAFSA submissions" 2 "FAFSA completions")) ///
			plotregion(margin(t = 12))

	graph export "${vis_data}/summary_total_rates.png", replace

	*---------------------------------------------------------------------
	*
	* Figure 2: FAFASA completion rates by baseline FAFSA submission rates
	*
	*---------------------------------------------------------------------

	twoway	(connected  complete_rate year if submit_rate_quart_2019 == 1)	///
			(connected  complete_rate year if submit_rate_quart_2019 == 2)	///
			(connected  complete_rate year if submit_rate_quart_2019 == 3)	///
			(connected  complete_rate year if submit_rate_quart_2019 == 4,  ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA completion rate") ///	
			legend(order(1 "≤ `p25'%" 2 "`p25'`endash'`p50'%" 3 "`p50'`endash'`p75'%" 4 "> `p75'%") rows(2)) ///
			plotregion(margin(t = 12)))		

	graph export "${vis_data}/summary_complete_by_base_submit.png", replace

	*---------------------------------------------------------------------
	*
	* Figure A.1: FAFASA submission rates by baseline FAFSA submission rates
	*
	*---------------------------------------------------------------------

	twoway	(connected  submit_rate year 		if submit_rate_quart_2019 == 1)	///
			(connected  submit_rate year 		if submit_rate_quart_2019 == 2)	///
			(connected  submit_rate year 		if submit_rate_quart_2019 == 3)	///
			(connected  submit_rate year 		if submit_rate_quart_2019 == 4,  ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA submission rate") ///	
			legend(order(1 "≤ `p25'%" 2 "`p25'`endash'`p50'%" 3 "`p50'`endash'`p75'%" 4 "> `p75'%") rows(2)) ///
			plotregion(margin(t = 12)))

	graph export "${vis_data}/summary_submit_by_base_submit.png", replace

	
	
restore

			

*---------------------------------------------------------------------
*
* By MEPS at 2018 Estimated percentage of students living in poverty (MEPS)
*
*---------------------------------------------------------------------

preserve
	su		meps_poverty_pct, detail
	
	local p25 = round(r(p25), 0.1)
	local p50 = round(r(p50), 0.1)
	local p75 = round(r(p75), 0.1)
	
	xtile 	meps_poverty_pct_quart_2018 = meps_poverty_pct, nq(4)
	table 	meps_poverty_pct_quart_2018	year							, statistic(mean submit) statistic(mean complete) statistic(mean enrollment99)

	table 	meps_poverty_pct_quart_2018	year							, statistic(mean meps_poverty_pct)

	collapse (sum) submit  complete  enrollment99, by(meps_poverty_pct_quart_2018	year)

	drop if meps_poverty_pct_quart_2018 == .

	sort year meps
	bysort year: gen total_submit 		= sum(submit)	
	bysort year: gen total_complete 	= sum(complete)
	bysort year: gen total_enroll	 	= sum(enrollment)

	gen submit_rate		= submit/enrollment99
	gen complete_rate	= complete/enrollment99

			
	*---------------------------------------------------------------------
	*
	* Figure 3: FAFASA completion rates by school poverty measure
	*
	*---------------------------------------------------------------------
			
	twoway (connected  submit_rate year if meps_poverty_pct_quart_2018 == 1)	///
			(connected  submit_rate year if meps_poverty_pct_quart_2018 == 2)	///
			(connected  submit_rate year if meps_poverty_pct_quart_2018 == 3)	///
			(connected  submit_rate year if meps_poverty_pct_quart_2018 == 4,  ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA submission rate") ///	
			legend(order(1 "≤ `p25'%" 2 "`p25'`endash'`p50'%" 3 "`p50'`endash'`p75'%" 4 "> `p75'%") rows(2)) ///
			plotregion(margin(t = 12)))	

	graph export "${vis_data}/summary_submit_by_meps.png", replace
	
	*---------------------------------------------------------------------
	*
	* Figure A.2: FAFASA submission rates by school poverty measure
	*
	*---------------------------------------------------------------------

	
	twoway (connected  complete_rate year if meps_poverty_pct_quart_2018 == 1)	///
			(connected  complete_rate year if meps_poverty_pct_quart_2018 == 2)	///
			(connected  complete_rate year if meps_poverty_pct_quart_2018 == 3)	///
			(connected  complete_rate year if meps_poverty_pct_quart_2018 == 4,  ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA completion rate") ///	
			legend(order(1 "≤ `p25'%" 2 "`p25'`endash'`p50'%" 3 "`p50'`endash'`p75'%" 4 "> `p75'%") rows(2)) ///
			plotregion(margin(t = 12)))

	graph export "${vis_data}/summary_complete_by_meps.png", replace
	
restore



*-----------------------------------------
*
* By Share of Black and Hispanic students
*
*-----------------------------------------

preserve

	sort ncessch_num  year 

	gen 	share_black_hisp			= share_black + share_hisp
	gen		share_black_hisp_2019		= share_black_hisp*100			if year == 2019
	
	by ncessch_num (year): carryforward share_black_hisp_2019, replace
	
	su		share_black_hisp_2019		, detail	
	
	
	local p25 = round(`r(p25)', 0.1)
	local p50 = round(`r(p50)', 0.1)
	local p75_1 = round(`r(p75)', 0.1)
	local p75 = substr("`p75_1'",1,4)
	
	di "`p25'%"
	di "`p50'%"
	di "`p75'%"

	xtile 	share_black_hisp_quart_2019 = share_black_hisp_2019			, nq(4)
	table 	share_black_hisp_quart_2019 year							, statistic(mean submit) statistic(mean complete) statistic(mean enrollment99)

	collapse (sum) submit  complete  enrollment99, by(share_black_hisp_quart_2019 	year)

	drop if share_black_hisp_quart_2019 == .

	sort year share_black_hisp
	bysort year: gen total_submit 		= sum(submit)	
	bysort year: gen total_complete 	= sum(complete)
	bysort year: gen total_enroll	 	= sum(enrollment)

	gen submit_rate		= submit/enrollment99	
	gen complete_rate	= complete/enrollment99

	*---------------------------------------------------------------------
	*
	* Figure 4: FAFASA completion rates by share of Black and Hispanic students
	*
	*---------------------------------------------------------------------
	
	twoway	(connected  submit_rate year if share_black_hisp_quart_2019 == 1)	///
			(connected  submit_rate year if share_black_hisp_quart_2019 == 2)	///
			(connected  submit_rate year if share_black_hisp_quart_2019 == 3)	///
			(connected  submit_rate year if share_black_hisp_quart_2019 == 4,  ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA submission rate") ///			
			legend(order(1 "≤ `p25'%" 2 "`p25'`endash'`p50'%" 3 "`p50'`endash'`p75'%" 4 "> `p75'%") rows(2)) ///
			plotregion(margin(t = 12)))

	graph export "${vis_data}/summary_submit_by_share_bkaa_hisp.png", replace

	*---------------------------------------------------------------------
	*
	* Figure A.3: FAFASA submission rates by share of Black and Hispanic students
	*
	*---------------------------------------------------------------------
	
	twoway	(connected  complete_rate year if share_black_hisp_quart_2019 == 1)	///
			(connected  complete_rate year if share_black_hisp_quart_2019 == 2)	///
			(connected  complete_rate year if share_black_hisp_quart_2019 == 3)	///
			(connected  complete_rate year if share_black_hisp_quart_2019 == 4,  ///
			xlabel(2019 "2018`endash'19" 2020 "2019`endash'20" 2021 "2020`endash'21" 2022 "2021`endash'22") ///
			xtitle("")	ytitle("FAFSA completion rate") ///			
			legend(order(1 "≤ `p25'%" 2 "`p25'`endash'`p50'%" 3 "`p50'`endash'`p75'%" 4 "> `p75'%") rows(2)) ///
			plotregion(margin(t = 12)))

	graph export "${vis_data}/summary_complete_by_share_bkaa_hisp.png", replace
	
restore

