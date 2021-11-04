** set paths **
global data "[your path here]"
global output "[your path here]"

cd ${data}

cap n ssc install seg

******Longitudinal Analaysis (1997-2019)

*First I am bringing in the data
*This pulls in the whole CCD panel of schools by year and include the high and low grade for each school. 
educationdata using "school ccd directory", csv
save "${data}\Longitudinal_Pre Grade.dta", replace

*Now I need to get the student enrollment in each grade for the whole panel. I am getting that by the enrollment file and will then merge in. 
educationdata using "school ccd enrollment", sub(grade=-1:1)csv clear
save "${data}\Student enrollment longitudinal_raw.dta", replace

*the data were long and disaggregated by gender and race, which i dont need, so I am just keeping the total sum rows through this process. 
gen pkenroll=enrollment if sex==99 & race==99 & grade==-1
gen kenroll=enrollment if sex==99 & race==99 & grade==0
gen firstenroll=enrollment if sex==99 & race==99 & grade==1

bysort year ncessch: egen pkenroll1=max(pkenroll)
bysort year ncessch: egen kenroll1=max(kenroll)
bysort year ncessch: egen firstenroll1=max(firstenroll)

keep ncessch year pkenroll1 kenroll1 firstenroll1

*Having gotten the total enrollment for PK, K, and first grade as their own columns, I am now going to manually get the dataset to have one school per year observation

duplicates drop
save "${data}\Student enrollment longitudinal_cleaned.dta", replace

*Here i am bring the student enrollment data together with the school CCD directory. 
use "${data}\Longitudinal_Pre Grade.dta", clear
merge 1:1 year ncessch using "${data}\Student enrollment longitudinal_cleaned.dta", keepusing(kenroll1 pkenroll1 firstenroll1)
save "${data}\SBPK_Longitudinal Analysis_Merged.dta", replace

*Running some checks
sort _merge
  *Note that the master only cases are those with higher grades since I only extracted student enrollment for PK, K, and first. This checks out. 
*retaining only 50 states and DC based on fips
keep if fips>=1 & fips<=56
  
******* Key Variable Generation

***Different definitions of elementary schools
*CCD definition (Low PK-3, high PK-8)
gen ccdelementary=.
replace ccdelementary=1 if (lowest_grade>=-1 & lowest_grade<=3) & (highest_grade>=-1 & highest_grade<=8)
recode ccdelementary (.=0)

*indicator for PK only schools (as a propotion of CCD elementary schools)
gen pkonly=.
replace pkonly=1 if lowest_grade==-1 & highest_grade==-1
recode pkonly (.=0) if ccdelementary==1  

*indicator for ECE schools (e.g. PK-3) as a proportion of elementary schools
gen earlyelem=.
replace earlyelem=1 if (lowest_grade>=-1 & lowest_grade<=3) & (highest_grade>=-1 & highest_grade<=3)
recode earlyelem (.=0) if ccdelementary==1  
  
*indicator for elementary school has a Pre-K (note that I need to extract how many are PK only schools to give a inclusive and exclusive estimate)  
gen haspk=.
replace haspk=1 if ccdelementary==1 & lowest_grade==-1  
recode haspk (.=0) if ccdelementary==1 
  
*Getting the propotion of different ece type elementary schools by year for graphs
preserve
collapse (mean) haspk earlyelem pkonly, by(year)
export excel using "${output}\Prekindergarten analyses.xlsx", sheet("Trend data") firstrow(variables) sheetreplace
restore	
	
*********Switching to student enrollment (note this is accross all states)
bysort year: egen totpk=sum(pkenroll1)
bysort year: egen totk=sum(kenroll1)
bysort year: egen tot1=sum(firstenroll1)

*Pk enrollment as a pecentage of K and first enrollment
gen pkpropk=totpk/totk
gen pkprop1=totpk/tot1

mean pkprop1, over(year)
   *Note: i checked and the pattern is no different as a prop of K or first grade, so I will stick with K as the closest adjacent grade. 
   
*title 1 figure
count if year==2019 & haspk==1 & title_i_eligible==1
count if year==2019 & haspk==1 & title_i_eligible==0

count if year==2019 & haspk==0 & title_i_eligible==1
count if year==2019 & haspk==0 & title_i_eligible==0

preserve
keep if year==2019 & haspk!=. & inlist(title_i_eligible,0,1)
collapse (mean) title_i_eligible, by(haspk)
export excel using "${output}\Prekindergarten analyses.xlsx", sheet("Title I data") firstrow(variables) sheetreplace
restore
   
****coding school locale
* City includes the subcategories of Large City, Mid-size City, and Small City. Suburban includes
*the subcategories of Large Suburb, Mid-size Suburb, and Small Suburb. Town includes the subcategories of Town, Fringe; Town, Distant; and
*Town, Remote. Rural includes the subcategories of Rural, Fringe; Rural, Distant; and Rural, Remote.   
 
*city 1, suburb 2, town 3, rural 4
recode urban_centric_locale (-2=.)(-1=.)(1=1)(2=1)(3=1)(4=1)(5=3)(6=3)(7=4)(8=4)(11=1)(12=1)(13=1)(21=2)(22=2)(23=2)(31=3)(32=3)(33=3)(41=4)(42=4)(43=4)
label define ucl 1 "City"
label define ucl 2 "Suburb", add
label define ucl 3 "Town", add
label define ucl 4 "Rural", add
label values urban_centric_locale ucl

preserve
keep if year==2019
gen has_pk=1
drop if haspk==.
collapse (sum) has_pk, by(haspk urban_centric_locale)
reshape wide has_pk, i(urban_centric_local) j(haspk)
export excel using "${output}\Prekindergarten analyses.xlsx", sheet("Locale data") firstrow(variables) sheetreplace
restore


***********
**************Moving on to examine differences in PK schools in the most recent year. 
*Bringing in data to look at disaggregation by race and grade
educationdata using "school ccd enrollment", sub(grade=-1:0 year=2019) csv clear
save "${data}\student enrollment by grade and race 2019.dta", replace

keep if sex==99
drop sex
drop if race==9 | race==99

********** Analysis of PK enrollment
*getting the total for each racial group for the excel table
preserve
drop if enrollment<0
collapse (sum) enrollment, by(grade race)
gen gr="_pk" if grade==-1
replace gr="_k" if grade==0
drop grade
reshape wide enrollment, i(race) j(gr) string
decode race, gen(race_str)
drop race
order race enrollment_pk enrollment_k
sort race
export excel using "${output}\Prekindergarten analyses.xlsx", sheet("Race data") firstrow(variables) sheetreplace
restore

** segregation analysis **
gen gr = "pk" if grade==-1
replace gr = "k" if grade==0
drop grade
replace enrollment = . if enrollment<0
reshape wide enrollment, i(ncessch race) j(gr) string
rename enrollment* *
reshape wide pk k, i(ncessch) j(race)

seg pk1 pk2 pk3 pk4 pk5 pk6 pk7, d
seg k1 k2 k3 k4 k5 k6 k7, d
