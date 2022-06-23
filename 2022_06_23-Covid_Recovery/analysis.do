/*Analysis for Urban Institute piece, all in one place
Put together:
	1. Levels of concerns and negative experiences
		overall, by race/ethnicity, by income
	2. Report availability, participation, interest, combined index*
		overall, by race/ethnicity, by income, by level of concern, by negative experiences
	4. Significance tests for differences by subgroups for all the above
	
	*Combined index = indicator for "is participating" OR "would participate" */

********************************************************************************
***************************** Workspace Preparation ****************************
********************************************************************************
clear all
cls
set more off

glo wd "C:/Users/`c(username)'/Documents/Github_repos/The-Learning-Curve/2022_06_23-Covid_Recovery"

glo data "${wd}/data"

glo output "${data}/output_data"
glo raw "${data}/raw_data"

cd "${wd}"
unzipfile "${wd}/data.zip"

cap n mkdir "${raw}"
cap n mkdir "${output}"

glo weight "[pweight=final_weight]"
glo undup "hh_pickone==1"

use "${raw}/uas461_forurbinst"

*surveyset the data (_n because uasid deleted--no dubplicates within wave so ok)
svyset _n ${weight}

********************************************************************************
************************* Generate Necessary Variables *************************
********************************************************************************

*Race and income indicators
	tab race_cat, g(race_cat)
	tab eco_hhincome, g(eco_hhincome)

*Interest: indicator for "is participating" or "would participate"
	foreach stub in sumsch mhealth excurr tut {
		g edu_`stub'_interest = 0 if !missing(edu_`stub'_schoffers) & edu_sample_inclusion_FLAG==1
		replace edu_`stub'_interest = 1 if edu_`stub'_does==1 | edu_`stub'_woulddo==1 & edu_sample_inclusion_FLAG==1
		}

*Concerns: is concerned+ for any item, any academic item, any nonacademic item
	*counts
	egen edu_conc_numa_der = rowtotal(edu_concern_psychealth edu_concern_amtlearn edu_concern_engage edu_concern_socprb edu_concern_math edu_concern_sci edu_concern_ela) if wave==26 & edu_sample_inclusion_FLAG==1
	egen edu_conc_numacad_der = rowtotal(edu_concern_amtlearn edu_concern_math edu_concern_sci edu_concern_ela) if wave==26 & edu_sample_inclusion_FLAG==1
	egen edu_conc_numnonacad_der = rowtotal(edu_concern_psychealth edu_concern_engage edu_concern_socprb) if wave==26 & edu_sample_inclusion_FLAG==1
	*indicators for any items concerned
	g edu_conc_anya_der = (edu_conc_numa_der>0 & !missing(edu_conc_numa_der))
	g edu_conc_anyacad_der = (edu_conc_numacad_der>0 & !missing(edu_conc_numacad_der))
	g edu_conc_anynonacad_der = (edu_conc_numnonacad_der>0 & !missing(edu_conc_numnonacad_der))
	*indicators for no items concerned
	g edu_conc_noa_der = (edu_conc_numa_der==0 & !missing(edu_conc_numa_der))
	g edu_conc_noacad_der = (edu_conc_numacad_der==0 & !missing(edu_conc_numacad_der))
	g edu_conc_nononacad_der = (edu_conc_numnonacad_der==0 & !missing(edu_conc_numnonacad_der))

*Negative experiences: has had 1+ overall / academic / behavioral negative experiences
	*counts
	egen edu_3mo_numa_der = rowtotal(se015bs1 se015bs2 se015bs3 se015bs4 se015bs5 se015bs6 se015bs7 se015bs8 se015bs9 se015bs10 se015bs11 se015bs12 se015bs13) if wave==26 & edu_sample_inclusion_FLAG==1
	egen edu_3mo_numacad_der = rowtotal(se015bs1 se015bs2 se015bs3 se015bs4 se015bs5 se015bs7 se015bs8) if wave==26 & edu_sample_inclusion_FLAG==1
	egen edu_3mo_numnonacad_der = rowtotal(se015bs6 se015bs9 se015bs10 se015bs11 se015bs12 se015bs13) if wave==26 & edu_sample_inclusion_FLAG==1
	*indicators for any negative experiences
	g edu_3mo_anya_der = (edu_3mo_numa_der>0 & !missing(edu_3mo_numa_der))
	g edu_3mo_anyacad_der = (edu_3mo_numacad_der>0 & !missing(edu_3mo_numacad_der))
	g edu_3mo_anynonacad_der = (edu_3mo_numnonacad_der>0 & !missing(edu_3mo_numnonacad_der))
	*indicators for no negative experiences
	g edu_3mo_noa_der = (edu_3mo_numa_der==0 & !missing(edu_3mo_numa_der))
	g edu_3mo_noacad_der = (edu_3mo_numacad_der==0 & !missing(edu_3mo_numacad_der))
	g edu_3mo_nononacad_der = (edu_3mo_numnonacad_der==0 & !missing(edu_3mo_numnonacad_der))

********************************************************************************
*********************************** Analysis ***********************************
********************************************************************************

************ 1. Concern / neg exp levels overall and by race/income ************

*Concern
	mat conc = J(10,7,.)
	mat rownames conc = "Overall" "NH White" "NH Black" "NH Asian" "Hispanic" "<$25k" "$25k-$49k" "$50K-$74K" "$75K-$149K" ">=$150k"
	mat colnames conc = "Psyc wellbeing" "Engagement" "Doing socially" "Amount learning" "Math progress" "Science progress" "ELA progress"	
	loc c 1
	foreach var of varlist edu_concern_psychealth edu_concern_engage edu_concern_socprb edu_concern_amtlearn edu_concern_math edu_concern_sci edu_concern_ela {
		loc r 1
		foreach grp in 1 race_cat1 race_cat2 race_cat3 race_cat5 eco_hhincome1 eco_hhincome2 eco_hhincome3 eco_hhincome4 eco_hhincome5 {
			di "`var' by `grp' lvl"
			qui svy: tab `var' if wave==26 & ${undup} & `grp'==1
			mat x = e(b)
			loc num: di %4.2f 100*x[1,2]
			mat conc[`r',`c'] = `num'
			loc ++r
			}
		loc ++c
		}

*Negative experiences
	mat negexp = J(10,14,.)
	mat rownames negexp = "Overall" "NH White" "NH Black" "NH Asian" "Hispanic" "<$25k" "$25k-$49k" "$50K-$74K" "$75K-$149K" ">=$150k"
	mat colnames negexp = "Low Grades" "Low Test Scores" "Struggles in Class" "Struggles with HW" "Academic Calls" "Behavioral Calls" "Risk Repeating" "Risk not Grad" "Depression" "Anxiety" "Problems with Friends" "Uninterested School" "Uninterested Activities" "None of These"
	loc c 1
	foreach var of varlist edu_3mo_badgrd edu_3mo_badtest edu_3mo_strgclass edu_3mo_strghw edu_3mo_acadcalls edu_3mo_behcalls edu_3mo_riskrpt edu_3mo_risknograd edu_3mo_depress edu_3mo_anxiety edu_3mo_frndprbs edu_3mo_schunint edu_3mo_actsunint edu_3mo_none {
		loc r 1
		foreach grp in 1 race_cat1 race_cat2 race_cat3 race_cat5 eco_hhincome1 eco_hhincome2 eco_hhincome3 eco_hhincome4 eco_hhincome5 {
			di "`var' by `grp' lvl"
			qui svy: tab `var' if wave==26 & ${undup} & `grp'==1
			mat x = e(b)
			loc num: di %4.2f 100*x[1,2]
			mat negexp[`r',`c'] = `num'
			loc ++r
			}
		loc ++c
		}

********* 2. Interventions overall and by race/income/concern/neg exp **********

*Overall and by race, income, concerns, and negative experiences
	mat ints = J(22,16,.)
	mat rownames ints = "Overall" "NH White" "NH Black" "NH Asian" "Hispanic" "<$25k" "$25k-$49k" "$50K-$74K" "$75K-$149K" ">=$150k" "No Concerned" "Any Concerned" "No Acad Concerned" "Any Acad Concerned" "No Non-Acad Concerned" "Any Non-Acad Concerned" "No NegExp" "Any NegExp" "No Acad NegExp" "Any Acad NegExp" "No Non-Acad NegExp" "Any Non-Acad NegExp"
	mat colnames ints = "SumSch Offer" "SumSch Interest" "SumSch Does" "SumSch WouldDo" "MHealth Offer" "MHealth Interest" "MHealth Does" "MHealth WouldDo" "ExCurr Offer" "ExCurr Interest" "ExCurr Does" "ExCurr WouldDo" "Tutor Offer" "Tutor Interest" "Tutor Does" "Tutor WouldDo"
	loc c 1
	foreach var of varlist edu_sumsch_schoffers edu_sumsch_interest edu_sumsch_does edu_sumsch_woulddo edu_mhealth_schoffers edu_mhealth_interest edu_mhealth_does edu_mhealth_woulddo edu_excurr_schoffers edu_excurr_interest edu_excurr_does edu_excurr_woulddo edu_tut_schoffers edu_tut_interest edu_tut_does edu_tut_woulddo {
		loc r 1
		foreach grp in 1 race_cat1 race_cat2 race_cat3 race_cat5 eco_hhincome1 eco_hhincome2 eco_hhincome3 eco_hhincome4 eco_hhincome5 edu_conc_noa_der edu_conc_anya_der edu_conc_noacad_der edu_conc_anyacad_der edu_conc_nononacad_der edu_conc_anynonacad_der edu_3mo_noa_der edu_3mo_anya_der edu_3mo_noacad_der edu_3mo_anyacad_der edu_3mo_nononacad_der edu_3mo_anynonacad_der {
		di "`var' by `grp' lvl"
			qui svy: tab `var' if wave==26 & ${undup} & `grp'==1
			mat x = e(b)
			loc num: di %4.2f 100*x[1,2]
			mat ints[`r',`c'] = `num'
			loc ++r
			}
		loc ++c
		}


******************************* 3. Significance ********************************

	*Concerns (by race and income)
	mat conc_sig = J(2,7,.)
	mat rownames conc_sig = "Race/Ethnicity" "HH Income"
	mat colnames conc_sig = "Psyc wellbeing" "Engagement" "Doing socially" "Amount learning" "Math progress" "Science progress" "ELA progress"
	loc c 1
	foreach var of varlist edu_concern_psychealth edu_concern_engage edu_concern_socprb edu_concern_amtlearn edu_concern_math edu_concern_sci edu_concern_ela {
		loc r 1
		foreach grp in ib0.race_cat ib3.eco_hhincome {
			di "`var' by `grp' sig"
			if "`grp'"=="ib0.race_cat" {
				qui reg `var' `grp' if wave==26 & ${undup} ${weight}
				qui test 1.race_cat 2.race_cat 4.race_cat
				loc num: di %4.3f `r(p)'
				mat conc_sig[`r',`c'] = `num'
				}
			if "`grp'"=="ib3.eco_hhincome" {
				qui reg `var' `grp' if wave==26 & ${undup} ${weight}
				qui test 0.eco_hhincome 1.eco_hhincome 2.eco_hhincome 4.eco_hhincome 
				loc num: di %4.3f `r(p)'
				mat conc_sig[`r',`c'] = `num'			
				}
			loc ++r
			}
		loc ++c
		}

	*Negative experiences (by race and income)
	mat negexp_sig = J(2,14,.)
	mat rownames negexp_sig = "Race/Ethnicity" "HH Income"
	mat colnames negexp_sig = "Low Grades" "Low Test Scores" "Struggles in Class" "Struggles with HW" "Academic Calls" "Behavioral Calls" "Risk Repeating" "Risk not Grad" "Depression" "Anxiety" "Problems with Friends" "Uninterested School" "Uninterested Activities" "None of These"
	loc c 1
	foreach var of varlist edu_3mo_badgrd edu_3mo_badtest edu_3mo_strgclass edu_3mo_strghw edu_3mo_acadcalls edu_3mo_behcalls edu_3mo_riskrpt edu_3mo_risknograd edu_3mo_depress edu_3mo_anxiety edu_3mo_frndprbs edu_3mo_schunint edu_3mo_actsunint edu_3mo_none {
		loc r 1
		foreach grp in ib0.race_cat ib3.eco_hhincome {
			di "`var' by `grp' sig"
			qui reg `var' `grp' if wave==26 & ${undup} ${weight}
			if "`grp'"=="ib0.race_cat" {
				qui test 1.race_cat 2.race_cat 4.race_cat
				loc num: di %4.3f `r(p)'
				mat negexp_sig[`r',`c'] = `num'		
				}
			if "`grp'"=="ib3.eco_hhincome" {
				qui test 0.eco_hhincome 1.eco_hhincome 2.eco_hhincome 4.eco_hhincome 
				loc num: di %4.3f `r(p)'
				mat negexp_sig[`r',`c'] = `num'			
				}
			loc ++r
			}
		loc ++c
		}

	*Interventions (by race and income and concerns and negative experiences)
	mat ints_sig = J(8,16,.)
	mat rownames ints_sig = "Race/Ethnicity" "HH Income" "Any Concerned" "Acad Concerned" "Non-Acad Concerned" "Any NegExp" "Acad NegExp" "Non-Acad NegExp"
	mat colnames ints_sig = "SumSch Offer" "SumSch Interest" "SumSch Does" "SumSch WouldDo" "MHealth Offer" "MHealth Interest" "MHealth Does" "MHealth WouldDo" "ExCurr Offer" "ExCurr Interest" "ExCurr Does" "ExCurr WouldDo" "Tutor Offer" "Tutor Interest" "Tutor Does" "Tutor WouldDo"
	loc c 1
	foreach var of varlist edu_sumsch_schoffers edu_sumsch_interest edu_sumsch_does edu_sumsch_woulddo edu_mhealth_schoffers edu_mhealth_interest edu_mhealth_does edu_mhealth_woulddo edu_excurr_schoffers edu_excurr_interest edu_excurr_does edu_excurr_woulddo edu_tut_schoffers edu_tut_interest edu_tut_does edu_tut_woulddo {
		loc r 1
		foreach grp in ib0.race_cat ib3.eco_hhincome edu_conc_anya_der edu_conc_anyacad_der edu_conc_anynonacad_der edu_3mo_anya_der edu_3mo_anyacad_der edu_3mo_anynonacad_der {
		di "`var' by `grp' sig"
			qui reg `var' `grp' if wave==26 & ${undup} ${weight}
			if "`grp'"=="ib0.race_cat" {
				qui test 1.race_cat 2.race_cat 4.race_cat
				loc num: di %4.3f `r(p)'
				mat ints_sig[`r',`c'] = `num'		
				}
			if "`grp'"=="ib3.eco_hhincome" {
				qui test 0.eco_hhincome 1.eco_hhincome 2.eco_hhincome 4.eco_hhincome 
				loc num: di %4.3f `r(p)'
				mat ints_sig[`r',`c'] = `num'			
				}
			if "`grp'"=="edu_conc_anya_der" | "`grp'"=="edu_conc_anyacad_der" | "`grp'"=="edu_conc_anynonacad_der" | "`grp'"=="edu_3mo_anya_der" | "`grp'"=="edu_3mo_anyacad_der" | "`grp'"=="edu_3mo_anynonacad_der" {
				mat x = r(table)
				loc num: di %4.3f x[4,1]
				mat ints_sig[`r',`c'] = `num'
				}
			loc ++r
			}
		loc ++c
		}

	*Concerns, negative experiences, and interventions: black vs non-black
	mat bnb_sig = J(37,1,.)
	mat rownames bnb_sig = "Psyc wellbeing" "Engagement" "Doing socially" "Amount learning" "Math progress" "Science progress" "ELA progress" "Low Grades" "Low Test Scores" "Struggles in Class" "Struggles with HW" "Academic Calls" "Behavioral Calls" "Risk Repeating" "Risk not Grad" "Depression" "Anxiety" "Problems with Friends" "Uninterested School" "Uninterested Activities" "None of These" "SumSch Offer" "SumSch Interest" "SumSch Does" "SumSch WouldDo" "MHealth Offer" "MHealth Interest" "MHealth Does" "MHealth WouldDo" "ExCurr Offer" "ExCurr Interest" "ExCurr Does" "ExCurr WouldDo" "Tutor Offer" "Tutor Interest" "Tutor Does" "Tutor WouldDo"
	mat colnames bnb_sig = "Black vs non-Black"
	loc r 1
	foreach var of varlist edu_concern_psychealth edu_concern_engage edu_concern_socprb edu_concern_amtlearn edu_concern_math edu_concern_sci edu_concern_ela edu_3mo_badgrd edu_3mo_badtest edu_3mo_strgclass edu_3mo_strghw edu_3mo_acadcalls edu_3mo_behcalls edu_3mo_riskrpt edu_3mo_risknograd edu_3mo_depress edu_3mo_anxiety edu_3mo_frndprbs edu_3mo_schunint edu_3mo_actsunint edu_3mo_none edu_sumsch_schoffers edu_sumsch_interest edu_sumsch_does edu_sumsch_woulddo edu_mhealth_schoffers edu_mhealth_interest edu_mhealth_does edu_mhealth_woulddo edu_excurr_schoffers edu_excurr_interest edu_excurr_does edu_excurr_woulddo edu_tut_schoffers edu_tut_interest edu_tut_does edu_tut_woulddo {
		di "`var' bnb sig"
		qui reg `var' race_cat2 if wave==26 & ${undup} ${weight}
			mat x = r(table)
			loc num: di %4.3f x[4,1]
			mat bnb_sig[`r',1] = `num'
		loc ++r
		}

********************************************************************************
******************************* Export to Excel ********************************
********************************************************************************

putexcel set "${output}\UrbanInst_intpart", sheet(Concerns, replace) replace
	putexcel A1 = "Levels", bold
	putexcel A2 = matrix(conc), names
	putexcel J1 = "Significance", bold
	putexcel J2 = matrix(conc_sig), names
	putexcel A1 = "Levels", bold
	putexcel close
putexcel set "${output}\UrbanInst_intpart", sheet(Negative Experiences, replace) modify
	putexcel A1 = "Levels", bold
	putexcel A2 = matrix(negexp), names
	putexcel Q1 = "Significance", bold
	putexcel Q2 = matrix(negexp_sig), names
	putexcel A1 = "Levels", bold
	putexcel close
putexcel set "${output}\UrbanInst_intpart", sheet(Interventions, replace) modify
	putexcel A1 = "Levels", bold
	putexcel A2 = matrix(ints), names
	putexcel S1 = "Significance", bold
	putexcel S2 = matrix(ints_sig), names
	putexcel A1 = "Levels", bold
	putexcel close
putexcel set "${output}\UrbanInst_intpart", sheet(Black_vs_nonBlack, replace) modify
	putexcel A1 = matrix(bnb_sig), names
	putexcel close
