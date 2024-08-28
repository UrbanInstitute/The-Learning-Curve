/*
HB729 LC piece - Proportionality Calculations


*/

set more off
clear

global id_vars "ncessch leaid gleaid county_name county"

global race_cats "whit bkaa hisp asia aian nhpi twom unkn"
global race_cat6 "whit bkaa hisp asia aian all_other"

use "${data}working_data_V0.dta"

drop if mi(enrl_totl) | enrl_totl == 0

// Make consistent groups
gen enrl_all_other = enrl_nhpi + enrl_twom + enrl_unkn
gen county_all_other = county_twom + county_nhpi + county_othr
gen child_all_other = child_twom + child_nhpi + child_othr


// LEA level race counts
foreach ra of global race_cat6 {
	bys leaid: egen lea_`ra' = total(enrl_`ra')
	bys gleaid: egen glea_`ra' = total(enrl_`ra')
	bys county: egen county_sch_`ra' = total(enrl_`ra')
}

// County and LEA totals
egen lea_totl = rowtotal( ///
						lea_whit	lea_bkaa	lea_aian ///
						lea_asia lea_all_other  lea_hisp)
egen glea_totl = rowtotal( ///
						glea_whit	glea_bkaa	glea_aian ///
						glea_asia glea_all_other glea_hisp)
						
egen county_sch_totl = rowtotal( ///
						county_sch_whit	county_sch_bkaa	county_sch_aian ///
						county_sch_asia county_sch_all_other county_sch_hisp)

// Race Proportions
foreach ra of global race_cat6 {
	gen sch_p_`ra' = enrl_`ra' / enrl_totl
	gen lea_p_`ra' = lea_`ra' / lea_totl
	gen glea_p_`ra' = glea_`ra' / glea_totl
	gen county_p_`ra' = county_`ra' / county_totl
	gen child_p_`ra' = child_`ra' / child_totl
	gen county_sch_p_`ra' = county_sch_`ra' / county_sch_totl
}

// Prop Score Calulation

foreach ra of global race_cat6{
	
	// Baseline Comparison Calculation
	gen lea_baseline_`ra' = enrl_totl * lea_p_`ra'
	gen glea_baseline_`ra' = enrl_totl * glea_p_`ra'
	gen county_baseline_`ra' = enrl_totl * county_p_`ra'
	gen child_baseline_`ra' = enrl_totl * child_p_`ra'
	gen county_sch_baseline_`ra' = enrl_totl * county_sch_p_`ra'
	
	// Difference btw school and baseline
	gen lea_abs_diff_`ra' = abs(lea_baseline_`ra' - enrl_`ra')
	gen glea_abs_diff_`ra' = abs(glea_baseline_`ra' - enrl_`ra')
	gen county_abs_diff_`ra' = abs(county_baseline_`ra' - enrl_`ra')
	gen child_abs_diff_`ra' = abs(child_baseline_`ra' - enrl_`ra')
	gen county_sch_abs_diff_`ra' = abs(county_sch_baseline_`ra' - enrl_`ra')
	

}

// Sum of Absolute Differences
egen lea_prop = rowtotal( ///
		lea_abs_diff_whit		lea_abs_diff_bkaa		lea_abs_diff_hisp ///
		lea_abs_diff_asia		lea_abs_diff_aian		lea_abs_diff_all_other)
egen glea_prop = rowtotal( ///
		glea_abs_diff_whit		glea_abs_diff_bkaa		glea_abs_diff_hisp ///
		glea_abs_diff_asia		glea_abs_diff_aian		glea_abs_diff_all_other)
		
egen county_prop = rowtotal( ///
		county_abs_diff_whit	county_abs_diff_bkaa	county_abs_diff_hisp ///
		county_abs_diff_asia	county_abs_diff_aian	county_abs_diff_all_other)
egen child_prop = rowtotal( ///
		child_abs_diff_whit		child_abs_diff_bkaa		///
		child_abs_diff_asia		child_abs_diff_aian		child_abs_diff_all_other)
		
egen county_sch_prop = rowtotal( ///
		county_sch_abs_diff_whit		county_sch_abs_diff_bkaa		county_sch_abs_diff_hisp ///
		county_sch_abs_diff_asia		county_sch_abs_diff_aian		county_sch_abs_diff_all_other)

//Scale to Propotion
replace lea_prop = lea_prop / (2*enrl_totl)
replace glea_prop = glea_prop / (2*enrl_totl)
replace county_prop = county_prop / (2*enrl_totl)
replace child_prop = child_prop / (2*enrl_totl)
replace county_sch_prop = county_sch_prop / (2*enrl_totl)

// Categorize based on bill cutoffs
gen lea_prop_cat = ///
		cond(lea_prop < 0.1, 1, ///
		cond(lea_prop >= 0.1 & lea_prop < 0.25, 2, ///
		cond(lea_prop >= 0.25 & lea_prop < 0.5, 3, ///
		4)))
gen glea_prop_cat = ///
		cond(glea_prop < 0.1, 1, ///
		cond(glea_prop >= 0.1 & glea_prop < 0.25, 2, ///
		cond(glea_prop >= 0.25 & glea_prop < 0.5, 3, ///
		4)))
gen county_prop_cat = ///
		cond(county_prop < 0.1, 1, ///
		cond(county_prop >= 0.1 & county_prop < 0.25, 2, ///
		cond(county_prop >= 0.25 & county_prop < 0.5, 3, ///
		4)))
gen child_prop_cat = ///
		cond(child_prop < 0.1, 1, ///
		cond(child_prop >= 0.1 & child_prop < 0.25, 2, ///
		cond(child_prop >= 0.25 & child_prop < 0.5, 3, ///
		4)))
		
gen county_sch_prop_cat = ///
		cond(county_sch_prop < 0.1, 1, ///
		cond(county_sch_prop >= 0.1 & county_sch_prop < 0.25, 2, ///
		cond(county_sch_prop >= 0.25 & county_sch_prop < 0.5, 3, ///
		4)))

order lea_base* glea_base* county_base*
order lea_prop* glea_prop* county_prop*
order county_p* lea_p* glea_p* sch_p*, first
order $id_vars enrl_totl, first

// Variable Labeling
label variable lea_totl "LEA Total enrollment"
label variable glea_totl "Geographic LEA Total enrollment"
label variable lea_prop "LEA Level Proportionality"
label variable glea_prop "GLEA Level Proportionality"
label variable county_prop "County Level Proportionality"
label variable lea_prop_cat "LEA Proportionality - 1 is proportional 4 is not"
label variable glea_prop_cat "Geographic LEA Proportionality - 1 is proportional 4 is not"
label variable county_prop_cat "County Proportionality - 1 is proportional 4 is not"

// save "${data}working_data_V0.dta", replace
save "${data}hb729_analysis_file_v0.dta", replace