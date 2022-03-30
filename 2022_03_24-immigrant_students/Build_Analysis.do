
clear

// CHANGE THIS
global working_dir = "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_04_07-immigrant_students"

cd "${working_dir}"

// Setting up macros
global data = "Data"
global output = "${data}\output_data"
global input = "${data}\input_data"
global vis = "${output}\vis"

cap n mkdir "${data}"
cap n mkdir "${input}"
cap n mkdir "${output}"
cap n mkdir "${vis}"

// Graphing
graph set window fontface "lato"

*IMPORT LANGUGAGE DATA FROM MN DEPT OF E

cap n copy "https://education.mn.gov/mdeprod/groups/educ/documents/basic/bwrl/mdmx/~edisp/mde031909.xlsx" "${input}\2019-20 Primary Home Language Totals.xlsx"
import excel "${input}\2019-20 Primary Home Language Totals.xlsx", sheet("rpt_homeLanguage_2019_2020_dist") cellrange(A2:M5969) firstrow

gen state_leaid="MN-"+DistrictType+DistrictNumber
 
 *Calculate Simpson's Diversity Index for Each School District
 *The value for Simpson’s Diversity Index ranges between 0 and 1. The higher the value, the lower the diversity.
 *Since this interpretation is a bit counterintuitive, we often calculate Simpson’s Index of Diversity (sometimes called a Dominance Index), which is calculated as 1 – D. The higher the value for this index, the higher the diversity of species.
 *D = Sum of all (n/N)^2
 
 *Calculate (Enrolled w/ Language/Total Enrollment)^2
 bysort state_leaid: egen sum_enroll=total(Enrollments)
 gen diversity_factor=(Enrollments/sum_enroll)^2
 
 *Collapse to get a diversity factor by school district
 preserve
 collapse (sum) diversity_factor, by(state_leaid)
 sort diversity_factor
 save "${output}\language_diversity.dta", replace
 restore
 
 *The format of the language data is such that keeping each name doesn't work. 
 *Preserving that information here, and recoding as a number (e_011 is English)
 preserve
 keep LanguageName HomePrimaryLanguage
 duplicates drop
 sort HomePrimaryLanguage
 export excel "${output}\Language Code List", replace
 restore
 
 *Calculate Simpson’s Index of Diversity
bysort state_leaid: egen s_diversity_factor_lang= sum(diversity_factor)

drop if HomePrimaryLanguage==""

keep state_leaid s_diversity_factor_lang HomePrimaryLanguage Enrollments 

rename Enrollments e_

*Wide File with Language Diversity Factor & Language Data
reshape wide e_, i(state_leaid s_diversity_factor_lang) j(HomePrimaryLanguage) string

*Calculate Simpson’s Index of Diversity
gen ind_of_div_lang=1-s_diversity_factor_lang

save "${output}\district_lang_enroll_w.dta", replace
 
 *IMPORT SCHOOL DISTRICT RACE DATA
 clear
 educationdata using "district ccd enrollment race", sub(year=2019 fips=27) csv
 
 keep if sex==99 //"Total"
 keep if grade==99 //"Total"
 drop if race==99
 
 
 *No Unknowns in data, so drop
 table race, c(max enrollment min enrollment)
 drop if race==9
 
 *Build Diversity Factor For Race & Ethnicity
 bysort leaid: egen sum_enroll_race=total(enrollment)
 gen diversity_factor_race=(enrollment/sum_enroll_race)^2
 browse if diversity_factor_race==.
 drop if diversity_factor_race==.
 save "${output}\district_race_enroll.dta", replace
 
 bysort leaid: egen s_diversity_factor_race= sum(diversity_factor_race)

 
 *Wide File with Race & Ethnicity Diversity Factor
 drop diversity_factor_race sum_enroll_race
 reshape wide enrollment, i(leaid fips s_diversity_factor_race) j(race)
 drop grade sex
 
 rename enrollment1 white
 rename enrollment2 black
 rename enrollment3 hisp
 rename enrollment4 asian
 rename enrollment5 aina
 rename enrollment6 nhpi
 rename enrollment7 twoplus
 
*Calculate Simpson’s Index of Diversity
gen ind_of_div_race=1-s_diversity_factor_race
   
save "${output}\district_race_enroll_w.dta", replace
 
 
 *IMPORT DIRECTOR DATA & MERGE DATA TOGETHER
clear
educationdata using "district ccd directory", sub(year=2019 fips=27) csv

merge 1:1 leaid using "${output}\district_race_enroll_w.dta", nogen
merge 1:1 state_leaid using "${output}\district_lang_enroll_w.dta"

list state_leaid if _merge==2 //Generic codes
list lea_name enrollment if _merge==1 //V. small or no enrollment

keep if _merge==3
drop _merge

*Correlation between language diversity & race & ethnicity diversity fairly low
corr ind_of_div_lang ind_of_div_race
twoway scatter ind_of_div_lang ind_of_div_race [w=enrollment*.9], mcolor("22 150 210") color(%40) ytitle("Diversity of language", size(small)) xtitle("Diversity of race", size(small)) graphregion(color(white)) bgcolor(white) ylabel(0 "0%" .2 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.0 "100%", angle(0)) xlabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0))

*Overall, less diversity in language, but similar variance
sum ind_*, detail

*But more 

*********************************
*EXPORT DATA FOR FIGURE 1
preserve
keep leaid lea_name enrollment ind_of_div_race ind_of_div_lang
export excel "${output}\Output.xls", sheet("Fig1") sheetreplace firstrow(variables)
restore
graph export "${vis}\graph_1_race_lang.png", as(png) height(1000) replace
*********************************

*IMPORT DATA ON ELL
clear
educationdata using "district ccd directory", sub(year=2018:2019 fips=27) csv

*ELL is not yet available for 2019, so using 2018
*Migrant is not available at all for MN
gen ell_share=english_language_learners/ enrollment
bysort leaid: egen ell_share_18=max(ell_share)
drop if year==2018
drop ell_share

replace ell_share_18=0 if ell_share_18==. //Not reported is 0

merge 1:1 leaid using "${output}\district_race_enroll_w.dta", nogen
merge 1:1 state_leaid using "${output}\district_lang_enroll_w.dta", nogen

drop zip_mailing zip4_mailing street_location city_location state_location zip_location zip4_location phone latitude longitude urban_centric_locale cbsa cbsa_type csa cmsa necta county_code county_name congress_district_id state_leg_district_lower state_leg_district_upper bureau_indian_education supervisory_union_number

drop teachers_prek_fte teachers_prek_fte teachers_kindergarten_fte teachers_elementary_fte teachers_secondary_fte teachers_ungraded_fte teachers_total_fte instructional_aides_fte coordinators_fte guidance_counselors_elem_fte guidance_counselors_sec_fte guidance_counselors_other_fte guidance_counselors_total_fte school_counselors_fte librarian_specialists_fte librarian_support_staff_fte lea_administrators_fte lea_admin_support_staff_fte lea_staff_total_fte school_administrators_fte school_admin_support_staff_fte school_staff_total_fte support_staff_students_fte school_psychologists_fte support_staff_stu_wo_psych_fte support_staff_other_fte staff_total_fte other_staff_fte


*Analyze correlation with ELL
egen total_lang=rowtotal(e_*)
*Subtract out English (e_011) to get Share non-English At Home
gen nonEng_lang=(total_lang-e_011)/total_lang

*High Correlation
pwcorr nonEng_lang ell_share_18

gen has_both=1 if nonEng_lang<. & ell_share_18<.

*Data for Text: Share ELL vs. Non-Eng Language
sum nonEng_lang ell_share_18 [fw=enrollment] if has_both==1

twoway scatter nonEng_lang  ell_share_18 [w=enrollment*.9], mcolor("22 150 210") color(%40) title("", position(11) justification(left) color("0 0 0") size(4)) xtitle("ELL Share", size(small)) ytitle("Non-English speaker share", size(small)) graphregion(color(white)) bgcolor(white) ylabel(0 "0%" .2 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) xlabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0))

*********************************
*EXPORT DATA FOR FIGURE 2
preserve
keep leaid lea_name enrollment nonEng_lang ell_share_18
export excel using "${output}\Output.xls", sheet("Fig2") sheetreplace firstrow(variables)
restore
graph export "${vis}\graph_2_ell_noneng.png", as(png) height(1000) replace
*********************************

save "${output}\district_ccd_ell_lang.dta", replace

clear
educationdata using "school ccd directory", sub(year=2019 fips=27) csv

gen sch_t1=(title_i_schoolwide==1) if title_i_eligible!=-1 
collapse (sum) sch_t1 (rawsum) free_or_reduced_price_lunch enrollment [fw=enrollment], by(leaid)

gen per_frpl=free_or_reduced_price_lunch/enrollment
gen per_title_1=sch_t1/enrollment

merge 1:1 leaid using "${output}\district_ccd_ell_lang.dta", nogen

*Analyze correlation
pwcorr per_frpl per_title_1 nonEng_lang

twoway scatter nonEng_lang  per_frpl [w=enrollment*.9], mcolor("22 150 210") color(%40) title("", position(11) justification(left) color("0 0 0") size(4)) xtitle("Free and reduced-price lunch share", size(small)) ytitle(" " "Non-English speaker share", size(small)) graphregion(color(white)) bgcolor(white) ylabel(0 "0%" .2 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0)) xlabel(0 "0%" .20 "20%"  .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", angle(0))

*********************************
*EXPORT DATA FOR FIGURE 3
preserve
keep leaid lea_name enrollment  nonEng_lang per_frpl per_title_1
order leaid lea_name enrollment  per_frpl nonEng_lang per_title_1
export excel using "${output}\Output.xls", sheet("Fig3") sheetreplace firstrow(variables)
restore
graph export "${vis}\graph_3_nonEng_freeLunch.png", as(png) height(1000) replace
*********************************