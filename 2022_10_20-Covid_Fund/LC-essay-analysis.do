* RI COVID FUND ANALYSIS FOR LEARNING CURVE ESSAY
* Xiaoyang Ye
* Last modified: 09/19/2022

********************************************************************************
* PROJECT FOLDER SETUP
********************************************************************************

* PROJECT MASTER FOLDER - modify to local project folder
global base 	"C:/Users/lrestrepo/Documents/Github_repos/The-Learning-Curve/2022_10_20-Covid_Fund"


global data"${base}/data"
* PROJECT FOLDERS

global raw  	"${base}/original_data/"
global clean 	"${data}/clean_data/"
global results  "${data}/results/"

cd "${base}"

cap noisily unzipfile "${base}/original_data.zip"
cap n mkdir "${data}"
cap n mkdir "${clean}"
cap n mkdir "${results}"

cap n ssc install openall
cap n ssc install fre
cap n ssc install labutil
cap n ssc install ftools
cap n ssc install reghdfe

cd "${clean}"


graph set window fontface "Lato"

* BEGIN LOG FILE

cap log close
local logdate : di %tdCYND daily("$S_DATE", "DMY")
log using "${results}LC-essay-analysis-`logdate'.log", replace


********************************************************************************
* PART 1: INTAKE RI COVID FUND DATA
********************************************************************************

* Data source: https://gms.ride.ri.gov/Default.aspx
	* Last accessed: Feb 20, 2022
	* Included in the current file: 
		* ESSER 1 (mostly updated in Jan 2021)
		* ESSER 2 (mostly updated in Dec 2021 - Feb 2022)

/* get sheet information */

	import excel using "${raw}ESSER-from-RI-website.xlsx", describe

/* loop through each of the sheets */		

	forvalues sheet=1/`=r(N_worksheet)' {

		di "`sheet'"

		local sheetname=r(worksheet_`sheet')
	   

		import excel using "${raw}ESSER-from-RI-website.xlsx", sheet("`sheetname'") clear

		save "${clean}file_`sheetname'.dta", replace
	}	

	
/* clean data */

	forv i = 1/99 {

		capture confirm file "${clean}file_`i'.dta"
		
		if _rc == 0 {

		/* ESSER */
		
			use "${clean}file_`i'.dta", clear
			
			local esser_total = B[22]

			keep in 5/20
			cap drop L M N
			
			/* get sub function name and code */
			
			split A, gen(a) p("[" "]")
			drop A
		
			rename a1 function
			rename a2 function_code
		
			/* temp code for object */
			
			rename B N1
			rename C N2
			rename D N3
			rename E N4
			rename F N5
			rename G N6
			rename H N7
			rename I N8
			rename J N9
			rename K N10

			/* reshape data */
			
			reshape long N, i(function) j(order)

			/* object name and code */
			
			gen object = "PERSONNEL SERVICES - COMPENSATION"
			gen object_code = "51000"
			
			replace object = "PERSONNEL SERVICES - EMPLOYEE BENEFITS" if order == 2
			replace object = "PURCHASED PROFESSIONAL & TECHNICAL SERVICES" if order == 3
			replace object = "PURCHASED PROPERTY SERVICES	" if order == 4
			replace object = "OTHER PURCHASED SERVICES" if order == 5
			replace object = "SUPPLIES & MATERIALS" if order == 6
			replace object = "PROPERTY & EQUIPMENT" if order == 7
			replace object = "MISCELLANEOUS" if order == 8
			replace object = "INDIRECT COSTS" if order == 9
			replace object = "TOTALS BY SUB FUNCTION" if order == 10
			
			replace object_code = "52000" if order == 2
			replace object_code = "53000" if order == 3
			replace object_code = "54000" if order == 4
			replace object_code = "55000" if order == 5
			replace object_code = "56000" if order == 6
			replace object_code = "57000" if order == 7
			replace object_code = "58000" if order == 8
			replace object_code = "60000" if order == 9
			replace object_code = "0" if order == 10

			drop order
			
			/* grant amount $ */
			
			replace N = "0" if N == "N/A"
			replace N = subinstr(N, "$", "",.)
			replace N = subinstr(N, ",", "",.)
			
			/* total grant amount */
			
			gen total = `esser_total'
			
			/* id */
			
			gen id = `i'
			
			/* esser */
			
			gen esser = 1
			
			order id function function_code object object_code N total
	  
			tempfile tmp
			save `tmp.dta', replace

	 
		/* ESSER 2 */
		
			use "${clean}file_`i'.dta", clear
	  
			local esser_total = B[47]
		 
			keep in 30/45
			cap drop L M N
			
			/* get sub function name and code */
			
			split A, gen(a) p("[" "]")
			drop A
			
			rename a1 function
			rename a2 function_code
			
			/* temp code for object */
			
			rename B N1
			rename C N2
			rename D N3
			rename E N4
			rename F N5
			rename G N6
			rename H N7
			rename I N8
			rename J N9
			rename K N10
			
			/* reshape data */
			
			reshape long N, i(function) j(order)
			
			/* object name and code */
			
			gen object = "PERSONNEL SERVICES - COMPENSATION"
			gen object_code = "51000"
			
			replace object = "PERSONNEL SERVICES - EMPLOYEE BENEFITS" if order == 2
			replace object = "PURCHASED PROFESSIONAL & TECHNICAL SERVICES" if order == 3
			replace object = "PURCHASED PROPERTY SERVICES	" if order == 4
			replace object = "OTHER PURCHASED SERVICES" if order == 5
			replace object = "SUPPLIES & MATERIALS" if order == 6
			replace object = "PROPERTY & EQUIPMENT" if order == 7
			replace object = "MISCELLANEOUS" if order == 8
			replace object = "INDIRECT COSTS" if order == 9
			replace object = "TOTALS BY SUB FUNCTION" if order == 10
			
			replace object_code = "52000" if order == 2
			replace object_code = "53000" if order == 3
			replace object_code = "54000" if order == 4
			replace object_code = "55000" if order == 5
			replace object_code = "56000" if order == 6
			replace object_code = "57000" if order == 7
			replace object_code = "58000" if order == 8
			replace object_code = "60000" if order == 9
			replace object_code = "0" if order == 10

			drop order
			
			/* grant amount $ */
			
			replace N = "0" if N == "N/A"
			replace N = subinstr(N, "$", "",.)
			replace N = subinstr(N, ",", "",.)
			replace N = subinstr(N, " ", "",.)
					
			/* total grant amount */
			
			gen total = `esser_total'
			
			/* id */
			
			gen id = `i'
			
			/* esser */
			
			gen esser = 2
			
			order id function function_code object object_code N total

			append using `tmp.dta'
		
			save "${clean}file_`i'.dta", replace
		}
		
		else {
		}
	}


/* append all files */

	openall *

/* merge on district name using the temp code */

	preserve
		import excel using "${raw}ESSER-RI-district-code.xlsx", clear
			keep A B D
			rename A district_code
			rename B district
			rename D id
			
		tempfile tmp
		save `tmp.dta', replace
	restore

	mmerge id using `tmp.dta', t(n:1)
	drop _merge

/* clean grant amount $ */

	cap drop grant
	destring N, replace
	rename N grant
	/* save the clean file */

	sort id esser function_code object_code
	save "${clean}ri-esser.dta", replace

/* erase temp files */

	shell rm file*.dta

********************************************************************************
* PART 2: INTAKE RI DISTRICT DATA FROM URBAN INSTITUTE
********************************************************************************

* Data source: https://educationdata.urban.org/data-explorer
	* Last accessed: Nov 24, 2021

	//ssc install libjson
	//ssc install educationdata, replace

/* "district ccd directory" */
	
	/* This endpoint contains school district (local education agency identification)
	-level geographic and mailing information, agency type, highest and lowest 
	grades offered, special education students and English language learners, 
	and full-time equivalent teachers and other staff. */
	
	educationdata using "district ccd directory", clear /// 
			sub(fips=44 year=2020)
			
	/* state ID */
	
	split state_leaid, gen(tmp) p("-")
	rename tmp2 id
	destring id, replace
	
	/* keep variables to use */
	
	keep leaid year id lea_name urban_centric_locale number_of_schools enrollment /// 
		 teachers_total_fte school_staff_total_fte

	tempfile tmp1
	save `tmp1.dta', replace
	
/* "district ccd enrollment race" */
	/* This endpoint contains student membership data for each school district by grade and race. */

	educationdata using "district ccd enrollment race", clear /// 
			sub(fips=44 year=2020)
			
	collapse (sum) enrollment, by(race leaid)
	
	fre race
	
	/* total enrollment */
	
	gen tmp1 = enrollment if race == 99
	bysort leaid: egen total = total(tmp1)

	/* non white/Asian */
	
	gen tmp2 = enrollment if race != 1 & race!=4 & race!= 99
	bysort leaid: egen minority = total(tmp2)
	
	duplicates drop leaid, force
	
	/* minority share */
	
	gen minority_pct = minority/total
	
	sum minority_pct, d
	
	keep leaid minority_pct
	
	tempfile tmp2
	save `tmp2.dta', replace
	
/* "district ccd finance" */

	/* This endpoint contains district level finance data including revenues 
	from federal, state, and local governments and expenditures. */

	educationdata using "district ccd finance", clear /// 
				sub(fips=44 year=2017)
	
/* merge data */

	mmerge leaid using `tmp1.dta', t(1:1)
	
	mmerge leaid using `tmp2.dta', t(1:1)	
	
/* save data */

	save "${clean}ri-ccd.dta", replace		
				
/* merge ESSER and CCD data */

	use "${clean}ri-esser.dta", clear
	sort id esser function_code object_code
	
	mmerge id using "${clean}ri-ccd.dta", t(n:1)
	keep if _merge == 3
	drop _merge
	
	/* label function using funciton_code */
	
	destring function_code, replace
	
	labmask function_code, values(function)

/* save data for analysis */

	save "ri-analysis.dta", replace
	
********************************************************************************
* PART 3: ANALYSIS
********************************************************************************
	
*--------------------------------
* RQ1: State-level distribution
*--------------------------------

/* Distribution of state-level ESSER grant by function */

	use "ri-analysis.dta", clear

	tab function
	sort id function_code
		
	/* keep sub-total counts */
	
	keep if object_code == "0"
	
	/* by district*function total */
	
	bysort esser district function function_code: egen grant_2 = sum(grant)
		
	/* by function total */
	
	bysort esser function function_code: egen grant_3 = sum(grant_2)	
	
	*--------------------------------
	* Figure 1
	*--------------------------------
	
	preserve
		duplicates drop esser function, force
		
		/* total grant amount in esser 1 & 2 */
		
		bysort esser: egen total_3 = sum(grant_3)
		
		keep esser function function_code grant_3 total_3
		
		// data check: comapre with official report numbers
			// ESSER 1 (CARES) total: 37,562,805 		vs. 37,562,937	(from report)
			// ESSER 2 (CRRSA) total: 147,253,126		vs. 147,193,126	(from report)
		
		/* pct by function */
		
		gen pct = grant/total * 100
	
		bysort function_code function: sum(pct) if esser == 1
	
		bysort function_code: sum(pct) if esser == 2
	
		/* drop 0 in both waves */
		
		bysort function: egen tmp=sum(pct)
		drop if tmp == 0
		
		/* ESSER 1 & ESSER 2 graph */
		
		keep esser function_code pct
		
			/* reshape data */
		
			reshape wide pct, i(esser) j(function_code)
		
			/* label esser */
		
			label define esser 1 "ESSER 1 (CARES)" 2 "ESSER 2 (CRRSA)"
			label values esser esser
		
			/* graph */
			
			graph bar pct*, over(esser, label(labsize(vsmall))) stack /// 
					ylabel(#5, valuelabel nogrid angle(h) labsize(small)) /// 
					ytitle("% of expenditure", size(small)) /// 
					bar(1, color("22 150 210"))		bar(2, color("85 183 72"))		bar(3, color("0 0 0")) ///
					bar(4, color("210 210 210"))	bar(5, color("253 191 17"))		bar(6, color("236 0 139")) ///
					bar(7, color("92 88 89"))		bar(8, color("219 43 39")) bar(9, color("6 38 53")) ///
					bar(10, color("132 50 21"))   bar(11, color("53 53 53")) bar(12, color("53 17 35")) ///
					bar(13, color("26 46 25"))   bar(14, color("55 11 10")) ///
					legend(order(14 13 12 11 10 9 8 7 6 5 4 3 2 1) ///
						label(1 "Face-to-face teaching") ///
						label(2 "Classroom materials") ///
						label(3 "Pupil support") /// 
						label(4 "Teacher support") ///
						label(5 "Program support") ///
						label(6 "Assessments") /// 
						label(7 "Non-instructional pupil services") /// 
						label(8 "Facilities") ///
						label(9 "Business services") /// 							
						label(10 "Capital") ///
						label(11 "Out-of-district obligations") ///
						label(12 "School management") /// 
						label(13 "Program management") ///
						label(14 "District management") /// 							
						cols(1) position(3) size(small) /// 
						region(color(none))) ///
					graphregion(color(white)) bgcolor(none)					
	
			graph save "tmp.gph", replace
			graph export "${results}fig-1.png", replace	
			erase "tmp.gph"
		
		restore			

	/* overall distribution - slope graph */
	
	*--------------------------------
	* Figure 1 - v.2
	*--------------------------------
	
	preserve
		duplicates drop esser function, force
		
		bysort esser: egen total_3 = sum(grant_3)
		
		keep esser function function_code grant_3 total_3
			
		/* pct by function */
		
		gen pct = grant/total * 100
	
		bysort function_code function: sum(pct) if esser == 1
	
		bysort function_code: sum(pct) if esser == 2
	
		/* drop 0 in both waves */
		
		bysort function: egen tmp=sum(pct)
		drop if tmp == 0
		
		/* ESSER 1 & ESSER 2 graph - note: reverse i & j*/
		
		keep esser function_code pct
		
		/* label x axis */
		
		label define x 1 "ESSER 1" 2 "ESSER 2"
		label values esser x
		
		/* graph */
		
			tw 	(connect pct esser if function == 11, color("22 150 210"))	/// 1
				(connect pct esser if function == 12, color("85 183 72"))	/// 2 
				(connect pct esser if function == 21, color("0 0 0"))	/// 3
				(connect pct esser if function == 22, color("210 210 210"))	/// 4
				(connect pct esser if function == 23, color("253 191 17"))	/// 5
				(connect pct esser if function == 24, color("236 0 139"))	/// 6
				(connect pct esser if function == 31, color("92 88 89"))	/// 7
				(connect pct esser if function == 32, color("219 43 39"))	/// 8
				(connect pct esser if function == 33, color("6 38 53"))	/// 9			
				(connect pct esser if function == 42, color("132 50 21"))	/// 10
				(connect pct esser if function == 43, lcolor("53 53 53"))	/// 11
				(connect pct esser if function == 51, lcolor("53 17 35"))	/// 12
				(connect pct esser if function == 52, lcolor("26 46 25"))	/// 13
				(connect pct esser if function == 53, lcolor("55 11 10")	/// 14
					 ///
					ylabel(#5, valuelabel nogrid angle(h) labsize(small)) /// 
					xscale(range(0.5, 2.5)) /// 
					xlabel(1 2, valuelabel labsize(small)) /// 
					ytitle("% of expenditure", size(small)) /// 
					xtitle(" ") /// 
					legend(order(1 2 3 4 5 6 7 8 9 10 11 12 13 14) /// 
						label(1 "Face-to-face teaching") ///
						label(2 "Classroom materials") ///
						label(3 "Pupil support") /// 
						label(4 "Teacher support") ///
						label(5 "Program support") ///
						label(6 "Assessments") /// 
						label(7 "Non-instructional pupil services") /// 
						label(8 "Facilities") ///
						label(9 "Business services") /// 							
						label(10 "Capital") ///
						label(11 "Out-of-district obligations") ///
						label(12 "School management") /// 
						label(13 "Program management") ///
						label(14 "District management") /// 							
						cols(1) position(3) size(small) /// 
						region(color(none))) ///
					graphregion(color(white)) bgcolor(none))				
	
			graph save "tmp.gph", replace
			graph export "${results}fig-1-slope-a.png", replace	
			erase "tmp.gph"
			
		/* graph - by group */
		
		*--------------------------------
		* Figure 1 - v.3
		*--------------------------------
			
			/* create function groups */
			
			gen group = 1 
			replace group = 2 if inlist(function, 21, 22, 23, 24)
			replace group = 3 if inlist(function, 31, 32, 33)
			replace group = 4 if inlist(function, 41, 42, 43)
			replace group = 5 if inlist(function, 51, 52, 53)
			
			collapse (sum) pct, by(group esser)
			
			/* graph */
			
			tw 	(connect pct esser if group == 1, color("22 150 210")) /// 
				(connect pct esser if group == 2, color("85 183 72"))	/// 
				(connect pct esser if group == 3, color("0 0 0"))	/// 
				(connect pct esser if group == 4, color("210 210 210"))	/// 
				(connect pct esser if group == 5, color("253 191 17")	///
					ylabel(#5, valuelabel nogrid angle(h) labsize(small)) /// 
					xscale(range(0.5, 2.5)) /// 
					xlabel(1 2, valuelabel labsize(small)) /// 
					ytitle("% of expenditure", size(small)) /// 
					xtitle(" ") /// 
					legend(order(1 2 3 4 5) /// 
						label(1 "Classroom instruction") ///
						label(2 "Support services") ///
						label(3 "Facilities & operation") /// 
						label(4 "Capital & obligations") ///
						label(5 "Management") ///							
						cols(1) position(3) size(small) /// 
						region(color(none))) ///
					graphregion(color(white)) bgcolor(none))				
	
			graph save "tmp.gph", replace
			graph export "${results}fig-1-slope-b.png", replace	
			erase "tmp.gph"				
			
		restore			
		
							
*--------------------------------
* RQ2: Variation by district
*--------------------------------

	/* group function sub-groups */
	
	cap drop func_group
	gen func_group = 1
	replace func_group = 2 if inlist(function_code, 21, 22, 23, 24)
	replace func_group = 3 if inlist(function_code, 31, 32, 33, 34)
	replace func_group = 4 if inlist(function_code, 41, 42, 43, 44)
	replace func_group = 5 if inlist(function_code, 51, 52, 53)
		
	/* label groups */	
		
	label define group 1 "Classroom instruction" 2 "Support services" /// 
		  3 "Facilities & operation" 4 "Capital & obligations" 5 "Management"
	label values func_group group
	
	tab func_group
	
	/* by district*function group total */
	
	cap drop grant_2
	bysort esser district func_group: egen grant_2 = sum(grant)
			
	/* by district distribution */
	
		keep esser district func_group grant_2
		
		/* drop duplicates */
		
		duplicates drop esser district func_group, force
		
		/* by district total */
		
		cap drop grant_3
		bysort esser district: egen grant_3 = sum(grant_2)	
		
		/* pct by function */
		
		gen pct = grant_2/grant_3 * 100
		
		*--------------------------------
		* Figure 2 - A
		*--------------------------------
		
		/* ESSER 1 graph */
		
		preserve
			keep if esser == 1
			encode district, gen(district_code)
			keep district_code func_group pct
			reshape wide pct, i(district_code) j(func_group)
			
			gsort pct1 -pct4 pct2 pct3 pct5
			cap drop order
			gen order = _n
		
			graph bar pct*, over(order, label(labsize(vsmall))) stack /// 
					ylabel(#5, valuelabel nogrid angle(h) labsize(small)) /// 
					ytitle("% of expenditure", size(small)) ///
					b1title("Districts (ranked by ESSER 1 expenditure %)", size(small)) ///
					bar(1, color("22 150 210"))		bar(2, color("85 183 72"))		bar(3, color("0 0 0")) ///
					bar(4, color("210 210 210"))	bar(5, color("253 191 17"))	///
					legend(order(1 2 3 4 5) /// 
						label(1 "Classroom instruction") ///
						label(2 "Support services") ///
						label(3 "Facilities & operation") /// 
						label(4 "Capital & obligations") ///
						label(5 "Management") ///							
						cols(3) size(small) /// 
						region(color(none))) ///
					graphregion(color(white)) bgcolor(none)	
			
			graph save "tmp.gph", replace
			graph export "${results}fig-2a.png", replace	
			erase "tmp.gph"		
		restore			

		*--------------------------------
		* Figure 2 - B
		*--------------------------------
		
		/* ESSER 2 graph */
		
		preserve
			keep if esser == 2
			encode district, gen(district_code)
			keep district_code func_group pct
			reshape wide pct, i(district_code) j(func_group)
			
			gsort pct1 -pct4 pct2 pct3 pct5
			cap drop order
			gen order = _n
		
			graph bar pct*, over(order, label(labsize(vsmall))) stack ///
					bar(1, color("22 150 210"))		bar(2, color("85 183 72"))		bar(3, color("0 0 0")) ///
					bar(4, color("210 210 210"))	bar(5, color("253 191 17"))	///
					ylabel(#5, valuelabel nogrid angle(h) labsize(small)) /// 
					ytitle("% of expenditure", size(small)) /// 
					b1title("Districts (ranked by ESSER 2 expenditure %)", size(small)) /// 
					legend(order(1 2 3 4 5) /// 
						label(1 "Classroom instruction") ///
						label(2 "Support services") ///
						label(3 "Facilities & operation") /// 
						label(4 "Capital & obligations") ///
						label(5 "Management") ///							
						cols(3) size(small) /// 
						region(color(none))) ///
					graphregion(color(white)) bgcolor(none)	
			
			graph save "tmp.gph", replace
			graph export "${results}fig-2b.png", replace	
			erase "tmp.gph"	
		restore	
		
	
	/* correlation of ESSER 1 and ESSER 2 - focus on instructional*/		
		
	preserve
	
		use "ri-analysis.dta", clear

		tab function
		sort id function_code
			
		/* keep sub-total counts */
		
		keep if object_code == "0"
		
		/* by district*function total */
		
		bysort esser district function function_code: egen grant_2 = sum(grant)
			
		/* by function total */
		
		bysort esser function function_code: egen grant_3 = sum(grant_2)	
		
		/* group function sub-groups */
	
		cap drop func_group
		gen func_group = 1
		replace func_group = 2 if inlist(function_code, 21, 22, 23, 24)
		replace func_group = 3 if inlist(function_code, 31, 32, 33, 34)
		replace func_group = 4 if inlist(function_code, 41, 42, 43, 44)
		replace func_group = 5 if inlist(function_code, 51, 52, 53)
		
		/* pct by function */
		
		gen pct = grant/total * 100
		
		/* by group-district-esser */
		
		collapse (sum) pct, by(esser district func_group)
		
		/* reshape */
		
		egen group = group(esser district)
		
		reshape wide pct, i(group) j(func_group)
		
		drop group
		
		reshape wide pct*, i(district) j(esser)
		
		/* correlation between esser 1 and esser 2 */
		
		forv i = 1/5 {
			reg pct`i'2 pct`i'1, robust
			// 0.234 (p=0.03), 0.192 (p=0.13), 0.065 (p=0.32), -0.03 (p=0.47), 0.008 (p=0.91)
		}
		
			// these results are reported in footnote #10
	
	restore
			
********************************************************************************
* PART 3: VARIATION IN SCHOOL SPENDING & STUDENT TEST SCORES
********************************************************************************

*--------------------------------
* ESSER spending pattern
*--------------------------------

	/* ESSER 1 */
	
		keep if esser == 1
		
		keep district func_group pct
		reshape wide pct, i(district) j(func_group)
		
		mmerge district using "ri-analysis.dta", t(1:n)
		keep if _merge == 3
		
		duplicates drop district, force
		
		tab district
		
		/* % rev from federal, state, local */
		
		gen share_fed = rev_fed_total / rev_total * 100
		sum share_fed, d
		
		gen share_state = rev_state_total / rev_total * 100
		sum share_state, d
		
		gen share_local = rev_local_total / rev_total * 100
		sum share_local, d
		
		reg pct5 share_state, robust
		
		/* classroom teaching + instructional support */
		
		cap drop pct_teaching
		gen pct_teaching = pct1 + pct2
		
		/* keep data for RQ 3 analysis */
		
		keep district pct_teaching share_state share_fed share_local minority_pct
		
		save "tmp-ri-1.dta", replace


*----------------------------------------------
* Import raw data of RICAS (grades 3-8)
*----------------------------------------------

* Data source: https://www.ride.ri.gov/instructionassessment/assessment/assessmentresults.aspx
* Last accessed: August 10, 2022

/* import data */

	import excel using "${raw}RICAS.xlsx", clear first sheet("RICAS-ELA-17-21")
	tempfile tmp1
	save `tmp1.dat', replace

	import excel using "${raw}RICAS.xlsx", clear first sheet("RICAS-ELA-17-21-SES")
	tempfile tmp2
	save `tmp2.dat', replace

	import excel using "${raw}RICAS.xlsx", clear first sheet("RICAS-MATH-17-21")
	tempfile tmp3
	save `tmp3.dat', replace

	import excel using "${raw}RICAS.xlsx", clear first sheet("RICAS-MATH-17-21-SES")

	append using `tmp1.dta'
	append using `tmp2.dta'
	append using `tmp3.dta'

/* clean variables */

	gen subject = "ELA"
	replace subject = "MATH" if regexm(Subject, "Math")
	tab subject
	
	/* academic year in the fall */
	
	gen year = substr(School_Year, 1, 4)
	destring year, replace force
	tab year
	
	foreach i in Percent_of_Students_Tested 		/// 
				 Percent_Not_Meeting_Expectations 	/// 
				 Percent_Partially_Meeting_Expect 	/// 
				 Percent_Meeting_Expectations 		/// 
				 Percent_Exceeding_Expectations 	///
				 Percent_Meeting_or_Exceeding_Exp 	/// 
				 Scale_Score {
				 	
					destring `i', replace force
					
				 }
				 
	drop Subject School_Year School Grade
	order subject year
	
/* merge to main analysis file */
	
	gen district = District + " School District" if !regexm(District, "Charter")
	
	replace district = "Burrilville School District" 		 if district == "Burrillville School District"
	replace district = "Exeter W. Greenwich School District" if district == "Exeter-W. Greenw School District"
	replace district = "No. Kingstown School District" 		 if district == "North Kingstown School District"
	replace district = "No. Providence School District" 	 if district == "North Providence School District"
	replace district = "No. Smithfield School District" 	 if district == "North Smithfield School District"
	replace district = "So. Kingstown School District" 	     if district == "South Kingstown School District"	
	
	save "tmp-ri-2.dta", replace
	
	/* merge district indicators: (1) % on teaching (vs. compensate state loss) by function; 
								  (2) % on personnel by objective */
	
	mmerge district using "tmp-ri-1.dta", t(n:1)
	keep if _merge == 3 	// unmatched are charter schools
	drop _merge
	
	save "ri-analysis-2.dta", replace
	
	/* drop temp files */
	
	forv i = 1/2 {
		erase "tmp-ri-`i'.dta"
	}


*----------------------------------------------
* Analysis: DID
*----------------------------------------------

	use "ri-analysis-2.dta", clear

/* additional variables */	

	/* "treatment" variable */
	
	sum pct_teaching, d
	
	gen treat = pct_teaching >= 60		// median
	tab district if treat
	
	/* post variable */
	
	gen post = year > 2019
	
	gen yr1 = year == 2017
	gen yr2 = year == 2020
	
	/* treatment*post variable */
	
	gen treat_post = treat*post
	
	gen treat_yr1 = treat*yr1 
	gen treat_yr2 = treat*yr2
	
	/* time-varying baseline covs */
	
	foreach i in minority_pct share_state {
		gen linear_`i' = (year - 2017)*`i'
	}
	
	/* global of covs */
	
	global covs "Number_of_Students_Tested Percent_of_Students_Tested linear_*"
	
*--------------------------------
* Figure 3
*--------------------------------

/* estimates for graph */

	/* pooled DID */
	
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_post 					 /// 
			if District!="Statewide" & Group == "All Groups", 				 /// 
			cluster(district) a(district year subject)
			
	/* pooled DID - adding covs */
	
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_post $covs 				 /// 
			if District!="Statewide" & Group == "All Groups", 				 /// 
			cluster(district) a(district year subject)

	/* event study */
	
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_yr1 treat_yr2 $covs 		 /// 
			yr1 yr2															 /// 
			if District!="Statewide" & Group == "All Groups", 				 /// 
			cluster(district) a(district subject)
	
	/* event study: math -> DID estimates to figure 3.A */
	
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_yr1 treat_yr2 $covs 		 /// 
			yr1 yr2															 /// 
			if District!="Statewide" & Group == "All Groups" 				 ///
			& subject == "MATH", 											 /// 
			cluster(district) a(district subject)
	
	/* event study: ELA -> DID estimates to figure 3.B */
	
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_yr1 treat_yr2 $covs 		 /// 
			yr1 yr2															 /// 
			if District!="Statewide" & Group == "All Groups" 				 ///
			& subject == "ELA", 											 /// 		
			cluster(district) a(district subject)
			
/* figure 3.A: math */
	
	preserve
		keep if District!="Statewide" & Group == "All Groups" & subject == "MATH"
		
		/* raw averages */
		
		cap drop y
		gen y = Percent_Meeting_or_Exceeding_Exp
		
		collapse y, by(treat year)
		
		/* DID estimates */
		
		gen b = 0 if year == 2018
		replace b = -0.646 if year == 2017
		replace b = 3.560 if year == 2020
		
		gen se = . if year == 2018
		replace se = 0.967 if year == 2017
		replace se = 2.013 if year == 2020
		
		gen ul = b + 1.645*se
		gen ll = b - 1.645*se
		
		tw  (connect y year if treat == 0, color("0 0 0")) /// 
			(connect y year if treat == 1, color("22 150 210") msymbol(triangle)) /// 
			(bar b year if treat == 1, barwidth(0.25) color("253 191 17")) ///
			(rspike ul ll year if treat == 1, color("210 210 210") lp(dash) /// 
				ylabel(0(10)45)				/// 
				title("Math")				/// 
				ytitle("% Students meeting or exceeding expectations", size(small)) /// 
				xtitle("Academic year (fall)", size(small)) /// 
				ylabel(#5, valuelabel nogrid angle(h) labsize(small)) ///
				legend(order(1 2 3) /// 
					label(1 "Districts spending ESSER 1 < state median on instruction") ///
					label(2 "Districts spending ESSER 1 > state median on instruction") ///
					label(3 "Estimate from DID model with covariates (90% CI by dashed line)") ///							
					cols(1) size(small) /// 
					region(color(none))) ///
				graphregion(color(white)) bgcolor(none))
			
			graph save "tmp.gph", replace
			graph export "${results}fig-3a.png", replace	
			erase "tmp.gph"		
			
	restore 
	
/* figure 3.B: ELA */
	
	preserve
		keep if District!="Statewide" & Group == "All Groups" & subject == "ELA"
		
		/* raw averages */
		
		cap drop y
		gen y = Percent_Meeting_or_Exceeding_Exp
		
		collapse y, by(treat year)
		
		/* DID estimates */
		
		gen b = 0 if year == 2018
		replace b = 0.496 if year == 2017
		replace b = 2.613 if year == 2020
		
		gen se = . if year == 2018
		replace se = 1.535 if year == 2017
		replace se = 1.825 if year == 2020
		
		gen ul = b + 1.645*se
		gen ll = b - 1.645*se
		
		tw  (connect y year if treat == 0, color("22 150 210")) /// 
			(connect y year if treat == 1, color("0 0 0") msymbol(triangle)) /// 
			(bar b year if treat == 1, barwidth(0.25) color("253 191 17")) ///
			(rspike ul ll year if treat == 1, color("210 210 210") lp(dash) /// 
				ylabel(0(10)45)				/// 
				title("English Language Arts")				/// 
				ytitle("% Students meeting or exceeding expectations", size(small)) /// 
				xtitle("Academic year (fall)", size(small)) /// 
				ylabel(#5, valuelabel nogrid angle(h) labsize(small)) ///
				legend(order(1 2 3) /// 
					label(1 "Districts spending ESSER 1 < state median on instruction") ///
					label(2 "Districts spending ESSER 1 > state median on instruction") ///
					label(3 "Estimate from DID model with covariates (90% CI by dashed line)") ///							
					cols(1) size(small) /// 
					region(color(none))) ///
				graphregion(color(white)) bgcolor(none))
			
			graph save "tmp.gph", replace
			graph export "${results}fig-3b.png", replace	
			erase "tmp.gph"		
			
	restore 
	
*--------------------------------
* Figure 4
*--------------------------------

/* heterogeneous by SES */

	gen poor = Group == "Economically Disadvantaged"
	gen treat_poor = treat*poor 
	gen post_poor = post*poor 
	gen yr1_poor = yr1*poor 
	gen yr2_poor = yr2*poor 
	gen treat_post_poor = treat_post*poor
	gen treat_yr1_poor = treat_yr1*poor 
	gen treat_yr2_poor = treat_yr2*poor 
	
	egen district_by_poor = group(district poor)
	
/* estimates for graph */

	/* pooled DID */
	
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_post treat_post_poor 	 ///
			$covs poor treat_poor post_poor 								 /// 
			if District!="Statewide" & Group != "All Groups", 				 /// 
			cluster(district) a(district_by_poor year subject)

	/* event study */		
			
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_yr1* treat_yr2*			 /// 
			$covs poor treat_poor yr1_poor yr2_poor 						 /// 
			if District!="Statewide" & Group != "All Groups", 				 /// 
			cluster(district) a(district_by_poor year subject)	
			
	/* event study: math */		
			
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_yr1* treat_yr2*			 /// 
			$covs poor treat_poor yr1_poor yr2_poor 						 /// 
			if District!="Statewide" & Group != "All Groups" 				 ///
			& subject == "MATH", 											 /// 		 
			cluster(district) a(district_by_poor year subject)	
			
	lincom treat_yr2 + treat_yr2_poor
			
	/* event study: ELA */		
			
	reghdfe Percent_Meeting_or_Exceeding_Exp treat_yr1* treat_yr2*			 /// 
			$covs poor treat_poor yr1_poor yr2_poor 						 /// 
			if District!="Statewide" & Group != "All Groups" 				 ///
			& subject == "ELA", 											 /// 		
			cluster(district) a(district_by_poor year subject)				
			
	lincom treat_yr2 + treat_yr2_poor
	
/* graph: Math --- add DID estimates in figure notes */

	preserve
		keep if District!="Statewide" & Group != "All Groups" & subject == "MATH"
		
		/* raw averages */
		
		cap drop y
		gen y = Percent_Meeting_or_Exceeding_Exp
		
		collapse y, by(treat year poor)
		
		tw  (connect y year if treat == 0 & poor == 0, color("22 150 210")) /// 
			(connect y year if treat == 1 & poor == 0, color("0 0 0") msymbol(triangle)) /// 
			(connect y year if treat == 0 & poor == 1, color("22 150 210") lp(dash)) /// 
			(connect y year if treat == 1 & poor == 1, color("0 0 0") msymbol(triangle) lp(dash) /// 
				ylabel(0(10)50)				/// 
				title("Math")				/// 
				ytitle("% Students meeting or exceeding expectations", size(small)) /// 
				xtitle("Academic year (fall)", size(small)) /// 
				ylabel(#5, valuelabel nogrid angle(h) labsize(small)) ///
				legend(order(1 2 3 4) /// 
					label(1 "High-income students in districts spending ESSER 1 < state median on instruction") ///
					label(2 "High-income students in districts spending ESSER 1 > state median on instruction") ///
					label(3 "Low-income students in districts spending ESSER 1 < state median on instruction") ///
					label(4 "Low-income students in districts spending ESSER 1 > state median on instruction") ///						
					cols(1) size(small) /// 
					region(color(none))) ///
				graphregion(color(white)) bgcolor(none))
			
			graph save "tmp.gph", replace
			graph export "${results}fig-4a.png", replace	
			erase "tmp.gph"		
			
	restore 
	
/* graph: ELA --- add DID estimates in figure notes */

	preserve
		keep if District!="Statewide" & Group != "All Groups" & subject == "MATH"
		
		/* raw averages */
		
		cap drop y
		gen y = Percent_Meeting_or_Exceeding_Exp
		
		collapse y, by(treat year poor)
		
		tw  (connect y year if treat == 0 & poor == 0, color("22 150 210")) /// 
			(connect y year if treat == 1 & poor == 0, color("0 0 0") msymbol(triangle)) /// 
			(connect y year if treat == 0 & poor == 1, color("22 150 210") lp(dash)) /// 
			(connect y year if treat == 1 & poor == 1, color("0 0 0") msymbol(triangle) lp(dash) /// 
				ylabel(0(10)50)				/// 
				title("English Language Arts")				/// 
				ytitle("% Students meeting or exceeding expectations", size(small)) /// 
				xtitle("Academic year (fall)", size(small)) /// 
				ylabel(#5, valuelabel nogrid angle(h) labsize(small)) ///
				legend(order(1 2 3 4) /// 
					label(1 "High-income students in districts spending ESSER 1 < state median on instruction") ///
					label(2 "High-income students  in districts spending ESSER 1 > state median on instruction") ///
					label(3 "Low-income students in districts spending ESSER 1 < state median on instruction") ///
					label(4 "Low-income students in districts spending ESSER 1 > state median on instruction") ///						
					cols(1) size(small) /// 
					region(color(none))) ///
				graphregion(color(white)) bgcolor(none))
			
			graph save "tmp.gph", replace
			graph export "${results}fig-4b.png", replace	
			erase "tmp.gph"		
			
	restore 

********************************************************************************
* CLOSE PROJECT
********************************************************************************

* DROP TEMP DATA FILES

erase "ri-esser.dta"
erase "ri-ccd.dta"
erase "ri-analysis.dta"

* END LOG FILE

log close
