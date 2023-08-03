///  NYC Class-Size Do-file for code check: this just produces the tables included in the essay. ///

glo wd "*******"
glo data "${wd}/data"

cap n mkdir "${data}"

net install urbanschemes, replace from("https://urbaninstitute.github.io/urbanschemes/")
	
set scheme urbanschemes
graph set window fontface "Lato"
	

cd "${wd}"

*1.) DOWNLOAD DEMOGRAPHIC DATA FROM WEB

clear all

* Set the URL for the Excel file

local url = "https://infohub.nyced.org/docs/default-source/default-document-library/demographic-snapshot-2018-19-to-2022-23-(public).xlsx"

* Set a local file name to store the downloaded file
local localfile "demographic_snapshot_2018-2023_NEW.xlsx"

* Download the file from the URL
cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/demographic-snapshot-2018-19-to-2022-23-(public).xlsx" "${data}/demographic_snapshot_2018-2023_NEW.xlsx"

* Import the Excel file into Stata
import excel using "${data}/demographic_snapshot_2018-2023_NEW.xlsx", sheet("School") firstrow

* Clean up by deleting the downloaded file
capture erase "`localfile'"

** Renaming variables
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

**dropping years before 22-23
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
save "${data}/22-23_demographics.dta", replace

* 2.) CLEANING CLASS SIZE DATA K-8 

clear all

* Set the URL for the Excel file

local url = "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx"

* Set a local file name to store the downloaded file
local localfile "avg_class_size_22-23.xlsx"

* Download the file from the URL
cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx" "${data}/avg_class_size_22-23.xlsx"

* Import the Excel file into Stata
import excel using "${data}/avg_class_size_22-23.xlsx", sheet("K-8 Avg") firstrow clear

* Clean up by deleting the downloaded file
capture erase "`localfile'"


*Clean class size variables
*** getting rid of < or > values 
replace MinimumClassSize = "14" if MinimumClassSize == "<15"
replace MaximumClassSize = "14" if MaximumClassSize == "<15"

*Assuming this 1 observation is a typo
replace MinimumClassSize = "14" if MinimumClassSize == ">15"
replace MaximumClassSize = "14" if MaximumClassSize == ">15"

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

save "${data}/22-23_K-8 Class Size Data Cleaned.dta", replace

* merge with demographic data 
sort DBN
merge m:1 DBN using "${data}/22-23_demographics.dta"

keep if _merge==3 // only drops 1 school from master file - THE CHILDREN's SCHOOL 
drop _merge

*Generate compliance/non-compliance
gen treated1 = (AverageClassSize>cap) // this one is our main interest for compliance. we do NOT use treated2 for any of the tables. 
gen treated2 = (MaximumClassSize>cap)

ren NumberofStudents num_total

foreach v in female male asian black hispanic multiracial nativeamerican white missingrace disabilities ELL poverty {
	gen num_`v' = round(pct_`v'*num_total,1)
}

gen num_nonpoverty = num_total-num_poverty
gen num_nondisabilities = num_total-num_disabilities
gen num_nonELL = num_total-num_ELL

*Create tag for borough for DBN
// K = Brooklyn, X = Bronx, Q = Queens, M = Manhattan, R = Staten Island
gen borough = substr(DBN,3,1)
replace borough="Brooklyn" if b=="K"
replace borough="Bronx" if b=="X"
replace borough="Queens" if b=="Q"
replace borough="Manhattan" if b=="M"
replace borough="Staten Island" if b=="R"

gen district = substr(DBN,1,2)
tab district

compress
save "${data}/22-23_K-8_merged_file.dta", replace

keep DBN SchoolName ProgramType borough district num_total pct_poverty year g treated* num_*
save "${data}/K-8_analysis.dta", replace

*Calculate treatment rate by characteristics (in tables, this is % of students whose class size is reduced)
use "${data}/K-8_analysis.dta", clear 
collapse treated* (rawsum) num_total [fw=num_total]
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_All") firstrow(variables) replace  

use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_total [fw=num_total], by(g)
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byGrade", modify) firstrow(variables)

*Repeat above by District and by Borough (Table A3)

** Borough: 
use "${data}/K-8_analysis.dta", clear
**# Bookmark #1
collapse treated* (rawsum) num_total [fw=num_total], by(borough)
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byborough") firstrow(variables)

** District
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_total [fw=num_total], by(district)
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byDistrict") firstrow(variables) 

** calculating pct_poverty in each borough and district for table A3

use "${data}/K-8_analysis.dta", clear
collapse pct_poverty, by(borough)
export excel using "${data}/K-8_Treatment Outputs", sheet("poverty_byborough") firstrow(variables) 

use "${data}/K-8_analysis.dta", clear
collapse pct_poverty, by(district)
export excel using "${data}/K-8_Treatment Outputs", sheet("poverty_bydistrict") firstrow(variables) 

*By Race code (for figure 1, figure 2, and Table A1)
foreach g in black hispanic multiracial nativeamerican white missingrace {
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen race="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_asian [fw=num_asian]
gen race="asian"
ren num_asian num
foreach g in black hispanic multiracial nativeamerican white missingrace {
	append using temp_`g'
	erase temp_`g'.dta
}
order race
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byRace") firstrow(variables) 

*repeat for num_disabilities num_nondisabilities (Table A2)

foreach g in disabilities nondisabilities {
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen disabilitystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_disabilities [fw=num_disabilities]
ren num_disabilities num
gen disabilitystatus="disabilities"
append using temp_nondisabilities
erase temp_nondisabilities.dta

order disabilitystatus
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byDisability") firstrow(variables) 

* repeat for num_ELL num_nonELL (Table A2)
foreach g in ELL nonELL {
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen ELLstatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_ELL [fw=num_ELL]
ren num_ELL num
gen ELLstatus = "ELL"
append using temp_nonELL
erase temp_nonELL.dta

order ELLstatus
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byELLStatus") firstrow(variables) 

* repeat for num_poverty num_nonpoverty (Figure 1 and Table A2)
foreach g in poverty nonpoverty {
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen povertystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse treated* (rawsum) num_poverty [fw=num_poverty]
ren num_poverty num
gen povertystatus="poverty"
	append using temp_nonpoverty
	erase temp_poverty.dta
	
order povertystatus
export excel using "${data}/K-8_Treatment Outputs", sheet("Treat_byPoverty") firstrow(variables) 

*Calculate distribution of total class-size reductions (all tables/figures except for Figure 1)

use "${data}/22-23_K-8_merged_file.dta", clear

*Simulate change in average class size: loop

gen new_average_cs = AverageClassSize
gen new_numclass = NumberofClasses

forval v = 0/30 {
gen new_numclass_`v' = `v' if new_average_cs > cap
replace new_numclass = new_numclass+1 if new_average_cs>cap
replace new_average_cs = num_total/new_numclass
}

gen reduction_cs = AverageClassSize - new_average_cs
tab reduction_cs

keep DBN SchoolName ProgramType AverageClassSize new_average_cs borough district reduction_cs num_total year g treated* num_*
save "${data}/K-8_analysis.dta", replace

* repeat all code for treated tables for reduction tables

use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total]
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_All", modify) firstrow(variables) 

use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total], by(g)
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byGrade", modify) firstrow(variables) 

use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total], by(borough)
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byborough", modify) firstrow(variables) 

use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total], by(district)
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byDistrict", modify) firstrow(variables) 

** by race

foreach g in black hispanic multiracial nativeamerican white missingrace {
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen race="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_asian [fw=num_asian]
gen race="asian"
ren num_asian num
foreach g in black hispanic multiracial nativeamerican white missingrace {
	append using temp_`g'
	erase temp_`g'.dta
}
order race
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byRace", modify) firstrow(variables) 

** by disability

foreach g in disabilities nondisabilities {
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen disabilitystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_disabilities [fw=num_disabilities]
ren num_disabilities num
gen disabilitystatus="disabilities"
append using temp_nondisabilities
erase temp_nondisabilities.dta

order disabilitystatus
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byDisability_3", modify) firstrow(variables) 

* repeat for num_ELL num_nonELL 
foreach g in ELL nonELL {
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen ELLstatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_ELL [fw=num_ELL]
ren num_ELL num
gen ELLstatus = "ELL"
append using temp_nonELL
erase temp_nonELL.dta

order ELLstatus
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byELL", modify) firstrow(variables) 

* repeat for num_poverty num_nonpoverty
foreach g in poverty nonpoverty {
use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen povertystatus="`g'"
ren num_`g' num
save temp_`g', replace
}

use "${data}/K-8_analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_poverty [fw=num_poverty]
ren num_poverty num
gen povertystatus="poverty"
append using temp_nonpoverty
erase temp_poverty.dta
	
order povertystatus
export excel using "${data}/K-8_Reduction Outputs", sheet("Reduction_byPoverty", modify) firstrow(variables) 

*3.) CLEANING MIDDLE AND HIGH SCHOOL CLASS SIZE DATA // basically all code above is repeated for high school/middle school. 

* Set the URL for the Excel file

local url = "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx"

* Set a local file name to store the downloaded file
local localfile "avg_class_size_22-23.xlsx"

* Download the file from the URL
cap n copy "https://infohub.nyced.org/docs/default-source/default-document-library/updated2023_avg_classsize_schl.xlsx" "${data}/avg_class_size_22-23.xlsx"

* Import the Excel file into Stata
import excel using "${data}/avg_class_size_22-23.xlsx", sheet("MS HS Avg") firstrow clear

* Clean up by deleting the downloaded file
capture erase "`localfile'"

** Cleaning class size variables 

*** getting rid of < or > values 
replace MinimumClassSize = "14" if MinimumClassSize == "<15"
replace MaximumClassSize = "14" if MaximumClassSize == "<15"

***Assuming these 29/122 observations are typos
replace MinimumClassSize = "14" if MinimumClassSize == ">15"
replace MaximumClassSize = "14" if MaximumClassSize == ">15"

replace MinimumClassSize = "5" if MinimumClassSize == "<6"
replace MaximumClassSize = "5" if MaximumClassSize == "<6"

replace MinimumClassSize = "35" if MinimumClassSize == ">34"
replace MaximumClassSize = "35" if MaximumClassSize == ">34"

destring MinimumClassSize MaximumClassSize, replace

gen year=2022

*cap of 23 for 6-8, 25 for 9-12

gen g = GradeLevel
replace g="7" if g=="MS Core"
replace g="10" if g=="HS Core"
destring g, replace
gen cap = 23 if g==7
replace cap = 25 if g==10

save "${data}/22_23_MS HS Class Size Cleaned.dta", replace

*5.) MERGE IN DEMOGRAPHIC DATA
**# Bookmark #2

sort DBN
merge m:1 DBN using "${data}/22-23_demographics.dta"

keep if _merge==3 
drop _merge

*Generate compliance/non-compliance
gen treated1 = (AverageClassSize>cap) // this one is our main interest for compliance
gen treated2 = (MaximumClassSize>cap)

ren NumberofStudents num_total
foreach v in female male asian black hispanic multiracial nativeamerican white missingrace disabilities ELL poverty {
	gen num_`v' = round(pct_`v'*num_total,1)
}

gen num_nonpoverty = num_total-num_poverty
gen num_nondisabilities = num_total-num_disabilities
gen num_nonELL = num_total-num_ELL

compress
save "${data}/22_23_HS MS merged_file.dta", replace

*Create tag for borough for DBN
// K = Brooklyn, X = Bronx, Q = Queens, M = Manhattan, R = Staten Island
gen borough = substr(DBN,3,1)
replace borough="Brooklyn" if b=="K"
replace borough="Bronx" if b=="X"
replace borough="Queens" if b=="Q"
replace borough="Manhattan" if b=="M"
replace borough="Staten Island" if b=="R"

gen district = substr(DBN,1,2)
tab district

save "${data}/22_23_HS MS merged_file.dta", replace

* 6.) HS MS ANALYSIS

use "${data}/22_23_HS MS merged_file.dta", clear
keep DBN SchoolName ProgramType borough district num_total pct_poverty year g treated* num_* 
save "${data}/HS MS analysis.dta", replace

*Calculate treatment rate by characteristics
use "${data}/HS MS analysis.dta", clear 
collapse treated* (rawsum) num_total [fw=num_total]
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_All") firstrow(variables) replace

use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_total [fw=num_total], by(g)
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byGrade") firstrow(variables)

*Repeat above by District and by Borough

** Borough: 
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_total [fw=num_total], by(borough)
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byborough") firstrow(variables)

** District
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_total [fw=num_total], by(district)
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byDistrict") firstrow(variables)

use "${data}/HS MS analysis.dta", clear
collapse (mean) pct_poverty, by(borough)
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("pct_poverty_borough") firstrow(variables)

use "${data}/HS MS analysis.dta", clear
collapse (mean) pct_poverty, by(district)
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("pct_poverty_district") firstrow(variables)

*By Race code:
foreach g in black hispanic multiracial nativeamerican white missingrace {
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen race="`g'"
ren num_`g' num
save temp_`g', replace
}

use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_asian [fw=num_asian]
gen race="asian"
ren num_asian num
foreach g in black hispanic multiracial nativeamerican white missingrace {
	append using temp_`g'
	erase temp_`g'.dta
}
order race
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byRace") firstrow(variables) 

*repeat for num_disabilities num_nondisabilities 

foreach g in disabilities nondisabilities {
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen disabilitystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_disabilities [fw=num_disabilities]
ren num_disabilities num
gen disabilitystatus="disabilities"
append using temp_nondisabilities
erase temp_nondisabilities.dta

order disabilitystatus
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byDisability") firstrow(variables) 

* repeat for num_ELL num_nonELL 
foreach g in ELL nonELL {
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen ELLstatus="`g'"
ren num_`g' num
save temp_`g', replace
}

use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_ELL [fw=num_ELL]
ren num_ELL num
gen ELLstatus = "ELL"
	append using temp_nonELL
	erase temp_nonELL.dta

order ELLstatus
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byELLStatus") firstrow(variables) 

* repeat for num_poverty num_nonpoverty
foreach g in poverty nonpoverty {
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_`g' [fw=num_`g']
gen povertystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/HS MS analysis.dta", clear
collapse treated* (rawsum) num_poverty [fw=num_poverty]
ren num_poverty num
gen povertystatus="poverty"
	append using temp_nonpoverty
	erase temp_poverty.dta
	
order povertystatus
export excel using "${data}/MS_HS_Treatment_Outputs", sheet("Treat_byPoverty") firstrow(variables) 

*Calculate distribution of total class-size reductions
**# Bookmark #2

use "${data}/22_23_HS MS merged_file.dta", clear

*Simulate change in average class size: loop

gen new_average_cs = AverageClassSize
gen new_numclass = NumberofClasses

forval v = 0/30 {
gen new_numclass_`v' = `v' if new_average_cs > cap
replace new_numclass = new_numclass+1 if new_average_cs>cap
replace new_average_cs = num_total/new_numclass
}

gen reduction_cs = AverageClassSize - new_average_cs
tab reduction_cs

keep DBN SchoolName ProgramType borough district AverageClassSize new_average_cs reduction_cs num_total year g treated* num_*
save "${data}/HS MS analysis.dta", replace

* repeat all code for treated for reduction

use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total]
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_All", modify) firstrow(variables) 

use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total], by(g)
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byGrade", modify) firstrow(variables) 

use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total], by(borough)
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byborough", modify) firstrow(variables) 

use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_total [fw=num_total], by(district)
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byDistrict", modify) firstrow(variables) 

** by race

foreach g in black hispanic multiracial nativeamerican white missingrace {
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen race="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_asian [fw=num_asian]
gen race="asian"
ren num_asian num
foreach g in black hispanic multiracial nativeamerican white missingrace {
	append using temp_`g'
	erase temp_`g'.dta
}
order race
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byRace", modify) firstrow(variables) 

** by disability

foreach g in disabilities nondisabilities {
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen disabilitystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_disabilities [fw=num_disabilities]
ren num_disabilities num
gen disabilitystatus="disabilities"
append using temp_nondisabilities
erase temp_nondisabilities.dta

order disabilitystatus
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byDisability", modify) firstrow(variables) 

* repeat for num_ELL num_nonELL 
foreach g in ELL nonELL {
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen ELLstatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_ELL [fw=num_ELL]
ren num_ELL num
gen ELLstatus = "ELL"
append using temp_nonELL
erase temp_nonELL.dta

order ELLstatus
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byELL", modify) firstrow(variables) 

* repeat for num_poverty num_nonpoverty
foreach g in poverty nonpoverty {
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_`g' [fw=num_`g']
gen povertystatus="`g'"
ren num_`g' num
save temp_`g', replace
}
use "${data}/HS MS analysis.dta", clear
collapse reduction_cs AverageClassSize new_average_cs (rawsum) num_poverty [fw=num_poverty]
ren num_poverty num
gen povertystatus="poverty"
append using temp_nonpoverty
erase temp_poverty.dta
	
order povertystatus
export excel using "${data}/MS_HS_Reduction Outputs", sheet("Reduction_byPoverty", modify) firstrow(variables) 