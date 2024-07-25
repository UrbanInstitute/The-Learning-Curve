// NYC Essay 3 - Analysis Code
/*
This is the third in a series of essays analyzing the effects of implementing NYC's class size mandate. This code was written Spring 2024 by Matt Chingos, Ariella Meltzer, and Jay Carter. 

*/

glo main "C:\Users\lrestrepo\Documents\github_repos\The-Learning-Curve\2024_07_25-NYC_Class_Size_3" // this is the only line that needs to be edited for code to run. 

cd "${main}"

glo data "${main}/data"
glo raw "${data}/raw"
glo int "${data}/intermediate"
glo fin "${data}/final"

foreach var in data raw int fin{
	cap n mkdir "${`var'}"
}


cd "${main}"

***************************************************
**# INTERNAL AND EXTERNAL TEACHER HIRES - ANALYSIS 
***************************************************

***************************************************
**# INTERNAL AND EXTERNAL TEACHER HIRES - ANALYSIS 
***************************************************

// looking at transfers by weighted and unweighted ENI (sending and receiving) - 2023

use "${int}/2023 internal and external teacher hires v2.dta", clear

// FIGURES - Figure 1 Figure 2 (Percentages generated in excel but same numbers using Table A1), Table A1 LR

**# 2023 weighted ENI - transfers
tab send_qu_ENI rec_qu_ENI, row // internal hires
tab qu_ENI if external_transfer == 1 // external hires

// (unweighted code below was not used for figure 1, 2, or table A1, but idk if you want to keep it in here just in case)

**# 2023 unweighted ENI - transfers
tab send_qu_ENI_uw rec_qu_ENI_uw 
tab qu_ENI_uw if external_transfer == 1		

// TABLE A.2 LR

use "${raw}/2022 internal and external teacher hires v2.dta", clear

**# 2022 weighted ENI - transfers - just these two lines for table A2
tab send_qu_ENI rec_qu_ENI // weighted
tab qu_ENI if external_transfer == 1 // weighted

// (unweighted code, special ed and gen ed matrix below was not used for figure 1, 2, or table A1, but idk if you want to keep it in here just in case)

**# 2022 unweighted ENI - transfers
tab send_qu_ENI_uw rec_qu_ENI_uw 
tab qu_ENI if external_transfer == 1

**# Special Ed ENI Matrix
tab send_qu_ENI rec_qu_ENI if int_sped_license != ""
tab qu_ENI ext_sped_license

**# Gen Ed ENI Matrix
tab send_qu_ENI rec_qu_ENI if int_non_sped_license != ""
tab qu_ENI ext_non_sped_license

// looking at number of NEW teachers needed by ENI

** K-5

// FIGURE 3 LR

use "${int}/23-24_K_5_class_size_demographics_file.dta", replace

**# Overall ENI (Total Teachers) - just for K-5

collapse (rawsum) num_teacher0 new_teacher1, by(qu_ENI)
br // (copy and paste # of new teachers needed for class size reduction by ENI. the "additional vacancies created" is from an excel simulation we ran here: https://urbanorg.app.box.com/integrations/officeonline/openOfficeOnline?fileId=1552764822325&sharedAccessCode=


** MS_HS

use "${int}/23-24_MS_HS_class_size_demographics_file.dta", replace

// FIGURE A1 LR

**# Overall ENI (Total Teachers) - just for 6-12

preserve
collapse (rawsum) num_teacher0 new_teacher1, by(qu_ENI)
list
restore
// (copy and paste into excel for numbers of new teachers by ENI / (copy and paste # of new teachers needed for class size reduction. the "additional vacancies created" is from an excel simulation we ran here: https://urbanorg.app.box.com/integrations/officeonline/openOfficeOnline?fileId=1552764822325&sharedAccessCode=)


**# Overall ENI Quartiles - # of students

use "${int}/22-23_demographics.dta", clear

preserve
collapse (rawsum) TotalEnrollment, by(qu_ENI_uw) //unweighted
list
restore

preserve
collapse (rawsum) TotalEnrollment, by(qu_ENI) //weighted
list
restore

**# Overall ENI Quartiles - # of Schools

use "${int}/22-23_demographics.dta", clear

**# Overall ENI Quartiles - quartile min and max: 

tabstat EconomicNeedIndex, s(n min max) by(qu_ENI_uw)

**# Borough Matrix

use "${int}/2023 internal and external teacher hires v2.dta", clear

tab send_qu_ENI rec_qu_ENI if CurrentBorough == "M" & SelectedBorough == "M", col // Manhattan
tab send_qu_ENI rec_qu_ENI if CurrentBorough == "Q" & SelectedBorough == "Q", col // Queens
tab send_qu_ENI rec_qu_ENI if CurrentBorough == "K" & SelectedBorough == "K", col // Brooklyn
tab send_qu_ENI rec_qu_ENI if CurrentBorough == "R" & SelectedBorough == "R", col // Staten Island
tab send_qu_ENI rec_qu_ENI if CurrentBorough == "X" & SelectedBorough == "X", col // Bronx

**# Individual Borough Matrices: 

ren send_qu_ENI qu_send_ENI
ren rec_qu_ENI qu_rec_ENI

foreach B in M Q K R X {
	putexcel set "Updated ENI Matrices.xlsx", sheet("ENI - `B'", replace) modify

	putexcel A1="Table for `B'"
	putexcel B1="CurrentBorough"
	putexcel C1="SelectedBorough"
	putexcel D1="qu_send_ENI"
	putexcel E1="qu_rec_ENI"
	putexcel A3="Sending ENI 1"
	putexcel A5="Sending ENI 2"
	putexcel A7="Sending ENI 3"
	putexcel A9="Sending ENI 4"
	putexcel B2="Receiving ENI 1"
	putexcel C2="Receiving ENI 2"
	putexcel D2="Receiving ENI 3"
	putexcel E2="Receiving ENI 4"


	forvalues r=1/4 {
		local cell_letter=`r'+1
		excelcol `cell_letter'
		local col "`r(column)'"
		
		local row=3
		forvalues s=1/4 {		
			
			count if CurrentBorough == "`B'" & SelectedBorough == "`B'" & qu_rec_ENI==`r'
			local total=`r(N)'
			count if qu_rec_ENI==`r' & qu_send_ENI==`s' & CurrentBorough == "`B'" & SelectedBorough == "`B'"
				putexcel `col'`row'=`r(N)'
			local row=`row'+1
				putexcel `col'`row'=`r(N)'/`total'
			local row=`row'+1
		}
		
		count if CurrentBorough == "`B'" & SelectedBorough == "`B'" & qu_rec_ENI==`r'
		local total=`r(N)'
		count if qu_rec_ENI==`r' & CurrentBorough == "`B'" & SelectedBorough == "`B'"
			putexcel `col'`row'=`r(N)'
		local row=`row'+1
			putexcel `col'`row'=`r(N)'/`total'
		local row=`row'+1
	}
	
	local row=3
	
	forvalues s=1/4 {
		count if CurrentBorough == "`B'" & SelectedBorough == "`B'"
		local total=`r(N)'
		count if qu_send_ENI==`s' & CurrentBorough == "`B'" & SelectedBorough == "`B'"
			putexcel F`row'=`r(N)'
		local row=`row'+1
			putexcel F`row'=`r(N)'/`total'
		local row=`row'+1
	}
}



/*
// Revising # of teachers

import excel "${raw}/NewYorkCitySchoolTransparency202223.xlsx", sheet("Part B") cellrange(A7:Y1616) firstrow clear

drop Doesthisschoolserveitsfull Ifnoisthisschoolopeningth Istheschoolscheduledtoclose Ifsowhatyear ClassroomTeachersw03Years ClassroomTeacherswMorethan K12Enrollment PreKEnrollment PreschoolSpecialEdEnrollment K12FRPLCount K12ELLCount K12SWDCount ParaprofessionalClassroomSta PrincipalsOtherAdminStaff PupilSupportServicesStaff AllRemainingStaff TotalStaff TotalNonTeachingStaff

drop if SchoolType == "Pre-K Only" | SchoolType == "NYC - YABC"
drop if LowestGrade == "Pre-K"

gen K_5_school = LocalSchoolCode if LowestGrade == "K" | LowestGrade == "1" | LowestGrade == "2" | LowestGrade == "3" | LowestGrade == "4" | LowestGrade == "5" & HighestGrade == "K" | HighestGrade == "1" | HighestGrade == "2" | HighestGrade == "3" | HighestGrade == "4" | HighestGrade == "5"

gen MS_HS_school = LocalSchoolCode if LowestGrade == "6" | LowestGrade == "7" | LowestGrade == "8" | LowestGrade == "9" | LowestGrade == "10" | LowestGrade == "11" | LowestGrade == "12" & HighestGrade == "6" | HighestGrade == "7" | HighestGrade == "8" | HighestGrade == "9" | HighestGrade == "10" | HighestGrade == "11" | HighestGrade == "12"

replace K_5_school = "1" if K_5_school != ""
replace MS_HS_school = "1" if MS_HS_school != ""
gen K_12_school = "1" if K_5_school == "1" & MS_HS_school == "1"

ren LocalSchoolCode DBN		
save "${raw}/new_teacher_count_v2.dta", replace

**************************************
// revised code for MS/HS teacher #s: 
*************************************

use "${raw}/new_teacher_count_v2.dta", clear

merge 1:m DBN using "${int}/23-24_MS HS Class Size Data Cleaned.dta"
keep if _merge == 3
sort DBN

collapse (mean) TotalClassroomTeachers (rawsum) num_teacher0 num_class0 ict_needed gen_ed_needed acc_classes_needed total_classes_needed, by(DBN)

drop num_teacher0

gen old_and_new_classes = num_class0 + total_classes_needed
gen class_per_teacher = old_and_new_classes/TotalClassroomTeachers
// collapse (rawsum) TotalClassroomTeachers, by (K_5_school MS_HS_school)

gen old_class_per_teacher = num_class0/TotalClassroomTeachers

sum old_class_per_teacher, d
// break down by school levels - K-5, MS/HS
// 3 -5 range for # of classes per teacher

ren total_classes_needed new_classes_needed


*/

