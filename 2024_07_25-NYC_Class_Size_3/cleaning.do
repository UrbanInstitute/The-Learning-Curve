// NYC Essay 3 - Cleaning Code
/*
This is the third in a series of essays analyzing the effects of implementing NYC's class size mandate. This code was written by Matt Chingos, Ariella Meltzer, and Jay Carter. 

*/

glo main "*******************" // this is the only line that needs to be edited for code to run. 

cd "${main}"

glo data "${main}/data"
glo raw "${data}/raw"
glo int "${data}/intermediate"
glo fin "${data}/final"

foreach var in data raw int fin{
	cap n mkdir "${`var'}"
}

cd "${raw}"

unzipfile "${main}/foia_zip.zip", replace

cd "${main}"


/// goal: create a file with counts of the number of new teachers needed by school, grade, and class type (ICT vs. everything else). This should use the 2023-24 data and the new ICT methodology we developed for the second essay.

cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/demographic-snapshot-2018-19-to-2022-23-(public).xlsx"  ///
	"${raw}/demographic_snapshot_2018-2023_NEW.xlsx"
	
*******************************************
* 1.) cleaning demographic file
*******************************************

import excel using "${raw}/demographic_snapshot_2018-2023_NEW.xlsx", sheet("School") firstrow clear // we still don't have 23-24 demo, so have to go back a year

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

drop Grade3K GradePKHalfDayFullDay // dropping pre-k

** Cleaning poverty and economic need index variables

replace pct_poverty = ".97" if pct_poverty == "Above 95%"
destring pct_poverty, replace

replace EconomicNeedIndex=".97" if EconomicNeedIndex=="Above 95%"
destring EconomicNeedIndex, replace

** creating ENI quartiles
xtile qu_ENI = EconomicNeedIndex [fweight=TotalEnrollment], n(4)

xtile qu_ENI_uw = EconomicNeedIndex, n(4)

tabstat EconomicNeedIndex, s(n min max) by(qu_ENI)

compress
sort DBN Year
save "${int}/22-23_demographics.dta", replace


*******************************************
* 1.) cleaning 23-24 class size file 
*******************************************

clear all

* Set the URL for the Excel file

local url = "https://infohub.nyced.org/docs/default-source/default-document-library/preliminary-2023-24-class-size---school.xlsx"

* Set a local file name to store the downloaded file
local localfile "avg_class_size_23-24.xlsx"	

* Download the file from the URL
cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/preliminary-2023-24-class-size---school.xlsx" ///
 "${raw}/avg_class_size_23-24.xlsx"

* Import the Excel file into Stata - K-5 ONLY
import excel using "${raw}/avg_class_size_23-24.xlsx", sheet("K-5 Average") firstrow clear

* Clean up by deleting the downloaded file
capture erase "`localfile'"

*Clean class size variables
tab MinimumClassSize // values of <15, <6, >15, and >34
tab MaximumClassSize

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

gen year=2023

gen g = GradeLevel
tab g ///1-6, Bridge - ES (4-5), Bridge - ES (K-3), Bridge - ES (K-5), K, K-8 SC

replace g="0" if g=="K"
replace g="-1" if g=="K-8 SC"
replace g="-2" if g=="Bridge - ES (4-5)"
replace g= "-2" if g=="Bridge - ES (K-3)"
replace g= "-2" if g=="Bridge - ES (K-5)"
destring g, replace

*Generating class size caps
gen cap = 20 if g>=-2 & g<=3
replace cap = 23 if g>=4 & g<=8
replace cap = 25 if g>=9 & g<=12

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
replace new_teacher1 = 0 if new_teacher1<0

save "${int}/23-24_K_5 Class Size Data Cleaned.dta", replace


// merge with demographics

sort DBN
merge m:1 DBN using "${int}/22-23_demographics.dta"
tab _merge
keep if _merge==3
drop _merge

foreach v in female male asian black hispanic multiracial nativeamerican white missingrace disabilities ELL poverty {
	gen num_`v' = round(pct_`v'*num_total, 1)
}

gen num_nonpoverty = num_total-num_poverty
gen num_nondisabilities = num_total-num_disabilities
gen num_nonELL = num_total-num_ELL

drop Grade6 Grade7 Grade8 Grade9 Grade10 Grade11 Grade12 
drop if g == -1 // dropping prek
drop if g == -2 // dropping prek
drop if g == 6 //dropping grade 6

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
save "${int}/23-24_K_5_class_size_demographics_file.dta", replace

//xtile qu_ENI_uw = EconomicNeedIndex, n(4)		

******************************************************************
** cleaning MS and HS class size 
******************************************************************

// demographics
use "${int}/22-23_demographics.dta", clear // this is the most up to date year we have
drop Female pct_female Male pct_male NeitherFemalenorMale pct_neitherfemaleormale
gen sending_school = substr(DBN,3,4)
gen receiving_school = substr(DBN,3,4)
save "${int}/22-23_demographics_for_transfers.dta", replace


import excel using "${raw}/avg_class_size_23-24.xlsx", sheet("MS HS Average") firstrow clear

* Clean up by deleting the downloaded file
capture erase "`localfile'"

*Clean class size variables
tab MinimumClassSize // values of <15, <6, >15, and >34
tab MaximumClassSize // values of <15, <6, >15, and >34

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

gen year=2023

gen g = GradeBand
tab g 
replace g="7" if g=="MS"
replace g="11" if g=="HS"
destring g, replace
drop GradeBand

*Generating class size caps
gen cap = 23 if g==7
replace cap = 25 if g==11
replace cap = 40 if Department == "Dance" | Department == "Music" | Department == "Physical Education and Health" | Department == "Theater"

ren NumberofStudents num_total

*Breakdown by department - how many additional teachers do we need by school and department?

tab Department
tab ProgramType

*Baseline 
rename NumberofClasses num_class0
gen num_teacher0 = num_class if ProgramType=="Gen Ed" | ProgramType=="Accelerated" | ProgramType =="Gen Ed & Acc"
replace  num_teacher0 = num_class*2 if ProgramType=="ICT" | ProgramType=="ICT & Acc"

*Calculate number of SPED and non-SPED students in ICT classes
gen sped_count = floor(num_total * .4) if ProgramType == "ICT" // max 40% of students in ICT classes can be SPED
replace sped_count = 0 if missing(sped_count)

gen non_sped_count = num_total - sped_count if ProgramType == "ICT"
replace non_sped_count = num_total if ProgramType=="Gen Ed"

*Collapse ICT/Gen Ed classes
replace ProgramType="ICT/Gen Ed" if ProgramType=="ICT" | ProgramType=="Gen Ed"


collapse (sum) num_total sped_count non_sped_count num_teacher0 num_class0, by(DBN g ProgramType Department cap) // collapsed by program type + department

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
gen acc_classes_needed = 0
replace acc_classes_needed =  ceil(num_total/cap) if ProgramType=="Accelerated" | ProgramType=="Gen Ed & Acc"

gen acc_teachers_needed = 0
replace acc_teachers_needed = ceil(num_total/cap) if ProgramType=="Accelerated" | ProgramType=="Gen Ed & Acc"
replace acc_teachers_needed = acc_teachers_needed * 2 if ProgramType=="ICT & Acc"

gen total_classes_needed = ict_needed + gen_ed_needed + acc_classes_needed // Total number of classes in school-grade
gen total_teachers_needed = ict_needed*2 + gen_ed_needed + acc_teachers_needed // Total teachers needed


*Collapse by school & department
collapse (rawsum) num_total (sum) sped_count non_sped_count num_teacher0 num_class0 ict_needed gen_ed_needed acc_classes_needed total_classes_needed acc_teachers_needed total_teachers_needed, by(DBN g Department) 

*Count new teachers needed
gen new_teacher1 = total_teachers_needed-num_teacher0
replace new_teacher1 = 0 if new_teacher1<0


save "${int}/23-24_MS HS Class Size Data Cleaned.dta", replace


********************************************************************
* merge with demographic data - MS/HS
********************************************************************

use "${int}/23-24_MS HS Class Size Data Cleaned.dta", replace

sort DBN
merge m:1 DBN using "${int}/22-23_demographics.dta"
tab _merge
keep if _merge==3
drop _merge

foreach v in female male asian black hispanic multiracial nativeamerican white missingrace disabilities ELL poverty {
	gen num_`v' = round(pct_`v'*num_total, 1)
}

gen num_nonpoverty = num_total-num_poverty
gen num_nondisabilities = num_total-num_disabilities
gen num_nonELL = num_total-num_ELL

drop TotalEnrollment GradeK Grade1 Grade2 Grade3 Grade4 Grade5		

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
save "${int}/23-24_MS_HS_class_size_demographics_file.dta", replace

// revising

// use "${int}/23-24_MS_HS_class_size_demographics_file.dta", clear

// collapse (rawsum) num_teacher0 new_teacher1, by(qu_ENI_uw)


***************************************************
**# INTERNAL AND EXTERNAL TEACHER HIRES - CLEANING 
***************************************************

//internal

import excel using "${raw}/internal teacher hires.xlsx", sheet("2023") firstrow clear
//import excel using "${raw}/internal teacher hires.xlsx", sheet("2022") firstrow clear (used this to get 2022 data)

drop BoroughCategory //already covered by BoroDetail and ToaDifferentBoro
drop DistrictCategory //already covered by DistrictDetail and ToaDifferentDistrict

unique CurrentTitle
replace CurrentTitle = "RegEd" if CurrentTitle == "TRTRQ"
replace CurrentTitle = "SpecialEd" if CurrentTitle == "TRTSQ"

unique ReportDate
drop ReportDate

gen sending_school = CurrentLocationfrom
gen receiving_school = SelectedLocationto
save "${int}/2023 internal teacher hires.dta", replace
//save "${int}/2022 internal teacher hires.dta", replace

//external

import excel using "${raw}/external teacher hires.xlsx", sheet("2023") firstrow clear

replace Title = "RegEd" if Title == "TRTRQ"
replace Title = "SpecialEd" if Title == "TRTSQ"

gen receiving_school = Location
ren Borough SelectedBorough
ren District SelectedDistrict
gen external_transfer = 1


save "${int}/2023 external teacher hires.dta", replace

// demo + external hires = receiving schools

use "${int}/22-23_demographics_for_transfers.dta", replace
merge 1:m receiving_school using "${int}/2023 external teacher hires.dta"

drop if _merge == 1

gen receiving_school_new = 0
replace receiving_school_new = 1 if strpos(receiving_school, "K") > 0 | strpos(receiving_school, "M") > 0 | strpos(receiving_school, "Q") > 0 | strpos(receiving_school, "R") > 0 | strpos(receiving_school, "X") > 0

save "${int}/2023 external teacher hires.dta", replace

// save "${int}/2022 external teacher hires.dta", replace


****************************************
// COMBINING SENDING AND RECEIVING FILES
****************************************

//combining files

clear all

preserve
	use "K:\EDP\EDP_shared\Class size NYC\Essay #3\data\intermediate\22-23_demographics_for_transfers.dta", clear
	rename * send_*
	rename send_sending_school sending_school

	tempfile sending
	save `sending', replace
restore	

preserve
	use "K:\EDP\EDP_shared\Class size NYC\Essay #3\data\intermediate\22-23_demographics_for_transfers.dta", clear
	rename * rec_*
	rename rec_receiving_school receiving_school
	tempfile receive

	save `receive', replace
restore	

use "K:\EDP\EDP_shared\Class size NYC\Essay #3\data\intermediate\2023 internal teacher hires.dta", clear

merge m:1 sending_school using `sending', gen(merge_send)
drop if merge_send == 2
merge m:1 receiving_school using `receive', gen(merge_rec)
drop if merge_rec == 2

drop send_receiving_school rec_sending_school merge_*

gsort AnonymousID

order CurrentBorough SelectedBorough BoroDetails CurrentDistrict SelectedDistrict DistDetails, after(AnonymousID)
order CurrentLocationfrom SelectedLocationto sending_school, after(DistDetails)

save "data\intermediate\2023 internal hires_sending & receiving.dta", replace


// appending with external hires
append using "${int}/2023 external teacher hires.dta", gen(external_hires)
drop Location
ren external_hires external_hire
save "${int}/2023 internal and external teacher hires.dta", replace

// breaking down licenses

** INTERNAL TRANSFERS

gen bilingual_license = CurrentLicense if ///
    (CurrentLicense == "BIL BIO AND GEN SCI SPANISH " | ///
    CurrentLicense == "BIL CB SUBJECTS (MANDARIN) " | ///
    CurrentLicense == "BIL SOCIAL STUDIES MANDARIN " | ///
    CurrentLicense == "BILINGUAL COMMON BRANCHES SPANISH " | ///
    CurrentLicense == "BILINGUAL EC SPANISH " | ///
    CurrentLicense == "BILINGUAL ECC CHINESE MANDARIN " | ///
    CurrentLicense == "BILINGUAL SOCIAL STUDIES SPANISH " | ///
    CurrentLicense == "BILINGUAL SPCH IMPROVEMENT CANTON " | ///
    CurrentLicense == "BILINGUAL SPECIAL ED MANDARIN " | ///
    CurrentLicense == "BILINGUAL SPECIAL EDUCATION SPANISH " | ///
	CurrentLicense == "ENGLISH AS A SECOND LANGUAGE " | ///
    CurrentLicense == "BILINGUAL SPECIAL EDUCATION YIDDISH ")
ren bilingual_license int_bilingual_license
	
gen language_license = CurrentLicense if ///
	(CurrentLicense == "CHINESE ") | ///
	(CurrentLicense == "FRENCH ") | ///
	(CurrentLicense == "ITALIAN ") | ///
	(CurrentLicense == "SPANISH ")
ren language_license int_language_license
	
gen stem_license = CurrentLicense if ///
	(CurrentLicense == "BIOLOGY AND GENERAL SCIENCE ") | ///
	(CurrentLicense == "MATHEMATICS ") | ///
	(CurrentLicense == "TECHNOLOGY EDUCATION ") | ///
	(CurrentLicense == "CHEMISTRY AND GENERAL SCIENCE ") | ///
	(CurrentLicense == "EARTH SCIENCE AND GENERAL SCIENCE ") | ///
	(CurrentLicense == "PHYSICS AND GENERAL SCIENCE ") | ///
	(CurrentLicense == "GENERAL SCIENCE ") | ///
	(CurrentLicense == "HEALTH ")
ren stem_license int_stem_license
	
gen english_license = CurrentLicense if ///
	(CurrentLicense == "ENGLISH ") | ///
	(CurrentLicense == "LIBRARY ") | ///
	(CurrentLicense == "READING ") | ///
	(CurrentLicense == "SOCIAL STUDIES ")
ren english_license int_english_license

gen phys_ed_license = CurrentLicense if (CurrentLicense == "PHYSICAL EDUCATION ") | (CurrentLicense == "SWIMMING AND PHYSICAL EDUCATION ")
ren phys_ed_license int_phys_ed_license

gen career_license = CurrentLicense if (CurrentLicense == "ACCOUNTING AND BUSINESS PRACTICE DHS") | (CurrentLicense == "ELEC INSTALL & PRAC DHS") | (CurrentLicense == "NURSING ")
ren career_license int_career_license
	
gen special_education = CurrentLicense if ///
	(CurrentLicense == "SPEECH IMPROVEMENT ") | ///
	(CurrentLicense == "SPEECH ") | ///
	(CurrentLicense == "STUDENTS WITH DISABILITIES MATHEMATICS 7-12 ") | ///
	(CurrentLicense == "STUDENTS WITH DISABILITIES BIOLOGY 7-12 ") | ///
	(CurrentLicense == "STUDENTS WITH DISABILITIES ENGLISH 7-12 ") | ///
	(CurrentLicense == "STUDENTS WITH DISABILITIES SOC STUDIES 7-12 ") | ///
	(CurrentLicense == "STUDENTS WITH DISABILITIES CHEMISTRY 7-12 ") | ///
	(CurrentLicense == "SPECIAL EDUCATION ")
ren special_education int_sped_license
	
gen arts_license = CurrentLicense if ///
	(CurrentLicense == "COMMERCIAL ART ") | ///
	(CurrentLicense == "DANCE ") | ///
	(CurrentLicense == "FINE ARTS ") | ///
	(CurrentLicense == "VOCAL MUSIC ") | ///
	(CurrentLicense == "ORCHESTRAL MUSIC ") | ///
	(CurrentLicense == "MUSIC ") | ///
	(CurrentLicense == "PERFORMING ARTS DRAMA ") | ///
	(CurrentLicense == "PERFORMING ARTS RADIO ") | ///
	(CurrentLicense == "PERFORMING ARTS MUSIC ") | ///
	(CurrentLicense == "PERFORMING ARTS DANCE ") | ///
	(CurrentLicense == "PERFORMING ARTS DANCE MODERN ")
ren arts_license int_arts_license
	
gen elem_license = CurrentLicense if ///
	(CurrentLicense == "COMMON BRANCHES ")	
ren elem_license int_elem_license
ren int_elem_license int_common_branches
	
gen other_license = CurrentLicense if ///
	(CurrentLicense == "CAFETERIA & CATERING ") | ///
	(CurrentLicense == "EARLY CHILDHOOD CLASSES ") | ///
	(CurrentLicense == "GENERALIST ") | ///
	(CurrentLicense == "HOMEBOUND ") | ///
	(CurrentLicense == "OFFSET PRESSWORK ") | ///
	(CurrentLicense == "HOME ECONOMICS ")	
ren other_license int_other_license

** EXTERNAL LICENSES

gen ext_bilingual_license = LicDesc if ///
    (LicDesc == "BILINGUAL COMMON BRANCHES SPANISH DES") | ///
    (LicDesc == "BILINGUAL SOCIAL STUDIES SPANISH DHS") | ///
    (LicDesc == "BIL CB SUBJECTS (MANDARIN) DES") | ///
    (LicDesc == "BIL COMMON BRANCHES ARABIC DES") | ///
    (LicDesc == "BIL MUSIC ITALIAN DAY") | ///
	(LicDesc == "BIL SPEECH IMPROVEMENT SPANISH DAY") | ///
    (LicDesc == "BILINGUAL COMMON BRANCHES POLISH DES") | ///
    (LicDesc == "BILINGUAL EARLY CHILDHOOD RUSSIAN DES") | ///
    (LicDesc == "BILINGUAL EC SPANISH DES") | ///
    (LicDesc == "BILINGUAL SPECIAL ED MANDARIN DAY") | ///
	(LicDesc == "BILINGUAL SPECIAL EDUCATION SPANISH DAY") | ///
	(LicDesc == "BILINGUAL SPEECH PATHOLOG") | ///
	(LicDesc == "ENGLISH AS A SECOND LANGUAGE") | ///
	(LicDesc == "ENGLISH AS A SECOND LANGUAGE SEC") | ///
    (LicDesc == "BILINGUAL SPECIAL EDUCATION YIDDISH DAY")
	
gen ext_language_license = LicDesc if ///
    (LicDesc == "CHINESE DHS") | ///
    (LicDesc == "CHINESE JHS") | ///
    (LicDesc == "FRENCH DHS") | ///
    (LicDesc == "ITALIAN DHS") | ///
    (LicDesc == "JAPANESE DHS") | ///
	(LicDesc == "LATIN DHS") | ///
    (LicDesc == "MANDARIN DHS") | ///
    (LicDesc == "RUSSIAN DHS") | ///
    (LicDesc == "SPANISH DHS")
	
gen ext_stem_license = LicDesc if ///
    (LicDesc == "AGRICULTURE DHS") | ///
    (LicDesc == "AVIATION MECHANICS DHS") | ///
    (LicDesc == "BIOLOGY AND GENERAL SCIENCE DHS") | ///
    (LicDesc == "CHEMISTRY AND GENERAL SCIENCE DHS") | ///
    (LicDesc == "COMPUTER SCIENCE") | ///
	(LicDesc == "COMPUTER TECHNOLOGY DHS") | ///
    (LicDesc == "EARTH SCIENCE AND GENERAL SCIENCE DHS") | ///
    (LicDesc == "GENERAL SCIENCE JHS") | ///
	(LicDesc == "HEALTH JHS") | ///
	(LicDesc == "NATURAL RES AND ECOLOGY D") | ///
	(LicDesc == "PHYSICS AND GENERAL SCIENCE DHS") | ///
	(LicDesc == "TECHNOLOGY EDUCATION DHS") | ///
    (LicDesc == "HEALTH DHS")
	
gen ext_english_license = LicDesc if ///
	(LicDesc == "ENGLISH DHS") | ///
    (LicDesc == "LIBRARY SEC") | ///
    (LicDesc == "READING DAY") | ///
    (LicDesc == "SOCIAL STUDIES") | ///
    (LicDesc == "SOCIAL STUDIES DHS")

gen ext_phys_ed_license = LicDesc if ///
	(LicDesc == "PHYSICAL EDUCATION DHS")

gen ext_career_license = LicDesc if ///
    (LicDesc == "ACCOUNTING AND BUSINESS PRACTICE DHS") | ///
    (LicDesc == "ARCHITECT DRAFTING DHS") | ///
    (LicDesc == "COSMETOLOGY DHS") | ///
    (LicDesc == "ELEC INSTALL & PRAC DHS") | ///
    (LicDesc == "ENTREPRENEURSHIP") | ///
	(LicDesc == "MECHANICAL STRUCTURAL CIVIL TECH DHS") | ///
    (LicDesc == "MEDICAL ASSISTING") | ///
    (LicDesc == "MILITARY SCIENCE") | ///
	(LicDesc == "NURSING DHS") | ///
	(LicDesc == "PHARMACY ASSISTANT") 
	
gen ext_special_education = LicDesc if ///
    (LicDesc == "BLIND DAY") | ///
    (LicDesc == "DEAF AND HARD OF HEARING") | ///
    (LicDesc == "DEAF AND HARD OF HEARING DAY") | ///
    (LicDesc == "SPECIAL EDUCATION") | ///
    (LicDesc == "SPEECH DHS") | ///
	(LicDesc == "SPEECH IMPROVEMENT") | ///
    (LicDesc == "SPEECH IMPROVEMENT DAY") | ///
    (LicDesc == "SWD BIOLOGY DHS") | ///
	(LicDesc == "SWD ENGLISH DHS") | ///
	(LicDesc == "SWD GENERAL SCIENCE JHS") | ///
	(LicDesc == "SWD MATHEMATICS DHS") | ///
	(LicDesc == "SWD SOCIAL STUDIES DHS")
	
gen ext_arts_license = LicDesc if ///
	(LicDesc == "COMMERCIAL ART DHS") | ///
	(LicDesc == "DANCE DAY") | ///
	(LicDesc == "FINE ARTS") | ///
	(LicDesc == "FINE ARTS DAY") | ///
	(LicDesc == "ORCHESTRAL MUSIC DAY") | ///
	(LicDesc == "PERF THEATRE ARTS - DRAMA DHS") | ///
	(LicDesc == "PERFORMING ARTS RADIO DHS") | ///
	(LicDesc == "VOCAL MUSIC DAY")
	
gen ext_common_branches = LicDesc if ///
	(LicDesc == "COMMON BRANCHES") | ///
	(LicDesc == "COMMON BRANCHES DES") | ///
	(LicDesc == "GENERALIST IN MIDDLE SCHOOL")
	
gen ext_other_license = LicDesc if ///
	(LicDesc == "CAFETERIA & CATERING DHS") | ///
	(LicDesc == "EARLY CHILDHOOD CLASSES") | ///
	(LicDesc == "EARLY CHILDHOOD CLASSES DES") | ///
	(LicDesc == "LICENSE UNKNOWN")
	
	
save "${int}/2023 internal and external teacher hires.dta", replace

// sorting grade levels 

** K - 5 ** 
gen send_K_5 = send_GradeK + send_Grade1 + send_Grade2 + send_Grade3 + send_Grade4 + send_Grade5
gen rec_K_5 = rec_GradeK + rec_Grade1 + rec_Grade2 + rec_Grade3 + rec_Grade4 + rec_Grade5

** middle + high ** 
gen send_6_12 = send_Grade6 + send_Grade7 + send_Grade8 + send_Grade9 + send_Grade10 + send_Grade11 + send_Grade12
gen rec_6_12 = rec_Grade6 + rec_Grade7 + rec_Grade8 + rec_Grade9 + rec_Grade10 + rec_Grade11 + rec_Grade12

drop send_GradeK send_Grade1 send_Grade2 send_Grade3 send_Grade4 send_Grade5 send_Grade6 send_Grade7 send_Grade8 send_Grade9 send_Grade10 send_Grade11 send_Grade12 rec_GradeK rec_Grade1 rec_Grade2 rec_Grade3 rec_Grade4 rec_Grade5 rec_Grade6 rec_Grade7 rec_Grade8 rec_Grade9 rec_Grade10 rec_Grade11 rec_Grade12

save "${int}/2023 internal and external teacher hires.dta", replace

gen send_elem_school = 1 if send_K_5>0
	replace send_elem_school = 0 if send_elem_school ==.
gen rec_elem_school = 1 if rec_K_5>0
	replace rec_elem_school = 0 if rec_elem_school ==.
gen send_ms_hs = 1 if send_6_12>0
	replace send_ms_hs = 0 if send_ms_hs ==.
gen rec_ms_hs = 1 if rec_6_12>0
	replace rec_ms_hs = 0 if rec_ms_hs ==.
	
// further sorting subjects
	
gen int_subject_license =.
	replace int_subject_license = 1 if int_bilingual_license != ""
	replace int_subject_license = 2 if int_language_license != ""
	replace int_subject_license = 3 if int_stem_license != ""
	replace int_subject_license = 4 if int_english_license != ""
	replace int_subject_license = 5 if int_phys_ed_license != ""
	replace int_subject_license = 6 if int_career_license != ""
	replace int_subject_license = 7 if int_sped_license != ""
	replace int_subject_license = 8 if int_arts_license != ""
	replace int_subject_license = 9 if int_common_branches != ""
	replace int_subject_license = 10 if int_other_license != ""
	
rename ext_special_education ext_sped_license
	
gen ext_subject_license =. 
	replace ext_subject_license = 1 if ext_bilingual_license != ""
	replace ext_subject_license = 2 if ext_language_license != ""
	replace ext_subject_license = 3 if ext_stem_license != ""
	replace ext_subject_license = 4 if ext_english_license != ""
	replace ext_subject_license = 5 if ext_phys_ed_license != ""
	replace ext_subject_license = 6 if ext_career_license != ""
	replace ext_subject_license = 7 if ext_sped_license != ""
	replace ext_subject_license = 8 if ext_arts_license != ""
	replace ext_subject_license = 9 if ext_common_branches != ""
	replace ext_subject_license = 10 if ext_other_license != ""
	
// breaking down by just sped vs. non-sped 

gen int_non_sped_license = int_bilingual_license + int_language_license + int_stem_license +int_english_license + int_phys_ed_license + int_career_license + int_arts_license + int_common_branches + int_other_license
gen ext_non_sped_license = ext_bilingual_license + ext_language_license + ext_stem_license +  ext_english_license + ext_phys_ed_license + ext_career_license + ext_arts_license + ext_common_branches + ext_other_license

label var send_qu_ENI "sending economic index"
label var rec_qu_ENI "receiving economic index"

save "${int}/2023 internal and external teacher hires v2.dta", replace

do "${main}/analysis.do"