**Clean IPEDS Awards Data for Use With GE Data**

******************************CLEAN DATA****************************************

*IPEDS directory for opeid
educationdata using "college ipeds directory", sub(year==2018) csv clear
keep unitid year opeid inst_name region fips zip
save "ipeds_directory_2018.dta", replace

educationdata using "college ipeds directory", sub(year==2017) csv clear
keep unitid year opeid inst_name region fips zip
append using "ipeds_directory_2018.dta"

gen opeid6=substr(opeid, -8, 6) // 6-digit opeid
drop if opeid=="-2"

replace zip=substr(zip, -10, 5) if strlen(zip)>5 // 5-digit zip code

save "${raw}/ipeds_directory_17_18.dta", replace


*IPEDS Completions
educationdata using "college ipeds completions-cip-6", sub(year=2018) csv clear
save "${raw}/ipeds_completions_2018.dta", replace

educationdata using "college ipeds completions-cip-6", sub(year=2017) csv clear
append using "ipeds_completions_2018.dta"

keep if inlist(award_level, 1, 3) // drop non-certificates
drop if majornum==2 // drop second major
drop majornum


merge m:1 unitid year using "${raw}/ipeds_directory_17_18.dta"
keep if _merge==3
drop _merge


*Align variables with GE data
gen credlev=.
replace credlev=1 if inlist(award_level, 1, 3)
drop award_level

tostring(cipcode_6digit), gen(cip6)
replace cip6="0"+cip6 if strlen(cip6)==5
drop if strlen(cip6)!=6

gen cipcode=substr(cip6, -6, 4) // 4-digit cip
drop cipcode_6digit cip6

rename awards_6digit awards


*Collapse awards to 4-digit level and combine years
collapse (sum) awards, by(opeid6 fips region zip cipcode credlev sex race)


*Reshape race and sex vars
reshape wide awards, i(opeid6 fips region zip cipcode credlev sex) j(race)
drop if opeid6==""

rename awards1 awards_white
rename awards2 awards_black
rename awards3 awards_hisp
rename awards4 awards_asian
rename awards5 awards_aian
rename awards6 awards_nhpi
rename awards7 awards_twomore
rename awards8 awards_nra
rename awards9 awards_unk
rename awards99 awards_total

reshape wide awards*, i(opeid6 fips region zip cipcode credlev) j(sex)

rename awards*99 awards*
rename awards_total1 awards_male
rename awards_total2 awards_female


destring zip, replace
collapse (sum) awards* (max) zip, by(opeid6 fips region cipcode credlev)
drop awards_*1 awards_*2

duplicates tag opeid6 cipcode credlev, gen(dup_opeid_cip_cred)
keep if dup_opeid_cip_cred==0 // 96%

save "${int}/ipeds_completions_clean_combined_17_18.dta", replace
