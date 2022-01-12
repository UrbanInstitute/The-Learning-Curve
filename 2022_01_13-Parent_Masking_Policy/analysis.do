/*Analysis file for "Support for Mask and Vaccine Policies in Schools Falls Along Racial and Political Lines"
	using data from UAS414 (https://uasdata.usc.edu/education)
(Change line as needed before running file.)*/

**************** Workspace preparation and variable derivation *****************
clear all
macro drop _all
cls
set more off
cap log close

**ADJUST THIS
global path "C:/Users/lrestrepo/Documents/Github_repos/The-Learning-Curve/2022_01_13-Parent_Masking_Policy"

*Useful globals
glo weight "[pweight=final_weight]"
glo undup "hh_pickone==1"

capture mkdir "${path}/Output"

glo data "${path}/Data"
glo output "${path}/Output"

*Load uas414 (including household unduplication variable, derived using earlier waves)
	*dataset without this variable available from https://uasdata.usc.edu/education
use "${data}/uas414_urbaninstitute", clear

*derive relevant variables
	*political identification variable
	capture drop polid
	gen polid = 1 if cf003==1
		replace polid = 2 if cf003a==1
		replace polid = 3 if cf003==2
		replace polid = 4 if cf003a==2
		replace polid = 5 if cf003==4 | cf003==5 | cf003==6
		replace polid = 6 if cf003a==3 | ((cf003==3 | cf003==7) & cf003a==.e)
	la def polid 1 "1 Democrat" 2 "2 Indep/Unaligned, lean Democrat" 3 "3 Republican" ///
		4 "4 Indep/Unaligned, lean Republican" 5 "5 Party other than Dem or Rep" ///
		6 "6 Indep/Unaligned, lean neither D nor R", replace
	la val polid polid
	la var polid "Political Identification"
	*collapse political identification variable
	capture drop polid3
	gen polid3 = 0 if polid==1 | polid==2
		replace polid3 = 1 if polid==3 | polid==4
		replace polid3 = 2 if polid==5 | polid==6
	la var polid3 "Political Identification (simplified categorical)"
	la def polid3 0 "0 Democrat or lean Democrat" 1 "1 Republican or lean Republican" 2 "2 Neither", replace
	la val polid3 polid3
	
	*race/ethnicity
	gen race_cat=0 if race==1 & hisplatino==0
		replace race_cat=1 if race==2 & hisplatino==0
		replace race_cat=2 if race==4 & hisplatino==0
		replace race_cat=3 if (race==3 | race==5 | race==6) & hisplatino==0
		replace race_cat=4 if hisplatino==1
	la def race_cat 0 "NH White" 1 "NH Black" 2 "NH Asian" 3 "NH Other" 4 "Hispanic", replace
	la val race_cat race_cat
	la var race_cat "Race/Ethnicity Categorical"
	
	*support for policies
	loc var edu_pol_sy2122_tchvacmand
	loc x sl095b
	loc varlab "Support for policy: teacher vaccine mandate"
	g `var' = inlist(`x', 3, 4) if !missing(`x') & edu_sample_inclusion_FLAG==1
		la var `var' "`varlab'"
		la val `var' yesno
		char `var'[A] `x'
	loc var edu_pol_sy2122_st12upvacmand
	loc x sl095c
	loc varlab "Support for policy: student vaccine mandate (12 and up)"
	g `var' = inlist(`x', 3, 4) if !missing(`x') & edu_sample_inclusion_FLAG==1
		la var `var' "`varlab'"
		la val `var' yesno
		char `var'[A] `x'
	loc var edu_pol_sy2122_stund12vacmand
	loc x sl095d
	loc varlab "Support for policy: student vaccine mandate (under 12, when approved)"
	g `var' = inlist(`x', 3, 4) if !missing(`x') & edu_sample_inclusion_FLAG==1
		la var `var' "`varlab'"
		la val `var' yesno
		char `var'[A] `x'
	loc var edu_pol_sy2122_maskunvac
	loc x sl095e
	loc varlab "Support for policy: required masking for unvaccinated"
	g `var' = inlist(`x', 3, 4) if !missing(`x') & edu_sample_inclusion_FLAG==1
		la var `var' "`varlab'"
		la val `var' yesno
		char `var'[A] `x'
	loc var edu_pol_sy2122_maskall
	loc x sl095f
	loc varlab "Support for policy: required masking for all"
	g `var' = inlist(`x', 3, 4) if !missing(`x') & edu_sample_inclusion_FLAG==1
		la var `var' "`varlab'"
		la val `var' yesno
		char `var'[A] `x'

*surveyset the data
svyset uasid ${weight}

********************************* Main analysis ********************************
qui tab race_cat, g(race_cat)
qui tab polid3, g(polid3)

mat main = J(8,5,.)
mat rownames main = "Overall" "NH White" "NH Black" "NH Asian" "Hispanic" "Democrat" "Republican" "Neither"
mat colnames main = "Vaccine - Teachers" "Vaccine - 12 and Up" "Vaccine - All Students" "Mask - Unvaccinated" "Mask - All"
loc c 1
foreach var of varlist edu_pol_sy2122_tchvacmand edu_pol_sy2122_st12upvacmand edu_pol_sy2122_stund12vacmand edu_pol_sy2122_maskunvac edu_pol_sy2122_maskall {
	loc r 1
	foreach cat in 1 race_cat1 race_cat2 race_cat3 race_cat5 polid31 polid32 polid33 {
		qui svy: tab `var' if `cat'==1 & ${undup}
		mat x = e(b)
		mat main[`r',`c'] = x[1,2]
		loc ++r
		}
	loc ++c
	}
mat main_100 = main*100
mat list main_100
putexcel set "${output}/urbinst_analysis", sheet(main) replace
putexcel A1 = "% of K12 parents in support of these policies", bold
putexcel A3 = matrix(main_100), names nformat(number)
putexcel close

***************************** Supplemental analyses ****************************
*do differences by race and political ID hold up controlling for each other?
log using "${output}/diffsforurbaninst.txt", text replace
foreach stub in maskunvac maskall tchvacmand st12upvacmand stund12vacmand {
	reg edu_pol_sy2122_`stub' ib0.race_cat ib1.polid3 if ${undup} & race_cat!=3 ${weight}
	*racial ID explain significant variation controlling for political ID?
	test 1.race_cat 2.race_cat 4.race_cat
	*political ID explain significant variation controlling for racial ID?
	test 0.polid3 2.polid3
	}
log close

*% in support of each policy by race/eth and polid
putexcel set "${output}/urbinst_analysis", sheet(additional) modify
loc xrow 1
foreach stub in maskunvac maskall tchvacmand st12upvacmand stund12vacmand {
	mat `stub' = J(5,4,.)
	mat rownames `stub' = "NH White" "NH Black" "NH Asian" "Hispanic" "Overall"
	mat colnames `stub' = "Democrat" "Republican" "Neither" "Overall"
	if "`stub'"=="maskunvac" {
		loc name "Mask - Unvaccinated (% in support)"
		}
	if "`stub'"=="maskall" {
		loc name "Mask - All (% in support)"
		}
	if "`stub'"=="tchvacmand" {
		loc name "Vaccine - Teachers (% in support)"
		}
	if "`stub'"=="st12upvacmand" {
		loc name "Vaccine - 12 and Up (% in support)"
		}
	if "`stub'"=="stund12vacmand" {
		loc name "Vaccine - All Students (% in support)"
		}
	*xtab
	loc r 1
	foreach rlvl in 0 1 2 4 {
		loc c 1
		foreach plvl in 0 1 2 {
			qui svy: tab edu_pol_sy2122_`stub' if race_cat==`rlvl' & polid3==`plvl' & ${undup}
			mat x = e(b)
			mat `stub'[`r',`c'] = x[1,2]
			loc ++c
			}
		loc ++r
		}
	*overall
	loc r 1
	foreach rlvl in 0 1 2 4 {
		qui svy: tab edu_pol_sy2122_`stub' if race_cat==`rlvl' & ${undup}
		mat x = e(b)
		mat `stub'[`r',4] = x[1,2]
		loc ++r
		}
	loc c 1
	foreach plvl in 0 1 2 {
		qui svy: tab edu_pol_sy2122_`stub' if polid3==`plvl' & ${undup}
		mat x = e(b)
		mat `stub'[5,`c'] = x[1,2]
		loc ++c
		}
	mat `stub'_100 = `stub'*100
	mat list `stub'_100
	putexcel A`xrow' = "`name'", bold
	putexcel A`=`xrow'+1' = matrix(`stub'_100), nformat(number) names
	loc xrow = `xrow'+9
	}
putexcel close
