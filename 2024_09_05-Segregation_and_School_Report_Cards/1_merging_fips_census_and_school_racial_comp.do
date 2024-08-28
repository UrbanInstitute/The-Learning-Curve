**# merge county race data (census) to fips code, V0


clear 
clear all
// Change this line to reflect the current working directory of this code
glo wd "C:\Users\jcarter\Documents\git_repos\HB_729_code\code\"
glo data "${wd}data_files\"

cd "${data}"

//Private School Survey
cap n copy "https://nces.ed.gov/surveys/pss/zip/pss2122_pu_sas7bdat.zip" "${data}pss2122_pu_sas7bdat.zip"

cap n unzipfile "${wd}data_zips.zip"
cap n unzipfile "${data}pss2122_pu_sas7bdat.zip"
cd "${wd}"

use "${data}schoolcountyrace2.dta"
  
gen fipscode = state + county

destring fipscode, replace

ren B01001_001E county_totl
ren B03002_003E county_whit
ren B03002_004E county_bkaa
ren B03002_005E county_aian
ren B03002_006E county_asia
ren B03002_007E county_nhpi
ren B03002_008E county_othr
ren B03002_009E county_twom
ren B03002_012E county_hisp

save "${data}county race data with fips 6 29.dta", replace

// Private School Survey
import sas P305 P320 P330 P325 P316 P318 P310 P332 PPIN PINST PADDRS PCITY PSTABB PZIP PZIP4 PPHONE PCNTY PCNTY22 PCNTNM using "${data}pss2122_pu.sas7bdat", clear

keep if PSTABB == "NC"
rename P305 enrl_totl
rename P320 enrl_hisp
rename P330 enrl_whit
rename P325 enrl_bkaa
rename P316 enrl_asia
rename P318 enrl_nhpi
rename P310 enrl_aian
rename P332 enrl_twom

destring PCNTY, replace
gen fipscode = 37000 + PCNTY

merge m:1 fipscode using "${data}county race data with fips 6 29.dta"
drop if _merge == 2
drop _merge
gen new_id = PPIN
save "${data}private_school_nc2021.dta", replace


**# merge with school racial comp data from ccd
//start here for part 2

cap n ssc install educationdata

cap n confirm file "${data}school_racial_composition_data_2.dta"
if _rc == 601{
	clear
	educationdata using "school ccd enrollment race", sub(year=2021 grade=99 fips=37) // getting portal stuff
	
	preserve
	drop ncessch_num sex grade
	reshape wide enrollment, i(ncessch leaid year fips) j(race) // reshaping wide
	tostring fips, replace
	save "${data}school_enr_comp.dta", replace
	restore
	
	use "${data}ccd_2020_2021.dta", clear //Adding 2020 Geographies
	
	keep ncessch county_fips_geo fips
	gen fipscode = fips + county_fips_geo // fips code, county level
	keep if fips == "37"
	destring fips, replace
	
	merge 1:1 ncessch using "${data}school_enr_comp.dta", update // merging in enrollment data
	drop _merge
	
	preserve
	clear
	educationdata using "school ccd directory", sub(year=2021 fips=37) // retrieving school level characteristics
	keep if fips == 37
	keep ncessch *_cedp charter magnet seasch school_id lea_name
	save "${data}nc_dir_data.dta", replace
	restore
	
	preserve
	clear
	educationdata using "school nhgis census-2010", sub(year=2021 fips=37)
	keep ncessch year gleaid
	tostring ncessch, replace
	destring year, replace
	tempfile temp_x
	save "`temp_x'"
	restore
	
	merge 1:1 ncessch using "`temp_x'", nogen
	
	merge 1:1 ncessch using "${data}nc_dir_data.dta"
	drop if _merge == 2
	drop _merge
	
	
	save "${data}school_racial_composition_data_2.dta", replace
}

use "${data}school_racial_composition_data_2.dta", clear

drop if fipscode==""

destring fipscode, replace


merge m:1 fipscode using "${data}county race data with fips 6 29.dta"
drop _merge
//all matched, need to make sure not all missing
//all right looks good 

ren enrollment1 enrl_whit
ren enrollment2 enrl_bkaa
ren enrollment3 enrl_hisp
ren enrollment4 enrl_asia
ren enrollment5 enrl_aian
ren enrollment6 enrl_nhpi
ren enrollment7 enrl_twom
ren enrollment9 enrl_unkn
ren enrollment99 enrl_totl



label var county_whit "County demo: white"
label var county_bkaa "County demo: black or african american"
label var county_aian "County demo: american indian"
label var county_asia "County demo: asian"
label var county_nhpi "County demo: native hawaiian, pacific islander"
label var county_othr "County demo: other racial group"
label var county_hisp "County demo: hispanic"


keep ncessch seasch leaid NAME gleaid enrl_* county_* child_* county *_cedp charter magnet lea_name
ren NAME county_name

preserve
import excel using "${data}01a_school_grades.xlsx", sheet("SPG Data For Download") clear firstrow
keep school_code spg_grade spg_score subgroup
keep if subgroup == "ALL"

destring spg_score, replace

gen p1 = substr(school_code, 1, 3)
gen p2 = substr(school_code, 4, 3)
gen seasch = p1 + "-" + p2
drop p1 p2 school_code subgroup
tempfile temp_0
save "`temp_0'", replace
restore 

merge m:1 seasch using "`temp_0'", nogen

order ncessch leaid gleaid county* seasch *_cedp charter magnet spg_grade spg_score

// Recode school districts misclassified in the CCD
replace charter = 1 if leaid == "3700429"
replace charter = 2 if inlist(leaid, "3700320", "3700321", "3700419", "3700421", "3700427", "3700431","3700442", "3700443")
drop if charter == 3

gen new_id = ncessch

append using "${data}private_school_nc2021.dta", gen(private)

label define priv 0 "No" 1 "Yes"
label values priv private

replace charter = 2 if missing(charter)

**# save
save "${data}working_data_V0.dta", replace