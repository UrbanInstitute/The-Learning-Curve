/*** Set Directory Structure ***/
set more off

// Set Directory here
gl working_directory "C:/Users/lrestrepo/Documents/Github_repos/The-Learning-Curve/2022_05_27-Excelsior_Scholarship/"

gl dofiles  "${working_directory}projects/CUNYPL/FINAID/dofiles/"
gl exc      "${working_directory}projects/CUNYPL/FINAID/EXC/"
gl derived  "${working_directory}projects/CUNYPL/FINAID/derived/"
gl tmp      "${working_directory}projects/CUNYPL/FINAID/tmp/"
gl student  "${working_directory}projects/CUNYPL/MAIN/derived/"

capture log close

log using "${exc}cunypl_faid_excel_desc2.log", replace
/******************************************************************************************************
*stata version 15.1
*  PROJECT:    CUNY Policy Lab
*  FOR:        Judy Scott-Clayton
*  PROGRAMMER: DS / JSC
*  PROGNAME:   cunypl_faid_excel_desc2.do
*  PURPOSE:    Explore/document distribution of Excelsior dollars
*              Same as desc1.do but includes only those analyses used in the Learning Curve report
*
*  USES DATA:  /projects/CUNYPL/FINAID/derived/cunypl_faid_s2.dta
*  SAVES DATA:  none
*
*  CREATED:     06/2021 (original written by DS, cunypl_faid_descriptives.do)
*  UPDATED:     12/20/2021 JSC to adjust AGI measure, address out-of-state students, adjust FT enrollment
*               1/4/2022 CJ added graphs by eligibility
*               1/4/2022 JSC fixed tuition amounts to exclude fees
*               4/27/2022 CJ added code to produce data tables in Excel, Judy cleaned up and commented code
*********************************************************************************************************/

// Data is not shared for public use
use "${derived}*****", clear

/* Limit sample to Fall 2018 FTFY degree-seeking (associate or bachelors) undergraduates */
/* Note: enrollment and aid receipt data use calendar year so "201803" = Fall 2018 */
/* FAFSA data use financial aid/ academic year so "2019" applies to 2018-19 aid year */
keep if fug_termcyr==2018 & fug_termtype=="AU" & (fug_degenr==2 | fug_degenr==3)

/* Limit sample to those who filed FAFSA, as indicated by non-missing EFC on file*/
keep if prim_efc_raw_19<. /* Note: 2019 aid year is 2018-19, about 87% of this sample has */

/*Exclude Macauley honors college for this analysis because all students receive full tuition scholarship already */
drop if fug_schtype==3

/* Create new variables needed to establish Excelsior eligibility and renewal */

*Recode 2019 fall Excelsior receipt to 0 if missing, create "other grant" variable to capture all non-Pell/TAP/Exc grants
recode excel201803 (.=0)
recode excel201903 (.=0)
gen othgrantamt201803 = totgrantamt201803 - pellamt201803 - tapamt201803 - excelamt201803

*Create an AGI variable that uses parent data if dependent and student data if independent
for X in var par_agi_amt_19 stu_agi_amt_19: replace X=. if X==9999999
gen agi2019=par_agi_amt_19 if stu_dep_stat_cd_19=="D"
replace agi2019=stu_agi_amt_19 if stu_dep_stat_cd_19=="I"

*Create a full-time indicator based on college level credits attempted only (excelsior excludes remedial credits)
gen ftnorem=fug_semcratt>=12 & fug_semcratt<.

*Generate measure of remaining fall tuition need after all grants other than excelsior
gen remaining_need = 2400-(totgrantamt201803-excelamt201803) if faid_schtype_19==1  /* CC tuition */
replace remaining_need = 3365-(totgrantamt201803-excelamt201803) if faid_schtype_19==2 /*Senior college tuition */
gen excel_gap = 1 if remaining_need>0 & remaining_need!=.
recode excel_gap (.=0) if totgrantamt201803!=. & excelamt201803!=.

*Create different excelsior eligibility indicators
gen excel_income_elig = (agi2019<=110000)
gen excel_enr_elig = (excel_income_elig==1 & ftpt201803==1)
gen excel_enr2_elig = (excel_income_elig==1 & ftnorem==1)
gen excel_fullelig = (excel_enr2_elig==1 & excel_gap==1 & instate==1)

*Create income bins for producing graphs
gen inc5k=floor(agi2019/5000)*5000
replace inc5k = 0 if inc5k<0 & inc5k!=.
replace inc5k = 150000 if inc5k>150000 & inc5k!=.

*Create an indicator var
gen all=1

/************* Figure 1: Average Grant Aid, 2018 FTFY students **********************/

tabstat pellamt201803 tapamt201803 excelamt201803 othgrantamt201803, by(inc5k) stat(mean)
tabstat pellamt201803 tapamt201803 excelamt201803 othgrantamt201803, by(inc5k) stat(n)

/******************** Figure 2: Percent receiving NYEXC among fully eligible, by subgroup ************/

tabstat excel201803 if excel_fullelig==1 , by(ethnicity)
tabstat excel201803 if excel_fullelig==1 , by(gender)
tabstat excel201803 if excel_fullelig==1 , by(fug_schtype)

/******************** Figure 3: Percent receiving NYEXC among fully eligible, by subgroup within CC/Senior coll ************/

tabstat excel201803 if fug_schtype==1 & excel_fullelig==1, by(ethnicity)
tabstat excel201803 if fug_schtype==2 & excel_fullelig==1, by(ethnicity)

/********************* Figure 4: Renewal rates among 2018 FTFY recipients, by subgroup ****************/

tab ftpt201903, m   /* 0=not enrolled */
tab ftpt201903 if excel201803==1   /* 0=not enrolled */

*Create two sets of bars for each group, first for returning students only
tabstat excel201903 if excel201803==1 & (ftpt201903==1 | ftpt201903==2), by(ethnicity) stats(mean) save nototal
tabstat excel201903 if excel201803==1 , by(ethnicity) stats(mean) save nototal

tabstat excel201903 if excel201803==1 & (ftpt201903==1 | ftpt201903==2), by(gender) stats(mean) save nototal
tabstat excel201903 if excel201803==1 , by(gender) stats(mean) save nototal

tabstat excel201903 if excel201803==1 & (ftpt201903==1 | ftpt201903==2), by(faid_schtype_19) stats(mean) save
tabstat excel201903 if excel201803==1 , by(faid_schtype_19) stats(mean) save

/************************** Other assorted statistics ***************************/

*calculate % of EXC dollars for FTFY 2018 cohort go to students with family income over $75K
*tabstat will show cumulative amount for those above/below $75K but will need to compute % manuallyu
gen incover75 = agi2019>=75000
tabstat excelamt201803, by(incover75) stat(sum)

*Percent of income-eligible meeting enrollment criteria
tab excel_enr2_elig if excel_income_elig==1

*Eligibility criteria and Receipt for NY EXC by income bin (for "Finding #2") **********************/
tabstat excel_income_elig excel_enr_elig excel_enr2_elig excel_fullelig excel201803, by(inc5k) m

*Overall pell, tap, excelsior receipt for this group
tabstat excel201803 pell201803 tap201803

*Renewal rates for different groups (for "Finding #3" text)
gen has2020efc=prim_efc_raw_20<.

tabstat excel201903 if excel201803==1
tabstat excel201903 if excel201803==1 & (ftpt201903==1 | ftpt201903==2)
tabstat excel201903 if excel201803==1 & (ftpt201903==1 | ftpt201903==2) & has2020efc
tabstat excel201903 if excel201803==1 & (ftpt201903==1 | ftpt201903==2) & has2020efc & tap201903==1

log close
