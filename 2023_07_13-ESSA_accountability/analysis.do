********************************************************************************
********************************************************************************
/*
Title: Cleaning and analyzing CSI Designations for ESSA Cohort 2 (2020-21, 2021-22, and 2022-23)
Author: Josh Bleiberg
Last Updated: June 13, 2022
Notes: File fuzzy names matches NCES school identifiers to the CSI data for each
state. Data is collected and cleaned from each state individually. CSI data for
2018-19 is cleaned for several states and a validation exercise or to address
missing data in the Ed Data Express 2019-20 File
*/
********************************************************************************
********************************************************************************
*Setting Directory
	* change line 16 to reflect the current working directory
	glo wd "C:\Users\lrestrepo\Documents\github_repos\The-Learning-Curve\2023_07_13-ESSA_accountability"
	glo raw_data "${wd}/rawdata"
	glo data "${wd}/data"
	glo out "${wd}/output"

	cap n mkdir "${data}"
	cap n mkdir "${out}"

	cap n ssc install strip
	cap n ssc install labutil
	cap n net install xlincom.pkg
	cap n net install coefplot.pkg
	cap n net install dm0082.pkg
	net install urbanschemes, replace from("https://urbaninstitute.github.io/urbanschemes/")
	
set scheme urbanschemes
graph set window fontface "Lato"
	
cd "${wd}"	

cap n unzipfile "${wd}/analysis.zip", replace

********* Cleaning raw data

use "${wd}/state_level_esea.dta", clear

gen state_abb = ""
replace state_abb = "AL" if statename == "alabama"
replace state_abb = "AK" if statename == "alaska"
replace state_abb = "AZ" if statename == "arizona"
replace state_abb = "AR" if statename == "arkansas"
replace state_abb = "CA" if statename == "california"
replace state_abb = "CO" if statename == "colorado"
replace state_abb = "CT" if statename == "connecticut"
replace state_abb = "DE" if statename == "delaware"
replace state_abb = "DC" if statename == "district of columbia"
replace state_abb = "FL" if statename == "florida"
replace state_abb = "GA" if statename == "georgia"
replace state_abb = "HI" if statename == "hawaii"
replace state_abb = "ID" if statename == "idaho"
replace state_abb = "IL" if statename == "illinois"
replace state_abb = "IN" if statename == "indiana"
replace state_abb = "IA" if statename == "iowa"
replace state_abb = "KS" if statename == "kansas"
replace state_abb = "KY" if statename == "kentucky"
replace state_abb = "LA" if statename == "louisiana"
replace state_abb = "ME" if statename == "maine"
replace state_abb = "MD" if statename == "maryland"
replace state_abb = "MA" if statename == "massachusetts"
replace state_abb = "MI" if statename == "michigan"
replace state_abb = "MN" if statename == "minnesota"
replace state_abb = "MS" if statename == "mississippi"
replace state_abb = "MO" if statename == "missouri"
replace state_abb = "MT" if statename == "montana"
replace state_abb = "NB" if statename == "nebraska"
replace state_abb = "NV" if statename == "nevada"
replace state_abb = "NH" if statename == "new hampshire"
replace state_abb = "NJ" if statename == "new jersey"
replace state_abb = "NM" if statename == "new mexico"
replace state_abb = "NY" if statename == "new york"
replace state_abb = "NC" if statename == "north carolina"
replace state_abb = "ND" if statename == "north dakota"
replace state_abb = "OH" if statename == "ohio"
replace state_abb = "OK" if statename == "oklahoma"
replace state_abb = "OR" if statename == "oregon"
replace state_abb = "PA" if statename == "pennsylvania"
replace state_abb = "RI" if statename == "rhode island"
replace state_abb = "SC" if statename == "south carolina"
replace state_abb = "SD" if statename == "south dakota"
replace state_abb = "TN" if statename == "tennessee"
replace state_abb = "TX" if statename == "texas"
replace state_abb = "UT" if statename == "utah"
replace state_abb = "VT" if statename == "vermont"
replace state_abb = "VA" if statename == "virginia"
replace state_abb = "WA" if statename == "washington"
replace state_abb = "WV" if statename == "west virginia"
replace state_abb = "WI" if statename == "wisconsin"
replace state_abb = "WY" if statename == "wyoming"

replace statename=proper(statename)
replace statename="District of Columbia" if statename=="District Of Columbia"

gen str essa_system=""
replace essa_system="Federal Tiers of Support" if statename=="Alabama"
replace essa_system="Index" if statename=="Alaska"
replace essa_system="Federal Tiers of Support" if statename=="Arizona"
replace essa_system="Index" if statename=="Arkansas"
replace essa_system="Dashboard" if statename=="California"
replace essa_system="Federal Tiers of Support" if statename=="Colorado"
replace essa_system="Index" if statename=="Connecticut"
replace essa_system="Descriptive" if statename=="Delaware"
replace essa_system="1 to 5 stars" if statename=="District of Columbia"
replace essa_system="Index" if statename=="Florida"
replace essa_system="Index" if statename=="Georgia"
replace essa_system="Index" if statename=="Hawaii"
replace essa_system="Federal Tiers of Support" if statename=="Idaho"
replace essa_system="Descriptive" if statename=="Illinois"
replace essa_system="A to F Rating" if statename=="Indiana"
replace essa_system="Index" if statename=="Iowa"
replace essa_system="Descriptive" if statename=="Kansas"
replace essa_system="1 to 5 stars" if statename=="Kentucky"
replace essa_system="A to F Rating" if statename=="Louisiana"
replace essa_system="Descriptive" if statename=="Maine"
replace essa_system="1 to 5 stars" if statename=="Maryland"
replace essa_system="Descriptive" if statename=="Massachusetts"
replace essa_system="A to F Rating" if statename=="Michigan"
replace essa_system="Descriptive" if statename=="Minnesota"
replace essa_system="A to F Rating" if statename=="Mississippi"
replace essa_system="Index" if statename=="Missouri"
replace essa_system="Federal Tiers of Support" if statename=="Montana"
replace essa_system="Descriptive" if statename=="Nebraska"
replace essa_system="1 to 5 stars" if statename=="Nevada"
replace essa_system="Federal Tiers of Support" if statename=="New Hampshire"
replace essa_system="Descriptive" if statename=="New Jersey"
replace essa_system="Index" if statename=="New Mexico"
replace essa_system="Federal Tiers of Support" if statename=="New York"
replace essa_system="A to F Rating" if statename=="North Carolina"
replace essa_system="Index" if statename=="North Dakota"
replace essa_system="A to F Rating" if statename=="Ohio"
replace essa_system="A to F Rating" if statename=="Oklahoma"
replace essa_system="Federal Tiers of Support" if statename=="Oregon"
replace essa_system="Federal Tiers of Support" if statename=="Pennsylvania"
replace essa_system="1 to 5 stars" if statename=="Rhode Island"
replace essa_system="Descriptive" if statename=="South Carolina"
replace essa_system="Index" if statename=="South Dakota"
replace essa_system="A to F Rating" if statename=="Tennessee"
replace essa_system="A to F Rating" if statename=="Texas"
replace essa_system="A to F Rating" if statename=="Utah"
replace essa_system="Descriptive" if statename=="Vermont"
replace essa_system="Federal Tiers of Support" if statename=="Virginia"
replace essa_system="Index" if statename=="Washington"
replace essa_system="Descriptive" if statename=="West Virginia"
replace essa_system="Index" if statename=="Wisconsin"
replace essa_system="Descriptive" if statename=="Wyoming"
encode essa_system, gen(essa_system_type)

gen formula=(inlist(essa_system_type,1,2,6))


save "${wd}/state_level_esea_2.dta", replace

********************************************************************************
//Estimating proportion of schools in intensive SI status across time
*Data collected from several sources CSPR, EdFacts, NAYPI

use "${wd}/state_level_esea_2.dta", clear

preserve
collapse (sum) csi flag, by(statename year waiver titlei_max)
desc
collapse (sum) csi (sum) flag, by(year waiver titlei_max)
gen severe_csi_2 = csi/flag
keep if waiver==0 & inrange(year,2004,2012) & titlei_max==1
tempfile part_1
save "`part_1'", replace
restore

preserve
collapse (sum) csi flag, by(statename year waiver titlei)
collapse (sum) csi (sum) flag, by(year waiver titlei)
gen severe_csi_2 = csi/flag
keep if waiver==1 & inrange(year,2013,2017) & titlei==1
tempfile part_2
save "`part_2'", replace
restore

clear
use "`part_1'", clear
append using "`part_2'"

//Graphing Intensive School Improvement Designations Across Time
graph twoway (connected severe_csi_2 year, mcolor("22 150 210") lcolor("22 150 210")), ///
graphregion(color(white)) bgcolor(white) ///
ytitle("Proportion of Most Intensive Sanction") ///
legend(off) ///
ylabel(0 .01 "1%" .02 "2%" .03 "3%" .04 "4%" .05 "5%" .06 "6%" .07 "7%" .08 "8%" .09 "9%" .10 "10%" .11 "11%" .12 "12%" .13 "13%" .14 "15%", labsize(small)) ///
yline(0 .01 .02 .03 .04 .05 .06 .07 .08 .09 .10 .11 .12 .13 .14, lp(solid) lc(gs14) lwid(vthin)) ///
xlabel(2004 "2004 NCLB" 2005 "2005 NCLB" 2006 "2006 NCLB" 2007 "2007 NCLB" 2008 "2008 NCLB" ///
2009 "2009 NCLB" 2010 "2010 NCLB" 2011 "2011 NCLB" 2012 "2012 NCLB" ///
2013 "2013 Waiver" 2014 "2014 Waiver" 2015 "2015 Waiver" /// 
2016 "2016 to 2020 ESSA" 2017 "2021 to 2023 ESSA", labsize(small) angle(45)) xtitle("")

graph save "Graph" "output/sanctions_over_time.gph", replace
graph export "output/sanctions_over_time.pdf", as(pdf) replace

*********************************************************************************
//Creating figure to show CSI schools by state
use "${wd}/state_level_esea_2.dta", clear

keep if year >= 2016 & titlei == 1
gen cohort = 1 if year == 2016
replace cohort = 2 if year == 2017


keep cohort csi statename state_abb
ren csi csi_

reshape wide csi, i(state_abb statename) j(cohort)

gen num_change = (csi_2-csi_1)

sort num_change
gen ord = _n


//Graphing Change in the Number of CSI Schools Across Cohorts
graph twoway bar num_change ord, ///
sort ///
lcolor("0  53  148%50") fcolor("22 150 210") /// 
mlabel(state_abb) mlabsize(vsmall) mlabcolor(black) mlabangle(45) ///
graphregion(color(white)) bgcolor(white) ///
ylabel(-50 0 50 100 150) ///
yline(-50 0 50 100 150, lp(solid) lc(gs12) lwid(vthin)) ///
xlabel(none) ///
ytitle("Change in Number of CSI Schools") xtitle("")

graph save "Graph" "output/csi_count_change.gph", replace
graph export "output/csi_count_change.pdf", as(pdf) replace
********************************************************************************
//Examining CSI Increase by ESSA system Type
* Source: https://www.ecs.org/50-state-comparison-states-school-accountability-systems/
// Observations are currently available at the visualization level; error vars
// can only be generated using school level rows. Reach out to the author in order to retrieve error terms.

//Combining School Level Data Sets
use "${wd}/coef_plot_attrib.dta", clear
tostring cohort, replace
tostring formula, replace

gen flag = cohort + "_" + formula
gen flag_1 = "First cycle, absolute cycle, relative" if flag == "1_0"
replace flag_1 = "First cycle, relative" if flag == "1_1"
replace flag_1 = "Second cycle, absolute" if flag == "2_0"
replace flag_1 = "Second cycle" if flag == "2_1"

graph bar avg, over(flag_1)

graph save "Graph" "output/change_by_essa_type.gph", replace
graph export "output/change_by_essa_type.pdf", as(pdf) replace
********************************************************************************
//Examining system changes in Florida
*Source: Florida Accountabilty data from https://www.fldoe.org/academics/essa.stml

//Florida 2020 Data
cap n copy "https://www.fldoe.org/core/fileparse.php/14196/urlt/FederalIndex19.xlsx" "data/FL 2019.xlsx", replace
import excel "data/FL 2019.xlsx", sheet("FPPI (Basic)") cellrange(A5:S3668) firstrow clear
keep FederalPercentofPointsIndex ESSACategoryTSIorCSI SchoolName DistrictName
rename FederalPercentofPointsIndex fedindexpct20
rename ESSACategoryTSIorCSI essa_cat20
gen year20=1
tempfile fl_essa_20
save "`fl_essa_20'"

//Florida 2022 Data
cap n copy "https://www.fldoe.org/core/fileparse.php/14196/urlt/FederalIndex22.xlsx" "data/FL 2022.xlsx", replace
import excel "data/FL 2022.xlsx", sheet("FPPI (Basic)") cellrange(A5:S3707) firstrow clear
keep FederalPercentofPointsIndex ESSACategoryCSITSIorATSI SchoolName DistrictName
rename FederalPercentofPointsIndex fedindexpct22
rename ESSACategoryCSITSIorATSI essa_cat22
gen year22=1
tempfile fl_essa_22
save "`fl_essa_22'"

use "`fl_essa_20'", clear 
merge 1:1 SchoolName DistrictName using "`fl_essa_22'"

sum fedindexpct20 if essa_cat20=="CS&I" & year20==1 & inrange(fedindexpct20,0,41), det
sum fedindexpct22 if essa_cat22=="CSI" & year22==1 & inrange(fedindexpct22,0,41), det
	
twoway (histogram fedindexpct20 if essa_cat20=="CS&I" & year20==1 & inrange(fedindexpct20,0,41), color("22 150 210") freq bin(20)) ///
       (histogram fedindexpct22 if essa_cat22=="CSI" & year22==1 & inrange(fedindexpct22,0,41), color("0 0 0%50") lcolor("0 0 0%50") freq bin(20)), ///
	   graphregion(color(white)) bgcolor(white) ///
	   legend(order(1 "FL Cycle 1" 2 "FL Cycle 2")) ///
	   yline(20 40 60 80 100, lp(solid) lc(gs12) lwid(vthin))

graph save "Graph" "output/fl_histogram.gph", replace
graph export "output/fl_histogram.pdf", as(pdf) replace

********************************************************************************
//Back of the envelope estimate for change in Section 1003 funding
*School Level School Improvement Funds 1003(a) for Title I Schools Downloaded from Ed Data Express
*Data note observed for each state
* can only be done with school level data; reach out to the author for school level observation
/*
cap n copy "https://eddataexpress.ed.gov/sites/default/files/data_download/EID_8124/SY1920_FS132_DG794_SCH_data_files.zip" ///
	"rawdata/SY1920_FS132_DG794_SCH.xlsx", replace
import excel "rawdata/SY1920_FS132_DG794_SCH.xlsx", sheet("SY1920_FS132_DG794_SCH") firstrow clear
tostring NCESLEAID, gen(leaid) format(%07.0f)
tostring NCESSCHID, gen(schid) format(%05.0f)
gen ncessch=leaid+schid
duplicates drop ncessch, force //Drop 214 true duplicates
drop Numerator Denominator Subgroup Subgroup Characteristics AgeGrade AcademicSubject Outcome ProgramType ///
NCESLEAID NCESSCHID Population DataDescription SchoolYear State NCESLEAID LEA

rename Value sec1003dol
destring sec1003dol, force replace
merge 1:1 ncessch using "data/CSI_Cohort_1.dta", keep(match) nogen

preserve
//2020 Enrollment Data
import excel "ELSI_excel_export_6381810347908733033797.xls", clear sheet("ELSI Export")
keep C D E
destring *, force replace
drop if C==.
gen ncessch = string(C,"%012.0f")
gen leaid = string(D,"%07.0f")
drop C D
rename E sch_enrl_20
save "data/sch_enrl_2020.dta", replace
restore

merge 1:1 ncessch using "data/sch_enrl_2020.dta", keep(match) nogen

//Dropping schools with no sec1003dol
drop if sec1003dol==0

gen sec1003_per_pupil=sec1003dol/sch_enrl_20

//School Count
unique ncessch //4374 schools

//1 percent increase in the number of CSI schools
di 4374*.01 //43.74 more CSI schools

//Average student enrollment
sum sch_enrl_20 ///524.741

//Increase in the number of students in CSI schools with 1 percent more CSI schools
di 524.741*43.74 //22952.171 more students

//Per Pupil 1003 spending in CSI schools
sum sec1003dol
local sum_sec1003dol=r(sum)

sum sch_enrl_20
local sum_sch_enrl_20=r(sum)

//2020 per pupil
di `sum_sec1003dol'/`sum_sch_enrl_20'

//2020 per pupil + 1 percent more CSI schools
di `sum_sec1003dol'/(`sum_sch_enrl_20'+22952.171)

//2020 per pupil + 5 percent more CSI schools
di `sum_sec1003dol'/(`sum_sch_enrl_20'+(22952.171*5))

//2020 per pupil + 10 percent more CSI schools
di `sum_sec1003dol'/(`sum_sch_enrl_20'+(22952.171*10))

//2020 per pupil + 20 percent more CSI schools
di `sum_sec1003dol'/(`sum_sch_enrl_20'+(22952.171*20))
*/
********************************************************************************
********************************************************************************
//CSI non-exit contributions to designation increase in Michigan and Arkansas

//Arkansas
*35 CSI schools in round 1 and 165 in round 2 (original data collection; ask author for school and LEA level data)
mat ar_tsi_convert=28/(165-35)
mat ar_csi_non_exit=30/(165-35)
mat ar_csi_new=(165-35-28-30)/(165-35)

//Michigan
*178 CSI schools in round 1 and 48 in round 2 (original data collection; ask author for school and LEA level data)
mat mi_tsi_convert=(15+13)/(178-48)
mat mi_csi_non_exit=19/(178-48)
mat mi_csi_new=(178-48-15-13-19)/(178-48)

mat convert=ar_tsi_convert\mi_tsi_convert
mat non_exit=ar_csi_non_exit\mi_csi_non_exit
mat new=ar_csi_new\mi_csi_new

clear
svmat convert
svmat non_exit
svmat new

gen state=1
replace state=2 if _n==1
label define state_l 1 "AR" 2 "MI"
label values state state_l 

//Proportion of CSI Schools Increases Accounted for by TSI conversions and CSI non-exits
graph bar convert1 non_exit1 new1, over(state) stack ///
ytitle("Proportion of CSI Designation Increase") ///
legend(order(1 "TSI Conversion" 2 "CSI Non-Exit" 3 "Newly Designated") region(lstyle(none)) symxsize(.1cm)) ///
ylabel(0  .10 "10%" .20 "20%" .30 "30%" .40 "40%" .50 "50%" ///
.60 "60%" .70 "70%" .80 "80%" .90 "90%" 1 "100%" ) plotregion(margin(t = 12))

graph save "Graph" "output/csi_prop_explained.gph", replace
graph export "output/csi_prop_explained.pdf", as(pdf) replace