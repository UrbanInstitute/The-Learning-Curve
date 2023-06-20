
*****CHANGE DIRECTORY TO LOCAL FOLDER
glo directory "****************"

global data = "${directory}/data"
global raw_data = "${data}/raw_data"
global out_data = "${data}/output_data"
global int_data = "${data}/intermediate"
global vis = "${out_data}/vis"

foreach x in "${data}" "${out_data}" "${int_data}" "${raw_data}" "${vis}" {
	cap n mkdir "`x'"
}

cd "${directory}"

****** creating the Data Documentation file
cap n copy "https://educationdata.urban.org/csv/ipeds/colleges_ipeds_completions-6digcip_2018.csv" "${raw_data}/awards_2019.csv", replace

import delimited "${raw_data}/awards_2019.csv", clear varnames(1)

destring cipcode_6digit, replace
replace cipcode_6digit = cipcode_6digit/10000

cap n drop cipcode2*
cap n drop cipcode3
gen cipcode2 = string(cipcode_6digit, "%07.4f")
tab cipcode2 if ustrregexm(cipcode2, "^45.")
replace cipcode2 = "0" + cipcode2 if strlen(cipcode2) == 6

gen cipcode2a = substr(cipcode2, 1, 2)
gen cipcode2b = substr(cipcode2, 1, 5)

gen cipcode3 = cipcode2a if !inlist(cipcode2a, "40", "45")
replace cipcode3 = cipcode2b if inlist(cipcode2a, "40", "45")

collapse (sum) awards_6dig, by(unitid year fips majornum award_level sex race cipcode3)
ren cipcode3 cipcode

keep if inlist(cipcode, "01", "03", "04", "05", "09") | ///
	inlist(cipcode,"10", "11")  |  ///
	inlist(cipcode, "12", "13", "14", "15", "16") | ///
	inlist(cipcode, "19", "22", "23", "24", "25") | ///
	inlist(cipcode, "26", "27", "29", "30", "31", "38") | ///
	inlist(cipcode, "39", "40", "40.01", "40.02") | ///
	inlist(cipcode, "40.04", "40.05", "40.06", "40.08") | ///
	inlist(cipcode, "40.10", "40.99", "41", "42") | ///
	inlist(cipcode, "43", "44", "45", "45.01") | ///
	inlist(cipcode, "45.02", "45.03") | ///
	inlist(cipcode, "45.04", "45.05", "45.06") | ///
	inlist(cipcode, "45.07", "45.09", "45.10", "45.11") | ///
	inlist(cipcode, "45.12", "45.13", "45.14") | ///
	inlist(cipcode, "45.99", "46", "47", "48") | ///
	inlist(cipcode, "49", "50", "51", "52", "54", "99")
	
gen CipTitle = ""
replace CipTitle = "Agriculture, Agriculture Operations and Related Sciences" if cipcode == "01"
replace CipTitle = "Natural Resources and Conservation" if cipcode == "03"
replace CipTitle = "Architecture and Related Services" if cipcode == "04"
replace CipTitle = "Area, Ethnic, Cultural, Gender, and Group Studies" if cipcode == "05"
replace CipTitle = "Communication, Journalism, and Related Programs" if cipcode == "09"
replace CipTitle = "Communications Technologies/Technicians and Support Servies" if cipcode == "10"
replace CipTitle = "Computer and Information Sciences and Support Services" if cipcode == "11"
replace CipTitle = "Personal and Culinary Services" if cipcode == "12"
replace CipTitle = "Education" if cipcode == "13"
replace CipTitle = "Engineering" if cipcode == "14"
replace CipTitle = "Engineering Technologies and Engineering-related Fields" if cipcode == "15"
replace CipTitle = "Foreign Languages, Literatures, and Linguistics" if cipcode == "16"
replace CipTitle = "Family and Consumer Sciences/Human Sciences" if cipcode == "19"
replace CipTitle = "Legal Professions and Studies" if cipcode == "22"
replace CipTitle = "English Language and Literature/Letters" if cipcode == "23"
replace CipTitle = "Liberal Arts and Sciences, General Studies and Humanities" if cipcode == "24"
replace CipTitle = "Library Science" if cipcode == "25"
replace CipTitle = "Biological and Biomedical Sciences" if cipcode == "26"
replace CipTitle = "Mathematics and Statistics" if cipcode == "27"
replace CipTitle = "Military Technologies and Applied Sciences" if cipcode == "29"
replace CipTitle = "Multi/Interdisciplinary Studies" if cipcode == "30"
replace CipTitle = "Parks, Recreation, Leisure and Fitness Studies" if cipcode == "31"
replace CipTitle = "Philosophy and Religious Studies" if cipcode == "38"
replace CipTitle = "Theology and Religious Vocations" if cipcode == "39"
replace CipTitle = "Physical Sciences" if cipcode == "40"
replace CipTitle = "Physical Sciences, general" if cipcode == "40.01"
replace CipTitle = "Astronomy and Astrophysics" if cipcode == "40.02"
replace CipTitle = "Atmospheric Sciences and Meteorology" if cipcode == "40.04"
replace CipTitle = "Chemistry" if cipcode == "40.05"
replace CipTitle = "Geological and Earth Sciences/Geosciences" if cipcode == "40.06"
replace CipTitle = "Physics" if cipcode == "40.08"
replace CipTitle = "Materials Sciences" if cipcode == "40.10"
replace CipTitle = "Physical Sciences, Other" if cipcode == "40.99"
replace CipTitle = "Science Technologies/Technicians" if cipcode == "41"
replace CipTitle = "Psychology" if cipcode == "42"
replace CipTitle = "Homeland Security, Law Enforcement, Firefighting, and Related Protective Service" if cipcode == "43"
replace CipTitle = "Public Administration and Social Service Professions" if cipcode == "44"
replace CipTitle = "Social Sciences" if cipcode == "45"
replace CipTitle = "Social Sciences, General" if cipcode == "45.01"
replace CipTitle = "Anthropology" if cipcode == "45.02"
replace CipTitle = "Archeology" if cipcode == "45.03"
replace CipTitle = "Criminology" if cipcode == "45.04"
replace CipTitle = "Demography and Population Studies" if cipcode == "45.05"
replace CipTitle = "Economics" if cipcode == "45.06"
replace CipTitle = "Geography and Cartography" if cipcode == "45.07"
replace CipTitle = "International Relations and National Security Studies" if cipcode == "45.09"
replace CipTitle = "Political Science and Government" if cipcode == "45.10"
replace CipTitle = "Sociology" if cipcode == "45.11"
replace CipTitle = "Urban Studies/Affairs" if cipcode == "45.12"
replace CipTitle = "Sociology and Anthropology" if cipcode == "45.13"
replace CipTitle = "Rural Sociology" if cipcode == "45.14"
replace CipTitle = "Social Sciences, Other" if cipcode == "45.99"
replace CipTitle = "Construction Trades" if cipcode == "46"
replace CipTitle = "Mechanic and Repair Technologies/Technicians" if cipcode == "47"
replace CipTitle = "Precision Production" if cipcode == "48"
replace CipTitle = "Transportation and Materials Moving" if cipcode == "49"
replace CipTitle = "Visual and Performing Arts" if cipcode == "50"
replace CipTitle = "Health Professions and Related Programs" if cipcode == "51"
replace CipTitle = "Business, Management, Marketing, and Related Support Services" if cipcode == "52"
replace CipTitle = "History" if cipcode == "54"
replace CipTitle = "Grand total" if cipcode == "99"
tab CipTitle


preserve
gen cipcode2 = substr(cipcode, 1, 2)
keep if inlist(cipcode2, "40", "45")
collapse (sum) awards_6dig, by(unitid year fips majornum award_level sex race cipcode2)
ren cipcode2 cipcode
gen CipTitle = "Physical Sciences" if cipcode == "40"
replace CipTitle = "Social Sciences" if cipcode == "45"
tempfile sciences
save "`sciences'"
restore

append using "`sciences'"

preserve
keep if inlist(cipcode, "01", "03", "04", "05", "09") | ///
	inlist(cipcode,"10", "11")  |  ///
	inlist(cipcode, "12", "13", "14", "15", "16") | ///
	inlist(cipcode, "19", "22", "23", "24", "25") | ///
	inlist(cipcode, "26", "27", "29", "30", "31", "38") | ///
	inlist(cipcode, "39", "40") | ///
	inlist(cipcode, "41", "42") | ///
	inlist(cipcode, "43", "44", "45") | ///
	inlist(cipcode, "46", "47", "48") | ///
	inlist(cipcode, "49", "50", "51", "52", "54", "99")
collapse (sum) awards_6dig, by(unitid year fips majornum award_level sex race)
gen cipcode = "99"
gen CipTitle = "Grand total"
tempfile total
save "`total'"
restore

append using "`total'"

tab cipcode
tab CipTitle

// Replacing Award Level values
gen award_level_2 = ""
replace award_level_2 = "Bachelor's Degree" if award_level == 7
replace award_level_2 = "Doctor's degree - research/scholarship" if award_level ==22

// Replacing Race data
cap drop C2019_*
gen C2019_X = ""
replace C2019_X = "Whitetotal" if race == 1
replace C2019_X = "BlackorAfricanAmerica" if race == 2
replace C2019_X = "HispanicorLatinototal" if race == 3
replace C2019_X = "Asiantotal" if race == 4
replace C2019_X = "AmericanIndianorAlask" if race == 5
replace C2019_X = "NativeHawaiianorOther" if race == 6
replace C2019_X = "Twoormoreracestotal" if race == 7
replace C2019_X = "Nonresidentalientotal" if race == 8
replace C2019_X = "Raceethnicityunknownt" if race == 9
replace C2019_X = "Othertotal" if race == 20
replace C2019_X = "Grandtotal" if race == 99

keep if sex == 99

drop race
ren awards_6dig C2019_A
reshape wide C2019_A, i(unitid year fips majornum award_level cipcode) j(C2019_X) string


preserve
keep if award_level == 7
ren  (C2019_AGrandtotal C2019_AAmericanIndianorAlask C2019_AAsiantotal C2019_ABlackorAfricanAmerica C2019_AHispanicorLatinototal C2019_ANativeHawaiianorOther C2019_AWhitetotal C2019_ATwoormoreracestotal C2019_ARaceethnicityunknownt C2019_ANonresidentalientotal) ///
	(C2019_A_RVGrandtotal C2019_A_RVAmericanIndianorAl C2019_A_RVAsiantotal C2019_A_RVBlackorAfricanAmer C2019_A_RVHispanicorLatinoto C2019_A_RVNativeHawaiianorOt C2019_A_RVWhitetotal C2019_A_RVTwoormoreracestot C2019_A_RVRaceethnicityunknow C2019_A_RVNonresidentalientot)
save "${int_data}/bach_data.dta", replace
restore

preserve
keep if award_level == 22
save "${int_data}/doctoral_data.dta", replace
restore


*****IMPORT PHD DATA
use "${int_data}/doctoral_data.dta", clear

*****SUM ACROSS ALL INSTITUTIONS BY FIELD OF STUDY
collapse (sum) C2019_AGrandtotal C2019_AAmericanIndianorAlask C2019_AAsiantotal C2019_ABlackorAfricanAmerica C2019_AHispanicorLatinototal C2019_ANativeHawaiianorOther C2019_AWhitetotal C2019_ATwoormoreracestotal C2019_ARaceethnicityunknownt C2019_ANonresidentalientotal, ///
	by(CipTitle cipcode)

*****CREATE "OTHER RACE/ETHNICITY" CATEGORY THAT COMBINES AMERICAN INDIAN OR ALASKA NATIVE, ASIAN, NATIVE HAWAIIAN, TWO OR MORE RACES, AND RACE UNKNOWN
gen C2019_AOther_race_ethnicity= C2019_AAmericanIndianorAlask+ C2019_AAsiantotal+ C2019_ANativeHawaiianorOther+ C2019_ATwoormoreracestotal+ C2019_ARaceethnicityunknownt

*****CREATE PERCENTAGES OF PHDS AWARDED BY RACE/ETHNICITY
gen double PCT_PHD_BLACK= C2019_ABlackorAfricanAmerica/ C2019_AGrandtotal
gen double PCT_PHD_HISPANIC= C2019_AHispanicorLatinototal / C2019_AGrandtotal
gen double PCT_PHD_WHITE= C2019_AWhitetotal / C2019_AGrandtotal
gen double PCT_PHD_OTHER= C2019_AOther_race_ethnicity / C2019_AGrandtotal

*****CREATE PERCENTAGES OF PHDS AWARDED BY RACE/ETHNICITY, EXCLUDING NON RESIDENT INTERNATIONAL STUDENTS
gen double PCT_PHD_BLACK_DOMESTIC=PCT_PHD_BLACK/(PCT_PHD_BLACK+PCT_PHD_HISPANIC+PCT_PHD_WHITE+PCT_PHD_OTHER)
gen double PCT_PHD_HISP_DOMESTIC=PCT_PHD_HISPANIC/(PCT_PHD_BLACK+PCT_PHD_HISPANIC+PCT_PHD_WHITE+PCT_PHD_OTHER)
gen double PCT_PHD_WHITE_DOMESTIC=PCT_PHD_WHITE/(PCT_PHD_BLACK+PCT_PHD_HISPANIC+PCT_PHD_WHITE+PCT_PHD_OTHER)
gen double PCT_PHD_OTHER_DOMESTIC=PCT_PHD_OTHER/(PCT_PHD_BLACK+PCT_PHD_HISPANIC+PCT_PHD_WHITE+PCT_PHD_OTHER)

*****ORGANIZE AND SORT DATA
order CipTitle PCT_PHD_BLACK_DOMESTIC PCT_PHD_HISP_DOMESTIC PCT_PHD_WHITE_DOMESTIC PCT_PHD_OTHER_DOMESTIC PCT_PHD_BLACK PCT_PHD_HISPANIC PCT_PHD_WHITE PCT_PHD_OTHER
sort CipTitle

*****SAVE
save "${int_data}/FACULTY_PIPELINE_DATA.dta", replace
clear


*****BACHELOR DEGREE DATA
use "${int_data}/bach_data.dta", clear

*****SUM ACROSS ALL INSTITUTIONS BY FIELD OF STUDY
collapse (sum) C2019_A_RVGrandtotal C2019_A_RVAmericanIndianorAl C2019_A_RVAsiantotal C2019_A_RVBlackorAfricanAmer C2019_A_RVHispanicorLatinoto C2019_A_RVNativeHawaiianorOt C2019_A_RVWhitetotal C2019_A_RVTwoormoreracestot C2019_A_RVRaceethnicityunknow C2019_A_RVNonresidentalientot , ///
	by(CipTitle cipcode)

*****CREATE "OTHER RACE/ETHNICITY" CATEGORY THAT COMBINES AMERICAN INDIAN OR ALASKA NATIVE, ASIAN, NATIVE HAWAIIAN, TWO OR MORE RACES, AND RACE UNKNOWN
gen C2019_Other_race_ethnicity= C2019_A_RVAmericanIndianorAl+C2019_A_RVAsiantotal+C2019_A_RVNativeHawaiianorOt+C2019_A_RVTwoormoreracestot+C2019_A_RVRaceethnicityunknow

*****CREATE PERCENTAGES OF BACHELORS AWARDED BY RACE/ETHNICITY
gen double PCT_BACH_BLACK= C2019_A_RVBlackorAfricanAmer/ C2019_A_RVGrandtotal
gen double PCT_BACH_HISPANIC= C2019_A_RVHispanicorLatinoto / C2019_A_RVGrandtotal
gen double PCT_BACH_WHITE= C2019_A_RVWhitetotal / C2019_A_RVGrandtotal
gen double PCT_BACH_OTHER= C2019_Other_race_ethnicity / C2019_A_RVGrandtotal

*****CREATE PERCENTAGES OF BACHELORS AWARDED BY RACE/ETHNICITY, EXCLUDING NON RESIDENT INTERNATIONAL STUDENTS
gen double PCT_BACH_BLACK_DOMESTIC=PCT_BACH_BLACK/(PCT_BACH_BLACK+PCT_BACH_HISPANIC+PCT_BACH_WHITE+PCT_BACH_OTHER)
gen double PCT_BACH_HISP_DOMESTIC=PCT_BACH_HISPANIC/(PCT_BACH_BLACK+PCT_BACH_HISPANIC+PCT_BACH_WHITE+PCT_BACH_OTHER)
gen double PCT_BACH_WHITE_DOMESTIC=PCT_BACH_WHITE/(PCT_BACH_BLACK+PCT_BACH_HISPANIC+PCT_BACH_WHITE+PCT_BACH_OTHER)
gen double PCT_BACH_OTHER_DOMESTIC=PCT_BACH_OTHER/(PCT_BACH_BLACK+PCT_BACH_HISPANIC+PCT_BACH_WHITE+PCT_BACH_OTHER)

*****ORGANIZE AND SORT DATA
order CipTitle PCT_BACH_BLACK_DOMESTIC PCT_BACH_HISP_DOMESTIC PCT_BACH_WHITE_DOMESTIC PCT_BACH_OTHER_DOMESTIC PCT_BACH_BLACK PCT_BACH_HISPANIC PCT_BACH_WHITE PCT_BACH_OTHER
sort CipTitle

****SAVE 
save "${int_data}/FACULTY_PIPELINE_BACHELOR.dta", replace
clear

*****MERGE PHD AND BACHELOR DATA
use "${int_data}/FACULTY_PIPELINE_DATA.dta", clear
merge 1:1 CipTitle cipcode using "${int_data}/FACULTY_PIPELINE_BACHELOR.dta"

*****KEEP ONLY DEGREE FIELDS THAT AWARD AT LEAST 500 PHDS AND AWARD BOTH BACHELOR AND PHD DEGREES

save "${out_data}/FACULTY_PIPELINE_DATA.dta", replace

****GENERATE DIFFERENCE BETWEEN PERCENTAGE OF BACHELOR DEGREE AND PERCENTAGE OF PHDS, BY RACE/ETHNICITY
gen double PHD_MINUS_BACH_BLACK= PCT_PHD_BLACK_DOMESTIC - PCT_BACH_BLACK_DOMESTIC
gen double PHD_MINUS_BACH_HISP= PCT_PHD_HISP_DOMESTIC - PCT_BACH_HISP_DOMESTIC
gen double PHD_MINUS_BACH_WHITE= PCT_PHD_WHITE_DOMESTIC - PCT_BACH_WHITE_DOMESTIC
gen double PHD_MINUS_BACH_OTHER= PCT_PHD_OTHER_DOMESTIC - PCT_BACH_OTHER_DOMESTIC

order CipTitle cipcode PHD_MINUS_BACH_BLACK PHD_MINUS_BACH_HISP PHD_MINUS_BACH_WHITE PHD_MINUS_BACH_OTHER PCT_PHD_BLACK_DOMESTIC PCT_PHD_HISP_DOMESTIC PCT_PHD_WHITE_DOMESTIC PCT_PHD_OTHER_DOMESTIC PCT_BACH_BLACK_DOMESTIC PCT_BACH_HISP_DOMESTIC PCT_BACH_WHITE_DOMESTIC PCT_BACH_OTHER_DOMESTIC

save "${out_data}/FACULTY_PIPELINE_DATA.dta", replace
export excel using "${out_data}/PHD_BACHELOR_2019.xls", firstrow(variables) replace