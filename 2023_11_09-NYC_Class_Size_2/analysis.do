// NYC Essay 2
/*
This is the second in a series of essays analyzing the effects of implementing NYC's class size mandate. This code was written 11/23 by Matt Chingos, Ariella Meltzer, and Jay Carter. 

*/

glo main "" // this is the only line that needs to be edited for code to run. 

cd "${main}"

glo data "${main}/data"
glo raw "${data}/raw"
glo int "${data}/intermediate"
glo fin "${data}/final"

foreach var in data raw int fin{
	cap n mkdir "${`var'}"
}

/*
Main File
	1) Cleaning File - this file, "Essay #2 - Cleaning Code"
	2) Analysis - "Essay #2 - Analysis Code"
*/ 


cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/demographic-snapshot-2018-19-to-2022-23-(public).xlsx"  ///
	"${raw}/demographic_snapshot_2018-2023_NEW.xlsx"
	
* 1.) cleaning demographic file

import excel using "${raw}/demographic_snapshot_2018-2023_NEW.xlsx", sheet("School") firstrow clear

ren U pct_female
ren W pct_male
ren Y pct_neitherfemaleormale
ren AA pct_asian
ren AC pct_black
ren AE pct_hispanic
ren AG pct_multiracial
ren AI pct_nativeamerican
ren AK pct_white
ren AM pct_missingrace
ren AO pct_disabilities
ren AQ pct_ELL
ren AS pct_poverty

** dropping years before 22-23
drop if Year == "2018-19"
drop if Year == "2019-20"
drop if Year == "2020-21"
drop if Year == "2021-22"

** Cleaning poverty and economic need index variables

replace pct_poverty = ".97" if pct_poverty == "Above 95%"
destring pct_poverty, replace

replace EconomicNeedIndex=".97" if EconomicNeedIndex=="Above 95%"
destring EconomicNeedIndex, replace

compress
sort DBN Year
save "${int}/22-23_demographics.dta", replace

* 2.) CLEANING CLASS SIZE DATA K-8 

clear all

* Set the URL for the Excel file

local url = "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx"

* Set a local file name to store the downloaded file
local localfile "avg_class_size_22-23.xlsx"	

* Download the file from the URL
cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx" "${raw}/avg_class_size_22-23.xlsx"

* Import the Excel file into Stata
import excel using "${raw}/avg_class_size_22-23.xlsx", sheet("K-8 Avg") firstrow clear

* Clean up by deleting the downloaded file
capture erase "`localfile'"


*Clean class size variables
*** getting rid of < or > values 
replace MinimumClassSize = "14" if MinimumClassSize == "<15"
replace MaximumClassSize = "14" if MaximumClassSize == "<15"

replace MinimumClassSize = "16" if MinimumClassSize == ">15"
replace MaximumClassSize = "16" if MaximumClassSize == ">15"

replace MinimumClassSize = "5" if MinimumClassSize == "<6"
replace MaximumClassSize = "5" if MaximumClassSize == "<6"

replace MinimumClassSize = "35" if MinimumClassSize == ">34"
replace MaximumClassSize = "35" if MaximumClassSize == ">34"

destring MinimumClassSize MaximumClassSize, replace

gen year=2022

gen g = GradeLevel
replace g="0" if g=="K"
replace g="-1" if g=="K-8 SC"
destring g, replace

*Setting a cap of 20 for K-8 SC but doesn't matter because they are all below*
gen cap = 20 if g>=-1 & g<=3
replace cap = 23 if g>=4 & g<=8
replace cap = 25 if g>=9 & g<=12

keep if g>=0 & g<=5

ren NumberofStudents num_total

*Baseline
rename NumberofClasses num_class0
gen num_teacher0 = num_class if ProgramType=="Gen Ed" | ProgramType=="G&T"
replace  num_teacher0 = num_class*2 if ProgramType=="ICT" | ProgramType=="ICT & G&T"

*Calculate number of SPED and non-SPED students in ICT classes
gen sped_count = floor(num_total * .4) if ProgramType == "ICT" // max 40% of students in ICT classes can be SPED
replace sped_count = 0 if missing(sped_count)

gen non_sped_count = num_total - sped_count if ProgramType == "ICT"
replace non_sped_count = num_total if ProgramType=="Gen Ed"

*Collapse ICT/Gen Ed classes
replace ProgramType="ICT/Gen Ed" if ProgramType=="ICT" | ProgramType=="Gen Ed"


collapse (sum) num_total sped_count non_sped_count num_teacher0 num_class0, by(DBN g ProgramType cap)

*Calculate number of teachers needed for ICT/Gen Ed
gen max_sped_count = floor(cap * .4) // How many SPED students can be in a single ICT class
gen max_non_sped_count = cap - max_sped_count // How many GenEd students can be in a single ICT class

gen ict_needed = ceil(sped_count/max_sped_count) // Number of ICT Classes needed for the number of SPED students in school
gen ict_with_max_sped_students = floor(sped_count/max_sped_count) // How many ICT classes have max number of SPED students

gen sped_in_last_ict_class = mod(sped_count, max_sped_count) // How many SPED students are in the "last" ICT class in a grade

gen gen_ed_in_max_sped_classes = max_non_sped_count * ict_with_max_sped_students  // How many GenEd students are in "full" ICT classes 
gen gen_ed_in_last_ict_class = cap - sped_in_last_ict_class // How many GenEd students are in the "last" ICT class in a grade

gen gen_ed_left_over = non_sped_count - gen_ed_in_max_sped_classes - gen_ed_in_last_ict_class // How many GenEd students need a non-ICT class
replace gen_ed_left_over = 0 if gen_ed_left_over < 0 // Make sure this number is not negative

gen gen_ed_needed = ceil(gen_ed_left_over/cap) // How many GenEd classes are needed 

// Calculate Classes/teachers for GT classrooms
gen gt_classes_needed = 0
replace gt_classes_needed =  ceil(num_total/cap) if ProgramType=="G&T" | ProgramType=="ICT & G&T"

gen gt_teachers_needed = 0
replace gt_teachers_needed = ceil(num_total/cap) if ProgramType=="G&T" | ProgramType=="ICT & G&T"
replace gt_teachers_needed = gt_teachers_needed * 2 if ProgramType=="ICT & G&T"

gen total_classes_needed = ict_needed + gen_ed_needed + gt_classes_needed // Total number of classes in school-grade
gen total_teachers_needed = ict_needed*2 + gen_ed_needed + gt_teachers_needed // Total teachers needed


*Collapse by school
collapse (rawsum) num_total (sum) sped_count non_sped_count num_teacher0 num_class0 ict_needed gen_ed_needed gt_classes_needed total_classes_needed gt_teachers_needed total_teachers_needed, by(DBN g) 

*Count new teachers needed
gen new_teacher1 = total_teachers_needed-num_teacher0
replace new_teacher1 = 0 if new_teacher<0

save "${int}/22-23_K-8 Class Size Data Cleaned.dta", replace

* 3.) merge with demographic data 
sort DBN
merge m:1 DBN using "${int}/22-23_demographics.dta"
tab _merge
keep if _merge==3
drop _merge

*Generate compliance/non-compliance
//gen treated1 = (AverageClassSize > cap) & !missing(AverageClassSize) 

foreach v in female male asian black hispanic multiracial nativeamerican white missingrace disabilities ELL poverty {
	gen num_`v' = round(pct_`v'*num_total, 1)
}

gen num_nonpoverty = num_total-num_poverty
gen num_nondisabilities = num_total-num_disabilities
gen num_nonELL = num_total-num_ELL

drop TotalEnrollment Grade6 Grade7 Grade8 Grade9 Grade10 Grade11 Grade12

*Create tag for borough for DBN
// K = Brooklyn, X = Bronx, Q = Queens, M = Manhattan, R = Staten Island
gen borough = substr(DBN,3,1)
replace borough = "Brooklyn" if b == "K"
replace borough = "Bronx" if b == "X"
replace borough = "Queens" if b == "Q"
replace borough = "Manhattan" if b == "M"
replace borough = "Staten Island" if b == "R"

gen district = substr(DBN, 1, 2)
tab district

compress
save "${int}/22-23_K-8_merged_file.dta", replace

** Cleaning basic school funding file ** 

cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/newyorkcityschooltransparency202223.zip" ///
	"${raw}/nyc_data.zip"

cd "${raw}"
cap n unzipfile "${raw}/nyc_data.zip"
cd "${main}"

import excel "${raw}/NewYorkCitySchoolTransparency202223.xlsx", sheet("Part C") cellrange(A7:Y1616) firstrow clear

ren LocalSchoolCode DBN

save "${int}/School level funding.dta", replace

** importing enrollment and staff counts **

clear
import excel "${raw}/NewYorkCitySchoolTransparency202223.xlsx", sheet("Part B") cellrange(A7:Y1616) firstrow clear


// dropping variables not of interest
drop Doesthisschoolserveitsfull Ifnoisthisschoolopeningth Istheschoolscheduledtoclose Ifsowhatyear ClassroomTeachersw03Years ClassroomTeacherswMorethan K12Enrollment PreKEnrollment PreschoolSpecialEdEnrollment K12FRPLCount K12ELLCount K12SWDCount

drop if HighestGrade == "6"
drop if HighestGrade == "7"
drop if HighestGrade == "8"
drop if HighestGrade == "9"
drop if HighestGrade == "10"
drop if HighestGrade == "11"
drop if HighestGrade == "12"
drop if HighestGrade == "Pre-K"

ren LocalSchoolCode DBN

save "${int}/Enrollment_StaffCounts", replace

** Merge with school level funding **

use "${int}/School level demographics.dta", clear

** merge with enrollment and staff counts **

merge 1:1 DBN using "${int}/Enrollment_StaffCounts"
tab _merge
keep if _merge == 3
drop _merge


merge 1:1 DBN using "${int}/School level funding.dta" // pre-k and charters not matched


drop if HighestGrade == "6"
drop if HighestGrade == "7"
drop if HighestGrade == "8"
drop if HighestGrade == "9"
drop if HighestGrade == "10"
drop if HighestGrade == "11"
drop if HighestGrade == "12"
drop if HighestGrade == "Pre-K"
tab _merge
keep if _merge == 3
drop _merge

save "${int}/merged_file", replace

**# Bookmark #2 // copy into another do file 
use "${int}/22-23_K-8_merged_file.dta", clear

// making sure everything below K - Grade 5 is dropped (grade 6 and above already dropped)
drop Grade3K GradePKHalfDayFullDay

collapse (rawsum) num_total (sum) num_class0 num_teacher0 new_teacher1 total_classes_needed total_teachers_needed, by(DBN)

** merging above versions with funding data **

save "${int}/version_1", replace

merge 1:1 DBN using "${int}/merged_file"
tab _merge

save "${int}/Class Size_Funding", replace

use "${int}/Class Size_Funding", clear

// dropping unnecessary variables
drop Preschool SpecialEdK12 PreK GeneralEdK12 SchoolAdministration InstructionalMedia PupilSupportServices StateLocalFunding FederalFunding TotalFundingSourcebySchool StateLocalFundingperPupil FederalFundingperPupil ParaprofessionalClassroomSta PrincipalsOtherAdminStaff PupilSupportServicesStaff AllRemainingStaff _merge

*** USING DISTRICT-BASED AVERAGE SALARY TO CALCULATE COSTS BY STUDENT GROUPS ***

gen district_avg_salary_benefits = (97607 + (97607 * .44))
gen v1_added_cost_district_salary = (district_avg_salary_benefits * (new_teacher1 * 1.2))
gen v1_added_per_pupil_cost_district = (v1_added_cost_district_salary / num_total)

// calculating costs WITHOUT fringe benefits: 
gen just_salary = 97607
gen added_cost_no_fringe = (just_salary * (new_teacher1* 1.2))
gen added_per_pupil_cost_no_fringe = (added_cost_no_fringe / num_total)

save "${int}/Funding Analysis File", replace 

**********************
// End of Cleaning File
**********************



use "${int}/Funding Analysis File", clear 
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) num_total [fw=num_total]
export excel using "Class Size Implementation V2", sheet("Per Pupil Funding Baseline", modify) firstrow(variables)

// calculating added funding by race -- FIGURE 2

use "${int}/Funding Analysis File", clear 
drop Asian Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData

gen Asian = round((num_total * pct_asian), 1)
gen Black = round((num_total * pct_black), 1)
gen Hispanic = round((num_total * pct_hispanic), 1)
gen MultiRacial = round((num_total * pct_multiracial), 1)
gen NativeAmerican = round((num_total * pct_nativeamerican), 1)
gen White = round((num_total * pct_white), 1)
gen MissingRaceEthnicityData = round((num_total * pct_missingrace), 1)

save "${int}/Funding Analysis File", replace 

foreach g in Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData {
use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) `g' [fw=`g']
gen race="`g'"
save "${int}/temp_`g'", replace
}
use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) Asian [fw=Asian]
gen race="Asian"
foreach g in Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta"
}
order race
export excel using "Class Size Implementation V2", sheet("Per Pupil Funding Race", modify) firstrow(variables)

//calculating added funding by poverty -- FIGURE 1

use "${int}/Funding Analysis File", clear

drop Poverty
gen Poverty = (pct_poverty * num_total)
gen NonPoverty = num_total - Poverty
gen Poverty_rounded = round(Poverty)
gen NonPoverty_rounded = round(NonPoverty)

save "${int}/Funding Analysis File", replace


foreach g in Poverty_rounded NonPoverty_rounded {
use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) `g' [fw=`g']
gen povertystatus="`g'"
save temp_`g', replace
}
use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) Poverty_rounded [fw=Poverty_rounded]
gen povertystatus="poverty"
	append using temp_NonPoverty_rounded
	erase temp_Poverty_rounded.dta
	
order povertystatus
export excel using "Class Size Implementation V2", sheet("Per Pupil Funding Poverty", modify) firstrow(variables) 


// using ENI 

use "${int}/Funding Analysis File", clear
sum EconomicNeedIndex, d

gen ENI_1 = EconomicNeedIndex if EconomicNeedIndex>=.052 & EconomicNeedIndex<=.637
gen ENI_2 = EconomicNeedIndex if EconomicNeedIndex>.638 & EconomicNeedIndex<=.811
gen ENI_3 = EconomicNeedIndex if EconomicNeedIndex>.812 & EconomicNeedIndex<=.903
gen ENI_4 = EconomicNeedIndex if EconomicNeedIndex>.904 & EconomicNeedIndex<=.97

gen ENI_1_count = (ENI_1 * num_total)
gen ENI_2_count = (ENI_2 * num_total)
gen ENI_3_count = (ENI_3 * num_total)
gen ENI_4_count = (ENI_4 * num_total)

gen ENI_1_rounded = round(ENI_1_count)
gen ENI_2_rounded = round(ENI_2_count)
gen ENI_3_rounded = round(ENI_3_count)
gen ENI_4_rounded = round(ENI_4_count)

save "${int}/Funding Analysis File", replace

foreach g in ENI_2_rounded ENI_3_rounded ENI_4_rounded {
use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) `g' [fw=`g']
gen ENI="`g'"
save "${int}/temp_`g'", replace
}
use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) ENI_1_rounded [fw=ENI_1_rounded]
gen ENI="ENI_1_rounded"
foreach g in ENI_2_rounded ENI_3_rounded ENI_4_rounded {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta"
}
order ENI
export excel using "Class Size Implementation V2", sheet("Per Pupil Funding ENI", modify) firstrow(variables)


// total by school

use "${int}/Funding Analysis File", clear
collapse TotalSchoolFundingperPupil v1_added_per_pupil_cost_district added_per_pupil_cost_no_fringe (rawsum) num_total [fw=num_total], by(DBN)
export excel using "Class Size Implementation V2", sheet("Total by School", modify) firstrow(variables)

// FSF Supplements and shortfalls:

cd "${raw}"
cap n unzipfile "${main}/data_zip.zip", replace
cd "${main}"

import delimited "${raw}/AppendedScapedData.csv", varnames(1) clear

destring fy2024, replace ignore("$" "," " ")

keep if allocationcategory == "TL Fair Student Funding                           "

save "${int}/FSF amounts", replace

//
use "${int}/Funding Analysis File", clear
gen school_code = substr(DBN,3,4)
save "${int}/Funding Analysis File", replace

merge 1:1 school_code using "${int}/FSF amounts"
drop if _merge==1

order school_code allocationcategory fy2024, after(HighestGrade)

save "${int}/Funding Analysis File", replace

// gen per capita FSF for all schools: 

gen per_capita_fsf = 4197.19	//from NYC comptroller allocations: https://comptroller.nyc.gov/reports/spotlight-school-budget-allocations/
gen fsf_per_pupil = (fy2024/num_total)
gen avg_fsf_weight = (fsf_per_pupil/per_capita_fsf)

// adding in FSF supplements
gen fsf_supplement_1 = 500
gen fsf_supplement_1_weighted = (avg_fsf_weight*500)
gen fsf_supplement_2 = 1000
gen fsf_supplement_2_weighted = (avg_fsf_weight*1000)
gen fsf_supplement_3 = 1500
gen fsf_supplement_3_weighted = (avg_fsf_weight*1500)
gen fsf_supplement_4 = 2000
gen fsf_supplement_4_weighted = (avg_fsf_weight*2000)
gen fsf_supplement_5 = 3000
gen fsf_supplement_5_weighted = (avg_fsf_weight*3000)
// gen fsf_supplement_6 = 4000 - taking out 4000 from NYCDOE comments
// gen fsf_supplement_6_weighted = (avg_fsf_weight*4000)
gen shortfall_1 = v1_added_per_pupil_cost_district - fsf_supplement_1_weighted
gen shortfall_2 = v1_added_per_pupil_cost_district - fsf_supplement_2_weighted
gen shortfall_3 = v1_added_per_pupil_cost_district - fsf_supplement_3_weighted
gen shortfall_4 = v1_added_per_pupil_cost_district - fsf_supplement_4_weighted
gen shortfall_5 = v1_added_per_pupil_cost_district - fsf_supplement_5_weighted
// gen shortfall_6 = v1_added_per_pupil_cost_district - fsf_supplement_6_weighted

// calculating shortfalls without fringe benefits: 

gen no_fringe_shortfall_1 = added_per_pupil_cost_no_fringe - fsf_supplement_1_weighted
gen no_fringe_shortfall_2 = added_per_pupil_cost_no_fringe - fsf_supplement_2_weighted
gen no_fringe_shortfall_3 = added_per_pupil_cost_no_fringe - fsf_supplement_3_weighted
gen no_fringe_shortfall_4 = added_per_pupil_cost_no_fringe - fsf_supplement_4_weighted
gen no_fringe_shortfall_5 = added_per_pupil_cost_no_fringe - fsf_supplement_5_weighted
// gen no_fringe_shortfall_6 = added_per_pupil_cost_no_fringe - fsf_supplement_6_weighted


save "${int}/Funding Analysis File", replace

// share with shortfall above 0 

gen shortfall_1_above_0 =.
replace shortfall_1_above_0 = 1 if shortfall_1 > 0 & !missing(shortfall_1)
replace shortfall_1_above_0 = 0 if shortfall_1 <= 0

gen shortfall_2_above_0 =.
replace shortfall_2_above_0 = 1 if shortfall_2 > 0 & !missing(shortfall_2)
replace shortfall_2_above_0 = 0 if shortfall_2 <= 0

gen shortfall_3_above_0 =.
replace shortfall_3_above_0 = 1 if shortfall_3 > 0 & !missing(shortfall_3)
replace shortfall_3_above_0 = 0 if shortfall_3 <= 0

gen shortfall_4_above_0 =.
replace shortfall_4_above_0 = 1 if shortfall_4 > 0 & !missing(shortfall_4)
replace shortfall_4_above_0 = 0 if shortfall_4 <= 0

gen shortfall_5_above_0 =.
replace shortfall_5_above_0 = 1 if shortfall_5 > 0 & !missing(shortfall_5)
replace shortfall_5_above_0 = 0 if shortfall_5 <= 0

// gen shortfall_6_above_0 =.
// replace shortfall_6_above_0 = 1 if shortfall_6 > 0 
// replace shortfall_6_above_0 = 0 if shortfall_6 <= 0

// share with shortfall above 0 with no fringe 

gen no_fringe_shortfall_1_above_0 =.
replace no_fringe_shortfall_1_above_0 = 1 if no_fringe_shortfall_1 > 0 & !missing(no_fringe_shortfall_1)
replace no_fringe_shortfall_1_above_0 = 0 if no_fringe_shortfall_1 <= 0

gen no_fringe_shortfall_2_above_0 =.
replace no_fringe_shortfall_2_above_0 = 1 if no_fringe_shortfall_2 > 0 & !missing(no_fringe_shortfall_2)
replace no_fringe_shortfall_2_above_0 = 0 if no_fringe_shortfall_2 <= 0

gen no_fringe_shortfall_3_above_0 =.
replace no_fringe_shortfall_3_above_0 = 1 if no_fringe_shortfall_3 > 0 & !missing(no_fringe_shortfall_3)
replace no_fringe_shortfall_3_above_0 = 0 if no_fringe_shortfall_3 <= 0

gen no_fringe_shortfall_4_above_0 =.
replace no_fringe_shortfall_4_above_0 = 1 if no_fringe_shortfall_4 > 0 & !missing(no_fringe_shortfall_4)
replace no_fringe_shortfall_4_above_0 = 0 if no_fringe_shortfall_4 <= 0

gen no_fringe_shortfall_5_above_0 =.
replace no_fringe_shortfall_5_above_0 = 1 if no_fringe_shortfall_5 > 0 & !missing(no_fringe_shortfall_5)
replace no_fringe_shortfall_5_above_0 = 0 if no_fringe_shortfall_5 <= 0

// gen no_fringe_shortfall_6_above_0 =.
// replace no_fringe_shortfall_6_above_0 = 1 if no_fringe_shortfall_6 > 0 
// replace no_fringe_shortfall_6_above_0 = 0 if no_fringe_shortfall_6 <= 0

save "${int}/Funding Analysis File", replace

// baseline FSF by race

foreach g in Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData {
use "${int}/Funding Analysis File", clear
collapse fsf_per_pupil (rawsum) `g' [fw=`g']
gen race="`g'"
save "${int}/temp_`g'", replace
}
use "${int}/Funding Analysis File", clear
collapse fsf_per_pupil (rawsum) Asian [fw=Asian]
gen race="Asian"
foreach g in Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta" 
	}
	
order race
export excel using "FSF Supplements and Shortfalls V2", sheet("Baseline FSF by Race", modify) firstrow(variables) 

**# Bookmark #1 // baseline FSF by ENI

foreach g in ENI_2_rounded ENI_3_rounded ENI_4_rounded {
use "${int}/Funding Analysis File", clear
collapse fsf_per_pupil (rawsum) `g' [fw=`g']
gen ENI="`g'"
save "${int}/temp_`g'", replace
}
use "${int}/Funding Analysis File", clear
collapse fsf_per_pupil (rawsum) ENI_1_rounded [fw=ENI_1_rounded]
gen ENI="ENI_1_rounded"
foreach g in ENI_2_rounded ENI_3_rounded ENI_4_rounded {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta"
}

order ENI
export excel using "FSF Supplements and Shortfalls V2", sheet("Baseline FSF by ENI", modify) firstrow(variables)

// baseline fsf by poverty

foreach g in NonPoverty_rounded { 
use "${int}/Funding Analysis File", clear
collapse fsf_per_pupil (rawsum) `g' [fw=`g']
gen povertystatus="`g'"
save "${int}/temp_`g'", replace
}
use "${int}/Funding Analysis File", clear
collapse fsf_per_pupil (rawsum) Poverty_rounded [fw=Poverty_rounded]
gen povertystatus="poverty"
foreach g in NonPoverty_rounded {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta"
}

order povertystatus
export excel using "FSF Supplements and Shortfalls V2", sheet("Baseline FSF by poverty", modify) firstrow(variables)

// CALCULATING BASELINE FSF SUPPLEMENTS: 


use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 (rawsum) num_total [fw=num_total]
export excel using "FSF Supplements and Shortfalls V2", sheet("Baseline Weighted Supplements", modify) firstrow(variables)

use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 (rawsum) num_total [fw=num_total], by(SchoolName)
export excel using "FSF Supplements and Shortfalls V2", sheet("Baseline by School", modify) firstrow(variables)

// calculating supplements for table 1 with no fringe:

use "${int}/Funding Analysis File", clear 
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0 (rawsum) num_total [fw=num_total]
export excel using "FSF Supplements and Shortfalls V2", sheet("Baseline without fringe", modify) firstrow(variables)

//# race - FIGURE 4

foreach g in Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData {
use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0 (rawsum) `g' [fw=`g']
gen race="`g'"
save "${int}/temp_`g'.dta", replace
}
use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0 (rawsum) Asian [fw=Asian]
gen race="Asian"
foreach g in Black Hispanic MultiRacial NativeAmerican White MissingRaceEthnicityData {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta" 
	}
	
order race
export excel using "FSF Supplements and Shortfalls V2", sheet("By Race", modify) firstrow(variables) 

//# by ENI - FIGURE 3

foreach g in ENI_2_rounded ENI_3_rounded ENI_4_rounded {
use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0 (rawsum) `g' [fw=`g']
gen ENI="`g'"
save "${int}/temp_`g'.dta", replace
}

use "${int}/Funding Analysis File", clear
collapse  fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0  (rawsum) ENI_1_rounded [fw=ENI_1_rounded]
gen ENI="ENI_1_rounded"
foreach g in ENI_2_rounded ENI_3_rounded ENI_4_rounded {
	append using "${int}/temp_`g'"
	erase "${int}/temp_`g'.dta"
}
	
order ENI
export excel using "FSF Supplements and Shortfalls V2", sheet("Supplements and Shortfalls_ENI", modify) firstrow(variables) 

// by poverty - Figure 3

foreach g in Poverty_rounded NonPoverty_rounded {
use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0 (rawsum) `g' [fw=`g']
gen povertystatus="`g'"
save temp_`g', replace
}
use "${int}/Funding Analysis File", clear
collapse fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted shortfall_1 shortfall_2 shortfall_3 shortfall_4 shortfall_5 shortfall_1_above_0 shortfall_2_above_0 shortfall_3_above_0 shortfall_4_above_0 shortfall_5_above_0 no_fringe_shortfall_1 no_fringe_shortfall_2 no_fringe_shortfall_3 no_fringe_shortfall_4 no_fringe_shortfall_5 no_fringe_shortfall_1_above_0 no_fringe_shortfall_2_above_0 no_fringe_shortfall_3_above_0 no_fringe_shortfall_4_above_0 no_fringe_shortfall_5_above_0 (rawsum) Poverty_rounded [fw=Poverty_rounded]
gen povertystatus="poverty"
	append using temp_NonPoverty_rounded
	erase temp_Poverty_rounded.dta
	
	
order povertystatus
export excel using "FSF Supplements and Shortfalls V2", sheet("by Poverty", modify) firstrow(variables) 

// sum of fsf weighted supplement
use "${int}/Funding Analysis File", clear
collapse (sum) fsf_supplement_1_weighted fsf_supplement_2_weighted fsf_supplement_3_weighted fsf_supplement_4_weighted fsf_supplement_5_weighted [fw=num_total]
export excel using "FSF Supplements and Shortfalls V2", sheet("Sum of weighted supplements", modify) firstrow(variables) 

// sum of shortfalls greater than 0 
use "${int}/Funding Analysis File", clear
gen shortfall_1_amount_if_over_0 = shortfall_1 if shortfall_1 >0 & !missing(shortfall_1)
gen shortfall_2_amount_if_over_0 = shortfall_2 if shortfall_2 >0 & !missing(shortfall_2)
gen shortfall_3_amount_if_over_0 = shortfall_3 if shortfall_3 >0 & !missing(shortfall_3)
gen shortfall_4_amount_if_over_0 = shortfall_4 if shortfall_4 >0 & !missing(shortfall_4)
gen shortfall_5_amount_if_over_0 = shortfall_5 if shortfall_5 >0 & !missing(shortfall_5)
// gen shortfall_6_amount_if_over_0 = shortfall_6 if shortfall_6 >0

save "${int}/Funding Analysis File", replace

use "${int}/Funding Analysis File", clear
collapse (sum) shortfall_1_amount_if_over_0 shortfall_2_amount_if_over_0 shortfall_3_amount_if_over_0 shortfall_4_amount_if_over_0 shortfall_5_amount_if_over_0 [fw=num_total]
export excel using "FSF Supplements and Shortfalls V2", sheet("sum of shortfall if over 0", modify) firstrow(variables) 

// Calculating costs if ICT cap is 1.25 normal amount: 


glo main "K:\EDP\EDP_shared\Class size NYC\Essay #2" // this is the only line that needs to be edited for code to run. 

cd "${main}"

glo data "${main}/data"
glo raw "${data}/raw"
glo int "${data}/intermediate"
glo fin "${data}/final"

foreach var in data raw int fin{
	cap n mkdir "${`var'}"
}

* Set the URL for the Excel file

local url = "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx"

* Set a local file name to store the downloaded file
local localfile "avg_class_size_22-23.xlsx"	

* Download the file from the URL
cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx" "${raw}/avg_class_size_22-23.xlsx"

* Import the Excel file into Stata
import excel using "${raw}/avg_class_size_22-23.xlsx", sheet("K-8 Avg") firstrow clear

* Clean up by deleting the downloaded file
capture erase "`localfile'"


*Clean class size variables
*** getting rid of < or > values 
replace MinimumClassSize = "14" if MinimumClassSize == "<15"
replace MaximumClassSize = "14" if MaximumClassSize == "<15"

replace MinimumClassSize = "16" if MinimumClassSize == ">15"
replace MaximumClassSize = "16" if MaximumClassSize == ">15"

replace MinimumClassSize = "5" if MinimumClassSize == "<6"
replace MaximumClassSize = "5" if MaximumClassSize == "<6"

replace MinimumClassSize = "35" if MinimumClassSize == ">34"
replace MaximumClassSize = "35" if MaximumClassSize == ">34"

destring MinimumClassSize MaximumClassSize, replace

gen year=2022

gen g = GradeLevel
replace g="0" if g=="K"
replace g="-1" if g=="K-8 SC"
destring g, replace

*Setting a cap of 20 for K-8 SC but doesn't matter because they are all below*
gen cap = 20 if g>=-1 & g<=3
replace cap = 23 if g>=4 & g<=8
replace cap = 25 if g>=9 & g<=12

keep if g>=0 & g<=5

ren NumberofStudents num_total

*Baseline
rename NumberofClasses num_class0
gen num_teacher0 = num_class if ProgramType=="Gen Ed" | ProgramType=="G&T"
replace  num_teacher0 = num_class*2 if ProgramType=="ICT" | ProgramType=="ICT & G&T"

*Calculate number of SPED and non-SPED students in ICT classes
gen sped_count = floor(num_total * .4) if ProgramType == "ICT" // max 40% of students in ICT classes can be SPED
replace sped_count = 0 if missing(sped_count)

gen non_sped_count = num_total - sped_count if ProgramType == "ICT"
replace non_sped_count = num_total if ProgramType=="Gen Ed"

// Flag for whether a line is ICT or not before we mess with ProgramType
gen is_ICT = regexm(ProgramType, "ICT")

*Collapse ICT/Gen Ed classes
replace ProgramType="ICT/Gen Ed" if ProgramType=="ICT" | ProgramType=="Gen Ed"


collapse (sum) num_total sped_count non_sped_count num_teacher0 num_class0, by(DBN g ProgramType cap)

tab ProgramType

// Make new classroom cap variable
gen cap_ge = cap
gen cap_ict = cap

replace cap_ict = floor(1.25 * cap)

cap program drop ict_calcs

program define ict_calcs

*Calculate number of teachers needed for ICT/Gen Ed
gen max_sped_count = floor(cap_ict * .4) // How many SPED students can be in a single ICT class
gen max_non_sped_count = cap_ict - max_sped_count // How many GenEd students can be in a single ICT class

gen ict_needed = ceil(sped_count/max_sped_count) // Number of ICT Classes needed for the number of SPED students in school
gen ict_with_max_sped_students = floor(sped_count/max_sped_count) // How many ICT classes have max number of SPED students

gen sped_in_last_ict_class = mod(sped_count, max_sped_count) // How many SPED students are in the "last" ICT class in a grade

gen gen_ed_in_max_sped_classes = max_non_sped_count * ict_with_max_sped_students  // How many GenEd students are in "full" ICT classes 
gen gen_ed_in_last_ict_class = cap_ict - sped_in_last_ict_class // How many GenEd students are in the "last" ICT class in a grade

gen gen_ed_left_over = non_sped_count - gen_ed_in_max_sped_classes - gen_ed_in_last_ict_class // How many GenEd students need a non-ICT class
replace gen_ed_left_over = 0 if gen_ed_left_over < 0 // Make sure this number is not negative

gen gen_ed_needed = ceil(gen_ed_left_over/cap_ge) // How many GenEd classes are needed 

// Calculate Classes/teachers for GT classrooms
gen gt_classes_needed = 0
replace gt_classes_needed =  ceil(num_total/cap_ge) if ProgramType=="G&T" 
replace gt_classes_needed =  ceil(num_total/cap_ict) if ProgramType=="ICT & G&T"

gen gt_teachers_needed = 0
replace gt_teachers_needed = ceil(num_total/cap_ge) if ProgramType=="G&T" 
replace gt_teachers_needed = ceil(num_total/cap_ict) if ProgramType=="ICT & G&T"

replace gt_teachers_needed = gt_teachers_needed * 2 if ProgramType=="ICT & G&T"

gen total_classes_needed = ict_needed + gen_ed_needed + gt_classes_needed // Total number of classes in school-grade
gen total_teachers_needed = ict_needed*2 + gen_ed_needed + gt_teachers_needed // Total teachers needed

*Collapse by school
collapse (rawsum) num_total (sum) sped_count non_sped_count num_teacher0 num_class0 ict_needed gen_ed_needed gt_classes_needed total_classes_needed gt_teachers_needed total_teachers_needed, by(DBN g) 

*Count new teachers needed
gen new_teacher1 = total_teachers_needed-num_teacher0
replace new_teacher1 = 0 if new_teacher<0

end

preserve

ict_calcs

collapse (rawsum) num_total (sum) sped_count non_sped_count num_teacher0 num_class0 new_teacher1

gen district_avg_salary_benefits = (97607 + (97607 * .44))
gen v1_added_cost_district_salary = (district_avg_salary_benefits * (new_teacher1 * 1.2))
gen v1_added_per_pupil_cost_district = (v1_added_cost_district_salary / num_total)

gen just_salary = 97607
gen added_cost_no_fringe = (just_salary * (new_teacher1* 1.2))
gen added_per_pupil_cost_no_fringe = (added_cost_no_fringe / num_total)

sum added_cost_no_fringe added_per_pupil_cost_no_fringe

restore
