
graph set window fontface "Lato"

cap ssc install ciplot

clear

// Set working directory where you want outputs to be created
global directory = "C:/Users/lrestrepo/Documents/Sagen_code"

cd "${directory}"

global data = "${directory}/data"
global raw = "${data}/raw"
global output = "${data}/output_data"
global int = "${data}/intermediate"
global vis = "${output}/vis"

foreach x in "${data}" "${output}" "${int}" "${vis}" "${raw}" {
	cap n mkdir "`x'"
}


// CCD Requires enrollment and Directory data

// Downloading CCD Enrollment from Ed portal
cap n copy "https://educationdata.urban.org/csv/ccd/schools_ccd_enrollment_2017.csv" "${raw}/NCES_CCD_2017_school_level_composition.csv"
// Downloading CCD Enrollment from Ed portal
cap n copy "https://educationdata.urban.org/csv/ccd/schools_ccd_directory.csv" "${raw}/NCES_CCD_DIR.csv"

// Clean CCD; merge the two above after reshaping enrollments wide by race

import delimited "${raw}/NCES_CCD_2017_school_level_composition.csv", clear 

preserve
keep if sex  == 99 & grade == 99
tostring ncessch, gen(ncessch_2) format("%12.0f")
replace ncessch_2 = "0" + ncessch_2 if strlen(ncessch_2)==11
drop ncessch
ren ncessch_2 ncessch
reshape wide enrollment, i(ncessch year) j(race)
ren enrollment1 white
ren enrollment2 black
ren enrollment3 hispanic
ren enrollment4 asian
ren enrollment5 amerind
ren enrollment99 totstud
keep ncessch white black hispanic asian amerind totstud
save "${int}/ccd_enr_2017.dta", replace
restore

import delimited "${raw}/NCES_CCD_DIR.csv", clear

preserve
keep if year == 2017
tostring ncessch, gen(ncessch_2) format("%12.0f")
replace ncessch_2 = "0" + ncessch_2 if strlen(ncessch_2)==11
drop ncessch
ren ncessch_2 ncessch
keep ncessch leaid school_name free_or_reduced_price_lunch teachers_fte enrollment
tostring ncessch, replace
replace ncessch = "0" + ncessch if strlen(ncessch)==1
save "${int}/ccd_dir_2017.dta", replace
restore

preserve
use "${int}/ccd_dir_2017.dta", clear
merge 1:1 ncessch using "${int}/ccd_enr_2017.dta"
replace totstud = enrollment if missing(totstud)
drop enrollment
ren free_or_reduced_price_lunch frpl
ren teachers_fte fte
drop _merge
save "${int}/NCES CCD 2017 school-level composition.dta", replace
restore

// CRDC requires Staff and Directory Endpoints

// Downloading CRDC Staff from Ed portal
cap n copy "https://educationdata.urban.org/csv/crdc/schools_crdc_teacher" "${raw}/2017-18_CRDC_School_Support.csv"
// Downloading CRDC Directory
cap n copy "https://educationdata.urban.org/csv/crdc/schools_crdc_school_characteristics.csv" "${raw}/2017-18_CRDC_Directory.csv"


// Cleaning up CRDC
import delimited "${raw}/2017-18_CRDC_Directory.csv",clear

preserve
keep if year == 2017
keep crdc_id ncessch lea_name lea_state leaid_crdc schoolid_crdc school_name_crdc charter_crdc alt_school_focus
g jj = "Yes" if alt_school_focus == 2 | alt_school_focus == 3
drop alt_school_focus
save "${int}/crdc_dir.dta", replace
restore

import delimited "${raw}/2017-18_CRDC_School_Support.csv", clear

preserve
keep if year == 2017
keep crdc_id teachers_fte_crdc security_guard_fte law_enforcement_fte
save "${int}/crdc_staff.dta", replace
restore

preserve
use "${int}/crdc_dir.dta", clear
merge 1:1 crdc_id using "${int}/crdc_staff.dta"
replace ncessch = "0" + ncessch if strlen(ncessch)==11
ren teachers_fte_crdc sch_fteteach_tot
ren security_guard_fte sch_ftesecurity_gua
ren law_enforcement_fte sch_ftesecurity_leo
//keep if charter_crdc != 1
drop charter_crdc _merge
save "${int}/2017-18_CRDC_School_Support excluding charters.dta", replace
restore

// Downloading MEPS Data
cap n copy "https://educationdata.urban.org/csv/meps/schools_meps.csv" "${raw}/MEPS_raw.csv"

// Cleaning up MEPS
import delimited "${raw}/MEPS_raw.csv", clear

preserve
keep if year == 2017
tostring ncessch, gen(ncessch_2) format("%12.0f")
replace ncessch_2 = "0" + ncessch_2 if strlen(ncessch_2)==11
drop ncessch
ren ncessch_2 ncessch
save "${int}/MEPS data 2017.dta", replace
restore

* Coding 2018 CRDC data
use "${int}/2017-18_CRDC_School_Support excluding charters.dta", clear

rename jj juvfacility
rename sch_fteteach_tot fteteach
rename sch_ftesecurity_leo ftelawenforce
rename sch_ftesecurity_gua ftesecurity

replace fteteach = . if fteteach==-6
replace fteteach = . if fteteach==-5
replace ftelawenforce = . if ftelawenforce==-6
replace ftelawenforce = . if ftelawenforce==-5
replace ftesecurity = . if ftesecurity==-9
replace ftesecurity = . if ftesecurity==-6
replace ftesecurity = . if ftesecurity==-5

gen year=2017
tostring leaid, gen(leaidstr) format(%07.0f)
rename schoolid_crdc schid
tostring schid, gen(schidstr) format(%05.0f)
gen ncesalt = leaid+schidstr
duplicates tag ncessch year, gen(dup)
drop if missing(leaid)
destring ncesalt, replace
save "${int}/CRDC 2017.dta", replace
clear


*NCES school-level data
use "${int}/NCES CCD 2017 school-level composition.dta", clear
local vars "totstud frpl amerind asian hispanic black white fte"
foreach x of local vars {
destring `x', replace
}
gen total = totstud
gen pwhite = white/total
gen pblack = black/total
gen phisp = hisp/total
gen pamer = amer/total
gen pasian = asian/total
gen pfrl = frpl/total
replace pfrl= 1 if pfrl>1 & pfrl!=.
gen puptch = total/fte
gen year=2017
save "${int}/NCES 2017 school membership.dta", replace


use "${int}/NCES 2017 school membership.dta", clear
* link to NCES CCD school-level data
merge 1:m ncessch year using "${int}/CRDC 2017.dta"
tostring _merge, g(m1)
drop _merge
gen totalall = total
egen ftelawsec = rowtotal(ftelawenforce ftesecurity)
sum pblack phisp pamer pasian pwhite pfrl puptch fte fteteach ftelawenforce ftesecurity totalall

* merge MEPS data
merge m:1 ncessch year using "${int}/MEPS data 2017.dta"
tostring _merge, g(m2)
drop _merge
g merge_purity = m1 + "_" + m2
drop if ncessch == "" | missing(ncessch)

keep if ustrregexm(merge_purity,"^3_*")

// Talk to Jay about this: keeping only perfect matches
* keep if merge_purity == "3_3"

g count = 1
bys ncessch year: gen dups = _n

drop if dups>1

cap drop dups dup
duplicates tag ncessch year, gen(dup)

tab dup

gen fipst = substr(ncessch,1,2) 
//destring fipst, replace

local vars "pblack phisp pamer pasian pwhite puptch fte fteteach ftelawenforce ftesecurity totalall"
foreach x of local vars {
egen med`x' = median(`x') , by(year)
gen high`x' = (`x'>med`x') 
replace high`x' = . if `x' == . | m2 != "3"
egen quart`x' = cut(`x') if year==2017, group(4)
}

local vars "pfrl meps_poverty_pct meps_mod_poverty_pct"
foreach x of local vars {
egen med`x' = median(`x') , by(fipst year)
gen high`x' = (`x'>med`x') 
replace high`x' = . if `x' == . | m2 != "3"
}


local vars "ftelawenforce ftesecurity ftelawsec"
foreach x of local vars {
gen pp`x' = (`x'/totalall)
}

local vars "ftelawenforce ftesecurity ftelawsec"
foreach x of local vars {
gen any`x' = (`x'>0 & `x'!=.)
}

 
 
sum pwhite if year==2017 & pblack!=. & phisp!=. & ftelawenforce!=., d
sum pblack if year==2017 & phisp!=. & ftelawenforce!=., d
sum phisp if year==2017 & pblack!=. & ftelawenforce!=., d
sum pfrl if year==2017 & pblack!=. & ftelawenforce!=., d



* Any security officer by high proportion student race groups

gen pblackcat = .
replace pblackcat = 0 if pblack<.2
replace pblackcat = 1 if pblack>=.2 & pblack<.5
replace pblackcat = 2 if pblack>=.5 & pblack<.8
replace pblackcat = 3 if pblack>=.8 & pblack!=.
label define rcat4_1 0 "<20%" 1 "20-50%" 2 "50-80%" 3 ">80%"
label values pblackcat rcat4_1
tab pblackcat, m

gen phispcat = .
replace phispcat = 0 if phisp<.2
replace phispcat = 1 if phisp>=.2 & phisp<.5
replace phispcat = 2 if phisp>=.5 & phisp<.8
replace phispcat = 3 if phisp>=.8 & phisp!=.
label values phispcat rcat4_1
tab phispcat, m

gen pwhitecat = .
replace pwhitecat = 0 if pwhite<.2
replace pwhitecat = 1 if pwhite>=.2 & pwhite<.5
replace pwhitecat = 2 if pwhite>=.5 & pwhite<.8
replace pwhitecat = 3 if pwhite>=.8 & pwhite!=.
label values pwhitecat rcat4_1
tab pwhitecat, m

gen highprace = .
replace highprace = 0 if pblackcat==3
replace highprace = 1 if phispcat==3
replace highprace = 2 if pwhitecat==3
label define rcat3 0 "Black" 1 "Latinx" 2 "White"
label values highprace rcat3
tab highprace,m
*ciplot anyftesecurity [aw=totstud] if year==2018,  by(highprace) graphregion(color(white)) xlabel(, labsize(small)) xtitle("School Racial/Ethnic Composition") ytitle("Proportion Any Security Officer") saving(highprace, replace)
*graph export "G:\My Drive\Kidane and Rauscher\Security officer by high proportion student race weighted.png", as(png) replace

bysort highprace: sum anyftesecurity [aw=totstud]

* Using MEPS adjusted poverty rate data
* Any security officer by high proportion student race groups and income
gen pblackcatf = .
replace pblackcatf = 0 if pblack<.2 & highmeps_mod_poverty_pct==0
replace pblackcatf = 1 if pblack<.2 & highmeps_mod_poverty_pct==1
replace pblackcatf = 2 if pblack>=.2 & pblack<.5 & highmeps_mod_poverty_pct==0
replace pblackcatf = 3 if pblack>=.2 & pblack<.5 & highmeps_mod_poverty_pct==1
replace pblackcatf = 4 if pblack>=.5 & pblack<.8 & highmeps_mod_poverty_pct==0
replace pblackcatf = 5 if pblack>=.5 & pblack<.8 & highmeps_mod_poverty_pct==1
replace pblackcatf = 6 if pblack>=.8 & pblack!=. & highmeps_mod_poverty_pct==0
replace pblackcatf = 7 if pblack>=.8 & pblack!=. & highmeps_mod_poverty_pct==1
label define rcat8 0 "<20% High" 1 "<20% Low" 2 "20-50% High" 3 "20-50% Low" 4 "50-80% High" 5 "50-80% Low" 6 ">80% High" 7 ">80% Low"
label values pblackcatf rcat8
tab pblackcatf, m

gen phispcatf = .
replace phispcatf = 0 if phisp<.2 & highmeps_mod_poverty_pct==0
replace phispcatf = 1 if phisp<.2 & highmeps_mod_poverty_pct==1
replace phispcatf = 2 if phisp>=.2 & phisp<.5 & highmeps_mod_poverty_pct==0
replace phispcatf = 3 if phisp>=.2 & phisp<.5 & highmeps_mod_poverty_pct==1
replace phispcatf = 4 if phisp>=.5 & phisp<.8 & highmeps_mod_poverty_pct==0
replace phispcatf = 5 if phisp>=.5 & phisp<.8 & highmeps_mod_poverty_pct==1
replace phispcatf = 6 if phisp>=.8 & phisp!=. & highmeps_mod_poverty_pct==0
replace phispcatf = 7 if phisp>=.8 & phisp!=. & highmeps_mod_poverty_pct==1
label values phispcatf rcat8
tab phispcatf, m

gen pwhitecatf = .
replace pwhitecatf = 0 if pwhite<.2 & highmeps_mod_poverty_pct==0
replace pwhitecatf = 1 if pwhite<.2 & highmeps_mod_poverty_pct==1
replace pwhitecatf = 2 if pwhite>=.2 & pwhite<.5 & highmeps_mod_poverty_pct==0
replace pwhitecatf = 3 if pwhite>=.2 & pwhite<.5 & highmeps_mod_poverty_pct==1
replace pwhitecatf = 4 if pwhite>=.5 & pwhite<.8 & highmeps_mod_poverty_pct==0
replace pwhitecatf = 5 if pwhite>=.5 & pwhite<.8 & highmeps_mod_poverty_pct==1
replace pwhitecatf = 6 if pwhite>=.8 & pwhite!=. & highmeps_mod_poverty_pct==0
replace pwhitecatf = 7 if pwhite>=.8 & pwhite!=. & highmeps_mod_poverty_pct==1
label values pwhitecatf rcat8
tab pwhitecatf, m

gen highprace_inc = .
replace highprace_inc = 0 if pblackcatf==6
replace highprace_inc = 1 if pblackcatf==7
replace highprace_inc = 2 if phispcatf==6
replace highprace_inc = 3 if phispcatf==7
replace highprace_inc = 4 if pwhitecatf==6
replace highprace_inc = 5 if pwhitecatf==7
label define rcat6 0 "Black, higher income" 1 "Black, lower income" 2 "Latinx, higher income" 3 "Latinx, lower Income" 4 "White, higher income" 5 "White, lower income"
label values highprace_inc rcat6
tab highprace_inc, m
ciplot anyftesecurity [aw=totstud] if year==2017,  by(highprace_inc) graphregion(color(white)) rcap(lcolor("22 150 210")) mcolor("22 150 210") xlabel(, labsize(vsmall)) xtitle("School racial, ethnic, and income composition") ytitle("Share of schools with any SRO") saving(highprace_inc_meps, replace)
graph export "${vis}/Security officer by high proportion student race and income adj MEPS weighted.png", as(png) replace


* Using MEPS adjusted poverty rate data
* Any security officer by percentage black and low-income

gen pblacklow = .
replace pblacklow = 0 if pblackcatf==1
replace pblacklow = 1 if pblackcatf==3
replace pblacklow = 2 if pblackcatf==5
replace pblacklow = 3 if pblackcatf==7
label values pblacklow rcat4_1
tab pblacklow, m
ciplot anyftesecurity [aw=totstud] if year==2017,  by(pblacklow) graphregion(color(white)) rcap(lcolor("22 150 210")) mcolor("22 150 210") xlabel(, labsize(vsmall)) xtitle("School racial, ethnic, and income composition") ytitle("Share of schools with any SRO") saving(pblacklow_meps, replace)
graph export "${vis}/Security officer by percent black and low-income adj MEPS weighted.png", as(png) replace


gen phisplow = .
replace phisplow = 0 if phispcatf==1
replace phisplow = 1 if phispcatf==3
replace phisplow = 2 if phispcatf==5
replace phisplow = 3 if phispcatf==7
label values phisplow rcat4_1
tab phisplow, m
ciplot anyftesecurity [aw=totstud] if year==2017,  by(phisplow) graphregion(color(white)) rcap(lcolor("22 150 210")) mcolor("22 150 210") xlabel(, labsize(vsmall)) xtitle("Percent Latinx") ytitle("Proportion Any Security Officer") saving(phisplow_meps, replace)
graph export "${vis}/Security officer by percent Latinx and low-income adj MEPS weighted.png", as(png) replace


* Appendix tables
bysort highprace_inc: sum anyftesecurity [aw=totstud]
bysort pblackcatf: sum anyftesecurity [aw=totstud]
bysort phispcatf: sum anyftesecurity [aw=totstud]
bysort pwhitecatf: sum anyftesecurity [aw=totstud]


