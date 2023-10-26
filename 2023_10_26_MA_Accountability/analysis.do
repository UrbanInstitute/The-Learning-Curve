** Cornyn MA Accountability Proposal Analysis **

// change line 4 to reflect the working directory for this file and 
glo main "*******"

cd "${main}"

glo data "${main}/data"
glo raw "${data}/raw"
glo int "${data}/intermediate"
glo fin "${data}/final"

foreach var in data raw int fin{
	cap n mkdir "${`var'}"
}

cd "${raw}"

cap n unzipfile "${main}/data.zip"
cd "${main}"

*IPEDS directory for state location
clear
cap n confirm file "${int}/ipeds_directory_15.dta"
if _rc == 601{
	educationdata using "college ipeds directory", sub(year=2015)
	keep unitid opeid inst_name state_abbr fips
	gen opeid6=substr(opeid, -8, 6) // 6-digit opeid
	drop if opeid=="-2"
	collapse (min) fips, by(opeid6)
	destring opeid6, replace
	save "${int}/ipeds_directory_15.dta", replace
}


****************************CLEAN SCORECARD DATA********************************


import delimited "${raw}/scorecard_program_042623.csv", clear
save "${int}/scorecard_program_042623.dta"


use "${int}/scorecard_program_042623.dta", clear


*Convert strings to numeric for debt, earnings, and repayment
destring ipeds* debt* earn* bbrr*, replace force


*Drop foreign
drop if control=="Foreign"


*Convert control from string to numeric
rename control control_old
gen control=1 if control_old=="Public"
replace control=2 if control_old=="Private, nonprofit"
replace control=3 if control_old=="Private, for-profit"
drop control_old

label define control_lbl 1 "Public" 2 "Private, nonprofit" 3 "Private, for-profit"
label values control control_lbl


*Collapse to OPEID-CIPCODE-CREDLEV level
collapse (mean) debt* earn* bbrr* (sum) ipeds*, by(opeid6 cipcode cipdesc control credlev creddesc) // debt, earnings, and repayment variables are reported at opeid level


*Indicators for control
gen public=control==1
gen priv_np=control==2
gen priv_fp=control==3


*Keep observations that have data on 4yr earnings
keep if earn_mdn_4yr<. & debt_all_stgp_eval_n<.


*Merge in state locations from IPEDS and BA earnings from ACS
merge m:1 opeid6 using "${int}/ipeds_directory_15.dta"
keep if _merge==3
drop _merge


rename fips statefip
merge m:1 statefip using "${raw}/acs_BA_earnings.dta"
drop if _merge==1
drop _merge
rename incwage incwage_state_mdn

tostring cipcode, gen(cip4)
replace cip4="0"+cip4 if strlen(cip4)==3
gen cip2=substr(cip4, 1, 2)
destring cip2, replace
drop cip4
merge m:1 statefip cip2 using "${raw}/acs_BA_earnings_field.dta"
keep if _merge==3
drop _merge
rename incwage incwage_field_mdn


*Keep only masters degrees
keep if credlev==5


*Variable for passing earnings test and alternative test by field
gen pass_earn=earn_mdn_4yr>=incwage_state_mdn
gen pass_earn_field=earn_mdn_4yr>=incwage_field_mdn if freq>=30 & freq<. // sample size min 30 in ACS

rename state_name state

******************************TABLES AND FIGURES********************************

*Figures 1 and 2
preserve
collapse (mean) pass_earn pass_earn_field earn_mdn_4yr (rawsum) debt_all_stgp_eval_n [fw=debt_all_stgp_eval_n], by(cipdesc)
gsort - debt_all_stgp_eval_n
keep if _n<=20
gsort - pass_earn
export excel using "${fin}/ba_earnings_threshold_figs.xlsx", sheet("Figures 1 and 2") sheetmodify firstrow(variables) keepcellfmt
restore



*Table 1
preserve
keep if pass_earn==0
collapse (mean) earn_mdn_4yr (rawsum) debt_all_stgp_eval_n [fw=debt_all_stgp_eval_n], by(cipdesc)
sum debt_all_stgp_eval_n
gen share=debt_all_stgp_eval_n/`r(sum)'
gsort - share
export excel using "${fin}/ba_earnings_threshold_figs.xlsx", sheet("Table 1") sheetmodify firstrow(variables) keepcellfmt
restore



*Table A.1
preserve
collapse (mean) incwage_state_mdn pass_earn [fw=debt_all_stgp_eval_n], by(state)
gsort - incwage_state_mdn
export excel using "${fin}/ba_earnings_threshold_figs.xlsx", sheet("Table A.1") sheetmodify firstrow(variables) keepcellfmt
restore



********************************STATS IN TEXT***********************************

*Share of failing programs - introduction
tab pass_earn [fw=debt_all_stgp_eval_n]
tab pass_earn // unweighted share in footnote


*Share of failing programs by sector - after table 1
tab pass_earn control [fw=debt_all_stgp_eval_n], col nofreq


*Share failing field-adjusted measure - before figure 2
tab pass_earn_field [fw=debt_all_stgp_eval_n]




