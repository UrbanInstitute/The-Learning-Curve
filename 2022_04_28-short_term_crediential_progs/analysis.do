clear
capture log close

graph set window fontface "lato"

// Only change line 9 to be the directory you want work to be done in
global working_directory= "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_04_28-short_term_crediential_progs"

cd "${working_directory}"

// Macros
global data = "${working_directory}\data"
global raw = "${data}\raw"
global intermediate = "${data}\intermediate"
global final = "${data}\final"
global vis = "${final}\vis"

cap n unzipfile "${working_directory}\raw_data.zip"

cap n mkdir "${intermediate}"
cap n mkdir "${intermediate}"
cap n mkdir "${final}"
cap n mkdir "${vis}"


// Creating a panel of scorecard program level data
cd "${working_directory}"

import delimited "${raw}\FieldOfStudyData1415_1516_PP.csv"

*use FOIA_merged_reshaped_3_urban, clear

des

save "${intermediate}\score_1.dta", replace

* keeping only certificate programs
keep if credlev == 1

gen year = 1

save "${intermediate}\score_1_cert.dta", replace

clear

import delimited "${raw}\FieldOfStudyData1516_1617_PP.csv"

*use FOIA_merged_reshaped_3_urban, clear

des

save "${intermediate}\score_2.dta", replace

keep if credlev == 1

gen year = 2

save "${intermediate}\score_2_cert.dta", replace

clear


import delimited "${raw}\FieldOfStudyData1617_1718_PP.csv"

*use FOIA_merged_reshaped_3_urban, clear

des

save "${intermediate}\score_3.dta", replace

keep if credlev == 1

gen year = 3

save "${intermediate}\score_3_cert.dta", replace

clear

use "${intermediate}\score_1_cert.dta"
append using "${intermediate}\score_2_cert.dta"
append using "${intermediate}\score_3_cert.dta"

save "${intermediate}\score_cert_panel.dta", replace


* Cleaning scorecard data
rename opeid6 opeid

rename cipcode cip_4

tostring cip_4, replace

save "${intermediate}\score_cert_panel.dta", replace


* Keeping only variables needed for analysis
keep unitid opeid instnm control main cip_4 cipdesc credlev creddesc ipedscount1 ipedscount2 earn_count_nwne_hi_1yr earn_cntover150_hi_1yr earn_count_wne_hi_1yr earn_mdn_hi_1yr earn_count_nwne_hi_2yr earn_cntover150_hi_2yr earn_count_wne_hi_2yr earn_mdn_hi_2yr bbrr2_fed_comp_n bbrr2_fed_comp_dflt bbrr2_fed_comp_dlnq bbrr2_fed_comp_fbr bbrr2_fed_comp_dfr bbrr2_fed_comp_noprog bbrr2_fed_comp_makeprog bbrr2_fed_comp_paidinfull bbrr2_fed_comp_discharge year


* Replacing privacy suppressed data with missings
foreach x of varlist earn_cntover150_hi_1yr earn_count_wne_hi_1yr earn_mdn_hi_1yr earn_count_nwne_hi_2yr earn_count_wne_hi_2yr earn_cntover150_hi_2yr earn_mdn_hi_2yr bbrr2_fed_comp_n bbrr2_fed_comp_dflt bbrr2_fed_comp_dlnq bbrr2_fed_comp_fbr bbrr2_fed_comp_dfr bbrr2_fed_comp_noprog bbrr2_fed_comp_paidinfull bbrr2_fed_comp_mak earn_count_nwne_hi_1yr bbrr2_fed_comp_discharge {
	replace `x' = "." if `x' == "PrivacySuppressed"
		}

foreach x of varlist earn_cntover150_hi_1yr earn_count_wne_hi_1yr earn_mdn_hi_1yr earn_count_nwne_hi_2yr earn_count_wne_hi_2yr earn_cntover150_hi_2yr earn_mdn_hi_2yr bbrr2_fed_comp_n bbrr2_fed_comp_dflt bbrr2_fed_comp_dlnq bbrr2_fed_comp_fbr bbrr2_fed_comp_dfr bbrr2_fed_comp_noprog bbrr2_fed_comp_paidinfull bbrr2_fed_comp_mak earn_count_nwne_hi_1yr bbrr2_fed_comp_discharge {
	replace `x' = "." if `x' == "NULL"
		}
		
foreach x of varlist earn_cntover150_hi_1yr earn_count_wne_hi_1yr earn_mdn_hi_1yr earn_count_nwne_hi_2yr earn_count_wne_hi_2yr earn_cntover150_hi_2yr earn_mdn_hi_2yr bbrr2_fed_comp_n bbrr2_fed_comp_dflt bbrr2_fed_comp_dlnq bbrr2_fed_comp_fbr bbrr2_fed_comp_dfr bbrr2_fed_comp_noprog bbrr2_fed_comp_paidinfull bbrr2_fed_comp_mak earn_count_nwne_hi_1yr bbrr2_fed_comp_discharge {
	destring `x', replace
		}
		
gen year_2 = year*-1
sort year_2

* Creating one obs per program - only most recent has earnings data	
collapse (firstnm) unitid instnm control main cipdesc credlev creddesc ipedscount1 ipedscount2 year year_2 (mean) earn_count_nwne_hi_1yr earn_cntover150_hi_1yr earn_count_wne_hi_1yr earn_mdn_hi_1yr earn_count_nwne_hi_2yr earn_cntover150_hi_2yr earn_count_wne_hi_2yr earn_mdn_hi_2yr bbrr2_fed_comp_n bbrr2_fed_comp_dflt bbrr2_fed_comp_dlnq bbrr2_fed_comp_fbr bbrr2_fed_comp_dfr bbrr2_fed_comp_noprog bbrr2_fed_comp_makeprog bbrr2_fed_comp_paidinfull bbrr2_fed_comp_discharge, by (opeid cip_4)

save "${intermediate}\scorecard_cert_collapsed.dta", replace

* Cleaning FOIA data

use "${raw}\FOIA_rates1.dta"

* Keeping only relevant years for analysis
drop if enrollmentawardyear < 2000

drop if enrollmentawardyear == 2020


* Transforming variables to match loans tab
tostring zipcode, replace

tostring province, replace

tostring country, replace

tostring foreignzip, replace

* Renaming variables
rename ïopeid opeid


* Keeping only relevant variables
keep programapprovalindicator programsystemid programplacementpercentage completionratepercentage enrollmentawardyear


* Reshaping to get one obs per program
sort programsystemid
reshape wide programapprovalindicator completionratepercentage programplacementpercentage, i(programsystemid) j(enrollmentawardyear)

save "${intermediate}\new_FOIA_rates_reshape.dta", replace

clear

* Merging FOIA rates with loans tab
use "${raw}\FOIA_ShortTerm1.dta"

merge 1:1 programsystemid using "${intermediate}\new_FOIA_rates_reshape.dta"

* Cleaning data to match scorecard data
rename ïopeid opeid
gen cip_nodec = cipcode * 10000
replace cip_nodec = cip_nodec*10 if cip_nodec < 100000
tostring cip_nodec, gen(cip_str) format("%6.0f") force
gen cip_4 = substr(cip_str, 1, 4)

tostring zipcode, replace
count if zipcode=="."

drop if zipcode == "."
* Dropped 27 foreign programs

* Reformating initial approval date
gen appdate2 = date(initialapprovaldate, "MDY" ,2020)
format appdate2 %td

* Reformating disapproval date
gen disapprdate = date(disapprovaldate, "MDY" ,2020)
format disapprdate %td

* Getting approval year
gen appyear=year(appdate2)
summarize appyear

* Getting disapproval year
gen disappyear=year(disapprdate)
summarize disappyear


save "${intermediate}\FOIA_final.dta", replace

* Generating average placement and completion rates
egen avg_placement_rate = rmean(programplacementpercentage2000 programplacementpercentage2001 programplacementpercentage2002 programplacementpercentage2003 programplacementpercentage2004 programplacementpercentage2005 programplacementpercentage2006 programplacementpercentage2007 programplacementpercentage2008 programplacementpercentage2009 programplacementpercentage2010 programplacementpercentage2011 programplacementpercentage2012 programplacementpercentage2013 programplacementpercentage2014 programplacementpercentage2015 programplacementpercentage2016 programplacementpercentage2017 programplacementpercentage2018 programplacementpercentage2019)



egen avg_completion_rate = rmean(completionratepercentage2000 completionratepercentage2001 completionratepercentage2002 completionratepercentage2003 completionratepercentage2004 completionratepercentage2005 completionratepercentage2006 completionratepercentage2007 completionratepercentage2008 completionratepercentage2009 completionratepercentage2010 completionratepercentage2011 completionratepercentage2012 completionratepercentage2013 completionratepercentage2014 completionratepercentage2015 completionratepercentage2016 completionratepercentage2017 completionratepercentage2018 completionratepercentage2019)



* Generating most recent completion and placement rates
gen completion_recent = .
replace completion_recent = completionratepercentage2019



replace completion_recent = completionratepercentage2018 if completion_recent==.
replace completion_recent = completionratepercentage2017 if completion_recent==.
replace completion_recent = completionratepercentage2016 if completion_recent==.
replace completion_recent = completionratepercentage2015 if completion_recent==.
replace completion_recent = completionratepercentage2014 if completion_recent==.
replace completion_recent = completionratepercentage2013 if completion_recent==.
replace completion_recent = completionratepercentage2012 if completion_recent==.
replace completion_recent = completionratepercentage2011 if completion_recent==.
replace completion_recent = completionratepercentage2010 if completion_recent==.
replace completion_recent = completionratepercentage2009 if completion_recent==.
replace completion_recent = completionratepercentage2008 if completion_recent==.
replace completion_recent = completionratepercentage2007 if completion_recent==.
replace completion_recent = completionratepercentage2006 if completion_recent==.
replace completion_recent = completionratepercentage2005 if completion_recent==.
replace completion_recent = completionratepercentage2004 if completion_recent==.
replace completion_recent = completionratepercentage2003 if completion_recent==.
replace completion_recent = completionratepercentage2002 if completion_recent==.
replace completion_recent = completionratepercentage2001 if completion_recent==.
replace completion_recent = completionratepercentage2000 if completion_recent==.




gen placement_recent = .
replace placement_recent = programplacementpercentage2019



replace placement_recent = programplacementpercentage2018 if placement_recent==.
replace placement_recent = programplacementpercentage2017 if placement_recent==.
replace placement_recent = programplacementpercentage2016 if placement_recent==.
replace placement_recent = programplacementpercentage2015 if placement_recent==.
replace placement_recent = programplacementpercentage2014 if placement_recent==.
replace placement_recent = programplacementpercentage2013 if placement_recent==.
replace placement_recent = programplacementpercentage2012 if placement_recent==.
replace placement_recent = programplacementpercentage2011 if placement_recent==.
replace placement_recent = programplacementpercentage2010 if placement_recent==.
replace placement_recent = programplacementpercentage2009 if placement_recent==.
replace placement_recent = programplacementpercentage2008 if placement_recent==.
replace placement_recent = programplacementpercentage2007 if placement_recent==.
replace placement_recent = programplacementpercentage2006 if placement_recent==.
replace placement_recent = programplacementpercentage2005 if placement_recent==.
replace placement_recent = programplacementpercentage2004 if placement_recent==.
replace placement_recent = programplacementpercentage2003 if placement_recent==.
replace placement_recent = programplacementpercentage2002 if placement_recent==.
replace placement_recent = programplacementpercentage2001 if placement_recent==.
replace placement_recent = programplacementpercentage2000 if placement_recent==.



*twoway (scatter completion_recent placement_recent, xline(70) yline(70) xtitle(Job Placement Rate) ytitle(Completion Percentage))
drop _merge

* Matching opeids with scorecard data
replace opeid = opeid/100

save "${intermediate}\FOIA_final1.dta", replace
*********************************************

* Merging FOIA and scorecard data

clear
use "${intermediate}\scorecard_cert_collapsed.dta"

merge 1:m opeid cip_4 using "${intermediate}\FOIA_final1.dta"

keep if _merge ==3 & year == 3

collapse (mean) completion_recent placement_recent earn_mdn_hi_2yr bbrr2_fed_comp_noprog, by (cip_4 unitid opeid credlev disapprovalreason)

save "${final}\FOIA_score_merged_final.dta", replace

* Getting counts and summary stats
tab disapprovalreason
sum completion_recent, detail
sum placement_recent, detail


* Creating final scatter plot of rates
twoway scatter completion_recent placement_recent, xline(70) yline(70) mcolor("22 150 210%40") xtitle("Job placement rate") ytitle("Completion rate") graphregion(color(white)) bgcolor(white) ylabel(0 "0%" 20 "20%"  40 "40%" 60 "60%" 80 "80%" 100 "100%", angle(0)) xlabel(0 "0%" 20 "20%"  40 "40%" 60 "60%" 80 "80%" 100 "100%", angle(0))

graph export "${vis}\graph_1_placement_completion.png", as(png) height(1000) replace

replace disapprovalreason = "Fail" if disapprovalreason == "Program Does Not Meet 70/70 Requirements"
replace disapprovalreason = "Pass" if disapprovalreason == ""
encode disapprovalreason, gen(disapprovalreason2)

keep if disapprovalreason=="Pass" | disapprovalreason=="Fail"

* Generating figure 2: Average median income
preserve
collapse (mean) earn_mdn_hi_2yr, by (unitid opeid cip_4 disapprovalreason2)
graph bar (mean) earn_mdn_hi_2yr, over(disapprovalreason2) bar(1, color("22 150 210")) bar(2, color("22 150 210")) blabel(bar, color("0 0 0")) graphregion(color(white)) ylabel(,angle(0)) bgcolor(white) ytitle("")
graph export "${vis}\graph_2_median_earnings.png", as(png) height(1000) replace
restore

* Generating figure 3: Percentage making no progress on loans (excluded but counts mentioned in text)
preserve
replace bbrr2_fed_comp_noprog = bbrr2_fed_comp_noprog*100
collapse (mean) bbrr2_fed_comp_noprog, by (unitid opeid cip_4 disapprovalreason2)
graph bar (mean) bbrr2_fed_comp_noprog, over(disapprovalreason2) bar(1, color("22 150 210")) bar(2, color("22 150 210")) blabel(bar, color("0 0 0") format(%2.1f)) ylabel(,angle(0)) graphregion(color(white)) bgcolor(white) ytitle("")
local nb=`.Graph.plotregion1.barlabels.arrnels'
forval i=1/`nb' {
  di "`.Graph.plotregion1.barlabels[`i'].text[1]'"
  .Graph.plotregion1.barlabels[`i'].text[1]="`.Graph.plotregion1.barlabels[`i'].text[1]'%"
}
.Graph.drawgraph
graph export "${vis}\graph_3_.png", as(png) height(1000) replace
restore

* Looking into which programs pass/fail
count if cip_4 == "1204" & disapprovalreason == "" & earn_mdn_hi_2yr !=.
count if cip_4 == "1204" & disapprovalreason == "Program Does Not Meet 70/70 Requirements" & earn_mdn_hi_2yr !=.
tab cip_4 if disapprovalreason == "Program Does Not Meet 70/70 Requirements"
tab cip_4 if disapprovalreason == ""

***************************

* Robustness check using percentages instead of diapproval reason

* Creating a new fail 7070 based just on rates, not on actual disapproval reason
gen fail_7070 = .
replace fail_7070 = 0 if completion_recent >=70 & placement_recent >= 70
replace fail_7070 = 1 if completion_recent <70 | placement_recent < 70

sum earn_mdn_hi_2yr if fail_7070 == 1
sum earn_mdn_hi_2yr if fail_7070 == 0

sum bbrr2_fed_comp_noprog if fail_7070 == 1
sum bbrr2_fed_comp_noprog if fail_7070 == 0

tab disapprovalreason if fail_7070 == 1 & disapprovalreason!="Program Does Not Meet 70/70 Requirements"

* Exporting final data to excel
export excel using "${final}\urban_dta_final.xlsx", replace