******************************************************************
*states with direct cert data for at least 90% of students in 2018
******************************************************************

cd ["YOUR_DIR"]

*--------------------------------------------------------------------
educationdata using "school ccd directory", sub(year=2019) 
save "school ccd 2019", replace 

use "school ccd 2019", clear

drop if fips>56
replace direct_certification=. if direct_certification<0
replace enrollment=. if enrollment<0
drop if enrollment==.
gen pct_dc = direct_certification/enrollment

*Identify what states have direct cert data for at least 90% of students
	preserve
		*enrollment for schools that report dc 
		gen dc_enroll = 0
		replace dc_enroll = enrollment if pct_dc!=.

		*collapse to state level, summing dc enrollment and enrollment
		collapse (sum) dc_enroll enrollment, by(fips)
		 *variable = share of studnets attending schools that report dc		
		gen pct_rep_dc = dc_enroll/enrollment
			
		*creates dummy = 1 if at least 90% of students in the state go to schools that report dc
		gen model_dc = 0
		replace model_dc = 1 if pct_rep_dc>=.9 & pct_rep_dc<.
		
		keep fips model_dc
		
		save "temp_state_model_indicators", replace
	restore
		
merge m:1 fips using "temp_state_model_indicators"		

keep if model_dc==1

collapse (sum) direct_certification enrollment, by(fips)
gen pct_dc = (direct_certification/enrollment)*100

sort pct_dc 
list fips pct_dc

keep fips pct_dc

export excel using "Output_Data/states dc 2019.xlsx", sheet("State's DC") sheetmodify firstrow(variables)

**********************************************************************
*ACS-ED https://nces.ed.gov/programs/edge/TableViewer/acsProfile/2019
*Look for states with direct cert data
*Alabama, Alaska, Arkansas, California, Delaware, District of Columbia, Florida, Georgia, 
*Hawaii, Indiana, Kentucky, Maine, Maryland, Massachusetts, Mississippi, Missouri, Nevada, North Dakota
*Oklahoma, Tennessee, Washington, West Virginia
*1, 2, 5, 6, 10, 11, 12, 13 ,15, 18, 21, 23, 24, 25, 28, 29, 32, 38, 40, 47, 53, 54
**********************************************************************

