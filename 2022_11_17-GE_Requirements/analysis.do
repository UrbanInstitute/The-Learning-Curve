**Gainful Employment Tuition-to-Earnings Test**

cap n unzipfile "${main}/raw_data.zip"


******************************CLEAN DATA****************************************

clear 
*IPEDS tuition and directory data
educationdata using "college ipeds program-year-tuition-cip", sub(year=2015) csv
save "${raw}/tuition_cip_2015.dta", replace

clear
educationdata using "college ipeds directory", sub(year==2015) csv
keep unitid opeid inst_name
save "${raw}/directory_2015.dta", replace

use "${raw}/directory_2015.dta", clear

gen opeid6=substr(opeid, 1, 6)
drop if opeid6=="-2"

merge 1:m unitid using "${raw}/tuition_cip_2015.dta"
keep if _merge==3
drop _merge

*Convert to 4-digit cip code
tostring(cipcode_6digit), gen(cip6)
replace cip6="0"+cip6 if strlen(cip6)==5
drop if strlen(cip6)!=6

gen cip4=substr(cip6, 1, 4)

*Tuition per month variable
gen tuition_per_month=tuition_fees/average_length_months


*Collapse to opeid6-cip4 level - options for tuition measures, none perfect
gen tuition_max=tuition_fees
collapse (mean) tuition_fees tuition_per_month (max) tuition_max, by(opeid6 cip4) // 3 options for tuition measure

save "${int}/tuition_opeid6_cip4.dta", replace



import excel "${raw}/geinforattedata.xlsx", sheet("Sheet1") firstrow clear
save "${raw}/fsa_ge_data_updated.dta", replace
`'

use "${raw}/fsa_ge_data_updated.dta", clear


*Check to see how many certificate programs with earnings data also have opeid-cip combo at another credlev
duplicates tag opeid6 cipcode, gen(dup_opeid_cipcode)
tab dup_opeid_cipcode if credlev==1


*Only keep undergrad certificates with reported earnings data and no duplicates - if they have duplicates we can't know if we're matching tuition correctly because tuition data has no credential level indicated
keep if dup_opeid_cipcode==0 & credlev==1 & earn_ne_mdn_3yr<.
drop dup_opeid_cipcode


*Merge in IPEDS awards data
merge 1:1 opeid6 cipcode credlev using "${int}/ipeds_completions_clean_combined_17_18.dta"

tab _merge if credlev==1 & earn_ne_mdn_3yr<. // matched 85%
drop if _merge==2
drop _merge

rename cipcode cip4


*Merge in IPEDS tuition data
merge m:1 opeid6 cip4 using "${int}/tuition_opeid6_cip4.dta"

tab _merge if earn_ne_mdn_3yr<. // matched 67%
drop if _merge!=3
drop _merge


*Indicators for control
gen public=control=="Public"
gen priv_np=control=="Private, nonprofit"
gen priv_fp=control=="Private, for-profit"


*Create tuition to earnings ratio and set failing thresholds at 100%, 85%, and 70%
gen tuition_to_earnings=tuition_fees/earn_ne_mdn_3yr

gen fail_tuit_earn_100=.
replace fail_tuit_earn_100=1 if (tuition_to_earnings>=1 & tuition_to_earnings<.) | earn_ne_mdn_3yr==0
replace fail_tuit_earn_100=0 if tuition_to_earnings<1

foreach t in 85 70 {
	gen fail_tuit_earn_`t'=.
	replace fail_tuit_earn_`t'=1 if (tuition_to_earnings>=0.`t' & tuition_to_earnings<.) | earn_ne_mdn_3yr==0
	replace fail_tuit_earn_`t'=0 if tuition_to_earnings<0.`t'
}


*Identify programs that fail the debt to earnings test
gen fail_debt=.
replace fail_debt=1 if annual_loan_payment_plus>earn_ne_mdn_3yr*0.08 & annual_loan_payment_plus>(earn_ne_mdn_3yr-18735)*0.2 & annual_loan_payment_plus<. // discretionary income is over 18735
replace fail_debt=0 if annual_loan_payment_plus<=earn_ne_mdn_3yr*0.08 | annual_loan_payment_plus<=(earn_ne_mdn_3yr-18735)*0.2


*Indicator for $0 median loan payment
gen debt_0=.
replace debt_0=1 if annual_loan_payment_plus==0
replace debt_0=0 if annual_loan_payment_plus>0 & annual_loan_payment_plus<.


*Awards shares
foreach var in white black hisp asian aian nhpi twomore nra unk male female {
	gen share_`var'_awards=awards_`var'/awards_total
}



***************************TABLES AND FIGURES***********************************

*Figure 1
preserve
collapse (mean) fail_debt fail_tuit_earn_100 fail_tuit_earn_85 fail_tuit_earn_70
tempfile file
save `file'
restore

preserve
collapse (mean) fail_debt fail_tuit_earn_100 fail_tuit_earn_85 fail_tuit_earn_70, by(control)
append using `file'
export excel using "${fin}/tuit_earn_lc_figs_v2.xlsx", sheet("Figure 1") sheetmodify firstrow(variables) keepcellfmt
restore



*Stats in text after figure 1
sum earn_ne_mdn_3yr median_debt_plus tuition_fees if priv_np==1 & fail_tuit_earn_85==1 // avg earnings, debt, and tuition for nonprofits that fail 85% threshold



*Figure 2
preserve
keep if inlist(cip4, "5135", "5107", "5139", "5108", "1204")
gen freq=1
collapse (mean) fail_debt fail_tuit_earn_100 fail_tuit_earn_85 fail_tuit_earn_70 (sum) freq, by(ciptitle)
gsort - freq
drop freq
export excel using "${fin}/tuit_earn_lc_figs_v2.xlsx", sheet("Figure 2") sheetmodify firstrow(variables) keepcellfmt
restore



*Stats in text after figure 2
sum earn_ne_mdn_3yr median_debt_plus tuition_fees if inlist(cip4, "5135", "5107", "5139", "5108") & fail_tuit_earn_85==1 // avg earnings, debt, and tuition for largest failing programs excluding cosmetology

count
local tot=`r(N)'
count if fail_tuit_earn_85==1 & fail_debt==0
di `r(N)'/`tot' // share that fail tuition/earnings and pass debt/earnings

sum fail_tuit_earn_* if debt_0==1 // share of $0 debt programs that fail
sum earn_ne_mdn_3yr if debt_0==1 & fail_tuit_earn_85==1 // avg earnings for $0 debt programs that fail 85% threshold

sum share_black_awards share_hisp_awards share_female_awards if fail_debt==1 // awards by race and gender for programs failing debt/earnings
sum share_black_awards share_hisp_awards share_female_awards if fail_tuit_earn_85==1 // awards by race and gender for programs failing tuition/earnings



*Table A.1
preserve
collapse (mean) priv_fp public priv_np median_debt_plus earn_ne_mdn_3yr tuition_fees
export excel using "${fin}/tuit_earn_lc_figs_v2.xlsx", sheet("Table A.1") sheetmodify firstrow(variables) keepcellfmt
restore



*Figure A.1
preserve
gen freq=1
collapse (sum) freq, by(ciptitle)
gsort - freq
order ciptitle freq
export excel using "${fin}/tuit_earn_lc_figs_v2.xlsx", sheet("Figure A.1") sheetmodify firstrow(variables) keepcellfmt
restore



*Table A.2
putexcel set "${fin}/tuit_earn_lc_figs_v2.xlsx", sheet("Table A.2", replace) modify

putexcel B1="Debt/earnings"
putexcel C1=">100% tuition/earnings"
putexcel D1=">85% tuition/earnings"
putexcel E1=">70% tuition/earnings"

putexcel A2="Median debt"
putexcel A3="Median earnings"
putexcel A4="Tuition and fees"


local cell_letter=2
foreach var in fail_debt fail_tuit_earn_100 fail_tuit_earn_85 fail_tuit_earn_70 {
	excelcol `cell_letter'
	local col "`r(column)'"
	local row=2
	
	foreach stat in median_debt_plus earn_ne_mdn_3yr tuition_fees {
		sum `stat' if `var'==1
			putexcel `col'`row'=`r(mean)'
		local row=`row'+1
	}
	local cell_letter=`cell_letter'+1
}



*Endnote 14 - programs that pass tuition/earnings but fail debt/earnings
count
local tot=`r(N)'
count if fail_tuit_earn_85==0 & fail_debt==1
di `r(N)'/`tot' // share of programs in this group

sum earn_ne_mdn_3yr median_debt_plus tuition_fees if fail_tuit_earn_85==0 & fail_debt==1 // avg earnings, debt, and tuition for this group
sum median_debt_plus tuition_fees // avg debt and tuition for all programs

