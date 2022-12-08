cd "${path}"

* Setting Font
graph set window fontface "lato"

*Note: year is fall of academic year
use "${pathclean}/4and8allscores.dta", clear
ren grade_edfacts grade

*Drop 2021 (fall) for now
drop if year==2021

ren mathmidpt statemath
ren readmidpt stateread

*Generate percent proficient and above
gen naepmath = NmathatProficient+NmathatAdvanced
gen naepread = NreadatProficient+NreadatAdvanced

ren Nscalemath naepscalemath
ren Nscaleread naepscaleread

keep year fips statemath stateread mathnum readnum grade naepmath naepread naepscalemath naepscaleread

*Interpolate NAEP scores
sort fips grade year
foreach v in readnum grade naepmath naepread naepscalemath naepscaleread {
replace `v' = (`v'[_n-1] + `v'[_n+1])/2 if fips==fips[_n-1] & fips==fips[_n+1] & grade==grade[_n-1] & grade==grade[_n+1] & year==year[_n-1]+1 & year==year[_n+1]-1 & `v'==. & inlist(year,2009,2011,2013,2015,2017)
}

gen honestymath = statemath-naepmath
gen honestyread = stateread-naepread

ren mathnum nummath
ren readnum numread

reshape long state num naep naepscale honesty, i(fips year grade) j(subj) str

*Make list of average honesty gap (across 4 tests) by state in 2018-19
preserve
keep if year==2018
collapse state naep honesty [fw=num], by(fips)
export excel using "${pathout}honestygap2019.xls", first(var) replace
restore

sort fips subj grade year
gen honestychange = honesty-honesty[_n-1] if fips==fips[_n-1] & grade==grade[_n-1] & subj==subj[_n-1] & year==year[_n-1]+1 

*Flag observations when honesty gap decreased by at least 30 points
gen bigch=(honestychange<-30)
bys fips subj grade: egen anych=max(bigch)

*Drop state*subj*grade groups without a big change
drop if anych==0 /* 1433 obs dropped */

*Can't number of subjects*grades that experienced big change
bys fips: egen numch=sum(bigch)

*Recenter time at year of most recently big change
gen var = year if bigch==1
bys fips subj grade: egen maxyr = max(var)
bys fips subj grade: egen minyr = min(var) /* No states had more than one big change */
drop minyr
drop var
gen t = year-maxyr
gen post = (t>=1)
gen tpost=t*post

keep if state~=. & naep~=.

preserve
gen countstate=1
collapse naep state naepscale (rawsum) countstate [fw=num], by(grade subj t)
drop if abs(t)>4
g g2 = "Grade 4" if grade == 4
replace g2 = "Grade 8" if grade == 8
g subj2 = "Math" if subj == "math"
replace subj2 = "Reading" if subj == "read"
line naep state t, by(g2 subj2, ixaxes note("") graphregion(color(white) fcolor("255 255 255"))) ///
	lcolor("22 150 210" "0 0 0") ///
	ytitle("Proficiency rate") ///
	ylabel(, angle(0)) ///
	xlabel(, angle(0) valuelabel grid) ///
	xtitle("Time since biggest change") ///
	legend(order(1 "NAEP" 2 "State test")) ///
	graphregion(color(white)) bgcolor(white)
graph export "${pathout}fig1.pdf", as(pdf) replace
export excel using "${pathout}fig1data.xls", first(var) replace
restore

*Make list of state changes
preserve
keep if t==0
keep fips year grade subj honestychange
tostring grade, replace force
gen subjgrade=subj+grade
drop subj grade
reshape wide year honestychange, i(fips) j(subjgrade) str
export excel using "${pathout}honestygap.xls", first(var) replace
restore

*Look by state for states that changed for all 4 grades*subjects, collapse across 4 tests
preserve
keep if numch==4
collapse state naep naepscale [fw=num], by(fips year t)
line naep state year, by(fips, note("") ixaxes graphregion(color(white) fcolor("255 255 255"))) ///
	lcolor("22 150 210" "0 0 0") ///
	ytitle("Proficiency rate") ///
	ylabel(, angle(0)) ///
	xlabel(2009 2013 2017, angle(0)) ///
	xtitle("Year") ///
	legend(order(1 "NAEP" 2 "State Test")) ///
	graphregion(color(white) fcolor("255 255 255")) bgcolor("255 255 255")
graph export "${pathout}fig2.pdf", as(pdf) replace
export excel using "${pathout}fig2data.xls", first(var) replace
restore