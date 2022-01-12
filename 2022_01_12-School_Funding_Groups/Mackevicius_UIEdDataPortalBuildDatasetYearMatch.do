/*
********************************************************************************
********************************************************************************
Data-Driven Analysis of Timely Education Policy Topics
Understanding How School-Specific Supplemental Fundraising Organizations Exacerbate Inequitable Resource Distribution

Data merging
********************************************************************************
********************************************************************************
*/
**ADJUST THIS
global path "C:/Users/LRestrepo/Documents/Clair_Folder"

/******
Build dataset for analysis
*******/


//install/replace
*ssc install libjson
*net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")
*help educationdata
*detailed documentation: https://educationdata.urban.org/documentation/school-districts.html

/*
get district-level char from CCD
*/
//district-level finance
educationdata using "district ccd finance", sub(year=2016 fips=17) clear

gen propexp_salben = (salaries_total+benefits_employee_total)/exp_total if exp_total > 0 //district avg spent on non-personnel

cd "${path}/Data Intermediate"
save IL_EdDataDistFinance, replace

/*
get school-level char from CCD
*/
//school-level demos
educationdata using "school ccd enrollment race", sub(year=2016 fips=17 grade=99) clear

save IL_EdDataDemoScrape, replace
keep if grade == 99 //(all grades)

reshape wide enrollment, i(ncessch) j(race)
rename enrollment1 enrollWhite
rename enrollment2 enrollBlack
rename enrollment3 enrollHispanic
rename enrollment4 enrollAsian
rename enrollment5 enrollAIAN
rename enrollment6 enrollNatHIPI
rename enrollment7 enroll2morerace
rename enrollment9 enrollUnknownrace
rename enrollment99 enrollTOTAL
keep enroll* ncessch
save IL_SchoolDemo, replace

//school-level ccd directory
educationdata using "school ccd directory", sub(year=2016 fips=17) clear

gen ShareLI = free_or_reduced_price_lunch/enrollment

save IL_SchoolDirectory, replace
merge 1:1 ncessch using IL_SchoolDemo
save IL_SchoolDirectoryDemo, replace

//input, clean school-level from edunomics
//source: https://edunomicslab.org/nerds/
import excel "${path}/Data Input/IL_1819_final_October_8th_21", clear sheet("FY 2018-19") firstrow

//cannot keep schools missing ncesid
keep if ncesid != "NA"
gen ncessch = ncesid
keep pp* ncessch

//cleaning
local NERDS_spendingvars "pp_stloc_raw_IL pp_fed_raw_IL pp_total_raw_IL"
foreach var in `NERDS_spendingvars'{
	replace `var' = "" if `var' == "NA"
	destring `var', replace
}

save IL_SchoolLevelSpend, replace

//merge demo with school-level
use IL_SchoolDirectoryDemo, clear
drop _merge
merge 1:1 ncessch using IL_SchoolLevelSpend
drop _merge

//prep for link
gen state = "IL"
gen zip_forlink = zip_mailing
gen city_forlink = lower(city_mailing)
gen street_forlink = lower(street_mailing)
gen name_forlink = lower(school_name)
destring ncessch, gen(NCESID_num)

replace name_forlink = regexr(name_forlink, "\((.)+\)", "")
replace name_forlink = regexr(name_forlink , "\(", "")
replace street_forlink = regexr(street_forlink, "\((.)+\)", "")
replace street_forlink = regexr(street_forlink , "\(", "")
replace street_forlink = regexr(street_forlink , "\)", "")
replace street_forlink = regexr(street_forlink, "`","")
replace name_forlink = subinstr(name_forlink, "school", "", .)

keep if school_type == 1 // "Regular school"
keep if highest_grade_offered != 0 //k
keep if highest_grade_offered != -1 //prek

bysort leaid: egen numSchools = count(ncessch)

save IL_SchoolInfoMerged, replace

//generate dataset of only those schools that are the sole school in the district
keep if numSchools == 1
replace name_forlink = lower(lea_name)
replace name_forlink = regexr(name_forlink, "\((.)+\)", "")
replace name_forlink = regexr(name_forlink , "\(", "")
replace name_forlink = subinstr(name_forlink, "district", "", .)
save IL_SingleSchoolDistInfoMerged, replace

/*
link schools to orgs
*/
//school-level orgs
use "IL_SchoolOrgstomerge", clear
reclink2 zip_forlink city_forlink street_forlink name_forlink using "IL_SchoolInfoMerged", idmaster(ein) idusing(NCESID_num) gen(linkScore) wmatch(15 17 12 20)

sort linkScore
order linkScore name school_name sec_name

gen badLink = 1 if missing(linkScore)

//Manually review
replace badLink = 1 if name == " MCLEANSBORO PTA" & school_name == "East Side Elementary School"
replace badLink = 0 if !missing(linkScore) 

keep if badLink == 0

save IL_SchoolOnlyOrgMerged, replace


//district-level orgs to schools that are only school in dist
use "IL_DistrictOrgstomerge", clear
reclink2 zip_forlink city_forlink name_forlink using "IL_SingleSchoolDistInfoMerged", idmaster(ein) idusing(NCESID_num) gen(linkScore) wmatch(15 17 20)

sort linkScore
order linkScore name_forlink lea_name

gen badLink = 1 if missing(linkScore)
replace badLink = 0 if linkScore > 0.9 & !missing(linkScore)

//review links, re-assign bad links to not include
replace badLink = 1 if name_forlink == "evanston skokie council of ptascouncil evanston skokie pta"
replace badLink = 1 if name_forlink == "bradley elementary   61"
replace badLink = 1 if name_forlink == "evanston-skokie  65 education foundation"
replace badLink = 1 if lea_name == "Chicago Lighthouse Chtr Sch"
replace badLink = 0 if name_forlink == "reavis community high  dist 220 educational foundation"
replace badLink = 0 if name_forlink == "joseph sears foundation-a keniworth  dist no 38 supporting org"
replace badLink = 0 if name_forlink == "mvths  201 foundation"
replace badLink = 0 if name_forlink == " no 90 educational foundation"
keep if badLink == 0

append using IL_SchoolOnlyOrgMerged

//one, summed observation per school
bysort ncessch: egen totalExps = sum(exps)
bysort ncessch: egen numOrgs = count(ein)
bysort ncessch: keep if _n==_N

replace totalExps = exps if missing(totalExps)

//gen vars for analyses
gen Org_PPE = totalExps/enrollment
label var Org_PPE "Organization Per Pupil Expenditure"
label var ShareLI "Share of Low-Income Students"

keep if !missing(Org_PPE)

drop _merge
merge m:1 leaid using "${path}/Data Intermediate/IL_EdDataDistFinance"
keep if _merge == 3
drop _merge

merge 1:1 ncessch using "${path}/Data Intermediate/IL_SchoolInfoMerged"
gen hasPTOOrg = 1 if _merge == 3
replace hasPTOOrg = 0 if _merge == 2

//generate share of racialized categories (though this post only includes shareWhite)
gen shareWhite = enrollWhite/enrollment
gen shareNonWhite = 1 - shareWhite
label var shareWhite "Share White"
gen shareBlack = enrollBlack/enrollment
label var shareBlack "Share Black"
gen shareAsian = enrollAsian/enrollment
label var shareAsian "Share Asian"
gen shareHispanic = enrollHispanic/enrollment
label var shareHispanic "Share Hispanic"
gen shareAIAN = enrollAIAN/enrollment
label var shareAIAN "Share American Indian or Alaska Native"
gen shareNHPI = enrollNatHIPI/enrollment
label var shareNHPI "Share Native Hawaiian or Pacific Islander"
gen shareMultRace = enroll2morerace/enrollment
label var shareMultRace "Share Multiple Racial Categories"

label var pp_fed_raw_IL "Per-pupil Exp. (Fed)"
label var pp_stloc_raw_IL "Per-pupil Exp. (State/Local)"

//only those that are primary, middle, high schools (not early or missing)
keep if school_level == 1 | school_level == 2 | school_level == 3

//only keep variables used in analyses
keep Org_PPE ShareLI leaid shareWhite hasPTOOrg ein exps enrollment pp_stloc_raw_IL pp_fed_raw_IL pp_total_raw_IL propexp_salben ass_eoy lea_name ncessch school_level
cd "${path}"
save IL_SchoolOrgMerge, replace
export excel using IL_SchoolOrgMerge.xlsx, replace
