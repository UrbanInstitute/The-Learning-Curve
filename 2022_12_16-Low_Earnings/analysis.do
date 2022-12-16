**Gainful Employment Low Earning Public Programs**

glo main "K:/EDP/EDP_shared/Scorecard Earnings/GE Data Work"

cd "${main}"

glo int "${main}/int_data"
glo raw "${main}/raw_data"
glo fin "${main}/fin_data"

cap n mkdir "${int}"
cap n mkdir "${fin}"

cap n unzipfile "${main}/raw_data.zip"

cd "K:\EDP\EDP_shared\Scorecard Earnings\GE Data Work"

******************************CLEAN DATA****************************************

*IPEDS directory for opeid

educationdata using "college ipeds directory", sub(year==2018) csv clear
keep unitid year opeid inst_name region fips zip
save "${int}/ipeds_directory_2018.dta", replace

educationdata using "college ipeds directory", sub(year==2017) csv clear
keep unitid year opeid inst_name region fips zip
append using "${int}/ipeds_directory_2018.dta"

gen opeid6=substr(opeid, -8, 6) // 6-digit opeid
drop if opeid=="-2"

replace zip=substr(zip, -10, 5) if strlen(zip)>5 // 5-digit zip code

save "${int}/ipeds_directory_17_18.dta", replace


*IPEDS Completions
educationdata using "college ipeds completions-cip-6", sub(year=2018) csv clear
save "${int}/ipeds_completions_2018.dta", replace

educationdata using "college ipeds completions-cip-6", sub(year=2017) csv clear
append using "${int}/ipeds_completions_2018.dta"

keep if inlist(award_level, 1, 3) // drop non-certificates
drop if majornum==2 // drop second major
drop majornum


merge m:1 unitid year using "${int}/ipeds_directory_17_18.dta"
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



*NHGIS data for household income by zip code

import delimited "${raw}/nhgis_hhinc_15_19.csv", clear

rename zcta5a zip
rename alw1e001 hh_inc_mdn

keep zip hh_inc_mdn

save "${int}/zip_hhinc_15_19.dta", replace


use "${raw}/fsa_ge_data_updated.dta", clear


keep if credlev==1 & earn_ne_mdn_3yr<.


*Merge in IPEDS awards data
merge 1:1 opeid6 cipcode credlev using "${int}/ipeds_completions_clean_combined_17_18.dta"

tab _merge if earn_ne_mdn_3yr<. // matched 84%
drop if _merge!=3
drop _merge


*Merge in NHGIS household income data
merge m:1 zip using "${int}/zip_hhinc_15_19.dta"

tab _merge if earn_ne_mdn_3yr<. // matched 97%
drop if _merge==2 // keep unmatched from GE data
drop _merge


*Indicators for control
gen public=control=="Public"
gen priv_np=control=="Private, nonprofit"
gen priv_fp=control=="Private, for-profit"


*Identify programs that fail the debt to earnings test
gen fail_debt=.
replace fail_debt=1 if annual_loan_payment_plus>earn_ne_mdn_3yr*0.08 & annual_loan_payment_plus>(earn_ne_mdn_3yr-18735)*0.2 & annual_loan_payment_plus<. // discretionary income is over 18735
replace fail_debt=0 if annual_loan_payment_plus<=earn_ne_mdn_3yr*0.08 | annual_loan_payment_plus<=(earn_ne_mdn_3yr-18735)*0.2


*Identify programs that fail the earnings test (median earnings less than the median HS grad)
gen fail_earnings=.
replace fail_earnings=1 if earn_ne_mdn_3yr<=state_mdincearn_lf
replace fail_earnings=0 if earn_ne_mdn_3yr>state_mdincearn_lf


*Identify programs that fail GE overall
gen fail_ge=fail_debt==1 | fail_earnings==1


*Awards shares
foreach var in white black hisp asian aian nhpi twomore nra unk male female {
	gen share_`var'_awards=awards_`var'/awards_total
}


*Indicator for southeast region
gen southeast=(region==5) if region<.



***********************************ANALYSIS*************************************

*Figure 1
preserve
keep if public==1 | priv_fp==1
collapse (mean) fail_ge, by(control)
export excel using "${fin}/public_low_earn_figs.xlsx", sheet("Figure 1") sheetmodify firstrow(variables) keepcellfmt
restore


preserve
use "${raw}/ge_data_2015_thirdway.dta", clear
gen control="Public" if regexm(InstitutionType, "PUBLIC")
replace control="Private, for-profit" if regexm(InstitutionType, "PROPRIETARY")
keep if NameofCredential=="01" & (control=="Public" | control=="Private, for-profit")
gen fail_ge_old=OfficialProgramPassZoneFail=="FAIL" | OfficialProgramPassZoneFail=="ZONE"
collapse (mean) fail_ge_old, by(control)
export excel using "${fin}/public_low_earn_figs.xlsx", sheet("Figure 1") sheetmodify cell(A6) firstrow(variables) keepcellfmt
restore



*Figure 2
preserve
keep if public==1
gen freq=1
collapse (sum) fail_earnings freq, by(cipcode ciptitle)
sort freq
gsort - fail_earnings
export excel using "${fin}/public_low_earn_figs.xlsx", sheet("Figure 2") sheetmodify firstrow(variables) keepcellfmt
restore



*Table 1
putexcel set "${fin}/public_low_earn_figs.xlsx", sheet("Table 1", replace) modify

putexcel B1="Failing programs at public institutions"
putexcel C1="All programs at public institutions"

putexcel A2="Median earnings"
putexcel A3="Median debt"
putexcel A4="Share white"
putexcel A5="Share Black"
putexcel A6="Share Hispanic"
putexcel A7="Share female"
putexcel A8="Share southeast"
putexcel A9="Median income in zip code"
putexcel A10="Number of programs"

local row=2
foreach var in earn_ne_mdn_3yr median_debt_plus share_white_awards share_black_awards share_hisp_awards share_female_awards southeast hh_inc_mdn {
	sum `var' if public==1 & fail_earnings==1
		putexcel B`row'=`r(mean)'
	sum `var' if public==1
		putexcel C`row'=`r(mean)'
		
	local row=`row'+1
}

count if public==1 & fail_earnings==1
	putexcel B10=`r(N)'
count if public==1
	putexcel C10=`r(N)'



*Table 2
putexcel set "${fin}/public_low_earn_figs.xlsx", sheet("Table 2", replace) modify

putexcel B1="Failing programs at public institutions"
putexcel C1="Failing programs at private, for-profit institutions"

putexcel A2="Median earnings"
putexcel A3="Median debt"
putexcel A4="Share white"
putexcel A5="Share Black"
putexcel A6="Share Hispanic"
putexcel A7="Share female"
putexcel A8="Share southeast"
putexcel A9="Median income in zip code"
putexcel A10="Share of programs in sector"

local row=2
foreach var in earn_ne_mdn_3yr median_debt_plus share_white_awards share_black_awards share_hisp_awards share_female_awards southeast hh_inc_mdn {
	sum `var' if public==1 & fail_earnings==1
		putexcel B`row'=`r(mean)'
	sum `var' if priv_fp==1 & fail_earnings==1
		putexcel C`row'=`r(mean)'
		
	local row=`row'+1
}

sum fail_earnings if public==1
	putexcel B10=`r(mean)'
sum fail_earnings if priv_fp==1
	putexcel C10=`r(mean)'



*Figure 3
preserve
keep if public==1 & fail_earnings==1
gen freq=1
collapse (sum) freq, by(cipcode ciptitle)
gsort - freq
export excel using "${fin}/public_low_earn_figs.xlsx", sheet("Figure 3") sheetmodify firstrow(variables) keepcellfmt
restore

preserve
keep if priv_fp==1 & fail_earnings==1
gen freq=1
collapse (sum) freq, by(cipcode ciptitle)
gsort - freq
export excel using "${fin}/public_low_earn_figs.xlsx", sheet("Figure 3") sheetmodify cell(G1) firstrow(variables) keepcellfmt
restore



*Table A.1
preserve
keep if public==1
gen freq=1
collapse (sum) fail_earnings freq, by(state)
export excel using "${fin}/public_low_earn_figs.xlsx", sheet("Table A.1") sheetmodify firstrow(variables) keepcellfmt
restore