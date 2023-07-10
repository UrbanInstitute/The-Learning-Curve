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
	glo wd "********"
	glo raw_data "${wd}/rawdata"
	glo data "${wd}/data"
	glo out "${wd}/output"

	cap n mkdir "${raw_data}"
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
	
cd "${raw_data}"

cap n unzipfile "${wd}/analysis.zip", replace

cd "${wd}"	

*********************************************************************************
*Creating school and state level datasets for Cohorts 1 and 2
//Cohort 1-2020
use "data/CSI_Cohort_1.dta", clear

//Dropping States that I don't observe CSI designations
drop if inlist(statename,"MAINE","NEW MEXICO","OHIO","SOUTH CAROLINA","VERMONT","")
gen cohort=1
recode csi (.=0)

save "data/CSI_Cohort_1_sch.dta", replace

//Cohort 2-2022, 2023, 2024
use "data/CSI_Cohort_2.dta", clear

//Dropping States that I don't observe CSI designations
drop if inlist(statename,"MAINE","NEW MEXICO","OHIO","SOUTH CAROLINA","VERMONT","")
gen cohort=2
recode csi (.=0)

save "data/CSI_Cohort_2_sch.dta", replace
********************************************************************************
//Estimating proportion of schools in intensive SI status across time
*Data collected from several sources CSPR, EdFacts, NAYPI
use "data/nclb_waiver_school_status.dta", clear
bysort ncessch: egen titlei_max=max(titlei) //Accounts for changes to the Title I measure in CCD prior to 2008

gen severe_csi=(inlist(school_status,"CORRACT","PRIORITY","RESTR","RESTRPLAN"))

mean severe_csi if waiver==0 & inrange(year,2004,2012) & titlei_max==1, over(year)
	mat nclb=e(b)
	mat nclb=nclb'
mean severe_csi if waiver==1 & inrange(year,2013,2015) & titlei==1, over(year)
	mat waiver=e(b)
	mat waiver=waiver'

mat nclb_and_wiaver=nclb\waiver

//ESSA
//Combining School Level Data Sets
use "data/CSI_Cohort_1_sch.dta", clear
append using "data/CSI_Cohort_2_sch.dta"

mean csi if titlei==1, over(cohort)
	mat essa=e(b)
	mat essa=essa'
mat all_esea=nclb_and_wiaver\essa
	
clear
svmat all_esea
gen year=2003+_n

//Graphing Intensive School Improvement Designations Across Time
graph twoway (connected all_esea year, mcolor("22 150 210") lcolor("22 150 210")), ///
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
//Exporting Count of CSI Schools by Cohort and State

//Combining School Level Data Sets
use "data/CSI_Cohort_1_sch.dta", clear
append using "data/CSI_Cohort_2_sch.dta"
keep if titlei==1

putexcel set "output/csi_count.xlsx", modify

//Export State Names
levelsof statename, local(state_names)
local run=3
foreach i of local state_names{
di "`i'"
putexcel B`run' = "`i'"
local run=`run'+1
}
//Exporting Titles
putexcel B2 = "State"
putexcel C2 = "Cohort 1"
putexcel D2 = "Cohort 2"

//Export CSI Status
tab statename csi if cohort==1, matcell(r1) m
	mat r1=r1[1..46,2]
	putexcel C3=matrix(r1)
tab statename csi if cohort==2, matcell(r2) m
	mat r2=r2[1..46,2]
	putexcel D3=matrix(r2)

//Entering Formulas
putexcel C49=formula(=SUM(C3:C48))
putexcel D49=formula(=SUM(D3:D48))
********************************************************************************
//Creating figure to show CSI schools by state
use "data/state_crosswalk.dta", clear
//Dropping States that I don't observe CSI designations
drop if inlist(statename,"Maine","New Mexico","Ohio","South Carolina","Vermont","")

//Creates CSI count from matrix for cohort 1
svmat r1
//Creates CSI count from matrix for cohort 2
svmat r2
//Creating Percent Change Variable
gen pct_change=(r21-r11)/r11
//Creating Count Change Variable
gen num_change=r21-r11

//Creating state value lables for figure
sort num_change
gen sort_order=_n
labmask sort_order, values(stusab)

//Graphing Change in the Number of CSI Schools Across Cohorts
graph twoway bar num_change sort_order, ///
sort ///
lcolor("0  53  148%50") fcolor("22 150 210") /// 
mlabel(sort_order) mlabsize(vsmall) mlabcolor(black) mlabangle(45) ///
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

//Combining School Level Data Sets
use "data/CSI_Cohort_1_sch.dta", clear
append using "data/CSI_Cohort_2_sch.dta"
keep if titlei==1

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

//Difference in Proportion CSI by cohort
mean csi, over(cohort)
reg csi cohort 
//Difference in Proportion CSI by cohort
mean csi, over(year)
reg csi i.year
//Difference in Proportion CSI by cohort
mean csi, over(cohort formula)

reg csi i.cohort##i.formula 
xlincom (c1_ranked = _cons) (c1_formula = _cons+1.formula) (c2_ranked = _cons+2.cohort) (c2_formula = _cons+2.cohort+1.formula+2.cohort#1.formula), post
	estimate store forumula_effect

 
coefplot (forumula_effect ), ///
		 recast(bar) barwidth(0.5) ciopts(recast(rcap) color(gs5)) citop ///
		 bcolor("22 150 210") ///
		 vert graphregion(color(white)) bgcolor(white) ///
		 ytitle("Proportion CSI Schools in State") ///
		 ylabel(0 .01 "1%" .02 "2%" .03 "3%" .04 "4%" .05 "5%" .06 "6%" .07 "7%") ///
	 	 yline(0 .01 .02 .03 .04 .05 .06 .07, lp(solid) lc(gs12) lwid(vthin)) ///
		 xlabel(1 "Cycle 1 Relative Systems" 2 "Cycle 1 Absolute Systems" 3 "Cycle 2 Relative Systems" 4 "Cycle 2 Absolute Systems", ///
		 angle(45)) ///
		 legend(off) xtitle("") 

graph save "Graph" "output/change_by_essa_type.gph", replace
graph export "output/change_by_essa_type.pdf", as(pdf) replace
********************************************************************************
//Examining system changes in Florida
*Source: Florida Accountabilty data from https://www.fldoe.org/academics/essa.stml

//Florida 2020 Data
import excel "data/FL 2019.xlsx", sheet("FPPI (Basic)") cellrange(A5:S3668) firstrow clear
keep FederalPercentofPointsIndex ESSACategoryTSIorCSI SchoolName DistrictName
rename FederalPercentofPointsIndex fedindexpct20
rename ESSACategoryTSIorCSI essa_cat20
gen year20=1
tempfile fl_essa_20
save "`fl_essa_20'"

//Florida 2022 Data
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
********************************************************************************
//Differences in CSI round 2 status by TSI status in round 1
use "data/CSI_Cohort_1_sch.dta", clear
append using "data/CSI_Cohort_2_sch.dta"

bysort ncessch: egen tsi_max=max(tsi)
replace tsi_max=0 if csi==1 & cohort==1
keep if cohort==2
drop tsi
rename tsi_max tsi

tab csi tsi
mean csi, over(tsi)
********************************************************************************
********************************************************************************
//Differences in systems with an SQSS that includes chronic absenteeism
//Combining School Level Data Sets
use "data/CSI_Cohort_1_sch.dta", clear
append using "data/CSI_Cohort_2_sch.dta"
keep if titlei==1

replace statename=proper(statename)
replace statename="District of Columbia" if statename=="District Of Columbia"

* Source: https://www.ecs.org/50-state-comparison-states-school-accountability-systems/
gen essa_chronic=0
replace essa_chronic=1 if statename=="Alabama"
replace essa_chronic=1 if statename=="Alaska"
replace essa_chronic=1 if statename=="Arizona"
replace essa_chronic=1 if statename=="Arkansas"
replace essa_chronic=0 if statename=="California"
replace essa_chronic=1 if statename=="Colorado"
replace essa_chronic=1 if statename=="Connecticut"
replace essa_chronic=1 if statename=="Delaware"
replace essa_chronic=1 if statename=="District of Columbia"
replace essa_chronic=0 if statename=="Florida"
replace essa_chronic=1 if statename=="Georgia"
replace essa_chronic=1 if statename=="Hawaii"
replace essa_chronic=0 if statename=="Idaho"
replace essa_chronic=0 if statename=="Illinois"
replace essa_chronic=1 if statename=="Indiana"
replace essa_chronic=0 if statename=="Iowa"
replace essa_chronic=0 if statename=="Kansas"
replace essa_chronic=0 if statename=="Kentucky"
replace essa_chronic=0 if statename=="Louisiana"
replace essa_chronic=1 if statename=="Maine"
replace essa_chronic=1 if statename=="Maryland"
replace essa_chronic=1 if statename=="Massachusetts"
replace essa_chronic=1 if statename=="Michigan"
replace essa_chronic=0 if statename=="Minnesota"
replace essa_chronic=0 if statename=="Mississippi"
replace essa_chronic=1 if statename=="Missouri"
replace essa_chronic=1 if statename=="Montana"
replace essa_chronic=1 if statename=="Nebraska"
replace essa_chronic=1 if statename=="Nevada"
replace essa_chronic=0 if statename=="New Hampshire"
replace essa_chronic=1 if statename=="New Jersey"
replace essa_chronic=1 if statename=="New Mexico"
replace essa_chronic=1 if statename=="New York"
replace essa_chronic=0 if statename=="North Carolina"
replace essa_chronic=0 if statename=="North Dakota"
replace essa_chronic=1 if statename=="Ohio"
replace essa_chronic=1 if statename=="Oklahoma"
replace essa_chronic=1 if statename=="Oregon"
replace essa_chronic=1 if statename=="Pennsylvania"
replace essa_chronic=0 if statename=="Rhode Island"
replace essa_chronic=0 if statename=="South Carolina"
replace essa_chronic=1 if statename=="South Dakota"
replace essa_chronic=1 if statename=="Tennessee"
replace essa_chronic=0 if statename=="Texas"
replace essa_chronic=0 if statename=="Utah"
replace essa_chronic=0 if statename=="Vermont"
replace essa_chronic=1 if statename=="Virginia"
replace essa_chronic=1 if statename=="Washington"
replace essa_chronic=1 if statename=="West Virginia"
replace essa_chronic=1 if statename=="Wisconsin"
replace essa_chronic=0 if statename=="Wyoming"

//Difference in Proportion CSI by cohort
mean csi, over(cohort essa_chronic)
reg csi i.cohort##i.essa_chronic 

********************************************************************************
//Back of the envelope estimate for change in Section 1003 funding
*School Level School Improvement Funds 1003(a) for Title I Schools Downloaded from Ed Data Express
*Data note observed for each state
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
import excel "rawdata/ELSI_excel_export_6381810347908733033797.xls", clear sheet("ELSI Export")
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
********************************************************************************
********************************************************************************
//CSI non-exit contributions to designation increase in Michigan and Arkansas

//Arkansas
*35 CSI schools in round 1 and 165 in round 2
mat ar_tsi_convert=28/(165-35)
mat ar_csi_non_exit=30/(165-35)
mat ar_csi_new=(165-35-28-30)/(165-35)

//Michigan
*178 CSI schools in round 1 and 48 in round 2
import excel "rawdata/MI 2022 CSI.xlsx", sheet("Sheet1") firstrow clear
table Reason if CharterAuthorizer=="n/a "

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