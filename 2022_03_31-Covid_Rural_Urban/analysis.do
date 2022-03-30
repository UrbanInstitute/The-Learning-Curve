clear
* CHANGE ONLY LINE 4 TO THE DIRECTORY OF INTEREST

global directory = "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_03_31-Covid_Rural_Urban"

cd "${directory}"

global data = "${directory}\data"
global output = "${data}\output_data"
global input = "${data}\input_data"
global vis = "${output}\vis"

cap n unzipfile "data.zip", replace

cap n mkdir "${output}"
cap n mkdir "${vis}"

// Setting the font
graph set window fontface "lato"

cd "${input}"

cap n copy "https://www.sluprime.org/s/PRiME-COVID-Content-Analysis.zip" "download.zip"
cap n unzipfile "download.zip"

! rename "PRiME COVID Content Analysis.csv" "prime_reopening_data.csv"

import delimited "prime_reopening_data.csv", clear
save "${output}\prime_reopening_data_2.dta", replace
merge 1:1 county_district_code using "${input}\crosswalk.dta"
save "${output}\prime_reopening_data_3.dta", replace


cd "${directory}"

*SAIPE data download
clear all
global state 29
educationdata using "district saipe", sub(fips=$state year=2018)
save "${output}\district saipe_2018.dta", replace //save SAIPE

clear
use "${output}\district saipe_2018.dta"
drop fips //drop state abbreviation variable
merge 1:1 leaid using "${output}\prime_reopening_data_3.dta", generate(_merge1) //merge with reopening data
save "${output}\saipe_2018_primereopening.dta", replace //save SAIPE+prime reopening data

clear
use "${output}\saipe_2018_primereopening.dta"

keep if _merge1==3 | _merge1==2
//merge1==3 are districts that are included in reopening sample
//merge1==2 are charter districts/buildings in STL and KC that do not appear in SAIPE data.

/*merge1==2 districts without SAIPE will receive SAIPE values that are equivalent to
St. Louis Public Schools and Kansas City Public Schools as students in each charter reside within those public school district boundaries. */

*for STL and KS districts without SAIPE values, copy and paste SLPS and KSPS SAIPE values

list est_population_5_17_poverty_pct if county_district_code==115115
//the poverty estimate for St. Louis area is 0.366904
gen est_pop_5_17_pv_pct_stl = 0.366904

list est_population_5_17_poverty_pct if county_district_code==48078
//the poverty estimate for Kansas City area is 0.274993
gen est_pop_5_17_pv_pct_kc = 0.274993 

//STL charters
replace est_population_5_17_poverty_pct = est_pop_5_17_pv_pct_stl if county_district_code == 115902 | county_district_code == 115906 | county_district_code == 115911 | county_district_code == 115923 | county_district_code == 115914 | county_district_code == 115930 | county_district_code == 115928 | county_district_code == 115913 | county_district_code == 115912 | county_district_code == 115924 | county_district_code == 115903 | county_district_code == 115926

//KC charters
replace est_population_5_17_poverty_pct = est_pop_5_17_pv_pct_kc if county_district_code == 48922 | county_district_code == 48926 | county_district_code == 48927 | county_district_code == 48913 | county_district_code == 48910 | county_district_code == 48901 | county_district_code == 48914 | county_district_code == 48928 | county_district_code == 48916 | county_district_code == 48905 | county_district_code == 48909 | county_district_code == 48924 | county_district_code == 48902 | county_district_code == 48918

save "${output}\saipe_prime_frl_enrollment_2018_2.dta", replace



********************************************************************************
***quintiles 
********************************************************************************

clear
use "${output}\saipe_prime_frl_enrollment_2018_2.dta"

encode instruction, generate(plan)
order plan, a(instruction)
sort district 
*plan = 4 = instruction 2 = distanced 
label define plan 4 "distanced only", modify
*plan = 2 = instruction 1,2 = in person distanced 
label define plan 2 "in-person, distanced", modify
*plan = 3 = instruction 1,2,3 = 
label define plan 3 "in-person, distanced, hybrid", modify
*plan = 1 = instruction 1 = in person
label define plan 1 "in-person only", modify
*plan = 5 = instruction 2,3 = 
label define plan 5 "distanced, hybrid", modify

*MIXED
replace plan = 99 if plan != 1 & plan != 4
label define plan 99 "mixed", modify


rename est_population_5_17_poverty_pct poverty_pct

save "${output}\saipe_prime_frl_enrollment_2018_3.dta", replace


********************************************************************************
*Combine urban & suburban / town & rural


clear
use "${output}\saipe_prime_frl_enrollment_2018_3.dta"

*Combine City+Suburb and Town+Rural
replace urbanicity = "CitySuburb" if urbanicity == "City"
replace urbanicity = "CitySuburb" if urbanicity == "Suburb"
replace urbanicity = "TownRural" if urbanicity == "Town"
replace urbanicity = "TownRural" if urbanicity == "Rural"

drop leaid district_id region
drop _merge
order county_district_code
drop firstday

save "${output}\saipe_prime_frl_enrollment_2018_4.dta", replace


********************************************************************************
*Clean up enrollment data

clear
use "${input}\enrollment.dta"

drop urbanicity
drop if year !=2021
drop year
destring leaid, replace
rename leaid county_district_code
drop graduates-frl_graduation_rate_7yr_cohort
order enrollment_grades_pk_12, after(enrollment_grades_k_12)
replace lunch_count_free_reduced_pct = lunch_count_free_reduced_pct/100
replace enrollment_asian_pct = enrollment_asian/enrollment_grades_pk_12
//There is an error from the original DESE datafile where n_Asian and %Asian are the same. Therefore, we're manually calculating the new %Asian by performing n_Asian divided by enrollment_grades_pk_12
replace enrollment_aapi_pct = enrollment_aapi_pct/100
replace enrollment_black_pct = enrollment_black_pct/100
replace enrollment_hispanic_pct = enrollment_hispanic_pct/100
replace enrollment_indian_pct = enrollment_indian_pct/100
replace enrollment_multiracial_pct = enrollment_multiracial_pct/100
replace enrollment_pacific_islander_pct = enrollment_pacific_islander_pct/100
replace enrollment_white_pct = enrollment_white_pct/100
replace ell_lep_students_enrolled_k_12_p = ell_lep_students_enrolled_k_12_p/100
replace ell_lep_students_enrolled_pk_pct = ell_lep_students_enrolled_pk_pct/100

generate enrollment_nonwhite_pct = 1-enrollment_white_pct
order enrollment_nonwhite_pct, after(enrollment_white_pct)

drop enroll_2019 enroll_category _merge

drop nonwhite_pct

drop transfers-longitude
drop district county county_name districtname rep_party sen_party other_pct ell_pct iep_pct 
drop enrollment
drop region1-region4
drop plan

save "${output}\enrollment_clean.dta", replace

********************************************************************************
*Merge with enrollment data

clear
use "${output}\enrollment_clean.dta"

merge 1:1 county_district_code using "${output}\saipe_prime_frl_enrollment_2018_4"
drop if _merge != 3
drop district
drop _merge

local variables "poverty_pct"
foreach v of local variables{
	xtile `v'_5 = `v' [aw=enrollment_grades_pk_12], nq(5)
	replace `v'_5 = 3 if `v'_5 == 4 | `v'_5 == 2
}
order poverty_pct_5, after(est_population_5_17_poverty)

save "${output}\data_clean.dta", replace
********************************************************************************

clear
use "${output}\data_clean.dta"

*rename question#s on the reopening profiles to relevant variable names
rename q22 food_distribution
rename q23 devices
rename q24 internet_provision
rename q25 typeofinternetaccess

format county_district_code %6.0f
gen str6 leaid2 = string(county_district_code,"%06.0f")
drop county_district_code
order leaid2

*SAIPE values for STL and KS charter schools have been manually copied and pasted from St. Louis Public Schools and Kansas City Public Schools rows because SAIPE values are not available for these charter schools


*Figure 1: Poverty in Missouri
//Missouri districts serving students with most severe poverty were most likely
//to serve non-white students

bysort poverty_pct_5: sum enrollment_nonwhite_pct enrollment_white_pct [aw=enrollment_grades_pk_12]

preserve 
	gen enrollment_nonwhite =  enrollment_total-enrollment_white
	collapse (mean) enrollment_nonwhite enrollment_white enrollment_total [aw=enrollment_grades_pk_12], by(poverty_pct_5)
	gen perc_nonwhite = enrollment_nonwhite/enrollment_total
	gen perc_white = enrollment_white/enrollment_total
	graph bar perc*, over(poverty_pct_5, label(labsize(vsmall)))  stack ///
		bar(1, color("22 150 210"))   bar(2, color("85 183 72")) bar(3, color("0 0 0")) ///
			title("" "") ///
			ylabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) ///
			ytitle("", size(small)) ///
			legend(order(1 "In Person Only" 2 "Distance Only" 3 "Mixed") region(lwidth(none)) position(6) cols(5)) ///
			graphregion(color(white)) bgcolor(white) 
	graph export "${vis}\fig_3.png", as(png) height(500) replace
restore


*Figure 2
//Urban and suburban students in Missouri are far more likely to be non-White
//than rural students

bysort urbanicity: sum enrollment_nonwhite_pct enrollment_white_pct [aw=enrollment_grades_pk_12]
preserve 
	keep if poverty_pct_5 == 1 | poverty_pct_5 == 5
	collapse (sum) enrl = enrollment_grades_pk_12 , by(plan urbanicity poverty_pct_5)
	by urbanicity poverty_pct_5, sort: egen totl_pln = sum(enrl)
	gen perc = enrl/totl_pln
	drop enrl totl_pln 
	reshape wide perc, i(poverty_pct_5 urbanicity) j(plan)
	gen Label = `""Lowest Poverty," "Urban""' if poverty_pct_5 == 1 & urbanicity == "CitySuburb"
	replace Label = `" "Lowest Poverty," "Rural" "' if poverty_pct_5 == 1 & urbanicity == "TownRural"
	replace Label = `""Highest Poverty," "Urban""' if poverty_pct_5 == 5 & urbanicity == "CitySuburb"
	replace Label = `""Highest Poverty," "Rural""' if poverty_pct_5 == 5 & urbanicity == "TownRural"
	list
	graph bar perc*, over(Label, label(labsize(vsmall)))  stack ///
		bar(1, color("22 150 210"))   bar(2, color("85 183 72")) bar(3, color("0 0 0")) ///
			title("" "") ///
			ylabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) ///
			ytitle("", size(small)) ///
			legend(order(1 "In Person Only" 2 "Distance Only" 3 "Mixed") region(lwidth(none)) position(6) cols(5)) ///
			graphregion(color(white)) bgcolor(white) 
	graph export "${vis}\fig_3.png", as(png) height(500) replace
restore

*Figure 3
//Almost all urban and suburban students in high-poverty districts learned remotely

preserve 
	keep if poverty_pct_5 == 1 | poverty_pct_5 == 5
	collapse (sum) enrl = enrollment_grades_pk_12 , by(plan urbanicity poverty_pct_5)
	by urbanicity poverty_pct_5, sort: egen totl_pln = sum(enrl)
	gen perc = enrl/totl_pln
	drop enrl totl_pln 
	reshape wide perc, i(poverty_pct_5 urbanicity) j(plan)
	gen Label = `""Lowest Poverty," "Urban""' if poverty_pct_5 == 1 & urbanicity == "CitySuburb"
	replace Label = `" "Lowest Poverty," "Rural" "' if poverty_pct_5 == 1 & urbanicity == "TownRural"
	replace Label = `""Highest Poverty," "Urban""' if poverty_pct_5 == 5 & urbanicity == "CitySuburb"
	replace Label = `""Highest Poverty," "Rural""' if poverty_pct_5 == 5 & urbanicity == "TownRural"
	list
	graph bar perc*, over(Label, label(labsize(vsmall)))  stack ///
		bar(1, color("22 150 210"))   bar(2, color("85 183 72")) bar(3, color("0 0 0")) ///
			title("" "") ///
			ylabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) ///
			ytitle("", size(small)) ///
			legend(order(1 "In Person Only" 2 "Distance Only" 3 "Mixed") region(lwidth(none)) position(6) cols(5)) ///
			graphregion(color(white)) bgcolor(white) 
	graph export "${vis}\fig_3.png", as(png) height(500) replace
   //in-person: in-person only
   //in-person, distanced: mixed
   //in-person, distanced, hybrid: mixed
   //distanced, hybrid: mixed
   //distanced: distanced only
restore
   
*Figure 4
//Urban and suburban districts were twice as likely to provide food access for students

bysort urbanicity: tab food_distribution if poverty_pct_5==5 [aw=enrollment_grades_pk_12]

preserve
	keep if poverty_pct_5 == 5
	collapse (sum) enrl = enrollment_grades_pk_12 , by(food_distribution urbanicity poverty_pct_5)
	by urbanicity poverty_pct_5, sort: egen totl_food = sum(enrl)
	gen perc = enrl/totl_food
	drop enrl totl_food 
	reshape wide perc, i(poverty_pct_5 urbanicity) j(food_distribution)
	gen Label = `""Lowest Poverty," "Urban""' if poverty_pct_5 == 1 & urbanicity == "CitySuburb"
	replace Label = `" "Lowest Poverty," "Rural" "' if poverty_pct_5 == 1 & urbanicity == "TownRural"
	replace Label = `""Highest Poverty," "Urban""' if poverty_pct_5 == 5 & urbanicity == "CitySuburb"
	replace Label = `""Highest Poverty," "Rural""' if poverty_pct_5 == 5 & urbanicity == "TownRural"
	list
	graph bar perc*, over(Label, label(labsize(vsmall)))  stack ///
		bar(1, color("22 150 210"))   bar(2, color("85 183 72")) ///
			title("" "") ///
			ylabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) ///
			ytitle("", size(small)) ///
			legend(order(1 "No Food" 2 "Food Offered") region(lwidth(none)) position(6) cols(5)) ///
			graphregion(color(white)) bgcolor(white) 
			graph export "${vis}\fig_4.png", as(png) height(500) replace
restore


*Figure 5
//Most urban and suburban districts offered both devices and internet whereas
//the majority of rural districts only offered devices

bysort urbanicity: tab devices internet_provision if poverty_pct_5==5 [aw=enrollment_grades_pk_12], cell
preserve
	keep if poverty_pct_5 == 5
	collapse (sum) enrl = enrollment_grades_pk_12 , by(devices internet_provision urbanicity poverty_pct_5)
	gen scaff = 1 if devices == 1 & internet_provision == 1
	replace scaff = 2 if devices == 0 & internet_provision == 1
	replace scaff = 3 if devices == 1 & internet_provision == 0
	replace scaff = 4 if devices == 0 & internet_provision == 0
	by urbanicity poverty_pct_5, sort: egen totl_int = sum(enrl)
	gen perc = enrl/totl_int
	drop enrl totl_int devices internet_provision
	reshape wide perc, i(poverty_pct_5 urbanicity) j(scaff)
	gen Label = `""Lowest Poverty," "Urban""' if poverty_pct_5 == 1 & urbanicity == "CitySuburb"
	replace Label = `" "Lowest Poverty," "Rural" "' if poverty_pct_5 == 1 & urbanicity == "TownRural"
	replace Label = `""Highest Poverty," "Urban""' if poverty_pct_5 == 5 & urbanicity == "CitySuburb"
	replace Label = `""Highest Poverty," "Rural""' if poverty_pct_5 == 5 & urbanicity == "TownRural"
	list
	graph bar perc*, over(Label, label(labsize(vsmall)))  stack ///
		bar(1, color("22 150 210"))   bar(2, color("85 183 72")) bar(3, color("0 0 0")) bar(4, color("253 191 17")) ///
			title("" "") ///
			ylabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) ///
			ytitle("", size(small)) ///
			legend(stack label(1 "Devices available," "Internet available") label(2 "No devices available," "Internet available") label(3 "Devices available," "No internet available") label(4 "No devices available," "No internet available") region	(lwidth(none)) position(3) cols(1)) ///
			graphregion(color(white)) bgcolor(white)
	graph export "${vis}\fig_5.png", as(png) height(500) replace
restore