/*
Tia Caldwell
6/27/2023 

This program pulls information about law programs circa 2015-2016 from a variety of sources. 
The main analysis creates a costs-to-earnings-premium metric. 
This metric uses 3 year median earnings of graduates from Scorecard and listed tuition and fees from IPEDS. 
The program exports a file to Excel with data for 3 figures and 1 table analyzing how programs perform on the metric.

Online data available here: https://educationdata.urban.org/documentation/colleges.htm

*/ 

********************************************************************************
********************************************************************************
*File set up
********************************************************************************
********************************************************************************
/*To run this file, you need 
	- an internet connection (some data pulls from Ubran's online portal)
	- To save this do file in a folder with a another file called "raw_data" containing several excel files 
	- To save the name of your folder/directory in the line below */ 
	
// Change this line
global main "C:\Users\lrestrepo\Documents\github_repos\The-Learning-Curve\2023_10_12-Law_School_Tuition"
 
cd "${main}"
global raw "${main}/raw_data"
global cleaned "${main}/cleaned_data"
global final "${main}/final_data"

cap n mkdir "${cleaned}"
cap n mkdir "${final}"
cap n mkdir "${raw}"

cd "${raw}"

unzipfile "${main}/raw_data.zip", replace

cd "${main}"

cap n ssc install cpcorr

********************************************************************************
********************************************************************************
*STEP 1: CLEAN AND SAVE DATASETS USED TO CORRELATE WITH COST/EARNINGS METRICS 
********************************************************************************
********************************************************************************

********************************************************************************
*Clean data on bar passage rate & US News Rankings
********************************************************************************
/* data seems to be from ABA & US News & World Report, archived here.
https://www.ilrg.com/rankings/law/2017/1/desc/LSATHigh
I manually changed law school names in the Excel file to match all schools. 
 */

import excel "${raw}/bar_passage_rate_2017_2.xlsx", sheet("Sheet1") firstrow clear
destring(No Accept GPA* LSATHigh LSATLow SFRatio EmplGrad Empl10 PassBar StateBar Library), replace force
cap n ren UNITID unitid
rename No rank 
save "${cleaned}/bar_pass.dta", replace  

********************************************************************************
*Clean FREOOP lifetime return on investment estimates* 
********************************************************************************

tempfile sheetsFile
copy "https://docs.google.com/spreadsheets/d/17PPYiLmpwGQqzeoViQ1eiF16bMa3njJNyrFolPNzKWY/export?format=xlsx" `sheetsFile', replace
import excel `sheetsFile', clear firstrow

rename *, lower

format *tuition* *spend* *roi* *earn* %12.0fc
gen cip4 = programcipcode
ren credentiallevel cred_lvl
gen keep = 0
replace keep = 1 if cred_lvl == 7 
sort unitid cip4 keep
by unitid cip4: keep if _n == _N 
drop keep 
save "${cleaned}/FREOOP_grad_roi.dta", replace 

********************************************************************************
*Clean programmatic data from Scorecard. Use this for median earnings and loan repayment
********************************************************************************
cap n copy "https://ed-public-download.app.cloud.gov/downloads/Most-Recent-Cohorts-Field-of-Study_04192023.zip" "${raw}/cs_data.zip"
cd "${raw}"
cap n unzipfile "${raw}/cs_data.zip"
cd "${main}"
import delimited "${raw}/Most-Recent-Cohorts-Field-of-Study.csv", clear  

gen keep = 0 
*** keep just the law programs*** 
keep if cipcode == 2201 & credlev == 7 

******Convert unitid, debt, and earnings variables to numbers.*********
*This changes "PrivacySuppressed" (and all other nonnumeric entries (hopefully none) to missing. 
quietly destring (earn* debt* unitid), force replace 

drop if unitid == . 

******Clean data on loan repayment**********
split bbrr4_fed_comp_paidinfull, p(-)
gen loan_paid_4yr = bbrr4_fed_comp_paidinfull1
replace loan_paid_4yr = ".1" if bbrr4_fed_comp_paidinfull1 == "<=0.20"
replace loan_paid_4yr = ".05" if bbrr4_fed_comp_paidinfull1 == "<=0.10"
replace loan_paid_4yr = "0" if bbrr4_fed_comp_paidinfull1 == "<=0.05"
replace loan_paid_4yr = "0" if bbrr4_fed_comp_paidinfull1 == "<=0.02"
destring(loan_paid_4yr), replace force 

****** Drop most variables*******
keep opeid6 unitid instnm control cipcode cipdesc credlev creddesc earn* loan_paid_4yr 

****Save**** 
save "${cleaned}/scorecard_loan_paid.dta", replace 

********************************************************************************
*Clean GE 2022 PPD data 
********************************************************************************
*Data is avaiable here: https://www2.ed.gov/policy/highered/reg/hearulemaking/2021/index.html?src=rn
*Under "General Information", expand "Federal Register Notices and Fact Sheets". 
*Near the bottom of the list, download "GE Data 3* – Dataset (Excel) (54M) [5/17/2023]"
cap n copy "https://www2.ed.gov/policy/highered/reg/hearulemaking/2021/nprm-2022ppd-public-suppressed.xlsx" ///
	"${raw}/nprm-2022ppd-public-suppressed.xlsx", replace
import excel "${raw}/nprm-2022ppd-public-suppressed.xlsx", sheet("Sheet1") firstrow clear
keep if cip4 == 2201 & cred_lvl == "Professional"
drop pell_vol_* // all zero or missing since law programs 
destring(inexpfte-tot_loan_vol2022), replace force 
save "${cleaned}/GE_2022ppd.dta", replace 

********************************************************************************
********************************************************************************
*STEP 2: MERGE IPEDS EARINGS WITH OTHER DATA  
********************************************************************************
********************************************************************************

********************************************************************************
*Clean IPEDS institutional data (from Urban)*
********************************************************************************
educationdata using "college ipeds directory", sub(year=2020) clear
keep unitid inst_name opeid inst_control inst_category sector hbcu tribal_college cc_basic_2018 
save "${cleaned}/instutional_ipeds", replace 


********************************************************************************
*Save 2016 tuition and fees as a check on the 2015 #s
********************************************************************************
educationdata using "college ipeds academic-year-tuition-prof-program", sub(year=2016 prof_program=9) clear 
rename tuition_fees tuition_fees_16 
keep unitid  tuition_type tuition_fees_16
save "${cleaned}/tuition_16", replace 


********************************************************************************
*Load and clean IPEDS Law Tuition Data (from Urban) 
********************************************************************************
*The form schools use to report their law earnings is here: https://surveys.nces.ed.gov/ipeds/public/survey-materials/forms?surveyid=11&instructionid=30072&formid=72 
*"List the typical tuition and required fees for a full-time doctor's-professional 
*practice student in any of the selected programs for the full academic year 2022-23." 

***main tuition file - download law programs with 2015-16 tuition data***
educationdata using "college ipeds academic-year-tuition-prof-program", sub(year=2015 prof_program=9) clear 

**2016 tuition data***
merge 1:1 unitid tuition_type using "${cleaned}/tuition_16", keep(match master) nogen 


****** drop in and out of state tuition if it is the same **** 
*leaves with 298 obs
gsort unitid tuition_type 
bys unitid: gen same = tuition_fees[1] == tuition_fees[_N]
replace tuition_type = 5 if same == 1 
bys unitid: drop if _n == 1 & same == 1
drop same 
label define in_state 3 "In state" 4 "Out of state" 5 "Same tuition"
label values tuition_type in_state 


**********************************************************************
*Check and fix the wrong tuition data 
**********************************************************************
sort tuition_fees
format tuition* fees* %12.0fc

*Massachusetts School of Law has recorded credit hours. Full-time is  30 credits 
*https://www.mslaw.edu/affordable-tuition/
replace tuition = tuition*30 if unitid == 369002

*Capital University has also recorded credit hour costs. Students are expected 
*to take around 29 credits per semester. 
*https://www.law.capital.edu/admission-aid/financial-aid/cost-of-attendance-tables/
replace tuition = tuition*29 if unitid == 201548

*Washburn is 29 for full-time 
*https://www.washburnlaw.edu/admissions/financing/costs.html
replace tuition = tuition*29 if unitid == 156082

*Trinity seems to cost somewhere in the 30k range, but is not reporting how many credit hours are needed for full-time. Assume 30 
*https://www.tiu.edu/online/financial-aid/
replace tuition = tuition*30 if unitid == 123448

*Dayton is also not clear but it takes 90 credit hours to graduate so also assume 30 
*https://udayton.edu/law/registrar/degree_requirements.php 
replace tuition = tuition*30 if unitid == 202480

*Faulner is 15 credit hours 
*https://law.faulkner.edu/admissions/tuition-and-financial-aid/
replace tuition = tuition*15 if unitid == 101189

*Mighican state is 29 https://www.law.msu.edu/admissions/tuition-fees.html
replace tuition = tuition*29 if unitid == 169628
 
*Regent is 15 https://www.regent.edu/tuition-aid/#tuition-rates-by-school-2023-2024/school-of-law
replace tuition = tuition*15 if unitid == 231651

**Stanford is an outlier, so I checked it out. It is wrong (in the 2016 data the tuition is $56,688. 
**Used the way back machine to check tuition 
** https://web.archive.org/web/20150906144301/https://law.stanford.edu/apply/tuition-financial-aid/cost-of-attendance/
replace tuition = 54183 if unitid == 243744

*Univeristy of PR seems right 
*TAft seems right https://www.taft.edu/tuition-fees 
*University of New Mexico seems right 
*I spot checked a few more expensive ones and they also seem in the right ballpark 
*Some state schools are confusing because most of their costs is in fees 

** Recalculate the tuition and fees ****
replace tuition_fees = tuition + fees if tuition_fees != tuition + fees  & fees != . & tuition != . 

********** Next compare 2016 tuition to 2015. If more than 50% higher, adjust 2015 **** 
*Checked Touro college and the 2016 data is aboslutely more accurate https://web.archive.org/web/20150619024328/https://www.tourolaw.edu/studentresources/tuition-fees
gen pct_dif = ((tuition_fees_16-tuition_fees)/tuition_fees) if tuition_fees != .  

*Replace with 2016 tuition but delflated 
*https://data.bls.gov/cgi-bin/cpicalc.pl?cost1=100.00&year1=201601&year2=201701
replace tuition_fees = tuition_fees_16*(1/1.025) if pct_dif >.5 & tuition_fees_16 !=. //8 changes 

drop pct_dif tuition fees tuition_fees_16 

********Create 3 year cost metric ************
gen tuition_fees_3yr = tuition_fees*3 

********************************************************************************
*Merge IPEDS Law Tuition Data with the other datasets 
********************************************************************************
*** Merge on OPEID & to get bascis about the university from IPEDS ***
merge m:1 unitid using "${cleaned}/instutional_ipeds.dta",  keep(match master) nogen // 297 merged 

*** Merge with debt repayment and earnings numbers from Scorecard ***
gen cipcode = 2201 //general law code  
gen credlev = 7 
merge m:1 unitid cipcode credlev using "${cleaned}/scorecard_loan_paid.dta",  keep(match master) nogen //  293 merged 
*the 6 nonmatched all had 0 tuition and fees so I think it is fine to drop. I checked the first one and there is no law program in the scorecard data 

*** merge to get GE passage rates plus some other good info in the PPD ***
gen cred_lvl = "Professional" 
gen cip4 = cipcode 
merge m:1 opeid6 cred_lvl cip4 using "${cleaned}/GE_2022ppd.dta", force  keep(match master) nogen // 244 merged, this merge is not great - 43 not matched so might want to go back to 

*** Merge to get law school bar passage rate ***
gen LawSchool = inst_name 
merge m:m unitid using "${cleaned}/bar_pass.dta",  keep(match master) nogen //267 merged 
replace rank = 210 if rank == . & earn_ne_mdn_3yr != . //set unranked above highest rank (200)

**** Merge to get FREOOP's ROI estimates ***
merge m:1 unitid cip4 using "${cleaned}/FREOOP_grad_roi.dta", force   keep(match master) nogen // 272 matched 


********************************************************************************
********************************************************************************
*STEP 3: MAKE ACCOUNTABILITY METRICS  
********************************************************************************
********************************************************************************
**Deflate scorecard earnings number 
**Scorecard inflated this number to be in 2020 dollars, but it is actually 2019 $$s. 
gen earn3yr =  earn_ne_mdn_3yr*.987813 
format earn3yr %12.0fc //looks like mdearnp3, as it should 

**********************************************************************
*Make different tuition to earnings measures
**********************************************************************

** Write a program to make many metrics more easily 
program drop _all 
program define make_metric 
	
	args name cost earn premium
	gen `name'  = `cost'/(`earn' - `premium')
	replace `name' = 30 if `name' < 0 
	replace `name' = 30 if `name' >= 30 & `name' != .   //programs that never pay off are capped at 30 years 

end 

** Tuition-to-earning-premium metrics 
foreach var of varlist earn3yr  {  //previously tried out different earnings variables, but it does not seem to matter too much
	foreach num of numlist 0 20000 40000 60000 {
		local name = "`var'" + "_" + string((`num')/1000)
		make_metric `name' tuition_fees_3yr `var' `num'
	}
}

** Cost-to-earning-premium metrics using $40k counterfactual earnings and different opportunity costs
foreach num of numlist 0 40000 60000 80000 120000{
		local name = "earn3yr_40" + "_" + string((`num')/1000)
		gen temp_cost = tuition_fees_3yr + `num'
		make_metric `name' temp_cost earn3yr 40000
		drop temp_cost
	}
	
*********Set Puerto Rico to missing *************
** Less certain that the counterfactual earnings work well for PR. Preston Cooper did not calculate counterfactual earnings for PR schools. 

replace earn3yr_40_60 = . if fips == 72

******************************************************************************
**** Clean and save the data ***** 
******************************************************************************

format earn3yr_* pfemale pnonwhite phisp pasian %5.1fc 
format tuition_fees_* earn3yr earn* meandebt mediandebt avg_t4 tot_loan_vol* %12.0fc 
sort earn3yr_40_60 

cap n ren estimatedearningsatage30 earn_30
cap n ren ap earn_cf_30
cap n ren lifetimereturnoninvestmentr life_roi
cap n ren roiweightedbycompletionlikel roi_completion_weight
cap n ren af roi_ed_specing

keep unitid opeid6 inst_name cipcode credlev tuition_type  tuition_fees tuition_fees_3yr earn3yr earn3yr_0 earn3yr_20 earn3yr_40 earn3yr_60 earn3yr_40_60 earn3yr_40_120 dDTE_2019  pfemale pnonwhite pblack phisp pasian earn_mdn_hi_1yr earn_mdn_hi_2yr earn_ne_mdn_3yr  earn_mdn_4yr  earn_30 earn_cf_30 earn_count_pell_ne_3yr earn_count_ne_3yr loan_paid_4yr meandebt mediandebt inGE fail_2019 aDTE_* dDTE_*  avg_t4_enr_AY1617 tot_loan_vol2016 tot_loan_vol2022  PassBar rank GPALow GPAHigh LSATLow LSATHigh Accept EmplGrad  Empl10Mos life_roi roi_completion_weight roi_ed_specing inst_control hbcu tribal_college hsi fips year 


order unitid opeid6 inst_name cipcode credlev tuition_type  tuition_fees tuition_fees_3yr earn3yr earn3yr_0 earn3yr_20 earn3yr_40 earn3yr_60 earn3yr_40_60 earn3yr_40_120 dDTE_2019  pfemale pnonwhite pblack phisp pasian earn_mdn_hi_1yr earn_mdn_hi_2yr earn_ne_mdn_3yr  earn_mdn_4yr  earn_30 earn_cf_30 earn_count_pell_ne_3yr earn_count_ne_3yr loan_paid_4yr meandebt mediandebt inGE fail_2019 aDTE_* dDTE_*  avg_t4_enr_AY1617 tot_loan_vol2016 tot_loan_vol2022  PassBar rank GPALow GPAHigh LSATLow LSATHigh Accept EmplGrad  Empl10Mos life_roi roi_completion_weight roi_ed_specing inst_control hbcu tribal_college hsi fips year 

save "${cleaned}/combined_law_school_data.dta", replace
use  "${cleaned}/combined_law_school_data.dta", clear 

	
********************************************************************************
********************************************************************************
*STEP 4: ANALYZE AND OUTPUT RESULTS   
********************************************************************************
********************************************************************************	
	
******************************************************************************
*Table one export
******************************************************************************
putexcel set "${final}/Law_Tuition_Figures.xlsx", modify sheet(correlations, replace)

cpcorr PassBar Empl10Mos rank  loan_paid_4yr life_roi dDTE_2019\ earn3yr_0 earn3yr_40 earn3yr_40_60

putexcel B1 = "Tution/Earnings"
putexcel C1 = "Tuition/(Earnings-$40K)"
putexcel D1 = "(Tuition+$60K)/(Earnings-$40K)"
putexcel E1 = "$60k"

putexcel A2 = "Bar passage rate" 
putexcel A3 = "Employment rate at 10 months" 
putexcel A4 = "U.S. News & World Report ranking"
putexcel A5 = "Portion of graduates who repaid their loans after 4 years"
putexcel A6 = "FREOOP's estimated lifetime return on investment" 
putexcel A7 = "Discretionary debt-to-earnings ratio from gainful employment" 

putexcel B2 = matrix(r(C))

******************************************************************************
*Scatter plot export 
******************************************************************************
egen metric_cat = cut(earn3yr_40_60), at(0,2,5,10,50)
label define metric_cat 0 "Less than 2 years" 2 "2 to 5 years" 5 "5 to 10 years" 10 "10 years or more"
label values metric_cat  metric_cat

sort earn3yr_40_60 
order inst_name tuition_type earn3yr tuition_fees_3yr earn3yr_40_60 metric_cat 
format tuition_fees_3yr earn3yr %12.0fc 

label variable earn3yr "Median earnings three years after graduation" 
label variable tuition_fees_3yr "Program costs"
label variable tuition_type "In-state?"
label variable inst_name "Institution"
label variable earn3yr_40_60 "Number of years for the law program to pay off"

export excel inst_name tuition_type earn3yr tuition_fees_3yr earn3yr_40_60 metric_cat using "${final}/Law_Tuition_Figures.xlsx", sheet("scatter_chart") sheetreplace firstrow(varlabels)

******************************************************************************
*Bar chart export 
******************************************************************************

preserve 
	drop if earn3yr_40_60 == .
	collapse (mean) earn3yr tuition_fees_3yr, by(metric_cat)
	format earn3yr tuition %12.0fc 

	label values metric_cat metric_cat
	label variable earn3yr "Median earnings three years after graduation" 
	label variable tuition "Tuition and fees of program"
	label variable metric_cat "Number of years for the law program to pay off"

	export excel using "${final}/Law_Tuition_Figures.xlsx", sheet("bar_chart") sheetreplace firstrow(varlabels)
restore 
		
		
******************************************************************************
*Histogram export 
******************************************************************************
preserve 
	gen hist_cat = trunc(earn3yr_40_60)
	replace hist_cat = 15 if hist_cat > 15 & hist_cat != . 

	gen count = 1 
	set obs `=_N+16' 
	replace count = 0 if count == . 
	bys count: replace hist_cat = _n -1 if count == 0 & earn3yr_40_60 == . 
	drop if earn3yr_40_60 == . & hist_cat == . 

	collapse (sum) count, by(hist_cat)

	label define hist_cat 0 "Less than 1 year" 1 "1 to 2 years" 2 "2 to 3" 3 "3 to 4" 4 "4 to 5" 5 "5 to 6" 6 "6 to 7" 7 "7 to 8" 8 "8 to 9" 9 "9 to 10" 10 "10 to 11" 11 "11 to 12" 12 "12 to 13" 13 "13 to 14" 14 "14 to 15" 15 "15 or more years"
	label values hist_cat hist_cat 

	label var hist_cat "Number of years for the law program to pay off"
	label var count "Number of law programs"
	
	export excel using "${final}/Law_Tuition_Figures.xlsx", sheet("histogram") sheetreplace firstrow(varlabels)
restore 

******************************************************************************
*Demographics export 
******************************************************************************

preserve 
	drop if earn3yr_40_60 == .
	gen pct_pell = earn_count_pell_ne_3yr/earn_count_ne_3yr 
	collapse (mean) phisp pblack pct_pell pfemale pnonwhite pasian, by(metric_cat)
	replace pct_pell = pct_pell * 100 

	label values metric_cat metric_cat
	label variable metric_cat "Number of years for the law program to pay off"
	label variable pct_pell "Received Pell in undergrad"
	label variable pblack "Black or African American"
	label variable phisp "Hispanic"
	label variable pasian "Asian"
	label variable pnonwhite "Nonwhite"
	label variable pfemale "Female"

	export excel using "${final}/Law_Tuition_Figures.xlsx", sheet("demographic_chart") sheetreplace firstrow(varlabels)
restore 		
		
		
******************************************************************************
*Tables to create the other stats mentioned in the blog
*Not exported 
******************************************************************************
gen lowvalue = 0 if earn3yr_40_60 != .
replace lowvalue = 1 if earn3yr_40_60 != . & earn3yr_40_60 > 10 

bys lowvalue: sum Pass 
bys lowvalue: sum Empl10Mos 

tab lowvalue fail_2019 
bys lowvalue: sum life_roi 
tab inst_control lowvalue, col
bys lowvalue: sum pnonwhite 
bys lowvalue: sum pblack  
bys lowvalue: sum phis  
bys lowvalue: sum pfemale   

gen pct_pell = earn_count_pell_ne_3yr/earn_count_ne_3yr 
bys lowvalue: sum pct_pell  

table lowvalue if inst_control != 3, statistic(sum tot_loan_vol2022)

tab tuition_type 

recode earn3yr_40_60 (0/2 = 0) (2/5 = 2) (5/10 = 5) (10/30 = 10), gen(value_cat)