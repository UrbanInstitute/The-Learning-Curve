

//NAEP 4th grade reading (2009-2022)
//canal and america samoa guam puerto rico
clear all
set more off 
import excel "Reading4", firstrow
drop if substr(Jurisdiction, 1,5)=="Natio"
drop if substr(Jurisdiction, 1,5)=="Puert"
rename Year year
rename belowBasic NreadbelowBasic
rename atBasic NreadatBasic
rename atProficient NreadatProficient
rename atAdvanced NreadatAdvanced
rename Averagescalescore Nscaleread
drop Allstudents
rename Jurisdiction fips
replace year = year-1
save "${pathclean}/NAEPreading4.dta", replace

//Missing 2021, 2018, 2016, 2014, 2012


//NAEP 4th grade math
clear all
set more off 
import excel "Math4", firstrow
drop if substr(Jurisdiction, 1,5)=="Natio"
drop if substr(Jurisdiction, 1,5)=="Puert"
destring atProficient, ignore("#") replace
destring atAdvanced, ignore("#") replace
destring belowBasic, replace
destring atBasic, replace
destring Averagescalescore, replace
rename Year year
rename belowBasic NmathbelowBasic
rename atBasic NmathatBasic
rename atProficient NmathatProficient
rename atAdvanced NmathatAdvanced
rename Averagescalescore Nscalemath
drop Allstudents
rename Jurisdiction fips
replace year = year-1
save "${pathclean}/NAEPmath4.dta", replace

clear all
set more off 


//NAEP 8th grade reading
import excel "Reading8", firstrow
drop if substr(Jurisdiction, 1,5)=="Natio"
drop if substr(Jurisdiction, 1,5)=="Puert"
destring atProficient, ignore("#") replace
destring atAdvanced, ignore("#") replace
rename Year year
rename belowBasic NreadbelowBasic
rename atBasic NreadatBasic
rename atProficient NreadatProficient
rename atAdvanced NreadatAdvanced
rename Averagescalescore Nscaleread
drop Allstudents
rename Jurisdiction fips
replace year = year-1
save "${pathclean}/NAEPreading8.dta", replace

clear all
set more off 

 
//NAEP 8th grade math
import excel "Math8", firstrow
drop if substr(Jurisdiction, 1,5)=="Natio"
drop if substr(Jurisdiction, 1,5)=="Puert"
destring atProficient, ignore("#") replace
destring atAdvanced, ignore("#") replace
rename Year year
rename belowBasic NmathbelowBasic
rename atBasic NmathatBasic
rename atProficient NmathatProficient
rename atAdvanced NmathatAdvanced
rename Averagescalescore Nscalemath
drop Allstudents
rename Jurisdiction fips
replace year = year-1
save "${pathclean}/NAEPmath8.dta", replace

//in-between years

clear all
set more off 

//State 4th grade reading (2009-2019)
//DONOTRUN//educationdata using "district edfacts assessments", sub(grade_edfacts=4)
//save "${pathData}Staterawfile.dta", replace
//read_test_num_valid
use "${pathraw}\Staterawfile.dta"

drop if fips==59
drop if fips==72
drop if fips==78

collapse (mean) read_test_pct_prof_midpt (rawsum) read_test_num_valid [fw= read_test_num_valid], by(fips year grade_edfacts)
rename read_test_pct_prof_midpt readmidpt
rename read_test_num_valid readnum
decode fips, gen(fipsnew)
drop fips
rename fipsnew fips
save "${pathclean}/StateReading4.dta", replace

//math

clear all
set more off
use "${pathraw}/Staterawfile.dta"

drop if fips==59
drop if fips==72
drop if fips==78
collapse (mean) math_test_pct_prof_midpt (rawsum) math_test_num_valid [fw= math_test_num_valid], by(fips year grade_edfacts)
rename math_test_pct_prof_midpt mathmidpt
rename math_test_num_valid mathnum
decode fips, gen(fipsnew)
drop fips
rename fipsnew fips
save "${pathclean}/StateMath4.dta", replace

clear all
set more off 

//State 8th grade math (2009-2019)
//DONOTRUN//educationdata using "district edfacts assessments", sub(grade_edfacts=8)
//save "${pathData}Staterawfile8.dta", replace

//reading
use "${pathraw}\Staterawfile8.dta"
drop if fips==59
drop if fips==72
drop if fips==78
collapse (mean) read_test_pct_prof_midpt (rawsum) read_test_num_valid [fw= read_test_num_valid], by(fips year grade_edfacts)
rename read_test_pct_prof_midpt readmidpt
rename read_test_num_valid readnum
decode fips, gen(fipsnew)
drop fips
rename fipsnew fips
save "${pathclean}/StateReading8.dta", replace


//math
use "${pathraw}/Staterawfile8.dta"
drop if fips==59
drop if fips==72
drop if fips==78
//set Virgina as missing 2016 (statemath8)

drop if year==2016 & fips==51
collapse (mean) math_test_pct_prof_midpt (rawsum) math_test_num_valid [fw= math_test_num_valid], by(fips year grade_edfacts)
rename math_test_pct_prof_midpt mathmidpt
rename math_test_num_valid mathnum
decode fips, gen(fipsnew)
drop fips
rename fipsnew fips


//collapse (mean) math_test_pct_prof_midpt (mean) math_test_num_valid, by(year fips grade_edfacts)
save "${pathclean}/StateMath8.dta", replace

 
clear all
set more off 

//MERGE 8th graders
use "${pathclean}/StateMath8.dta"
merge m:m year fips using "${pathclean}/StateReading8.dta"
drop _merge
save "${pathclean}/test1.dta", replace

use "${pathclean}/NAEPmath8.dta"
merge m:m year fips using  "${pathclean}/NAEPreading8.dta"
drop _merge I J K L M N O P Q R S T U V W X Y Z
save "${pathclean}/test2.dta", replace

merge m:m year fips using "${pathclean}/test1.dta"

drop _merge
order year fips mathmidpt NmathbelowBasic NmathatBasic NmathatProficient NmathatAdvanced readmidpt NreadbelowBasic NreadatBasic NreadatProficient NreadatAdvanced mathnum readnum
replace grade_edfacts=8
save "${pathclean}/8thgradescores.dta", replace

clear all 
set more off

//MERGE 4th
use "${pathclean}/StateMath4.dta"
merge m:m year fips using "${pathclean}/StateReading4.dta"
drop _merge
save "${pathclean}/test3.dta", replace

use "${pathclean}/NAEPmath4.dta"
merge 1:1 year fips using  "${pathclean}/NAEPreading4.dta"
drop _merge I J K L M N O P Q R S T U V W X Y Z
save "${pathclean}/test4.dta", replace

merge m:m year fips using "${pathclean}/test3.dta"
drop _merge
order year fips mathmidpt NmathbelowBasic NmathatBasic NmathatProficient NmathatAdvanced readmidpt NreadbelowBasic NreadatBasic NreadatProficient NreadatAdvanced mathnum readnum
replace grade_edfacts=4
save "${pathclean}/4thgradescores.dta", replace


clear all
set more off

append using "${pathclean}/8thgradescores.dta" "${pathclean}/4thgradescores.dta"

save "${pathclean}/4and8allscores.dta", replace


