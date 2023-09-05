*Avila-Acosta & Sorensen*
*Data for Occupational Employment and Wage Statistics 2017 obtained from the U.S. Bureau of Labor Statistics https://www.bls.gov/oes/tables.htm*

clear 

** Specify to current working directory
glo wd "**********"

glo raw_data "${wd}/raw_data"
glo out_data "${wd}/raw_data"
glo int_data "${wd}/int_data"


foreach var in raw_data out_data int_data{
	cap n mkdir "${`var'}"
}

cap n copy "https://www.bls.gov/oes/special-requests/oesm17st.zip" "${raw_data}/oes_data.zip"

cd "${wd}"

cap n unzipfile "${raw_data}/oes_data.zip"

import excel "oesm17st/state_M2017_dl.xlsx", sheet("state_dl") firstrow

/*OCC codes correspond to the following
19-3031 Clinical, Counseling, and School Psychologists
21-1012 Educational, Guidance, School, and Vocational Counselors
21-1021 Child, Family, and School Social Workers
29-2061 Licensed Practical and Licensed Vocational Nurses
33-3051 Police and Sheriff's Patrol Officers
33-9032 Security Guards
*/

/*Creating independent data files for each occupation relevant to our analysis.
Each data file keeps only the annual mean wage and is saved using occupation word*/
local occ_codes 19-3031 21-1012 21-1021 29-2061 33-3051 33-9032
local occ_word psy_sch couns_sch sw nurse_lic sro sg
local n: word count `occ_word'
forvalues i=1/`n'{
	local a: word `i' of `occ_codes'
	local b: word `i' of `occ_word'
	preserve
	keep if OCC_CODE=="`a'"
	keep ST A_MEAN 
	rename A_MEAN amean_`b'
	save `b'.dta, replace
	restore
}
clear 

/*Merging all occupations in the same file*/
local files psy_sch couns_sch sw nurse_lic sro sg
foreach file in `files'{
	if "`file'.dta"=="psy_sch.dta" use "`file'.dta"
	else merge 1:1 ST using "`file'.dta", nogen
}
save occ_annual_wages.dta, replace

/*Cleaning resulting dataset*/
local occ_word psy_sch couns_sch sw nurse_lic sro sg
foreach occ in `occ_word'{
	destring amean_`occ', gen(amean_`occ'_numeric) i("*")
}
save occ_annual_wages.dta,replace

** installing/updating Urban's Education Data Portal package to pull data directly from the web 

cap ssc install libjson
cap ssc install educationdata
cap ssc install estout

clear
educationdata using "school crdc teachers-staff", sub(year=2017)

keep leaid ncessch crdc_id counselors_fte security_guard_fte law_enforcement_fte psychologists_fte social_workers_fte nurses_fte fips
save support_staff.dta, replace

use support_staff.dta, clear
local names leaid counselors_fte security_guard_fte law_enforcement_fte psychologists_fte social_workers_fte nurses_fte fips

/*Dropping New York City Public Schools because of missing data for SROs (every school has missing data)
Dropping only for SROs as this is the main focus of our analysis*/

/*Dropping New York City Public Schools because of missing data for SROs (dropping student counts accordingly)*/
drop if inlist(leaid, "3600076", "3600077", "3600078", "3600079", "3600081")| ///
	inlist(leaid, "3600083", "3600084", "3600085", "3600086", "3600087")| ///
	inlist(leaid, "3600088", "3600090", "3600091", "3600092")| ///
	inlist(leaid, "3600094", "3600095", "3600096", "3600097", "3600098")| ///
	inlist(leaid, "3600099", "3600100", "3600101", "3600102", "3600103")| ///
	inlist(leaid, "3600119", "3600120", "3600121", "3600122")| ///
	inlist(leaid, "3600123", "3600135", "3600151", "3600152", "3600153")| ///
	inlist(crdc_id, "362058000102", "362058000103", "362058000107", "362058000110")| ///
	inlist(crdc_id, "362058000112", "362058000113", "362058006323", "362058099884")| ///
	inlist(crdc_id, "362058099885", "362058099886", "362058099941", "362058099965")| ///
	inlist(crdc_id, "362058099985")

// AM: destringing leaid

destring leaid, generate(leaid_num)

/*Recoding negative numbers to missing values*/
local personnel leaid_num counselors_fte security_guard_fte law_enforcement_fte psychologists_fte social_workers_fte nurses_fte
foreach var in `personnel'{
	gen `var'_n=`var'
	replace `var'_n=. if `var'<0
	egen st_`var'=total(`var'_n), by(fips) //replaced the by(lea_state) to by(fips) 
}

/*Creating state level dataset */
destring ncessch, gen(ncessch_num)
collapse (mean) st* (count) ncessch_num, by(fips)
rename fips ST 
tostring ST, generate(ST_new)

//AM - renaming state variables to match OCC data

// Alabama
replace ST_new = "AL" if ST == 1

// Alaska
replace ST_new = "AK" if ST == 2

// Arizona
replace ST_new = "AZ" if ST == 4

// Arkansas
replace ST_new = "AR" if ST == 5

// California
replace ST_new = "CA" if ST == 6

// Colorado
replace ST_new = "CO" if ST == 8

// Connecticut
replace ST_new = "CT" if ST == 9

// Delaware
replace ST_new = "DE" if ST == 10

// District of Columbia
replace ST_new = "DC" if ST == 11

// Florida
replace ST_new = "FL" if ST == 12

// Georgia
replace ST_new = "GA" if ST == 13

// Hawaii
replace ST_new = "HI" if ST == 15

// Idaho
replace ST_new = "ID" if ST == 16

// Illinois
replace ST_new = "IL" if ST == 17

// Indiana
replace ST_new = "IN" if ST == 18

// Iowa
replace ST_new = "IA" if ST == 19

// Kansas
replace ST_new = "KS" if ST == 20

// Kentucky
replace ST_new = "KY" if ST == 21

// Louisiana
replace ST_new = "LA" if ST == 22

// Maine
replace ST_new = "ME" if ST == 23

// Maryland
replace ST_new = "MD" if ST == 24

// Massachusetts
replace ST_new = "MA" if ST == 25

// Michigan
replace ST_new = "MI" if ST == 26

// Minnesota
replace ST_new = "MN" if ST == 27

// Mississippi
replace ST_new = "MS" if ST == 28

// Missouri
replace ST_new = "MO" if ST == 29

// Montana
replace ST_new = "MT" if ST == 30

// Nebraska
replace ST_new = "NE" if ST == 31

// Nevada
replace ST_new = "NV" if ST == 32

// New Hampshire
replace ST_new = "NH" if ST == 33

// New Jersey
replace ST_new = "NJ" if ST == 34

// New Mexico
replace ST_new = "NM" if ST == 35

// New York
replace ST_new = "NY" if ST == 36

// North Carolina
replace ST_new = "NC" if ST == 37

// North Dakota
replace ST_new = "ND" if ST == 38

// Ohio
replace ST_new = "OH" if ST == 39

// Oklahoma
replace ST_new = "OK" if ST == 40

// Oregon
replace ST_new = "OR" if ST == 41

// Pennsylvania
replace ST_new = "PA" if ST == 42

// Rhode Island
replace ST_new = "RI" if ST == 44

// South Carolina
replace ST_new = "SC" if ST == 45

// South Dakota
replace ST_new = "SD" if ST == 46

// Tennessee
replace ST_new = "TN" if ST == 47

// Texas
replace ST_new = "TX" if ST == 48

// Utah
replace ST_new = "UT" if ST == 49

// Vermont
replace ST_new = "VT" if ST == 50

// Virginia
replace ST_new = "VA" if ST == 51

// Washington
replace ST_new = "WA" if ST == 53

// West Virginia
replace ST_new = "WV" if ST == 54

// Wisconsin
replace ST_new = "WI" if ST == 55

// Wyoming
replace ST_new = "WY" if ST == 56

// Puerto Rico
replace ST_new = "PR" if ST == 72

drop ST
rename ST_new ST
sort ST
drop st_leaid_num
order ST st_counselors_fte st_law_enforcement_fte st_security_guard_fte st_nurses_fte st_psychologists_fte st_social_workers_fte ncessch_num
save school_support.dta,replace

// AM: pulling enrollment data from portal
clear
educationdata using "school crdc enrollment race sex", sub(year=2017) csv
keep if race == 99 & sex == 99 & disability == 99 & lep == 99
keep leaid ncessch crdc_id fips enrollment_crdc

/*Dropping New York City Public Schools because of missing data for SROs (dropping student counts accordingly)*/
drop if inlist(leaid, "3600076", "3600077", "3600078", "3600079", "3600081")| ///
	inlist(leaid, "3600083", "3600084", "3600085", "3600086", "3600087")| ///
	inlist(leaid, "3600088", "3600090", "3600091", "3600092")| ///
	inlist(leaid, "3600094", "3600095", "3600096", "3600097", "3600098")| ///
	inlist(leaid, "3600099", "3600100", "3600101", "3600102", "3600103")| ///
	inlist(leaid, "3600119", "3600120", "3600121", "3600122")| ///
	inlist(leaid, "3600123", "3600135", "3600151", "3600152", "3600153")| ///
	inlist(crdc_id, "362058000102", "362058000103", "362058000107", "362058000110")| ///
	inlist(crdc_id, "362058000112", "362058000113", "362058006323", "362058099884")| ///
	inlist(crdc_id, "362058099885", "362058099886", "362058099941", "362058099965")| ///
	inlist(crdc_id, "362058099985")

/*Recoding negative numbers to missing*/
replace enrollment_crdc=. if enrollment_crdc<0
egen st_enr=total(enrollment_crdc), by(fips)
gen schools = 1
collapse (mean) st_enr (sum) schools , by(fips leaid)
gen count = 1
collapse (mean) st_enr (sum) schools count, by(fips)
rename fips ST
save enrollment.dta, replace

//AM - renaming state variables to match OCC data
use enrollment.dta, clear
tostring ST, generate(ST_new)

// Alabama
replace ST_new = "AL" if ST == 1

// Alaska
replace ST_new = "AK" if ST == 2

// Arizona
replace ST_new = "AZ" if ST == 4

// Arkansas
replace ST_new = "AR" if ST == 5

// California
replace ST_new = "CA" if ST == 6

// Colorado
replace ST_new = "CO" if ST == 8

// Connecticut
replace ST_new = "CT" if ST == 9

// Delaware
replace ST_new = "DE" if ST == 10

// District of Columbia
replace ST_new = "DC" if ST == 11

// Florida
replace ST_new = "FL" if ST == 12

// Georgia
replace ST_new = "GA" if ST == 13

// Hawaii
replace ST_new = "HI" if ST == 15

// Idaho
replace ST_new = "ID" if ST == 16

// Illinois
replace ST_new = "IL" if ST == 17

// Indiana
replace ST_new = "IN" if ST == 18

// Iowa
replace ST_new = "IA" if ST == 19

// Kansas
replace ST_new = "KS" if ST == 20

// Kentucky
replace ST_new = "KY" if ST == 21

// Louisiana
replace ST_new = "LA" if ST == 22

// Maine
replace ST_new = "ME" if ST == 23

// Maryland
replace ST_new = "MD" if ST == 24

// Massachusetts
replace ST_new = "MA" if ST == 25

// Michigan
replace ST_new = "MI" if ST == 26

// Minnesota
replace ST_new = "MN" if ST == 27

// Mississippi
replace ST_new = "MS" if ST == 28

// Missouri
replace ST_new = "MO" if ST == 29

// Montana
replace ST_new = "MT" if ST == 30

// Nebraska
replace ST_new = "NE" if ST == 31

// Nevada
replace ST_new = "NV" if ST == 32

// New Hampshire
replace ST_new = "NH" if ST == 33

// New Jersey
replace ST_new = "NJ" if ST == 34

// New Mexico
replace ST_new = "NM" if ST == 35

// New York
replace ST_new = "NY" if ST == 36

// North Carolina
replace ST_new = "NC" if ST == 37

// North Dakota
replace ST_new = "ND" if ST == 38

// Ohio
replace ST_new = "OH" if ST == 39

// Oklahoma
replace ST_new = "OK" if ST == 40

// Oregon
replace ST_new = "OR" if ST == 41

// Pennsylvania
replace ST_new = "PA" if ST == 42

// Rhode Island
replace ST_new = "RI" if ST == 44

// South Carolina
replace ST_new = "SC" if ST == 45

// South Dakota
replace ST_new = "SD" if ST == 46

// Tennessee
replace ST_new = "TN" if ST == 47

// Texas
replace ST_new = "TX" if ST == 48

// Utah
replace ST_new = "UT" if ST == 49

// Vermont
replace ST_new = "VT" if ST == 50

// Virginia
replace ST_new = "VA" if ST == 51

// Washington
replace ST_new = "WA" if ST == 53

// West Virginia
replace ST_new = "WV" if ST == 54

// Wisconsin
replace ST_new = "WI" if ST == 55

// Wyoming
replace ST_new = "WY" if ST == 56

// Wyoming
replace ST_new = "PR" if ST == 72

drop ST
rename ST_new ST
sort ST

//rename enrollment_crdc 
save enrollment_2.dta, replace

/*Merging and cleaning three datasets to create final one*/
use enrollment_2.dta, clear
merge 1:1 ST using school_support.dta, nogen
merge 1:1 ST using occ_annual_wages.dta 

drop if _merge==2 //dropping territories (GU and VI)
drop _merge
drop if ST=="PR" //dropping Puerto Rico from our analysis, which only focuses on states 

/*Computing school personnel expenditure per state and nationally*/
local personnel ///
	st_counselors_fte 		st_law_enforcement_fte	st_security_guard_fte ///
	st_psychologists_fte	st_nurses_fte			st_social_workers_fte
local occ_word ///
	couns_sch	sro			sg ///
	psy_sch		nurse_lic 	sw  
local description `" "FTE counselors (school)" "FTE SROs" "FTE security guards" "FTE psychologists (school)" "FTE nurses (licensed)" "FTE social workers" "'
local n: word count `occ_word'
forvalues i=1/`n'{
	local a: word `i' of `personnel'
	local b: word `i' of `occ_word'
	local c: word `i' of `description'
	label var `a' "`c'"
	rename `a' st_`b' 
}

local personnel couns_sch sro sg nurse_lic psy_sch sw
foreach var in `personnel'{
	gen st_exp_`var'_salary=st_`var'*amean_`var'_numeric
	label var st_exp_`var'_salary "state expenditure on `var' salary"
	egen fed_avg_`var'_wage=mean(amean_`var'_numeric)
	label var fed_avg_`var'_wage "national average of `var' annual wages"
	replace st_exp_`var'_salary=st_`var'*fed_avg_`var'_wage if mi(st_exp_`var'_salary) //HI missing SRO wage/MS missing psy wage
	egen fed_exp_`var'_salary=total(st_exp_`var'_salary)
	label var fed_exp_`var'_salary "national expenditure on `var' salary"
	gen st_exp_`var'_benefits=st_exp_`var'_salary*(38/62)
	label var st_exp_`var'_benefits "state expenditure on `var' benefits"
	egen fed_exp_`var'_benefits=total(st_exp_`var'_benefits)
	label var fed_exp_`var'_benefits "national expenditure on `var' benefits"
	gen st_exp_`var'_total=st_exp_`var'_salary+st_exp_`var'_benefits
	label var st_exp_`var'_total "state expenditure on `var' salary & benefits"
	egen fed_exp_`var'_total=total(st_exp_`var'_total)
	label var fed_exp_`var'_total "national expenditure on `var' salary & benefits"
}

/*Generating additional variables for Table 1*/
local personnel sro couns_sch nurse_lic sg psy_sch sw
foreach var in `personnel'{
	egen fed_`var'=sum(st_`var')
	label var fed_`var' "FTE `var' national total"
	egen fed_avg_`var'_salben=mean(amean_`var'_numeric)
	replace fed_avg_`var'_salben=fed_avg_`var'_salben*100/62
	label var fed_avg_`var'_salben "national average of `var' annual salary & benefits"
}

*Table 1 arguments*
drop if ST == "72"
local personnel sro couns_sch nurse_lic sg psy_sch sw
foreach var in `personnel'{
	estpost sum fed_`var' fed_avg_`var'_wage fed_avg_`var'_salben fed_exp_`var'_total
	esttab using "table1.csv", cells ("mean") append
}

/*Calculating national expenditure for 24,900 SROs*/ 
di 58370.2*100/62*24900

/*Calculating per pupil expenditure on school personnel*/
local personnel couns_sch sro sg nurse_lic psy_sch sw
foreach var in `personnel'{
	gen st_exp_`var'_pp=st_exp_`var'_total/st_enr
}

*Table 2*
estpost sum st_exp_sro_pp st_exp_couns_sch_pp st_exp_nurse_lic_pp st_exp_sg_pp st_exp_psy_sch_pp st_exp_sw_pp if ST!="HI" & ST!="FL",de //excluding HI and FL for per-pupil calculations
esttab using "table2.csv", cells ("mean p50 sd min max") replace

*Table 3 arguments*
local personnel couns_sch sro sg nurse_lic psy_sch sw
foreach var in `personnel'{
	sort st_exp_`var'_pp 
	list ST st_exp_`var'_pp in f/10 if ST!="HI" & ST!="FL"
	list ST st_exp_`var'_pp in -10/l if ST!="HI" & ST!="FL"
}

*Appendix Table A2*
local personnel couns_sch sro sg nurse_lic psy_sch sw
foreach var in `personnel'{
	sort st_exp_`var'_pp 
	export excel ST st_exp_`var'_pp using "table3.xlsx" if ST!="HI" & ST!="FL", sheet("`var'",replace)
}

/*Calculating total US enrollment to create state weights by student population
and additional per pupil funding for SRO*/
egen fed_enr=total(st_enr)
gen st_weight=(st_enr/fed_enr)
gen add_st_sro=st_weight*(500000000) //Additional funding under SRO Act of 2022
gen st_exp_sro_post=st_exp_sro_total+add_st_sro
gen st_exp_sro_post_pp=st_exp_sro_post/st_enr
gen diff_1=st_exp_sro_post_pp-st_exp_sro_pp 
sum diff_1 if ST!="HI" & ST!="FL"
save enr_sup_wages.dta,replace