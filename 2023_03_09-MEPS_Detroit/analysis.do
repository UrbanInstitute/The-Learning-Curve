***************************************************
// LAUNCH MICHIGAN FUNDING BRIEF - URBAN INSTUTITE
***************************************************

*set your common directory here
cap n ssc install nsplit

global directory = "*******"


cd "${directory}"

global data = "${directory}/data"
global output = "${data}/output_data"
global int = "${data}/intermediate"
global vis = "${output}/vis"

foreach x in "${data}" "${output}" "${int}" "${vis}" {
	cap n mkdir "`x'"
}

cd "${data}"

unzipfile "${directory}/data2.zip", replace

*****************************************
*** DATA PREP ***************************
*****************************************

*I. ACS Poverty Data Prep -- children income-to-poverty from ACS 2020 (B17024)
import delimited "${data}/ACSDT5Y2020.B17024-Data.csv", clear

split geo_id, parse(US)
rename geo_id2 geoid
drop geo_id1
destring geoid, replace
nsplit geoid, digits(2 5)
rename geoid2 fips
drop geoid1
order geo* fips

rename b17024_001e total

rename b17024_015e total_6to11
rename b17024_016e inc2pov_6to11_under50
rename b17024_017e inc2pov_6to11_50to74
rename b17024_018e inc2pov_6to11_75to99
rename b17024_019e inc2pov_6to11_100to124
rename b17024_020e inc2pov_6to11_125to149
rename b17024_021e inc2pov_6to11_150to174
rename b17024_022e inc2pov_6to11_175to184
rename b17024_023e inc2pov_6to11_185to199
rename b17024_024e inc2pov_6to11_200to299
rename b17024_025e inc2pov_6to11_300to399
rename b17024_026e inc2pov_6to11_400to499
rename b17024_027e inc2pov_6to11_500andup

rename b17024_028e total_12to17
rename b17024_029e inc2pov_12to17_under50
rename b17024_030e inc2pov_12to17_50to74
rename b17024_031e inc2pov_12to17_75to99
rename b17024_032e inc2pov_12to17_100to124
rename b17024_033e inc2pov_12to17_125to149
rename b17024_034e inc2pov_12to17_150to174
rename b17024_035e inc2pov_12to17_175to184
rename b17024_036e inc2pov_12to17_185to199
rename b17024_037e inc2pov_12to17_200to299
rename b17024_038e inc2pov_12to17_300to399
rename b17024_039e inc2pov_12to17_400to499
rename b17024_040e inc2pov_12to17_500andup

keep geo* name inc* total*

gen total_6to17 = total_6to11 + total_12to17

gen inc2pov_under50 = inc2pov_6to11_under50 + inc2pov_12to17_under50
gen inc2pov_50to74 = inc2pov_6to11_50to74 + inc2pov_12to17_50to74
gen inc2pov_75to99 = inc2pov_6to11_75to99 + inc2pov_12to17_75to99
gen inc2pov_100to124 = inc2pov_6to11_100to124 + inc2pov_12to17_100to124
gen inc2pov_125to149 = inc2pov_6to11_125to149 + inc2pov_12to17_125to149
gen inc2pov_150to174 = inc2pov_6to11_150to174 + inc2pov_12to17_150to174
gen inc2pov_175to184 = inc2pov_6to11_175to184 + inc2pov_12to17_175to184
gen inc2pov_185to199 = inc2pov_6to11_185to199 + inc2pov_12to17_185to199
gen inc2pov_200to299 = inc2pov_6to11_200to299 + inc2pov_12to17_200to299
gen inc2pov_300to399 = inc2pov_6to11_300to399+ inc2pov_12to17_300to399
gen inc2pov_400to499= inc2pov_6to11_400to499 + inc2pov_12to17_400to499
gen inc2pov_500andup = inc2pov_6to11_500andup + inc2pov_12to17_500andup

foreach x of varlist inc2pov_under50 inc2pov_50to74 inc2pov_75to99 inc2pov_100to124 inc2pov_125to149 inc2pov_150to174 inc2pov_175to184 inc2pov_185to199 inc2pov_200to299 inc2pov_300to399 inc2pov_400to499 inc2pov_500andup {
	gen pct_`x' = `x'/total_6to17
}

nsplit geoid, digits(2 5) // this is to extract the Federal Information Processing Standards (FIPS) code which I'll use to merge ACS and district data together
rename geoid2 fips

save "${int}/schoolchildren inc2pov ACS 2020.dta", replace

*II. Crosswalk between FIPS and ACS Poverty Data
import delimited "${data}/School_Districts_(v17a)", clear // this file has school district codes and FIPS codes, and so it can be used as a crosswalk between FIPS codes which are in the ACS data and school codes which are in the Michigan enrollment data. It comes from the Michigan GIS Open Data portal https://gis-michigan.opendata.arcgis.com/datasets/f40e3bf5815e4045a68c53af572690f6
rename fipscode fips
rename dcode districtcode
keep fips name districtcode
save "${int}/fips district crosswalk.dta", replace

*III. Michigan Enrollment Data Prep
import delimited "${data}/eem aug22.csv", clear // this file is the Educational Entity Master (EEM), downloaded from the CEPI website in August 2022 -- https://cepi.state.mi.us/eem/PublicDatasets.aspx
gen school_code=entitycode
destring school_code, replace force
keep if school_code<=9999
drop if missing(school_code)
gen geo_district_code=entitygeographicleadistrictcode
gen geo_district_name=entitygeographicleadistrictoffic
keep school_code geo_district_code geo_district_name entityncescode entitylocalecode entitylocalename
save "${int}/eem aug22 trimmed.dta", replace

import delimited "${data}/MI student count 21-22.csv", clear // this file has student counts by school for the 2021-22 school year, from Michigan's MI School Data portal https://www.mischooldata.org/k-12-data-files/
gen school_code=buildingcode
drop if missing(school_code)
destring school_code, replace
merge 1:1 school_code using "${int}/eem aug22 trimmed", force
drop if _merge==2
drop _merge
replace geo_district_code=districtcode if missing(geo_district_code)

gen grade_7to12= grade_7_enrollment + grade_8_enrollment + grade_9_enrollment  + grade_10_enrollment +  grade_11_enrollment +  grade_12_enrollment // for CTE weight
replace economic_disadvantaged_enrollmen="10" if economic_disadvantaged_enrollmen=="<10" // suppressed data
replace special_education_enrollment="10" if special_education_enrollment=="<10" // suppressed data
replace english_language_learners_enroll="10" if english_language_learners_enroll=="<10" // suppressed data (...may want to use administrative so use of suppressed data is not necessary?)
destring economic_disadvantaged_enrollmen special_education_enrollment english_language_learners_enroll, replace
gen pct_econdis = economic_disadvantaged_enrollmen / total_enrollment
gen econdis50=0
replace econdis50=economic_disadvantaged_enrollmen if pct_econdis>0.5
gen econdis75=0
replace econdis75=economic_disadvantaged_enrollmen if pct_econdis>0.75

gen charter=0
replace charter=1 if entitytype=="PSA School"

collapse charter (sum) total_enrollment american_indian_enrollment asian_enrollment african_american_enrollment hispanic_enrollment hawaiian_enrollment white_enrollment two_or_more_races_enrollment grade_7to12 economic_disadvantaged_enrollmen special_education_enrollment english_language_learners_enroll econdis50 econdis75, by(districtcode districtname geo_district_code) // collapsing student counts to district level

rename districtcode district_code // operating district
label var district_code "operating district"
rename geo_district_code districtcode // geographic district
label var districtcode "geographic district"

merge m:1 districtcode using "${int}/fips district crosswalk.dta"
keep if _merge==3 // drop "district created from ISD" observations
drop _merge

merge m:1 fips using "${int}/schoolchildren inc2pov ACS 2020.dta"
keep if _merge==3 // drop districts with no data from ACS
drop inc2pov_12to17* inc2pov_6to11* total_12to17 total_6to11 geo* _merge 

save "${int}/singer - learning curve jan 2023 dataset" , replace

*****************************************
*** ANALYSIS ****************************
*****************************************

use "${int}/singer - learning curve jan 2023 dataset", clear

//Figure 1 & Appendix A: poverty and deep poverty quartile distribution for districts

gen pct_pov= pct_inc2pov_under50 + pct_inc2pov_50to74 + pct_inc2pov_75to99
gen pct_deep = pct_inc2pov_under50
pwcorr pct_pov pct_deep, star(0.001) // r=0.87

gen pct_ed=economic_disadvantaged_enrollmen/total_enr
replace pct_ed=1 if economic_disadvantaged_enrollmen>total_enrollment // 12 disticts--mostly correctional facilities or other alternative educational settings--that list more economically disadv. students than total students; impute 100% economic disadvantage for those districts

gen ed_low=0
replace ed_low=1 if pct_ed<0.25
gen ed_midlow=0
replace ed_midlow=1 if pct_ed>=0.25 & pct_ed<0.50
gen ed_midhigh=0
replace ed_midhigh=1 if pct_ed>=0.50 & pct_ed<0.75
gen ed_high=0
replace ed_high=1 if pct_ed>0.75

gen ed_category=.
replace ed_category=1 if ed_low==1
replace ed_category=2 if ed_midlow==1
replace ed_category=3 if ed_midhigh==1
replace ed_category=4 if ed_high==1
label define ed_category 1 "low poverty" 2 "mid-low poverty" 3 "mid-high poverty" 4 "high poverty"
label values ed_category ed_category

preserve
gen n_district=1
collapse pct_pov pct_deep pct_ed (sum) n_district total_enrollment, by(ed_category)  // at this point, before restoring, I pulled up the data browser and copied this data into a spreadsheet. not the most elegent coding, I know...
rename total_enrollment n_student
export excel using "${data}/Launch MI graphs v2.xlsx", sheet("Tables 1", replace) firstrow(variables)
restore

//Create funding estimates! note: "addtl" denotes additional funding for "high need poverty" students at 15% weight; index denotes scaling that allocation of funding down into the 35% weight total funding amount
egen poverty=rowtotal(pct_inc2pov_under50 pct_inc2pov_50to74 pct_inc2pov_75to99)

gen deep=pct_inc2pov_under50

**flat 35% funding for E.D. students
gen flat_econdis= 10421*0.35*economic_disadvantaged_enrollmen // 35% econ. disadv. weight
egen flat_total=total(flat_econdis)
gen flat_totaladj=flat_total/0.35*0.22 // Launch MI has calculated that the additional cost of the 35% weight would amount to an additional 22% (not the full 35%) given existing revenue streams
gen flat_perpupil = flat_econdis/total_enrollment
format flat* %18.2fc

**poverty
gen povaddtl_econdis = 10421*0.35*economic_disadvantaged_enrollmen + 10421*0.15*total_enrollment*poverty // additional 15% for students in "poverty"
gen povaddtl_perpupil = povaddtl_econdis/total_enrollment
egen povaddtl_total = total(povaddtl_econdis)
gen povaddtl_pct = povaddtl_econdis/povaddtl_total
gen povindex_econdis = povaddtl_pct*flat_total
gen povindex_perpupil = povindex_econdis/total_enrollment
format povaddtl* povindex* %18.2fc

**deep poverty
gen deepaddtl_econdis = 10421*0.35*economic_disadvantaged_enrollmen + 10421*0.15*total_enrollment*deep // additional 15% for students in "poverty"
gen deepaddtl_perpupil = deepaddtl_econdis/total_enrollment
egen deepaddtl_total = total(deepaddtl_econdis)
gen deepaddtl_pct = deepaddtl_econdis/deepaddtl_total
gen deepindex_econdis = deepaddtl_pct*flat_total
gen deepindex_perpupil = deepindex_econdis/total_enrollment
format deepaddtl* deepindex* %18.2fc

**blended
gen blendaddtl_econdis = 10421*0.35*economic_disadvantaged_enrollmen + 10421*0.10*total_enrollment*poverty + 10421*0.05*total_enrollment*deep // additional 10% for all students in poverty, additional 5% for students in deep poverty
gen blendaddtl_perpupil = blendaddtl_econdis/total_enrollment
egen blendaddtl_total = total(blendaddtl_econdis)
gen blendaddtl_pct = blendaddtl_econdis/blendaddtl_total
gen blendindex_econdis = blendaddtl_pct*flat_total
gen blendindex_perpupil = blendindex_econdis/total_enrollment
format blendaddtl* blendindex* %18.2fc

**econ. disadv. 75% concentration-based
gen concen75addtl_econdis = 10421*0.35*economic_disadvantaged_enrollmen + 10421*0.15*econdis75 // additional 15% for all students who are economically disdavantaged and who are in a district with over 75% econ disadv. rate
gen concen75addtl_perpupil = concen75addtl_econdis/total_enrollment
egen concen75addtl_total = total(concen75addtl_econdis)
gen concen75addtl_pct = concen75addtl_econdis/blendaddtl_total
gen concen75index_econdis = concen75addtl_pct*flat_total
gen concen75index_perpupil = concen75index_econdis/total_enrollment
format concen75addtl* concen75index* %18.2fc

//Table 1: additional total statewide
preserve
collapse (sum) flat_econdis povaddtl_econdis deepaddtl_econdis blendaddtl_econdis concen75addtl_econdis total_enrollment  // don't need to include "index" because they all have the same total funds and average per-pupil funds as "flat"
foreach x of varlist flat* pov* deep* blend* concen75* {
	gen perpupil_`x' = `x'/total_enrollment
}
export excel using "${data}/Launch MI graphs v2.xlsx", sheet("Tables 1A", replace) firstrow(variables)
format perpupil* %18.2fc
restore

//Figures 2 - 4: additional per pupil statewide by district econ disadv. levels (also provides data for appendices that show progressivity of funding ratios)
preserve
g count = 1  	
collapse (sum) count *_econdis total_enrollment, by(ed_category)
foreach x of varlist flat* pov* deep* blend* concen75* {
	gen perpupil_`x' = `x'/total_enrollment
}
format perpupil* %18.2fc 
export excel using "${data}/Launch MI graphs v2.xlsx", sheet("Tables 2-4", replace) firstrow(variables)
restore

//Pct. of students attending a school with 75% econ disadv or more
preserve
collapse (sum) econdis75 total_enrollment
gen pct_concen75=econdis75/total_enrollment
sum pct_concen75 // 19.57%
restore
