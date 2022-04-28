clear
capture log close

graph set window fontface "lato"

// Only change line 9 to be the directory you want work to be done in
global working_directory= "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_04_28-Covid_NC"

cd "${working_directory}"

// Macros
global data = "${working_directory}\data"

global data = "${working_directory}\data"
global raw = "${working_directory}\raw_data"
global intermediate = "${data}\intermediate"
global temp = "${intermediate}\temp"
global final = "${data}\final"
global vis = "${final}\vis"


cap n mkdir "${data}"
cap n mkdir "${intermediate}"
cap n mkdir "${temp}"
cap n mkdir "${final}"
cap n mkdir "${vis}"

unzipfile "${working_directory}\raw_data.zip", replace

*cd "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\"

*****this records the order for running do files to rebuilt the NC school-level panel

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                          NC DPI and Common Core of Data                                                  //
//                                                                                                                          //
// ****this code preps the DPI data for analysis"                                                                           //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//// Import raw dataset
use "${raw}\18_19_20_21_all_ccd.dta" , clear

drop if year == 2020


*Create tmp district ID (1-119)
egen district_id = group (districtname)

*Create flag for schools that move district
sort schoolcode year
bysort schoolcode: egen ncessch_f=max(ncessch)
bysort schoolcode: gen move_district=(district_id!= district_id[_n-1])
replace move_district=0 if move_district!=1
replace move_district=. if year==18
bysort schoolcode: egen ever_move_district=max(move_district)


*Create grade level proficiency for Math and Reading for student subgroups (all - all students, black - black students, white - white students, ed - economically disadvantaged, ned - not economically disadvantaged, fem - female students, male - students, dis - students with a disability, ndis - students without a disability)
foreach x in all black white ed ned fem male dis ndis {

*Convert from string to real
destring m_pct_glp`x', gen (math_glp`x') ignore(> < ) 
destring r_pct_glp`x', gen (read_glp`x') ignore(> < ) 

*Convert percent of studetns tested to real

destring m_pct_tested`x', gen (math_tested`x') ignore (> <) force
destring r_pct_tested`x', gen (read_tested`x') ignore (> <) force
}


*Constrain dataset to schools that are in data in 2018, 2019, and 2021
drop if year==2020
gen yr=21 if year==21
replace yr=18 if year==2018
replace yr=19 if year==2019
keep schoolcode districtname yr math_glp* read_glp* math_tested* read_tested* sch* ncessch_f leaid
drop if missing(schoolcode)
sort schoolcode yr
by schoolcode: egen obs=count(schoolcode)
keep if obs==3

rename schoolcode str_school

*Make data wide by school code and year
reshape wide districtname math_glp* read_glp* math_tested* read_tested* leaid sch*, i(str_school) j(yr)

*Save School Level Wide Dataset
save "${intermediate}\school_level_wide_analysis.dta", replace


////Start District Wide Database

*Missing school enrollment data for 2021, norming on school enrollment in SY 2019
gen schenroll=schenroll19

*Create district level aggregation of student enrollment
bysort districtname21: egen dist_schenroll=total(schenroll)

*Create GLP for Math and Reading aggregation for student subgroups at district level (all - all students, black - black students, white - white students, ed - economically disadvantaged, ned - not economically disadvantaged, fem - female students, male - students, dis - students with a disability, ndis - students without a disability) for SY 2018, 2019, and 2021
foreach x in  math_glpall read_glpall math_testedall read_testedall schblack schhisp schasian schotherrace schwhite sched {
foreach yr in 18 19 21 {

gen temp_`x'`yr'=`x'`yr'*schenroll
bysort districtname21: egen dtemp_`x'`yr'=total(temp_`x'`yr')
gen dist_`x'`yr'=dtemp_`x'`yr'/dist_schenroll

}
}

bysort districtname21: keep if _n==1
sum dist*

*Save District Level Wide Dataset
save "${intermediate}\district_level_wide_analysis.dta", replace



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                COVID Cases and Deaths                                                    //
//                                                                                                                          //
//do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\covid cases & death.do"                                  //
//***COVID case and fatality data.                                                                                          //
//****the data that we have here is far more detailed than we can use --- we have daily case/fatality counts through        //
//   the pandemic.                                                                                                          //
//****could just report total as of test date                                                                               //
//****but maybe useful to distinguish between spring 2020, summer 2020, fall 2020, and spring 2021                          //
//                                                                                                                          //
//**spring 2020 - 1/1/20 - 5/31/20                                                                                          //
//**summer 2020 - 6/1/20 - 8/31/20                                                                                          //
//**fall 2020 --  9/1/20 - 12/31/20                                                                                         //
//**spring 2021 - 1/1/21 - 5/31/21                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

*Import NC COVID Case and Fatality data
import excel "${raw}\NC county COVID data.xlsx", firstrow clear

*Generate flags for period
gen p1=1 if Date==td(31/5/2020)
tab p1
gen p2=1 if Date==td(31/8/2020)
tab p2
gen p3=1 if Date==td(31/12/2020)
tab p3
gen p4=1 if Date==td(31/5/2021)
tab p4 

*Drop observations not within Spring 2020 to Spring 2021
keep if p1==1 | p2==1 | p3==1 | p4==1

*Create categorical variable flag for period
gen period=1 if p1==1
replace period=2 if p2==1
replace period=3 if p3==1
replace period=4 if p4==1
label define period 1 "spring 2020" 2 "summer 2020" 3 "fall 2020" 4 "spring 2021"
label values period period
sum p*

*Create cases variable for each period
sort LEAID period
gen cases=ConfirmedC if period==1
replace cases=ConfirmedC-ConfirmedC[_n-1] if period!=1
sum cases

*Create fatality variable for each period
sort LEAID period
gen deaths=ConfirmedD if period==1
replace deaths=ConfirmedD-ConfirmedD[_n-1] if period!=1
sum deaths

*Constrain dataset to variables for county, LEAID, GEOID, period, cases, deaths -- drop all observations with missing district IDs
keep County LEAID GEOID period cases deaths 
drop if LEAID==.

*Reshape the data to be wide by district ID and school year period
reshape wide cases deaths, i(LEAID) j(period)

*Save final COVID dataset
save "${intermediate}\covid_data.dta", replace





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                       Pandemic Mode of Instruction                                                                       //
//                                                                                                                          //
// do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\pandemic mode of instruction.do"                        //
//                                                                                                                          //
//****this code grabs the instructional days variables from Cole's file                                                     //
//****spring 2021 was not complete when I ran this on 12/31/21, but can be easily updated                                   //
//***as a pre-step, I pulled the 1st sheet of Cole's excel into its own spreadsheet, which I titled "district summary"      //
//***updated 1/10/22 to reflect Cole's new data                                                                             //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


*Import Pandemic Mode of Instruction File
use "${raw}\District Summary Final.dta" , clear

*Rename Day Count of Instructional Mode in Fall 2020
rename fallfullyinperson f20_inperson_only
rename fallfullyremote f20_remote_only
rename fallhybridinstructionaldaysnoch f20_hybrid_only
rename fallfullyinpersonwchoiceoptio f20_inperson_choice
rename fallhybridwchoicehybridvsremote f20_hybrid_choice

*Create total days in Fall 2020 variable
egen f20_tot_day=rowtotal(f20_inperson_only f20_remote_only f20_hybrid_only f20_inperson_choice f20_hybrid_choice)

*Rename Day Count of Instructional Mode in Spring 2021
rename springfullyinperson s21_inperson_only
rename springfullyremote s21_remote_only
rename springhybridinstructionaldaysnoc s21_hybrid_only
rename springfullyinpersonwchoiceoptio s21_inperson_choice
rename springhybridwchoicehybridvsremot s21_hybrid_choice

*Create total days in Spring 2021 variable
egen s21_tot_day=rowtotal(s21_inperson_only s21_remote_only s21_hybrid_only s21_inperson_choice s21_hybrid_choice)
sum s21_tot_day

*Create percent of time in instructional mode for Fall 2020 and Spring 2020
foreach x in inperson_only remote_only hybrid_only inperson_choice hybrid_choice {
	foreach sem in f20 s21{
		
		replace `sem'_`x'=0 if `sem'_`x'==.
}	
gen pf20_`x'=f20_`x'/f20_tot_day
gen ps21_`x'=s21_`x'/s21_tot_day
}
sum f20* pf20* s21* ps21*

*Constrain dataset to new total and percent days variables 
keep leaid f20* pf20* s21* ps21*

*Save final 
save "${intermediate}\NC_dist_pandemic_instructional_mode.dta", replace


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                       Unemployment Data                                                                                  //
//                                                                                                                          //
// do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\unemp.do".                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

*Import USDA Unemployment Data -- each referenced final is a NC county
foreach x in LAUCN370010000000003 LAUCN370030000000003 LAUCN370050000000003 LAUCN370070000000003 ///
LAUCN370090000000003 LAUCN370110000000003 LAUCN370130000000003 LAUCN370150000000003 LAUCN370170000000003 ///
LAUCN370190000000003 LAUCN370210000000003 LAUCN370230000000003 LAUCN370250000000003 LAUCN370270000000003 ///
LAUCN370290000000003 LAUCN370310000000003 LAUCN370330000000003 LAUCN370350000000003 LAUCN370370000000003 ///
LAUCN370390000000003 LAUCN370410000000003 LAUCN370430000000003 LAUCN370450000000003 LAUCN370470000000003 ///
LAUCN370490000000003 LAUCN370510000000003 LAUCN370530000000003 LAUCN370550000000003 LAUCN370570000000003 ///
LAUCN370590000000003 LAUCN370610000000003 LAUCN370630000000003 LAUCN370650000000003 LAUCN370670000000003 ///
LAUCN370690000000003 LAUCN370710000000003 LAUCN370730000000003 LAUCN370750000000003 LAUCN370770000000003 ///
LAUCN370790000000003 LAUCN370810000000003 LAUCN370830000000003 LAUCN370850000000003 LAUCN370870000000003 ///
LAUCN370890000000003 LAUCN370910000000003 LAUCN370930000000003 LAUCN370950000000003 LAUCN370970000000003 ///
LAUCN370990000000003 LAUCN371010000000003 LAUCN371030000000003 LAUCN371050000000003 LAUCN371070000000003 ///
LAUCN371090000000003 LAUCN371110000000003 LAUCN371130000000003 LAUCN371150000000003 LAUCN371170000000003 ///
LAUCN371190000000003 LAUCN371210000000003 LAUCN371230000000003 LAUCN371250000000003 LAUCN371270000000003 ///
LAUCN371290000000003 LAUCN371310000000003 LAUCN371330000000003 LAUCN371350000000003 LAUCN371370000000003 ///
LAUCN371390000000003 LAUCN371410000000003 LAUCN371430000000003 LAUCN371450000000003 LAUCN371470000000003 ///
LAUCN371490000000003 LAUCN371510000000003 LAUCN371530000000003 LAUCN371550000000003 LAUCN371570000000003 ///
LAUCN371590000000003 LAUCN371610000000003 LAUCN371630000000003 LAUCN371650000000003 LAUCN371670000000003 ///
LAUCN371690000000003 LAUCN371710000000003 LAUCN371730000000003 LAUCN371750000000003 LAUCN371770000000003 ///
LAUCN371790000000003 LAUCN371810000000003 LAUCN371830000000003 LAUCN371850000000003 LAUCN371870000000003 ///
LAUCN371890000000003 LAUCN371910000000003 LAUCN371930000000003 LAUCN371950000000003 LAUCN371970000000003 ///
LAUCN371990000000003 { 

import excel "${raw}\USDA.xlsx", sheet("`x'") cellrange(A12:E46) firstrow clear

*Updated County Name 
replace County=County[_n==1] if missing(County)

*Rename ObvservationValue to unemp - value of the unemployment rate
rename ObservationValue unemp

*Create month variable
egen month=group(Period) 

*Drop Period variable
drop Period

*Convert Year to real
destring Year, replace

***************Create Period Variable
**P1 = spring 2020 - 1/1/20 - 5/31/20
**P2 = summer 2020 - 6/1/20 - 8/31/20
**P3 = fall 2021 --  9/1/20 - 12/31/20
**P4 = spring 2021 - 1/1/21 - 4/31/21
gen period=0 if Year==2019
replace period=1 if month>=1 & month<6 & Year==2020
replace period=2 if month>=6 & month<9 & Year==2020
replace period=3 if month>=9 & month<=12 & Year==2020
replace period=4 if month>=1 & month<5 & Year==2021

*Drop observations missing a period
drop if period==.

*Create aggregated unemploymnet mean during period
sort Year month
bysort period: egen p_unemp=mean(unemp)

*Remove duplicated variables
bysort period: keep if _n==1

*Constrain data to County, period, and p_unemp
keep County period p_unemp

*Reshape to wide data set by County and period
reshape wide p_unemp, i(County) j(period)

*Update County name and percent unemployment for 2019 if missing
replace County=County[_n+1] if missing(County)
replace p_unemp0=p_unemp0[_n+1] if p_unemp0==.

*Remove any duplicated/unnecessary variables
keep if _n==1

*Save in temporary subdirectory
save "${temp}\temp`x'.dta", replace
}


*Import temporary datasets from subdirectory
use "${temp}\tempLAUCN370010000000003.dta", clear 

foreach x in LAUCN370030000000003 LAUCN370050000000003 LAUCN370070000000003 ///
LAUCN370090000000003 LAUCN370110000000003 LAUCN370130000000003 LAUCN370150000000003 LAUCN370170000000003 ///
LAUCN370190000000003 LAUCN370210000000003 LAUCN370230000000003 LAUCN370250000000003 LAUCN370270000000003 ///
LAUCN370290000000003 LAUCN370310000000003 LAUCN370330000000003 LAUCN370350000000003 LAUCN370370000000003 ///
LAUCN370390000000003 LAUCN370410000000003 LAUCN370430000000003 LAUCN370450000000003 LAUCN370470000000003 ///
LAUCN370490000000003 LAUCN370510000000003 LAUCN370530000000003 LAUCN370550000000003 LAUCN370570000000003 ///
LAUCN370590000000003 LAUCN370610000000003 LAUCN370630000000003 LAUCN370650000000003 LAUCN370670000000003 ///
LAUCN370690000000003 LAUCN370710000000003 LAUCN370730000000003 LAUCN370750000000003 LAUCN370770000000003 ///
LAUCN370790000000003 LAUCN370810000000003 LAUCN370830000000003 LAUCN370850000000003 LAUCN370870000000003 ///
LAUCN370890000000003 LAUCN370910000000003 LAUCN370930000000003 LAUCN370950000000003 LAUCN370970000000003 ///
LAUCN370990000000003 LAUCN371010000000003 LAUCN371030000000003 LAUCN371050000000003 LAUCN371070000000003 ///
LAUCN371090000000003 LAUCN371110000000003 LAUCN371130000000003 LAUCN371150000000003 LAUCN371170000000003 ///
LAUCN371190000000003 LAUCN371210000000003 LAUCN371230000000003 LAUCN371250000000003 LAUCN371270000000003 ///
LAUCN371290000000003 LAUCN371310000000003 LAUCN371330000000003 LAUCN371350000000003 LAUCN371370000000003 ///
LAUCN371390000000003 LAUCN371410000000003 LAUCN371430000000003 LAUCN371450000000003 LAUCN371470000000003 ///
LAUCN371490000000003 LAUCN371510000000003 LAUCN371530000000003 LAUCN371550000000003 LAUCN371570000000003 ///
LAUCN371590000000003 LAUCN371610000000003 LAUCN371630000000003 LAUCN371650000000003 LAUCN371670000000003 ///
LAUCN371690000000003 LAUCN371710000000003 LAUCN371730000000003 LAUCN371750000000003 LAUCN371770000000003 ///
LAUCN371790000000003 LAUCN371810000000003 LAUCN371830000000003 LAUCN371850000000003 LAUCN371870000000003 ///
LAUCN371890000000003 LAUCN371910000000003 LAUCN371930000000003 LAUCN371950000000003 LAUCN371970000000003 ///
LAUCN371990000000003 {

*Append to into aggregated dataset
append using "${temp}\temp`x'.dta"
}

*Save final unemploymnet dataset
save "${intermediate}\unemp.dta", replace



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                      School Finance Data                                                                                 //
//                                                                                                                          //
// do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\schoolfinance.do"                                       //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

*Import NC Statistical Profile school finance data (per pupil expenditure) for 2021
import delimited "${raw}\District Summary Final.csv", clear

keep leaid stateppe2021 federalppe2021 localppe2021 totalppe2021

sort leaid

*Save final school finance dataset
save "${intermediate}\schoolfinance.dta", replace


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                       ID Crosswalk                                                                                       //
//                                                                                                                          //
// do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\ID Crosswalk.do"                                        //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////// LEA/County ID Cross Walk Import 
import delimited "${raw}\District ID Crosswalk.csv", clear
gen county_name = countytrimmed
tempfile id_walk
save `id_walk'

///Merge using county name: county pop.dta
use "${raw}\county pop.dta", clear
gen county_name_long = subinstr(CTYNAME," County", "",.)
gen county_name = trim(county_name_long)
drop county_name_long
mmerge county_name using `id_walk', unmatched(master)
drop countid leaname countytrimmed county
*Save ID merged county population dataset
save "${intermediate}\county popIDMatch.dta", replace

///Merge using LEA ID: covid_data.dta
use "${intermediate}\covid_data.dta", clear
gen leaid = LEAID
mmerge leaid using `id_walk', unmatched(master)
drop countid leaname countytrimmed county 
*Save ID merged COVID dataset
save "${intermediate}\covid_dataIDMatch.dta", replace

///Merge using LEA ID: district_level_wide_analysis.dta
use "${intermediate}\district_level_wide_analysis.dta", clear
gen leaid = real(leaid18)
mmerge leaid using `id_walk', unmatched(master)
drop countid leaname countytrimmed county 
*Save ID merged district level wide dataset
save "${intermediate}\district_level_wide_analysisIDMatch.dta", replace


///Merge using LEA ID: NC_dist_pandemic_instructional_mode.dta
use "${intermediate}\NC_dist_pandemic_instructional_mode.dta", clear
mmerge leaid using `id_walk', unmatched(master)
drop countid leaname countytrimmed county 
*Save ID merged district instructional mode dataset
save "${intermediate}\NC_dist_pandemic_instructional_modeIDMatch.dta", replace


///Merge using LEA ID: school_level_wide_analysis.dta
use "${intermediate}\school_level_wide_analysis.dta", clear
gen leaid = real(leaid18)
mmerge leaid using `id_walk', unmatched(master)
drop countid leaname countytrimmed county 
*Save ID merged county school level wide dataset
save "${intermediate}\school_level_wide_analysisIDMatch.dta", replace


///Merge using county name: unemp.dta
use "${intermediate}\unemp.dta", clear
gen county_name_long = subinstr(County," County, NC", "",.)
gen county_name = trim(county_name_long)
drop county_name_long
mmerge county_name using `id_walk', unmatched(master)
drop countid leaname countytrimmed county _merge
*Save ID merged county unemployment dataset
save "${intermediate}\unempIDMatch.dta", replace



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                       NC Covid Data                                                                                      //
//                                                                                                                          //
// do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\merge_NC_covid.do"                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


use "${intermediate}\county popIDMatch.dta" , clear

*Summarize and sort population, growth rate, and population density by LEA ID
keep leaid pop2021 GrowthRate popDensity
sort leaid 
sum leaid

save "${intermediate}\county popIDMatch_2.dta", replace 

*instructional mode.

use "${intermediate}\NC_dist_pandemic_instructional_mode.dta", clear

*Summarize and sort by LEA ID
sort leaid
sum leaid

save "${intermediate}\NC_dist_pandemic_instructional_modeIDMatch_2.dta", replace

*unemployment

use "${intermediate}\unempIDMatch.dta", clear

*Summarize and sort county name and period unemployment by LEA ID
keep leaid county_name p_unemp*
sort leaid
sum leaid

save "${intermediate}\unempIDMatch_2.dta", replace


*COVID case and death data

use "${intermediate}\covid_dataIDMatch.dta", clear

*Summarize and sort county name, COVID case load, and COVID death rate by LEA ID
keep leaid county_name cases* deaths*
sort leaid
sum leaid

save "${intermediate}\covid_dataIDMatch_2.dta", replace


*merge in county level population data to create per 100k norming variable for cases and deaths
merge 1:1 leaid using "${intermediate}\county popIDMatch_2.dta"
tab _merge
drop if _merge==2
drop _merge


sort leaid 

*For each period, create COVID cases and death rates per 100k for each LEA
foreach x in 1 2 3 4 {
gen p`x'_cases_p100k=(cases`x'/pop2021)*100000
gen p`x'_deaths_p100k=(deaths`x'/pop2021)*100000

label variable p`x'_cases_p100k "confirmed new cases in county per 100,000 people during period `x'"
label variable p`x'_deaths_p100k "confirmed new deaths in county per 100,000 people during period `x'"
sum p`x'*
sum p`x'* [w=pop2021]
}

*Merge Instructional Modality Data by LEA ID
merge m:m leaid using "${intermediate}\NC_dist_pandemic_instructional_modeIDMatch_2.dta"
drop _merge 

*Merge Unemployment Data by LEA ID
merge m:m leaid using "${intermediate}\unempIDMatch_2.dta"
drop if _merge == 2 | _merge == 1
drop _merge

save "${intermediate}\NC_covid_analysis_district_level.dta", replace

*Merge school finance data by LEA ID

merge m:m leaid using "${intermediate}\schoolfinance.dta"
drop _merge

save "${intermediate}\NC_covid_analysis_district_level2.dta", replace




//////NEW BASE FILE - School Level Wide Dataset
use "${intermediate}\school_level_wide_analysisIDMatch.dta", clear
sort leaid 
drop _merge

*Merge created combined file from District Level Wide above
merge m:m leaid using "${intermediate}\NC_covid_analysis_district_level2.dta"
drop if _merge == 1
tab _merge


local unemp "p_unemp1 p_unemp2 p_unemp3 p_unemp4"
local covid "p1_cases_p100k p2_cases_p100k p3_cases_p100k p4_cases_p100k p1_deaths_p100k p2_deaths_p100k p3_deaths_p100k p4_deaths_p100k"
local f20 "pf20_inperson_only pf20_remote_only pf20_hybrid_only pf20_inperson_choice pf20_hybrid_choice"

*Create z-score std variables for math and reading
foreach x in all black white {
egen zmath_tested`x'21=std(math_tested`x'21)
gen zmath_tested`x'21_2=zmath_tested`x'21^2

egen zread_tested`x'21=std(read_tested`x'21)
gen zread_tested`x'21_2=zread_tested`x'21^2

}

*Create z-score std varaibles for enrollment and GLP variables
foreach x in schenroll19 schblack19 schhisp19 sched19 math_glpall18 math_glpall19 read_glpall18 read_glpall19  {

egen z`x'=std(`x')

}


save "${intermediate}\NC_covid_analysis_school_level.dta", replace


/////Generating district-level variables for figure 1 & 2

*Create district level enrollment for SY 2019
bysort districtname21: egen dist_schenroll=total(schenroll19)

*Create enrollment normed GLP variables
foreach y in math read {

gen temp_`y'_glpall21=`y'_glpall21*schenroll19
gen temp_`y'_glpall18=`y'_glpall18*schenroll19
gen temp_`y'_glpall19=`y'_glpall19*schenroll19

bysort districtname21: egen dtemp_`y'_glpall21=total(temp_`y'_glpall21)
bysort districtname21: egen dtemp_`y'_glpall18=total(temp_`y'_glpall18)
bysort districtname21: egen dtemp_`y'_glpall19=total(temp_`y'_glpall19)

gen dist_`y'_glpall21=dtemp_`y'_glpall21/dist_schenroll
gen dist_`y'_glpall18=dtemp_`y'_glpall18/dist_schenroll
gen dist_`y'_glpall19=dtemp_`y'_glpall19/dist_schenroll

}

*Create SY remote only variable and quartile across district
bysort districtname21: gen first=_n==1
gen p2021_remote_only=(pf20_remote_only+ps21_remote_only)/2
xtile q4_p2021_remote_only=p2021_remote_only, n(4)

*Create SY 2018-19 & SY 2020-21 district difference in score variable
foreach y in math read {

gen diff_dist_`y'2119=dist_`y'_glpall21-dist_`y'_glpall19
gen diff_dist_`y'1918=dist_`y'_glpall19-dist_`y'_glpall18

} 

*Keep Needed Variables
keep leaid q4_p2021_remote_only first diff* dist*
bysort leaid: keep if _n==1
keep if leaid!=.
sort leaid

save "${intermediate}\q4_remote.dta", replace

*Sort school-level wide data by LEA ID
use "${intermediate}\NC_covid_analysis_school_level.dta", clear
sort leaid
save "${intermediate}\NC_covid_analysis_school_level.dta", replace

*Merge with newly created instructional shift variables
drop _merge 
merge m:1 leaid using "${intermediate}\q4_remote.dta"

*Create SY remote only variable
gen p2021_remote_only=(pf20_remote_only+ps21_remote_only)/2
*Create z-score std variables for remote only
egen zp2021_remote_only=std(p2021_remote_only)


*Create period normed covid cases per 100k 
egen tot_cases=rowtotal(p1_cases_p100k p2_cases_p100k p3_cases_p100k p4_cases_p100k )

*Create summary covid cases per 100k
gen tot_cases_p100k=(tot_cases/pop2021)*100000
replace tot_cases_p100k=. if tot_cases_p100k>50000
drop _merge

save "${final}\NC_covid_analysis_school_level.dta", replace



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                       Urban Paper                                                                                        //
//                                                                                                                          //
// do "C:\Users\tdomina\Dropbox (EQUAL)\COVID lit\analysis\do files\Urban paper analyses.do"                                //
// Urban "Learning Curves" COVID and school resilience analyses                                                             //
// note -- everything below replicates for math and reading, although paper draft only reports math                         //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


use "${final}\NC_covid_analysis_school_level.dta", clear

****TABLE 1 is very simple descriptives

sum math_glpall* read_glpall* [w=schenroll19]

foreach y in math read {
*FIGURE 2 


*2021 vs 2019
twoway (scatter dist_`y'_glpall21 dist_`y'_glpall19 [w=schenroll19], msize(small) msymbol(circle) mlcolor("255 255 255") mfcolor("255 255 255") color(%50) yscale(range(0 100))) ///
(line dist_`y'_glpall21 dist_`y'_glpall21 [w=dist_schenroll], lcolor(black) lwidth(thin)  yscale(range(0 100)) ) /// 
(lfit dist_`y'_glpall21 dist_`y'_glpall19 if dist_`y'_glpall21>0 [w=dist_schenroll], lcolor("253 181 17") lwidth(thin)  yscale(range(0 100))) ///
(scatter dist_`y'_glpall21 dist_`y'_glpall19 [w=dist_schenroll], ///
msymbol(circle) msize(vsmall) mlcolor("22 150 210") mfcolor("22 150 210%10") yscale(range(0 100))) ///
, title("2019 vs. 2021", size(medlarge)) xtitle("% of all 3rd graders proficient in `y', 2019", size(medsmall)) ytitle("% of all 3rd graders proficient in `y', 2021", size(medsmall)) legend(off) ylabel(0(20)100) xlabel(0(20)100) yscale(range(0 100)) graphregion(color(white)) bgcolor(white)

graph save "${vis}\\`y'_2019_2021_covid_scatter_district_all.gph", replace

graph export "${vis}\\`y'_2019_2021_covid_scatter_district_all.pdf", replace


*2019 vs 2018
twoway (scatter dist_`y'_glpall19 dist_`y'_glpall18 [w=dist_schenroll], msize(small) msymbol(circle) mlcolor("255 255 255") mfcolor("255 255 255") color(%50) yscale(range(0 100))) ///
(line dist_`y'_glpall21 dist_`y'_glpall21 [w=dist_schenroll], lcolor(black) lwidth(thin) yscale(range(0 100))) ///
(scatter dist_`y'_glpall19 dist_`y'_glpall18 [w=dist_schenroll], ///
msize(vsmall) msymbol(circle) mlcolor("22 150 210") mfcolor("22 150 210%10") yscale(range(0 100))) ///
, title("2018 vs. 2019", size(medlarge)) xtitle("% of all 3rd graders proficient in `y', 2018", size(medsmall)) ytitle("% of all 3rd graders proficient in `y', 2019", size(medsmall)) legend(off) ylabel(0(20)100) xlabel(0(20)100) graphregion(color(white)) bgcolor(white)

graph save "${vis}\\`y'_2018_2019_covid_scatter_district_all.gph", replace

graph export "${vis}\\`y'_2018_2019_covid_scatter_district_all.pdf", replace


graph combine "${vis}\\`y'_2018_2019_covid_scatter_district_all.gph" "${vis}\\`y'_2019_2021_covid_scatter_district_all.gph", c(2) ycommon xcommon ysize(3) xsize(8)

graph save "${vis}\\`y'_2018_2019_2021_covid_scatter_district_all.gph", replace

graph export "${vis}\\`y'_2018_2019_2021_covid_scatter_district_all.pdf", replace
}

*Table 2 Regressions
eststo clear

*Create variable of difference between SY 2019-21 and 2018-19
foreach y in math read {
gen diff_`y'2119=`y'_glpall21-`y'_glpall19
gen diff_`y'1918=`y'_glpall19-`y'_glpall18
}

*Create mean unemployment varaible
gen unemp=((p_unemp1*5)+(p_unemp2*3)+(p_unemp3*4)+(p_unemp4*4))/16

*Standardize unemplyment
egen zunemp=std(unemp)

*Standardize total cases per 100k population
egen ztot_cases=std(tot_cases_p100k)

*Standardize total per pupil spending in 2021 school year
egen ztotalppe=std(totalppe2021)

*Create regression tables 
foreach y in math read {
xtmixed diff_`y'1918  ///
|| districtname21: 

estat icc

eststo urb_t2_`y'm0

xtmixed diff_`y'2119 ///
z`y'_testedall21 z`y'_testedall21_2 [w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm1v2

estat icc

xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases ///
[w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm2v2

estat icc

xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases ///
i.q4_p2021_remote_only ztotalppe ///
[w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm3v2

estat icc

xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases ztotalppe  if q4_p2021_remote_only==1  ///
[w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm2v2_q1

estat icc

xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases ztotalppe if q4_p2021_remote_only==4  ///
[w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm2v2_q4

estat icc
}

*Export Regression Table to Excel
estout urb* using "${final}\Urban_table_2_models.xls", cells(b(star fmt(%9.3f)) se) stats(N , fmt(%9.0g %9.3f))  varlabels(_cons Constant) varwidth(15) modelwidth(10) prefoot("") postfoot("") legend replace `table_notes'  transform(ln*: exp(@) exp(@))



use "${final}\NC_covid_analysis_school_level.dta", clear

*Create average economically disadvantaged variable by district
bysort leaid: egen distfrpl = mean(sched19) 

*Create z-nomred PPE variable
egen ztotalppe=std(totalppe2021)

*Create z-normed total covid cases variable
egen ztot_cases=std(tot_cases_p100k)

*Create year-long unemployment variable
gen unemp=((p_unemp1*5)+(p_unemp2*3)+(p_unemp3*4)+(p_unemp4*4))/16
*Create z-normed unemp variable
egen zunemp=std(unemp)

save "${final}\NC_covid_analysis_school_levelsched.dta", replace

////Recreated Figure 4
use "${final}\NC_covid_analysis_school_level.dta", clear

*Create z-nomred PPE variable
egen ztotalppe=std(totalppe2021)

*Create z-normed total covid cases variable
egen ztot_cases=std(tot_cases_p100k)

*Create year-long unemployment variable
gen unemp=((p_unemp1*5)+(p_unemp2*3)+(p_unemp3*4)+(p_unemp4*4))/16
*Create z-normed unemp variable
egen zunemp=std(unemp)

***we're reprorting the ICCs from math...m0, m1v2, m2v2, and m3v2 below in Fig 3a and 3b. 

*Create Regression Tables
foreach y in math read {

gen diff_`y'2119=`y'_glpall21-`y'_glpall19
gen diff_`y'1918=`y'_glpall19-`y'_glpall18

xtmixed diff_`y'1918  ///
|| districtname21: 

estat icc
eststo urb_t2_`y'm0

xtmixed diff_`y'2119 ///
z`y'_testedall21 z`y'_testedall21_2 [w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm1v2
estat icc

xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases  ///
[w=schenroll19] ///
|| districtname21:

eststo urb_t2_`y'm2v2
estat icc

xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases ///
zp2021_remote_only ///
[w=schenroll19] ///
|| districtname21:

estat icc
eststo urb_t2_`y'm3v2


xtmixed diff_`y'2119 z`y'_testedall21 z`y'_testedall21_2 i.schtype19 i.schurbanicity19 zschenroll19 zschblack19 zschhisp19 zsched19 ///
zunemp ///
ztot_cases ///
zp2021_remote_only ztotalppe ///
[w=schenroll19] ///
|| districtname21:

estat icc

}


foreach y in math read {

gen dist_diff_`y'2119=dist_`y'_glpall21-dist_`y'_glpall19

}

drop dist_schenroll

bysort districtname21: egen dist_schenroll=total(schenroll19)
tab districtname21
drop first
bysort districtname21: gen first=_n==1
tab dist_schenroll if first==1

*Figure 5

twoway (lfit dist_diff_math2119 p2021_remote_only if first==1 [w=dist_schenroll], lcolor(black) lwidth(thick) lp(solid) yscale(range(-60 20)) range(0 1)) ///
(scatter dist_diff_math2119 p2021_remote_only if first==1 [w=dist_schenroll], ///
 msymbol(circle) msize(small) mlcolor("22 150 210") mfcolor("22 150 210") color(%50) yscale(range(-60 20)) xlabel(0 "0" .2 "20%" .4 "40%" .6  "60%" .8 "80%" 1 "100%") ylabel(-60(20)20)) ///
, legend(off) xtitle("% 2020-21 remote only", size(medsmall)) ytitle("Change in 3rd grade math proficiency, 2019-2021", size(medsmall)) graphregion(color(white)) bgcolor(white)

graph save "${vis}\\Urban_Fig_4_math_change_vs_remote.gph", replace

graph export "${vis}\\Urban_Fig_4_math_change_vs_remote.pdf", replace

