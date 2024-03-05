***************************************************
// LAUNCH MICHIGAN FUNDING BRIEF - URBAN INSTUTITE
***************************************************

*set your common directory here
glo main "******"

glo data "${main}/data"
cap n mkdir "${data}"

cd "${main}"

foreach var in raw int fin vis{
	glo `var' "${data}/`var'"
	cap n mkdir "${`var'}"
}

cap n net install nsplit.pkg
cap n net install grstyle.pkg
cap n ssc install palettes
cap n ssc install colrspace

cd "${raw}"
unzipfile "${main}/raw_data.zip", replace

cd "${main}"

*****************************************
*** DATA PREP ***************************
*****************************************

*I. ACS Poverty Data Prep -- children income-to-poverty from ACS 2020 (B17024)
import excel "${raw}/ACSDT5Y2022.B17024-Data", firstrow case(lower) clear
drop if _n==1 // extra ow
destring *, replace

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

egen pct_snap = rowtotal(pct_inc2pov_under50 pct_inc2pov_50to74 pct_inc2pov_75to99 pct_inc2pov_100to124)
label var pct_snap "SNAP proxy - 125% of poverty line or below"

save "${int}/schoolchildren inc2pov ACS 2022.dta", replace

*II. Crosswalk between FIPS and ACS Poverty Data
import excel "${raw}/School_Districts_(v17a)", firstrow case(lower) clear // this file has school district codes and FIPS codes, and so it can be used as a crosswalk between FIPS codes which are in the ACS data and school codes which are in the Michigan enrollment data. It comes from the Michigan GIS Open Data portal https://gis-michigan.opendata.arcgis.com/datasets/f40e3bf5815e4045a68c53af572690f6
rename fipscode fips
rename dcode districtcode
keep fips name districtcode
drop if mi(districtcode)
save "${int}/fips district crosswalk.dta", replace

*III. Michigan Enrollment Data Prep
import excel "${raw}/EEM Feb 2024", firstrow case(lower) clear // this file is the Educational Entity Master (EEM), downloaded from the CEPI website -- https://cepi.state.mi.us/eem/PublicDatasets.aspx
gen school_code=entitycode
destring school_code, replace force
keep if school_code<=9999 // keep only K-12 entities
drop if missing(school_code)
gen geo_district_code=entitygeographicleadistrictcode
gen geo_district_name=entitygeographicleadistrictoffic
keep school_code geo_district_code geo_district_name entityncescode entitylocalecode entitylocalename
save "${int}/eem feb24 trimmed.dta", replace

import excel "${raw}/MI student count data 2023-24", firstrow case(lower) clear // this file has student counts by school for the 2023-24 school year, from Michigan's MI School Data portal https://www.mischooldata.org/k-12-data-files/
gen school_code=buildingcode
drop if missing(school_code)
destring school_code, replace
merge 1:1 school_code using "${int}/eem feb24 trimmed", force
drop if _merge==2
drop _merge
replace geo_district_code=districtcode if missing(geo_district_code)

gen grade_7to12= grade_7_enrollment + grade_8_enrollment + grade_9_enrollment  + grade_10_enrollment +  grade_11_enrollment +  grade_12_enrollment
replace economic_disadvantaged_enrollmen="10" if economic_disadvantaged_enrollmen=="<10" // suppressed data
replace special_education_enrollment="10" if special_education_enrollment=="<10" // suppressed data
replace english_language_learners_enroll="10" if english_language_learners_enroll=="<10" // suppressed data
destring economic_disadvantaged_enrollmen special_education_enrollment english_language_learners_enroll, replace
gen pct_econdis = economic_disadvantaged_enrollmen / total_enrollment

gen charter=0
replace charter=1 if entitytype=="PSA School"

collapse charter (sum) total_enrollment american_indian_enrollment asian_enrollment african_american_enrollment hispanic_enrollment hawaiian_enrollment white_enrollment two_or_more_races_enrollment grade_7to12 economic_disadvantaged_enrollmen special_education_enrollment english_language_learners_enroll, by(districtcode districtname geo_district_code) // collapsing student counts to district level

rename districtcode district_code // operating district
label var district_code "operating district"
rename geo_district_code districtcode // geographic district
label var districtcode "geographic district"

merge m:1 districtcode using "${int}/fips district crosswalk.dta"
drop if _merge==2 // drop 4 "district created from ISD" observations
drop _merge

merge m:1 fips using "${int}/schoolchildren inc2pov ACS 2022.dta"
drop if _merge==2 // drop 1 district with no data from ACS
drop inc2pov_12to17* inc2pov_6to11* total_12to17 total_6to11 geo* _merge 

save "${fin}/singer - learning curve feb 2024 dataset" , replace


*****************************************
*** ANALYSIS ****************************
*****************************************

use "${fin}/singer - learning curve feb 2024 dataset", clear

sum pct_snap, d

gen n_snap=pct_snap*total_enrollment
egen total_snap=total(n_snap)
gen share_snap=n_snap/total_snap

egen mi_enrollment=total(total_enrollment)


*get figures for discretionary vs. formula-based allocation of funding
di 90000000/total_snap // $312.82 per income-eligible student
di 90000000/mi_enrollment // $65.89 per income-eligible student


*get figures for targeted vs. universal formula funding
sum pct_snap, d // "moderate" will be 22%+ "income eligible" (median); high-poverty will be 34% "income eligible" (75th pctile)

gen moderate_poverty=0
replace moderate_poverty=1 if pct_snap>=0.21766 // 426 districts (about 50%)
gen high_poverty=0
replace high_poverty=1 if pct_snap>=0.3439 // 216 districts (about 25%)

egen moderate_enrollment=total(total_enrollment) if moderate_poverty==1
egen moderate_snap=total(n_snap) if moderate_poverty==1
di 90000000/moderate_enrollment
di 90000000/moderate_snap

egen high_enrollment=total(total_enrollment) if high_poverty==1
egen high_snap=total(n_snap) if high_poverty==1
di 90000000/high_enrollment
di 90000000/high_snap

di moderate_snap/total_snap
di high_snap/total_snap


/* graphing alternative allocation options
*gen amount_nomin=90000000*share_snap // budget calls for at least $10K for districts receiving funds

*Option 1 - all districts by share of income-eligible students
gen allocation1=1
*replace allocation1=0 if amount_nomin<10000 // 14% of disticts would be ineligible bc they'd get < $10K

egen total_allocation1=total(n_snap) if allocation1==1
gen share_snap1=n_snap/total_allocation1
gen amount_1=90000000*share_snap1
gen amount_1_pp=amount_1/n_snap

*Option 2 - only highest-poverty districts
gen allocation2=0
replace allocation2=1 if pct_snap>=0.34 // 75th pctile for income-eligibility, ~25% of districts

egen total_allocation2=total(n_snap) if allocation2==1
gen share_snap2=n_snap/total_allocation2
gen amount_2=90000000*share_snap2
replace amount_2=0 if missing(amount_2)
gen amount_2_pp=amount_2/n_snap

*Option 3 - random draw of districts with at least 25th pctile income-eligibility
gen allocation3_eligible=0
replace allocation3_eligible=1 if pct_snap>=0.12 // 25th pctile for income-eligibility, ~75% of districts
gen random=runiform() if allocation3_eligible==1
sort random
gen allocation3=0
replace allocation3=1 if _n<=217 // keep about 1/4 of schools total
sum pct_snap if allocation3==1 // 29%
sum pct_snap if allocation3_eligible==1 & allocation3==0 // 31% -- pretty random!

egen total_allocation3=total(n_snap) if allocation3==1
gen share_snap3=n_snap/total_allocation3
gen amount_3=90000000*share_snap3
replace amount_3=0 if missing(amount_3)
gen amount_3_pp=amount_3/n_snap

// graphs with "share snap" and "amount"

grstyle clear
set scheme s2color
grstyle init
grstyle set plain, box
grstyle color background white
grstyle set color Set1
grstyle yesno draw_major_hgrid yes
grstyle yesno draw_major_ygrid yes
grstyle color major_grid gs8
grstyle linepattern major_grid dot

preserve
foreach x of varlist amount_1 amount_2 amount_3 {
	replace `x'=`x'/1000000 // scale down var
}

graph twoway ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap<0.12 ///
			, mfcolor(green%50) msize(vsmall) mlcolor(green%25) legend(off)) ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap>=0.12 & pct_snap<22 ///
			, mfcolor(yellow%50) msize(vsmall) mlcolor(yellow%25) legend(off)) ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap>=0.22 & pct_snap<0.34 ///
			, mfcolor(orange%50) msize(vsmall) mlcolor(orange%25) legend(off)) ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap>=0.34 ///
			, mfcolor(red%75) msize(vsmall) mlcolor(red%50) legend(off)) ///
			(lowess amount_1 share_snap1, lcolor(black) legend(off)), ///
			ytitle("Allocated 25m Funds ($ millions)" " ", size(small)) ///
			xtitle(" " "Share Students Income-Eligible", size(small)) ///
			yscale(range(0(1)20)) ylabel(0 5 10 15 20) ///
			title("Allocated Automatically Per Income-Eligible Pupil", size(medium)) ///
			name(allocation1, replace)

graph twoway ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap<0.12 ///
			, mfcolor(green%50) msize(vsmall) mlcolor(green%25) legend(off)) ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap>=0.12 & pct_snap<22 ///
			, mfcolor(yellow%50) msize(vsmall) mlcolor(yellow%25) legend(off)) ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap>=0.22 & pct_snap<0.34 ///
			, mfcolor(orange%50) msize(vsmall) mlcolor(orange%25) legend(off)) ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap>=0.34 ///
			, mfcolor(red%75) msize(vsmall) mlcolor(red%50) legend(off)) ///
			(lowess amount_1 share_snap1, lcolor(black) legend(off)), ///
			ytitle("Allocated 25m Funds ($ millions)" " ", size(small)) ///
			xtitle(" " "Share Students Income-Eligible", size(small)) ///
			yscale(range(0(1)20)) ylabel(0 5 10 15 20) ///
			title("Allocated To Highest-Poverty Districts Only", size(medium)) ///
			name(allocation2, replace)
			

graph twoway ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap<0.12 ///
			, mfcolor(green%50) msize(vsmall) mlcolor(green%25) legend(off)) ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap>=0.12 & pct_snap<22 ///
			, mfcolor(yellow%50) msize(vsmall) mlcolor(yellow%25) legend(off)) ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap>=0.22 & pct_snap<0.34 ///
			, mfcolor(orange%50) msize(vsmall) mlcolor(orange%25) legend(off)) ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap>=0.34 ///
			, mfcolor(red%75) msize(vsmall) mlcolor(red%50) legend(off)) ///
			(lowess amount_1 share_snap1, lcolor(black) legend(off)), ///
			ytitle("Allocated 25m Funds ($ millions)" " ", size(small)) ///
			xtitle(" " "Share Students Income-Eligible", size(small)) ///
			yscale(range(0(1)20)) ylabel(0 5 10 15 20) ///
			title("Allocated To Random Set of Districts", size(medium)) ///
			name(allocation3, replace)
			
restore

graph combine allocation1 allocation2 allocation3, name(compare, replace)

// graphs without dpscd and dearborn
preserve
foreach x of varlist amount_1 amount_2 amount_3 {
	replace `x'=`x'/1000000 // scale down var
}

drop if district_code==82030 | district_code==82015 // removes outliers

graph twoway ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap<0.12 ///
			, mfcolor(green%50) msize(vsmall) mlcolor(green%25) legend(off)) ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap>=0.12 & pct_snap<22 ///
			, mfcolor(yellow%50) msize(vsmall) mlcolor(yellow%25) legend(off)) ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap>=0.22 & pct_snap<0.34 ///
			, mfcolor(orange%50) msize(vsmall) mlcolor(orange%25) legend(off)) ///
			(scatter amount_1 share_snap1 [fw=total_enrollment] if pct_snap>=0.34 ///
			, mfcolor(red%75) msize(vsmall) mlcolor(red%50) legend(off)) ///
			(lowess amount_1 share_snap1, lcolor(black) legend(off)), ///
			ytitle("Allocated 25m Funds ($ millions)" " ", size(small)) ///
			xtitle(" " "Share Students Income-Eligible", size(small)) ///
			yscale(range(0(1)5)) ylabel(0 1 2 3 4 5) ///
			title("Allocated Automatically Per Income-Eligible Pupil", size(medium)) ///
			name(allocation1_alt, replace)

graph twoway ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap<0.12 ///
			, mfcolor(green%50) msize(vsmall) mlcolor(green%25) legend(off)) ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap>=0.12 & pct_snap<22 ///
			, mfcolor(yellow%50) msize(vsmall) mlcolor(yellow%25) legend(off)) ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap>=0.22 & pct_snap<0.34 ///
			, mfcolor(orange%50) msize(vsmall) mlcolor(orange%25) legend(off)) ///
			(scatter amount_2 share_snap1 [fw=total_enrollment] if pct_snap>=0.34 ///
			, mfcolor(red%75) msize(vsmall) mlcolor(red%50) legend(off)) ///
			(lowess amount_1 share_snap1, lcolor(black) legend(off)), ///
			ytitle("Allocated 25m Funds ($ millions)" " ", size(small)) ///
			xtitle(" " "Share Students Income-Eligible", size(small)) ///
			yscale(range(0(1)5)) ylabel(0 1 2 3 4 5) ///
			title("Allocated To Highest-Poverty Districts Only", size(medium)) ///
			name(allocation2_alt, replace)
			

graph twoway ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap<0.12 ///
			, mfcolor(green%50) msize(vsmall) mlcolor(green%25) legend(off)) ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap>=0.12 & pct_snap<22 ///
			, mfcolor(yellow%50) msize(vsmall) mlcolor(yellow%25) legend(off)) ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap>=0.22 & pct_snap<0.34 ///
			, mfcolor(orange%50) msize(vsmall) mlcolor(orange%25) legend(off)) ///
			(scatter amount_3 share_snap1 [fw=total_enrollment] if pct_snap>=0.34 ///
			, mfcolor(red%75) msize(vsmall) mlcolor(red%50) legend(off)) ///
			(lowess amount_1 share_snap1, lcolor(black) legend(off)), ///
			ytitle("Allocated 25m Funds ($ millions)" " ", size(small)) ///
			xtitle(" " "Share Students Income-Eligible", size(small)) ///
			yscale(range(0(1)5)) ylabel(0 1 2 3 4 5) ///
			title("Allocated To Random Set of Districts", size(medium)) ///
			name(allocation3_alt, replace)
			
restore

graph combine allocation1_alt allocation2_alt allocation3_alt, name(compare_alt, replace)
*/
