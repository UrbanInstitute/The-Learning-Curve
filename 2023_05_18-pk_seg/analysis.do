*********************************
*** download data from portal ***
*********************************

// Main directory: Edit this to reflect where you want outputs saved
global main "*****"

global data "${main}/data"
global output "${data}/output"

cap n mkdir "${data}"
cap n mkdir "${output}"

cd ${data}

*We bring data from pre-K and first grade seperately from CCD school enrollment files by race

clear
educationdata using "school ccd enrollment race", sub(year=2007:2019 grade=-1) csv
save "${data}/pk", replace
clear
educationdata using "school ccd enrollment race", sub(year=2007:2019 grade=1) csv
save "${data}/first", replace


******************************************************************************
******************************************************************************
*************       SECTION 1: Data transformations       ********************
******************************************************************************
******************************************************************************



********************************
***   pre-K data organize    ***
********************************

use "${data}/pk", clear
keep if sex==99 
drop sex //do not use sex data therefore drop the variable here

**generate enrollment by race categories
sort year ncessch
reshape wide enrollment, i(ncessch_num year) j(race)
rename enrollment1 white
rename enrollment2 blk
rename enrollment3 hisp
rename enrollment4 asian
rename enrollment5 indian
rename enrollment6 hawa
rename enrollment7 more2 
rename enrollment9 unknown
rename enrollment99 tot

**if total enrollment is smaller than 2, replace values to missing. We do not include percentage enrolled by race to be skewed by programs that are very small, i.e. less than 2 students.

replace blk=. if tot<2
replace white=. if tot<2
replace asian=. if tot<2
replace hisp=. if tot<2
replace indian=. if tot<2
replace hawa=. if tot<2
replace more2=. if tot<2
replace tot = . if tot<2

** generate percentage of each racial category to total enrollment and time 100 to get percentage points.
gen perc_blk = blk/ tot*100
gen perc_white = white/ tot*100
gen perc_asian = asian/ tot*100
gen perc_hisp = hisp/ tot*100
gen perc_indian = indian/ tot*100
gen perc_hawa = hawa/ tot*100
gen perc_more2 = more2/ tot*100

** generate percentage of students that enroll in schools with 0-10% white students (one of our segregation measure)
gen white_0_10 =0
label variable white_0_10 "highly segregated schools with 0-10% white students"
replace white_0_10=1 if perc_white <=10 & tot>2

gen white_90_100 = 0 
label variable white_90_100 "highly segregated schools with 90-100% white students"
replace white_90_100=1 if perc_white >=90 & tot>2

gen blk_lowwhite = blk*white_0_10
label variable blk_lowwhite "number of black students in school with 0-10% white students"

gen hisp_lowwhite = hisp*white_0_10
label variable  hisp_lowwhite "number of hispanic students in school with 0-10% white students"

gen white_lowwhite = white*white_0_10
label variable  white_lowwhite "number of white students in school with 0-10% white students"

gen asian_lowwhite = asian*white_0_10
label variable asian_lowwhite "number of asian students in school with 0-10% white students"



** generate STATE total enrollment for overall, black, white, and hispanic students, and total students by racial group in segregated schools
bysort fips year: egen state_n_blk = total(blk)
bysort fips year: egen state_n_white = total (white)
bysort fips year: egen state_tot = total (tot)
bysort fips year: egen state_n_hisp = total(hisp)

bysort fips year: egen state_blk_lowwhite = total(blk_lowwhite)
bysort fips year: egen state_hisp_lowwhite = total (hisp_lowwhite)
bysort fips year: egen state_white_lowwhite = total (white_lowwhite)
bysort fips year: egen state_asian_lowwhite = total(asian_lowwhite)


*****************************************
***  generate pre-K exposure indices  ***
*****************************************

**generate black white (bw) exposure index
** link to the formula: https://www.dartmouth.edu/~segregation/IndicesofSegregation.pdf
sort year fips
by year fips: gen bw1 =(blk*white)/(state_n_blk*tot)
bysort fips year: egen state_pk_expo_bw =total(bw1)

**generate black hispanic (bh) exposure index

sort year fips
by year fips: gen bh1 =(blk*hisp)/(state_n_blk*tot)
bysort fips year: egen state_pk_expo_bh =total(bh1)

**generate hispanic black (hb) exposure index

sort year fips
by year fips: gen hb1 =(hisp*blk)/(state_n_hisp*tot)
bysort fips year: egen state_pk_expo_hb =total(hb1)


**generate hispanic white (hw) exposure index

sort year fips
by year fips: gen hw1 =(hisp*white)/(state_n_hisp*tot)
bysort fips year: egen state_pk_expo_hw =total(hw1)

**generate white black (wb) exposure index

sort year fips
by year fips: gen wb1 =(white*blk)/(state_n_white*tot)
bysort fips year: egen state_pk_expo_wb =total(wb1)

**generate white hispanic (wh) exposure index
sort year fips
by year fips: gen wh1 =(white*hisp)/(state_n_white*tot)
bysort fips year: egen state_pk_expo_wh =total(wh1)

**********************************
***collapse prek to state level***
**********************************
collapse (sum) tot blk hisp asian hawa white indian more2 (first) state_blk_lowwhite state_white_lowwhite state_hisp_lowwhite state_asian_lowwhite state_pk_expo_bh state_pk_expo_hb state_pk_expo_hw state_pk_expo_wb state_pk_expo_wh state_pk_expo_bw, by (year fips)

**generate state level enrollment percentage by racial group
gen pk_perc_blk = blk/ tot*100
gen pk_perc_white = white/ tot*100
gen pk_perc_asian = asian/ tot*100
gen pk_perc_hisp = hisp/ tot*100
gen pk_perc_indian = indian/ tot*100
gen pk_perc_hawa = hawa/ tot*100
gen pk_perc_more2 = more2/ tot*100

**generate state level enrollment by race in high segregation and low segregation schools
gen pk_perc_blk_lowwhite = state_blk_lowwhite/blk*100
gen pk_perc_white_lowwhite = state_white_lowwhite/white*100
gen pk_perc_hisp_lowwhite = state_hisp_lowwhite/hisp*100
gen pk_perc_asian_lowwhite = state_asian_lowwhite/asian*100


**rename the variable to indicate pre-K level data
rename tot pk_tot
rename blk pk_blk_tot
rename hisp pk_hisp_tot
rename asian pk_asian_tot
rename hawa pk_hawa_tot
rename white pk_white_tot
rename indian pk_indian_tot
rename more2 pk_more2_tot

**********************************
*** add means_tested variable***
**********************************
gen means_tested = . /*this variable aims to indicate which state are means tested between 2007-2019. //
1 means means-tested, 0 means no income requirement for enrollment during 2007-2019, and . indicate everything else (no program, program //
with eligibility changes, etc. during the period) */
replace means_tested = 0 if fips == 1 | fips == 11 | fips == 12 |fips == 13 | fips == 19| fips == 23 | fips == 25 | fips == 34 | fips == 35|fips == 36 |fip== 40 | fips == 50| fips == 54| fips == 55 

replace means_tested = 1 if fips == 4 | fips== 5 | fips == 8 | fips == 9 | ///
fip == 10 | fips == 17 | fips == 20 | fips == 21 | fips == 22 | fips == 24 ///
| fips == 27 | fips == 29 | fips == 31| fips == 32 | fips ==37 | fips == 39 | fips == 41|fips == 42| fips == 45| fips == 47 | fips == 48| fips == 51 | fips == 53

save "${data}/pk_bystate", replace

****************************************************************************
*** collapse prek indices by program type (weighted by state enrollment) ***
****************************************************************************
use "${data}/pk_bystate", clear
collapse (mean) pk_tot pk_blk_tot pk_hisp_tot pk_asian_tot pk_hawa_tot pk_white_tot pk_indian_tot pk_more2_tot state_pk_expo_bh state_pk_expo_hb state_pk_expo_hw state_pk_expo_wb state_pk_expo_wh state_pk_expo_bw pk_perc_blk_lowwhite pk_perc_white_lowwhite pk_perc_hisp_lowwhite pk_perc_asian_lowwhite [aweight=pk_tot], by(means_tested year)
save "${data}/pk_bytype", replace

********************************
*** 1st grade data organize  ***
********************************

//this is basically the same proceduce as the pre-K data organization
use "first", clear
keep if sex==99 
drop sex

**generate enrollment by race
sort year ncessch
reshape wide enrollment, i(ncessch_num year) j(race)
rename enrollment1 white
rename enrollment2 blk
rename enrollment3 hisp
rename enrollment4 asian
rename enrollment5 indian
rename enrollment6 hawa
rename enrollment7 more2 
rename enrollment9 unknown
rename enrollment99 tot


**if total enrollment is smaller than 2, replace values to missing
replace blk=. if tot<2
replace white=. if tot<2
replace asian=. if tot<2
replace hisp=. if tot<2
replace indian=. if tot<2
replace hawa=. if tot<2
replace more2=. if tot<2
replace tot = . if tot<2

** generate percentage of each racial category to total enrollment
gen perc_blk = blk/ tot*100
gen perc_white = white/ tot*100
gen perc_asian = asian/ tot*100
gen perc_hisp = hisp/ tot*100
gen perc_indian = indian/ tot*100
gen perc_hawa = hawa/ tot*100
gen perc_more2 = more2/ tot*100

** generate percentage of students that enroll in schools with 0-10% white students
gen white_0_10 =0
label variable white_0_10 "highly segregated schools with 0-10% white students"
replace white_0_10=1 if perc_white <=10 & tot>2

gen white_90_100 = 0 
label variable white_90_100 "highly segregated schools with 90-100% white students"
replace white_90_100=1 if perc_white >=90 & tot>2

gen blk_lowwhite = blk*white_0_10
label variable blk_lowwhite "number of black students in school with 0-10% white students"

gen hisp_lowwhite = hisp*white_0_10
label variable  hisp_lowwhite "number of hispanic students in school with 0-10% white students"

gen white_lowwhite = white*white_0_10
label variable  white_lowwhite "number of white students in school with 0-10% white students"

gen asian_lowwhite = asian*white_0_10
label variable asian_lowwhite "number of asian students in school with 0-10% white students"


** generate state total enrollment for overall, black, white, and hispanic students and students in segregated schools
bysort fips year: egen state_n_blk = total(blk)
bysort fips year: egen state_n_white = total (white)
bysort fips year: egen state_tot = total (tot)
bysort fips year: egen state_n_hisp = total(hisp)

bysort fips year: egen state_blk_lowwhite = total(blk_lowwhite)
bysort fips year: egen state_hisp_lowwhite = total (hisp_lowwhite)
bysort fips year: egen state_white_lowwhite = total (white_lowwhite)
bysort fips year: egen state_asian_lowwhite = total(asian_lowwhite)


********************************
***generate 1st grade indices***
********************************

**generate black white (bw) exposure index
** link to the formula: https://www.dartmouth.edu/~segregation/IndicesofSegregation.pdf
sort year fips
by year fips: gen bw1 =(blk*white)/(state_n_blk*tot)
bysort fips year: egen state_g1_expo_bw =total(bw1)

**generate black hispanic (bh) exposure index

sort year fips
by year fips: gen bh1 =(blk*hisp)/(state_n_blk*tot)
bysort fips year: egen state_g1_expo_bh =total(bh1)

**generate hispanic black (hb) exposure index

sort year fips
by year fips: gen hb1 =(hisp*blk)/(state_n_hisp*tot)
bysort fips year: egen state_g1_expo_hb =total(hb1)


**generate hispanic white (hw) exposure index

sort year fips
by year fips: gen hw1 =(hisp*white)/(state_n_hisp*tot)
bysort fips year: egen state_g1_expo_hw =total(hw1)

**generate white black (wb) exposure index

sort year fips
by year fips: gen wb1 =(white*blk)/(state_n_white*tot)
bysort fips year: egen state_g1_expo_wb =total(wb1)

**generate white black (wb) exposure index
sort year fips
by year fips: gen wh1 =(white*hisp)/(state_n_white*tot)
bysort fips year: egen state_g1_expo_wh =total(wh1)



***************************************
***collapse 1st grade to state level***
***************************************
collapse (sum) tot blk hisp asian hawa white indian more2 (first) state_blk_lowwhite state_white_lowwhite state_hisp_lowwhite state_asian_lowwhite state_g1_expo_bh state_g1_expo_hb state_g1_expo_hw state_g1_expo_wb state_g1_expo_wh state_g1_expo_bw, by (year fips)

**generate state level enrollment percentage by racial group
gen g1_perc_blk = blk/ tot*100
gen g1_perc_white = white/ tot*100
gen g1_perc_asian = asian/ tot*100
gen g1_perc_hisp = hisp/ tot*100
gen g1_perc_indian = indian/ tot*100
gen g1_perc_hawa = hawa/ tot*100
gen g1_perc_more2 = more2/ tot*100

**generate state level enrollment by race in high segregation and low segregation schools
gen g1_perc_blk_lowwhite = state_blk_lowwhite/blk*100
gen g1_perc_white_lowwhite = state_white_lowwhite/white*100
gen g1_perc_hisp_lowwhite = state_hisp_lowwhite/hisp*100
gen g1_perc_asian_lowwhite = state_asian_lowwhite/asian*100

**rename the variable to indicate pre-K level data
rename tot g1_tot
rename blk g1_blk_tot
rename hisp g1_hisp_tot
rename asian g1_asian_tot
rename hawa g1_hawa_tot
rename white g1_white_tot
rename indian g1_indian_tot
rename more2 g1_more2_tot

**********************************
*** add means_tested variable***
**********************************
gen means_tested = . /*this variable aims to indicate which state are means tested between 2007-2019. //
1 means means-tested, 0 means no income requirement for enrollment during 2007-2019, and . indicate everything else (no program, program //
with eligibility changes, etc. during the period) */
replace means_tested = 0 if fips == 1 | fips == 11 | fips == 12 |fips == 13 | fips == 19| fips == 23 | fips == 25 | fips == 34 | fips == 35|fips == 36 |fip== 40 | fips == 50| fips == 54| fips == 55 

replace means_tested = 1 if fips == 4 | fips== 5 | fips == 8 | fips == 9 | ///
fip == 10 | fips == 17 | fips == 20 | fips == 21 | fips == 22 | fips == 24 ///
| fips == 27 | fips == 29 | fips == 31| fips == 32 | fips ==37 | fips == 39 | fips == 41|fips == 42| fips == 45| fips == 47 | fips == 48| fips == 51 | fips == 53

save "${data}/g1_bystate", replace

**************************************************
*** merge state level 1st grade and pre-K data ***
**************************************************
use "${data}/g1_bystate", clear
merge 1:1 fips year using "pk_bystate"
drop if _merge !=3 //dropping cases with missing data
drop _merge
save "${data}/master_bystate", replace


****************************************************************************
*** collapse prek indices by program type (weighted by state enrollment) ***
****************************************************************************
use "${data}/g1_bystate", clear
collapse (mean) g1_tot g1_blk_tot g1_hisp_tot g1_asian_tot g1_hawa_tot g1_white_tot ///
g1_indian_tot g1_more2_tot state_g1_expo_bh state_g1_expo_hb state_g1_expo_hw ///
state_g1_expo_wb state_g1_expo_wh state_g1_expo_bw g1_perc_blk_lowwhite g1_perc_white_lowwhite g1_perc_hisp_lowwhite g1_perc_asian_lowwhite [aweight=g1_tot], by(means_tested year)
save "${data}/g1_bytype", replace



**********************************************************
*** merge program type 1st grade and pre-K level ***
**********************************************************
use "${data}/g1_bytype", clear
merge 1:1 year means_tested using "${data}/pk_bytype.dta"
save "${data}/master_bytype", replace


 ***************************************
 *** master_bytype data calculations ***
 ***************************************
 use "${data}/master_bytype", clear
 gen bw_dif = state_pk_expo_bw-state_g1_expo_bw
 gen hw_dif = state_pk_expo_hw-state_g1_expo_hw
 gen wb_dif = state_pk_expo_wb-state_g1_expo_wb
 gen wh_dif = state_pk_expo_wh-state_g1_expo_wh
 gen bh_dif = state_pk_expo_bh-state_g1_expo_bh
 gen hb_dif = state_pk_expo_hb-state_g1_expo_hb //this calculates the differences between pre-K and 1st grade exposure indices by state.
 
 gen dif_perc_blk_lowwhite = pk_perc_blk_lowwhite-g1_perc_blk_lowwhite
 gen dif_perc_white_lowwhite = pk_perc_white_lowwhite-g1_perc_white_lowwhite
 gen dif_perc_hisp_lowwhite = pk_perc_hisp_lowwhite-g1_perc_hisp_lowwhite
 gen dif_perc_asian_lowwhite = pk_perc_asian_lowwhite-g1_perc_asian_lowwhite //this calculate the differences in percentage of 
 //students in segregated schools between pre-K and 1st grade
 

drop _merge
sort means_tested year
drop if means_tested==.
 save "${data}/master_bytype", replace
 
 ******************************************************
 *** generate example states indices and differences***
 ******************************************************
 
 use "${data}/master_bystate", clear
 keep if fips == 40| fips==13 | fips== 37 | fips== 48
 gen bw_dif = state_pk_expo_bw-state_g1_expo_bw
 gen hw_dif = state_pk_expo_hw-state_g1_expo_hw
 gen wb_dif = state_pk_expo_wb-state_g1_expo_wb
 gen wh_dif = state_pk_expo_wh-state_g1_expo_wh
 gen bh_dif = state_pk_expo_bh-state_g1_expo_bh
 gen hb_dif = state_pk_expo_hb-state_g1_expo_hb //this calculates the differences between pre-K and 1st grade exposure indices in example states.
 
 save "${data}/example_states", replace
 
 

******************************************************************************
******************************************************************************
************     SECTION 2: DATA EXPORT, ANALYSIS, GRAPHS     ****************
******************************************************************************
******************************************************************************


****1. EXCEL SHEET 1: EXPORT DATASET TO EXCEL FOR AVERAGE EXPOSURE INDICES ACROSS TIME FRAME

**to get average index across the time period

use "${data}/master_bytype", clear
collapse (mean) state_pk_expo_bh state_pk_expo_hb state_pk_expo_hw state_pk_expo_wb ///
state_pk_expo_wh state_pk_expo_bw state_g1_expo_bh state_g1_expo_hb state_g1_expo_hw ///
 state_g1_expo_wb state_g1_expo_wh state_g1_expo_bw, by (means_tested) //to get yearly average data
drop if means_tested==.


rename *state_* ** 
rename pk_* *1
rename g1_* *2 //rename the variables to perform reshape
reshape long expo_bh expo_hb expo_hw expo_wb expo_wh expo_bw, i(means_tested) j(grade) //change the dataset from wide to long format

label define grade 1 "Pre-K" 2 "1st grade"
label values grade grade 

label define means_tested 1 "Means-tested" 0 "Open-enrollment"
label values means_tested means_tested

save "${data}/crossyear_indices", replace
export excel using "${output}/prek segregation analysis.xlsx", sheet("crossyear_indices") firstrow(variables) sheetreplace keepcellfmt



****2. EXCEL SHEET 2: EXPORT DATASET TO EXCEL FOR AVERAGE PERCENT ENROLLED IN SEGREGATED SCHOOLS ACROSS TIME FRAME

use "${data}/master_bytype", clear
collapse (mean) g1_perc_blk_lowwhite g1_perc_white_lowwhite g1_perc_hisp_lowwhite  pk_perc_blk_lowwhite pk_perc_white_lowwhite pk_perc_hisp_lowwhite, by (means_tested)
drop if means_tested==. //to get yearly average data

rename *_lowwhite *
rename pk_* *1
rename g1_* *2 //rename the variables to perform reshape
reshape long perc_blk perc_white perc_hisp, i(means_tested) j(grade) //change the dataset from wide to long format

label define grade 1 "Pre-K" 2 "1st grade"
label values grade grade 

label define means_tested 1 "Means-tested" 0 "Open-enrollment"
label values means_tested means_tested

save "${data}/crossyear_pctinseg", replace
export excel using "${output}/prek segregation analysis.xlsx", sheet("crossyear_pctinseg") firstrow(variables) sheetreplace keepcellfmt


****3. EXCEL SHEET 3: EXPORT DATASET TO EXCEL FOR EXAMPLE STATE DATASET
use "${data}/example_states", clear

collapse (mean) state_pk_expo_bh state_pk_expo_hb state_pk_expo_hw state_pk_expo_wb ///
state_pk_expo_wh state_pk_expo_bw state_g1_expo_bh state_g1_expo_hb state_g1_expo_hw ///
 state_g1_expo_wb state_g1_expo_wh state_g1_expo_bw g1_perc_blk_lowwhite g1_perc_white_lowwhite g1_perc_hisp_lowwhite  pk_perc_blk_lowwhite pk_perc_white_lowwhite pk_perc_hisp_lowwhite, by (fips)


rename *state_* ** 
rename *_lowwhite *
rename pk_* *1
rename g1_* *2 //rename the variables to perform reshape
reshape long expo_bh expo_hb expo_hw expo_wb expo_wh expo_bw perc_blk perc_white perc_hisp, i(fips) j(grade) //change the dataset from wide to long format

label define grade 1 "Pre-K" 2 "1st grade"
label values grade grade 

save "crossyear_egstates", replace
export excel using "${output}/prek segregation analysis.xlsx", sheet("crossyear_egstates") firstrow(variables) sheetreplace keepcellfmt



****4. EXCEL SHEET 4: EXPORT DATASET TO EXCEL FOR TRENDS DATA (IN APPENDIX)

use "${data}/master_bytype", clear
keep year means_tested bw_dif bw_dif hw_dif wb_dif wh_dif bh_dif hb_dif dif_perc_blk_lowwhite dif_perc_hisp_lowwhite //keep only the variables used

save "yearly_data", replace
export excel using "${output}/prek segregation analysis.xlsx", sheet("yearly_data") firstrow(variables) sheetreplace keepcellfmt


//the end
