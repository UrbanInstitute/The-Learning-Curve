**Tuition-to-Earnings Test for Short-Term Pell**


* Edit this line to be the directory where you want to save your inputs/outputs
global directory "C:/Users/lrestrepo/Documents/cohh_pell_code"


global data = "${directory}/data"
global raw_data = "${data}/raw_data"
global out_data = "${data}/output_data"
global int_data = "${data}/intermediate"
global vis = "${out_data}/vis"

foreach x in "${data}" "${out_data}" "${int_data}" "${raw_data}" "${vis}" {
	cap n mkdir "`x'"
}

cd "${directory}"

cap n ssc install libjson
cap n ssc install educationdata
cap n ssc install statastates

/*Before running the rest, please download a table from the following file location
https://apps.bea.gov/iTable/?reqid=70&step=1&acrdn=8#eyJhcHBpZCI6NzAsInN0ZXBzIjpbMSwyNCwyOSwyNSwzMSwyNiwyNywzMCwzMF0sImRhdGEiOltbIlRhYmxlSWQiLCIxMDEiXSxbIkNsYXNzaWZpY2F0aW9uIiwiTm9uLUluZHVzdHJ5Il0sWyJNYWpvcl9BcmVhIiwiMCJdLFsiU3RhdGUiLFsiMCJdXSxbIkFyZWEiLFsiWFgiXV0sWyJTdGF0aXN0aWMiLCIxIl0sWyJVbml0X29mX21lYXN1cmUiLCJMZXZlbHMiXSxbIlllYXIiLFsiMjAxOSJdXSxbIlllYXJCZWdpbiIsIi0xIl0sWyJZZWFyX0VuZCIsIi0xIl1dfQ==

The table should be called "Table1.csv". Move it from your downloads folder to the "data/raw_data" folder created in the directory you specified above, and rename it "state_price_parity.csv"

*/



******************************CLEAN DATA****************************************



**Clean IPEDS Awards Data for Use With GE Data**

******************************CLEAN DATA****************************************

cap n confirm file "${int_data}/ipeds_completions_clean_combined_17_18.dta"
if _rc == 601{
	


*IPEDS directory for opeid
educationdata using "college ipeds directory", sub(year==2018) csv clear
keep unitid year opeid inst_name region fips zip
save "${raw_data}/ipeds_directory_2018.dta", replace

educationdata using "college ipeds directory", sub(year==2017) csv clear
keep unitid year opeid inst_name region fips zip
append using "${raw_data}/ipeds_directory_2018.dta"

gen opeid6=substr(opeid, -8, 6) // 6-digit opeid
drop if opeid=="-2"

replace zip=substr(zip, -10, 5) if strlen(zip)>5 // 5-digit zip code

save "${int_data}/ipeds_directory_17_18.dta", replace


*IPEDS Completions
educationdata using "college ipeds completions-cip-6", sub(year=2018) csv clear
save "${raw_data}/ipeds_completions_2018.dta", replace

educationdata using "college ipeds completions-cip-6", sub(year=2017) csv clear
append using "${raw_data}/ipeds_completions_2018.dta"

keep if inlist(award_level, 1, 3) // drop non-certificates
drop if majornum==2 // drop second major
drop majornum


merge m:1 unitid year using "${int_data}/ipeds_directory_17_18.dta"
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

save "${int_data}/ipeds_completions_clean_combined_17_18.dta", replace
}


cap n copy "https://www2.ed.gov/policy/highered/reg/hearulemaking/2021/geinforattedata.xlsx" ///
	"${raw_data}/geinforattedata.xlsx"


*IPEDS tuition and directory data
clear
educationdata using "college ipeds program-year-tuition-cip", sub(year=2015) csv
save "${raw_data}/tuition_cip_2015.dta", replace

clear
educationdata using "college ipeds directory", sub(year==2015) csv
keep unitid opeid inst_name
save "${raw_data}/directory_2015.dta", replace

use "${raw_data}/directory_2015.dta", clear

gen opeid6=substr(opeid, 1, 6)
drop if opeid6=="-2"

merge 1:m unitid using "${raw_data}/tuition_cip_2015.dta"
keep if _merge==3
drop _merge

*Convert to 4-digit cip code
tostring(cipcode_6digit), gen(cip6)
replace cip6="0"+cip6 if strlen(cip6)==5
drop if strlen(cip6)!=6

gen cip4=substr(cip6, 1, 4)

*Check to see how tuition differs at the opeid6-cip4 level
duplicates tag opeid6 cip4, gen(dup_opeid_cip4)
duplicates tag opeid6 cip4 tuition_fees, gen(dup_opeid_cip4_tuition)
count if dup_opeid_cip4!=dup_opeid_cip4_tuition
drop dup_*


*Collapse to opeid6-cip4 level - options for tuition measures, none perfect
gen tuition_max=tuition_fees
collapse (mean) tuition_fees (max) tuition_max program_length_weeks, by(opeid6 cip4)

gen tuition_diff=tuition_max-tuition_fees
sum tuition_diff, d

save "${int_data}/tuition_opeid6_cip4.dta", replace


import delimited "${raw_data}/state_price_parity.csv", varnames(4) rowrange(4:56) clear
rename geoname state_nm
rename v3 price_parity
drop geofips
statastates, name(state_nm)
drop if _merge != 3
keep state_abbrev price_parity
rename state_abbrev state
save "${int_data}/state_price_parity.dta", replace


import excel "${raw_data}/geinforattedata.xlsx", sheet("Sheet1") firstrow clear
save "${int_data}/fsa_ge_data_updated.dta", replace


use "${int_data}/fsa_ge_data_updated.dta", clear

drop if state=="PR" // cannot use with price parity data


*Check to see how many certificate programs with earnings data also have opeid-cip combo at another credlev
duplicates tag opeid6 cipcode, gen(dup_opeid_cipcode)
tab dup_opeid_cipcode if credlev==1


*Only keep undergrad certificates with reported earnings data and no duplicates - if they have duplicates we can't know if we're matching tuition correctly because tuition data has no credential level indicated
keep if dup_opeid_cipcode==0 & credlev==1 & earn_ne_mdn_3yr<.
drop dup_opeid_cipcode


*Merge in IPEDS awards data
merge 1:1 opeid6 cipcode credlev using "${int_data}/ipeds_completions_clean_combined_17_18.dta"

tab _merge if credlev==1 & earn_ne_mdn_3yr<. // matched 85%
drop if _merge==2
drop _merge

rename cipcode cip4


*Merge in IPEDS tuition data
merge m:1 opeid6 cip4 using "${int_data}/tuition_opeid6_cip4.dta"

tab _merge if earn_ne_mdn_3yr<. // matched 68%
drop if _merge!=3
drop _merge


*Merge in state price parity data
merge m:1 state using "${int_data}/state_price_parity.dta"
drop _merge


*Indicators for control
gen public=control=="Public"
gen priv_np=control=="Private, nonprofit"
gen priv_fp=control=="Private, for-profit"


*2019 FPL = $12,490 --> 150% FPL = $18,735 https://aspe.hhs.gov/topics/poverty-economic-mobility/poverty-guidelines/prior-hhs-poverty-guidelines-federal-register-references/2019-poverty-guidelines

*Create adjusted earnings measure by state and var for 150% FPL
gen earn_ne_mdn_3yr_adj=earn_ne_mdn_3yr*(100/price_parity)
gen fpl_150=18735


*Create value added earnings to tuition ratio - as in R short-term pell proposal
gen value_added=earn_ne_mdn_3yr_adj-fpl_150
gen value_to_tuition=(value_added)/tuition_fees


*Set failing threshold at 100% as in R proposal
gen fail_value=value_to_tuition<1 if value_to_tuition<.
gen fail_value_50=value_to_tuition<(1/2) if value_to_tuition<.



**********************************ANALYSIS**************************************

*Stats before fig 1 - tuition and earnings avgs
sum tuition_fees earn_ne_mdn_3yr_adj value_added if fail_value<.



*Figure 1
putexcel set "${out_data}/short term pell figs.xlsx", sheet("Figure 1", replace) modify

putexcel A2="Pass"
putexcel A3="Fail"

putexcel B1="Private, for-profit"
putexcel C1="Private, nonprofit"
putexcel D1="Public"
putexcel E1="Total"

foreach c in priv_fp priv_np public {
	if "`c'"=="priv_fp" local col B
	if "`c'"=="priv_np" local col C
	if "`c'"=="public" local col D
	
	count if fail_value<. & `c'==1
	local tot=`r(N)'
	count if fail_value==0 & `c'==1
		putexcel `col'2=`r(N)'/`tot'
	count if fail_value==1 & `c'==1
		putexcel `col'3=`r(N)'/`tot'
}
count if fail_value<.
local tot=`r(N)'
count if fail_value==0
	putexcel E2=`r(N)'/`tot'
count if fail_value==1
	putexcel E3=`r(N)'/`tot'



*Stats in paragraph after fig 1
bysort control: sum tuition_fees earn_ne_mdn_3yr_adj if fail_value<. // avg tuition and earnings by sector

foreach cip in 1204 5108 5139 {
	tab fail_value if cip4=="`cip'" // program level pass/fail
	tab control if cip4=="`cip'" & fail_value<. // program level sector dist
}



*Table 1
putexcel set "${out_data}/short term pell figs.xlsx", sheet("Table 1", replace) modify

putexcel A1="Hypothetical tuition and fees"
putexcel B1="Share of programs with earnings below minimum"

local row=2
foreach t in 0 2000 4000 6000 8000 10000 {
	putexcel A`row'=`t'
	
	count if earn_ne_mdn_3yr_adj<.
	local tot=`r(N)'
	count if earn_ne_mdn_3yr_adj<(fpl_150+`t')
		putexcel B`row'=`r(N)'/`tot'
	
	local row=`row'+1
}



*Footnote - earnings under 150% FPL by sector
foreach c in priv_fp priv_np public {
	count if earn_ne_mdn_3yr_adj<. & `c'==1
	local tot=`r(N)'
	count if earn_ne_mdn_3yr_adj<fpl_150 & `c'==1
	di `r(N)'/`tot'
}



*Figure 2
putexcel set "${out_data}/short term pell figs.xlsx", sheet("Figure 2", replace) modify

putexcel A2="Female"
putexcel A3="Male"
putexcel A4="AIAN"
putexcel A5="Asian"
putexcel A6="Black"
putexcel A7="Hispanic"
putexcel A8="NHPI"
putexcel A9="White"
putexcel A10="Total"

putexcel B1="Share of awards at failing programs"

local row=2
foreach var in female male aian asian black hisp nhpi white total {
	sum awards_`var' if fail_value<.
	local tot=`r(sum)'
	sum awards_`var' if fail_value==1
		putexcel B`row'=`r(sum)'/`tot'
	
	local row=`row'+1
}



*Stats in paragraph after fig 2 - excludes cosmetology programs
foreach var in female male {
	sum awards_`var' if fail_value<. & cip4!="1204"
	local tot=`r(sum)'
	sum awards_`var' if fail_value==1 & cip4!="1204"
	di `r(sum)'/`tot'
}



*Stats in policy implication section - lower threshold
tab fail_value_50

foreach var in female male {
	sum awards_`var' if fail_value_50<.
	local tot=`r(sum)'
	sum awards_`var' if fail_value_50==1
	di `r(sum)'/`tot'
}



*Appendix footnote - program length dist
sum program_length_weeks, d


