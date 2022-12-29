// Specifying the directory where you saved this file; only thing you need to change
glo main "*********"

glo data "${main}/data"
glo zips "${data}/zips"
glo raw "${data}/raw"
glo int "${data}/int"
glo out "${data}/out"

foreach y in data zips raw int out{
	cap n mkdir "${`y'}"
}

cd "${main}"

cap n copy "https://www.federalreserve.gov/consumerscommunities/files/SHED_public_use_data_2019_(STATA).zip" "${zips}/data_2019.zip"
cap n copy "https://www.federalreserve.gov/consumerscommunities/files/SHED_public_use_data_2021_(STATA).zip" "${zips}/data_2021.zip"

cd "${raw}"

cap n unzipfile "${zips}/data_2019.zip"
cap n unzipfile "${zips}/data_2021.zip"

cd "${main}"

use "${raw}/public2019.dta", clear
gen year=2019
append using "${raw}/public2021.dta"
recode year (.=2021)

*Restrict to people with student debt held as student loans (exclude home equity, credit cards)
gen hasstuloan=(SL2_a==1)

gen loan_cat = 1 if (hasstuloan==1 & SL3>=1 & SL3<=2)
replace loan_cat = 2 if (hasstuloan==1 & SL3>=3 & SL3<=4)
replace loan_cat = 3 if (hasstuloan==1 & SL3>=5 & SL3<=6)
replace loan_cat = 4 if (hasstuloan==1 & SL3>=7 & SL3<=11)

lab def loan_cat 1 "Less than $10k" 2 "10-20k" 3 "20-30k" 4 "30k+"
lab val loan_cat loan_cat

gen inc_cat = 1 if (I40>=0 & I40<=3)
replace inc_cat = 2 if (I40>=4 & I40<=5)
replace inc_cat = 3 if (I40>=6 & I40<=7)
replace inc_cat = 4 if (I40>=8 & I40<=10)

lab def inc_cat 1 "Less than $25k" 2 "25-50k" 3 "50-100k" 4 "100k+"
lab val inc_cat inc_cat

gen race_cat = 1 if ppethm==2
replace race_cat = 2 if ppethm==4
replace race_cat = 3 if ppethm==1
replace race_cat = 4 if ppethm==3 | ppethm==5

lab def race_cat 1 "Black, non-Hispanic" 2 "Hispanic" 3 "White, non-Hispanic" 4 "2+ races or other"

lab val race_cat race_cat

gen ed_cat = 1 if ED0==3
replace ed_cat = 2 if ED0>=4 & ED0<=5
replace ed_cat = 3 if ED0>=6 & ED0<=9

lab def ed_cat 1 "Some college, no degree" 2 "Associate or certificate" 3 "Bachelor or more"
lab val ed_cat ed_cat

*Doing at least ok financially
gen atleastok = (B2>=3 & B2<=4)

*Doing better/worse than 2 years ago (only asked in 2021)
gen worse = (B4>=1 & B4<=2) if year==2021
gen same = (B4==3) if year==2021
gen better = (B4>=4 & B4<=5) if year==2021

*Doing better/wrose than 1 year ago (asked in 2021 and 2019)
gen worse1 = (B3>=1 & B3<=2) 
gen same1 = (B3==3) 
gen better1 = (B3>=4 & B3<=5) 

bys year: sum worse1 same1 better1 if hasstuloan==1 [aw=weight]

*Descriptives on student borrowers in 2021
preserve
keep if year==2021
gen income=I40
recode income (-1=.)
gen nocoll = (ED0>=1 & ED0<=2)
gen somecoll = (ED0==3)
gen aacert = (ED0>=4 & ED0<=5)
gen baplus = (ED0>=6 & ED0<=9)
gen black=(ppethm==2)
gen hisp=(ppethm==4)
gen white=(ppethm==1)
gen raceoth=(ppethm==3 | ppethm==5)
gen female=(ppgender==2)

collapse ppage nocoll somecoll aacert baplus black hisp white raceoth female (p50) income [pweight=weight], by(hasstuloan)
export excel using "${out}/descriptive", first(var) replace

*Restrict to people with student loans
restore
keep if hasstuloan==1
gen count=1
preserve

collapse atleastok worse same better (rawsum) count [pw=weight], by(year)
export excel using all, first(var) replace

foreach v in loan_cat ed_cat race_cat inc_cat {
restore
preserve
collapse atleastok worse same better (rawsum) count [pw=weight], by(year `v')
export excel using "${out}/`v'", first(var) replace
}