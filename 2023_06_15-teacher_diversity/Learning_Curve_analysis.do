********************************************************************************

	// Melanie Rucinski
	// Analysis for Learning Curve essay
	// Last modified 4/30/23

********************************************************************************

clear all
set more off

// Set directories
	global wd "****"
	global data "$wd/stata_files"
	global raw "$data/raw"
	global clean "$data/clean"
	global temp "$data/temp"
	
	global out "****"
	
// Set what to run
	local fig1 = 0 // racial gaps in passing CLST
	local fig2 = 0 // racial gaps in college graduation
	local fig3 = 0 // gaps in licensure--waterfall; subject tests
	local fig4 = 1 // simulations

	
// Step 1: Racial gaps in Comm/Lit pass rates
if `fig1' {
	local fnum=1
	
	// bar graph of pass on first try, ever pass
	
	use "$clean/pipeline_merged.dta" if inrange(year12,2003,2013) & mtel==1, clear
	
	gen firstpass=tresult==1
	replace firstpass=rresult if tresult==. & rresult!=. & wresult==.
	replace firstpass=wresult if tresult==. & rresult==. & wresult!=.
		// deferring to the tresult variable when it is not missing
		// creates a small number of cases where e.g. tresult=0, rresult=., wresult=1
	replace firstpass=. if tresult==. & rresult==. & wresult==.
	
	// tab pass rates by race
	tab race5 firstpass, row m
	
	// tab licensure rates by race for those who pass
	tab race5 ever_any if teverpass==1, row m

	gen retookcond=retook if firstpass==0 // retaking conditional on failing the first time
	
	*gen teverpasscond=teverpass if retook==1
	
	gen race5=race
	replace race5=3 if inrange(race,5,8)
	replace race5=4 if race==3
	replace race5=5 if race==4
	
	preserve
	
		collapse firstpass retookcond teverpass, by(race5)
		
		rename (firstpass retookcond teverpass) (v1 v2 v3)
		replace v1=v1*100
		replace v2=v2*100
		replace v3=v3*100
		
		graph bar v1 v2 v3, over(race5, relabel(1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other") label(labsize(small))) ///
			bar(1, color(navy)) bar(2, color(ltblue)) bar(3, color(teal)) ///
			legend(label(1 "Passed first attempt") label(2 "Retook if failed") label(3 "Ever passed") ///
			rows(1) size(small) region(lstyle(none)) symxsize(.1cm)) ///
			ylabel(0(20)100, grid gmin gmax) ytitle("Percent") graphregion(color(white)) plotregion(color(white)) name(lc_fig`fnum', replace)
		graph export "$out/lc_fig`fnum'.png", name(lc_fig`fnum') replace
		
	restore
}

// Step 2: Racial gaps in graduation
if `fig2' {
	
	local fnum=2
	
	// graduation outcomes -- full sample graduation rates by race for mention in text
	use "$clean/pipeline_merged.dta" if inrange(year12,2003,2013), clear
	
	tab race5 ever_4yr, row
	
	tab race5 evergrad_4, row
	
	// CLST sample for figures
	use "$clean/pipeline_merged.dta" if inrange(year12,2003,2013) & mtel==1, clear
	
	gen takebefore=testdate<graddate_4yr
	egen temp=rowmax(rpassdate wpassdate) // take later of the two subject test pass dates for those missing testdate
	gen passbefore=tpassdate<graddate_4yr
	replace passbefore=1 if temp<graddate_4yr & tpassdate==. & temp!=.
	replace passbefore=0 if teverpass==0
	drop temp
	
	// take before/pass before figure
	replace takebefore=takebefore*100
	replace passbefore=passbefore*100
	
	graph bar (mean) takebefore passbefore , ///
		over(race5, relabel(1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other/multiple")) ///
		bar(1, color(navy)) bar(2, color(ltblue)) ///
		legend(label(1 "Take before graduation") label(2 "Pass before graduation") region(lstyle(none)) symxsize(.1cm)) ///
		ylabel(0(20)60, grid gmin gmax) ytitle("Percent") graphregion(color(white)) plotregion(color(white)) name(lc_fig`fnum'a, replace)
	graph export "$out/lc_fig`fnum'a.png", name(lc_fig`fnum'a) replace
	
	// 4-year graduation variables separately by whether passed Comm/Lit in college (bring back full sample)
	use "$clean/pipeline_merged.dta" if inrange(year12,2003,2013), clear 
	
	gen takebefore=testdate<graddate_4yr
	egen temp=rowmax(rpassdate wpassdate)
	gen passbefore=tpassdate<graddate_4yr
	replace passbefore=1 if temp<graddate_4yr & tpassdate==. & temp!=.
	replace passbefore=0 if teverpass==0
	drop temp
	
	gen evergrad_4_cl = evergrad_4*100 if passbefore==1 // ever graduated variable for those who passed before
	gen evergrad_4_nt = evergrad_4*100 if mtel==0 & ever_4yr==1 // comparison: never took CLST
		// people who took CLST in college but did not pass are omitted. they are a pretty small group
	
	graph bar (mean) evergrad_4_cl evergrad_4_nt , ///
		over(race5, relabel(1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other/multiple")) ///
		bar(1, color(navy)) bar(2, color(ltblue)) ///
		legend(label(1 "Passed CLST") label(2 "Never took CLST") region(lstyle(none)) symxsize(.1cm)) ///
		ylabel(0(20)60, grid gmin gmax) ytitle("Percent") graphregion(color(white)) plotregion(color(white)) name(lc_fig`fnum'b, replace)
	graph export "$out/lc_fig`fnum'b.png", name(lc_fig`fnum'b) replace
	
}

// Step 3: Licensure/subject tests
if `fig3' {
	
	local fnum=3
	
	use "$clean/pipeline_merged.dta" if inrange(year12,2003,2013) & mtel==1, clear
	
	// subject tests
	preserve
		use "$clean/mtel_clean.dta", clear

		// Number of tests ever taken and number of tests passed
		qui bys mepid: egen ntests = nvals(testcode)
		qui bys mepid: egen npass  = total(teverpass)
		
		// Keep one row for each teacher
		keep if test_type==1
		replace npass = npass - 1 if teverpass==1 // Subtract 1 from # of tests passed for teachers who passed Comm/Lit
		assert npass >=0 & npass!=.
		
		// Keep variables to merge to full pipeline data 
		keep mepid npass ntests
		
		tempfile tests
		save `tests', replace
	
	restore
				
	merge m:1 mepid using `tests'
		// This is a m:1 rather than 1:1 merge because a (very) small number of student IDs link to multiple teacher IDs, and vice versa
		// For now, my solution to this is to take the maximum value of passing the test, getting a license, etc. for each student ID
	
	gen pass_other=npass>0 & npass<.
	gen take_other=ntests>1 & ntests<. // ntests includes CLST so if ntests=1, only took CLST
	
	tab race5 take_other if teverpass==1, row m
	tab race5 pass_other if teverpass==1, row m
	tab race5 pass_other if teverpass==1 & take_other==1, row m	
	
	// waterfall figure for alums
		preserve
		keep if inrange(year12,2003,2013) & mtel==1 // restricts to people actually observed in SIMS in relevant years, who took Comm/Lit
				
		foreach var of varlist maxgrad_hs ever_4yr evergrad_4 mtel teverpass pass_other ever_any ever_teacher retain_3yrs {
			replace `var'=0 if missing(`var')
		}
		
		rename (mtel  teverpass pass_other ever_any ever_teacher retain_3yrs) ///
			   (step1 step2     step3      step4    step5        step6)
		
		keep race5 sasid step*
		
		** COLLAPSE FOR DUPLICATES **
		collapse (max) step*, by(sasid race5) // because of SASIDs attached to multiple MEPIDs, see note above
		reshape long step, i(sasid) j(n)
		
		collapse step, by(race5 n)
		
		replace step=step*100
		
		// all stages
		
		twoway (scatter step n if race5==1, connect(l) lcolor(navy) mcolor(navy) msymbol(O)) ///
			   (scatter step n if race5==2, connect(l) lcolor(ltblue) mcolor(ltblue) msymbol(S)) ///
			   (scatter step n if race5==3, connect(l) lcolor(teal) mcolor(teal) msymbol(D)) ///
			   (scatter step n if race5==4, connect(l) lcolor(olive_teal) mcolor(olive_teal) msymbol(T)) ///
			   (scatter step n if race5==5, connect(l) lcolor(gs10) mcolor(gs10) msymbol(+)), ///
			   ytitle("% of Comm/Lit takers") xtitle("") ///
			   xlabel(1 `""Took" "CLST""' 2 `""Passed" "CLST""' 3 `""Passed" "subj. test""' 4 `""Earned" "license""' ///
					  5 `""Hired as" "teacher""' 6 `""Taught for" "3+ years""', labsize(small)) ///
			   legend(/*order (1 3 5 2 4)*/ label(1 "White") label(2 "Black") label(3 "Hispanic") label(4 "Asian") label(5 "Other") ///
			   rows(1) size(small) region(lstyle(none)) symxsize(.1cm)) ///
			   ylabel( , grid gmin gmax) graphregion(color(white) m(r+4)) plotregion(color(white)) name(lc_fig`fnum', replace)
		graph export "$out/lc_fig`fnum'.png", name(lc_fig`fnum') replace
		
		restore	
	
	// subject tests figure (take/pass)
	
	local fnum=4
	
	preserve 
	
	keep if inrange(year,2003,2013) & teverpass==1
	
	replace pass_other=pass_other*100
	replace take_other=take_other*100
	
	graph bar (mean) take_other pass_other, over(race5, relabel(1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other") label(labsize(small))) ///
		bar(1, color(navy)) bar(2, color(ltblue)) ///
		legend(label(1 "Took any") label(2 "Passed any") ///
		rows(1) size(small) region(lstyle(none)) symxsize(.1cm)) ///
		ylabel(0(20)100, grid gmin gmax) ytitle("Percent") graphregion(color(white)) plotregion(color(white)) name(lc_fig`fnum', replace)
	graph export "$out/lc_fig`fnum'.png", name(lc_fig`fnum') replace	
	
	restore
	
}

// Simulations
if `fig4' {
	local fnum=4
	use "$clean/pipeline_merged.dta" if inrange(year12,2003,2013) & mtel==1, clear
	
	/* simulation list:
		1. no gap in CLST passing
		2. no gap in 4-year degree | pass CLST while in college
		3. no gap in taking subject tests | pass CLST
		4. no gap in passing subject tests | pass CLST (close both taking & passing gaps)
		5. no gap in licensure | CLST pass
		6. close all test-related gaps
		7. close all gaps post taking CLST
	*/

	// replace non-Hisp race variables with 0 if Hisp=1
	label var hisp "Hispanic"
	foreach x in black asian white oth_mult {
		replace `x'=0 if hisp==1
	}
	
********************************************************************************	
	// panel a: close the gap with White teaching candidates
********************************************************************************	
	local mname "fig`fnum'a"
	mat `mname'=J(8,5,.)
	
	// store the share of test-takers by race
	foreach x in black hisp asian oth_mult white {
		qui su `x'
		local s`x'=r(mean)
	}
	
	// share of license-holders by race (in reality)
	local c=1
	foreach x in black hisp asian oth_mult white {
		qui su `x' if ever_any==1
		mat `mname'[1,`c']=r(mean)*100
		local ++c
	}
	
	// 1. gap in CLST passing
	qui su teverpass if white==1 // White CLST pass rate
	local wpass=r(mean)
	local tot=0 // New total number of license holders
	foreach x in black hisp asian oth_mult white {
		qui su ever_any if `x'==1 & teverpass==1 // Take the true Pr(License|Pass) by race
		local `x'lic = r(mean)
		qui count if `x'==1 // count the number of CLST takers
		local tsim`x'=r(N)*`wpass'*``x'lic' // Simulated licensure number = true N * White pass rate * race-specific licensure rate
		local tot=`tot'+`tsim`x'' // Add simulated number to simulated total
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[2,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 2. no gap in earning a 4-year degree | passing CLST before earning a degree
		// generate passbefore variable 
		egen temp=rowmax(rpassdate wpassdate)
		gen passbefore=tpassdate<graddate_4yr
		replace passbefore=1 if temp<graddate_4yr & tpassdate==. & temp!=.
		drop temp
		
	qui su evergrad_4 if white==1 & passbefore==1
	local wgr=r(mean)
	local tot=0
	foreach x in black hisp asian oth_mult white {
		qui su ever_any if `x'==1 & evergrad_4==1 & passbefore==1
			// license rate among those who pass before *and* earn the degree
		local `x'lic = r(mean)
		qui count if `x'==1 & passbefore==1
			// total number who pass before
		local tsim`x'=r(N)*`wgr'*``x'lic'
			// number who pass before * White graduation rate * true Pr(license | pass before and earn degree)
		// now add people who pass CLST after and earn a license 
		qui count if `x'==1 & passbefore==0 & ever_any==1
		local tsim`x'=`tsim`x'' + r(N)
		// and add to total
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[3,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

	// 3. closing gap in subject test taking among those who pass CLST
		// need to merge on test data
		preserve
			use "$clean/mtel_clean.dta", clear

			// Number of tests ever taken and number of tests passed
			qui bys mepid: egen ntests = nvals(testcode)
			qui bys mepid: egen npass  = total(teverpass)
			
			// Keep one row for each teacher
			keep if test_type==1
			replace npass = npass - 1 if teverpass==1 // Subtract 1 from # of tests passed for teachers who passed Comm/Lit
			assert npass >=0 & npass!=.
			
			// Keep variables to merge to full pipeline data 
			keep mepid npass ntests
			
			tempfile tests
			save `tests', replace
		restore		
		merge m:1 mepid using `tests', keep(match master)
			// note: master-only obs at this point come from SASIDs that matched to multiple MEPIDs where one MEPID was fake (generated by me based on name and birthdate for someone missing a MEPID in the raw MTEL data)
			// if only the fake MEPID is in MTEL data, I will miss those people here
			// it's a small number, .7%
			// they are slightly disproportionately likely to be Black or Hispanic, but not very much
		
		gen pass_other=npass>0 & npass<.
		gen take_other=ntests>1 & ntests<. // ntests not corrected to exclude Comm/Lit so if ntests=1, only took Comm/Lit
	
	// now do the actual simulation
	qui su take_other if white==1 & teverpass==1 // White take rate among CLST passers
	local wtake=r(mean)
	local tot=0
	foreach x in black hisp asian oth_mult white {
		qui su ever_any if `x'==1 & teverpass==1 & take_other==1 // condition on both passing CLST & taking a subject test
		local `x'lic = r(mean)
		qui count if `x'==1 & teverpass==1 // not closing gap in passing CLST -> restrict to those who passed
		local tsim`x'=r(N)*`wtake'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[4,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 4. closing gap in *passing* subject tests, in combination with taking (not conditional on taking)
	qui su pass_other if white==1 & teverpass==1
	local wpass=r(mean)
	local tot=0
	foreach x in black hisp asian oth_mult white {
		qui su ever_any if `x'==1 & teverpass==1 & pass_other==1
		local `x'lic = r(mean)
		qui count if `x'==1 & teverpass==1
		local tsim`x'=r(N)*`wpass'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[5,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 5. closing gap in licensure conditional on passing CLST (different from simulation in paper, which only conditions on taking)
		// this also implicitly addresses gaps in subject test behavior
	qui su ever_any if white==1 & teverpass==1
	local wlic=r(mean)
	local tot=0
	foreach x in black hisp asian oth_mult white {
		qui count if `x'==1 & teverpass==1
		local tsim`x' = r(N)*`wlic'
		local tot=`tot' + `tsim`x''
		// simpler than other simulations: just apply White likelihood of licensure to those who actually passed the test
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[6,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 6. close all test-related gaps in combination: passing CLST, passing subject tests (which also accounts for taking gap)
	gen pass_all=teverpass==1 & pass_other==1
	qui su pass_all if white==1
	local wpass=r(mean)
	local tot=0
	foreach x in black hisp asian oth_mult white {
		qui su ever_any if `x'==1 & pass_all==1
		local `x'lic = r(mean)
		qui count if `x'==1
		local tsim`x'=r(N)*`wpass'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[7,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

	// 7. close all gaps: apply White licensure probability unconditionally
	qui su ever_any if white==1
	local wlic=r(mean)
	local tot=0
	foreach x in black hisp asian oth_mult white {
		qui count if `x'==1 // all CLST takers
		local tsim`x'=r(N)*`wlic' // CLST takers x White licensure rate
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[8,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

********************************************************************************	
	// panel b: retain 1/2 of lost candidates at each stage
********************************************************************************	
	
	// For simulations below, instead of applying White pass/take/license rates to candidates of color, just take the algebraic mean of the true rate and 1 to close half the gap
	
	local mname "fig`fnum'b"
	mat `mname'=J(8,5,.)
	
	foreach x in black hisp asian oth_mult white {
		qui su `x'
		local s`x'=r(mean)
	}
	
	local c=1
	foreach x in black hisp asian oth_mult white {
		qui su `x' if ever_any==1
		mat `mname'[1,`c']=r(mean)*100
		local ++c
	}
	
	// 1. gap in CLST passing
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su teverpass if `x'==1
		local simpass=(1 + r(mean))/2
		qui su ever_any if `x'==1 & teverpass==1
		local `x'lic = r(mean)
		qui count if `x'==1
		local tsim`x'=r(N)*`simpass'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[2,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 2. gap in earning a 4-year degree | passing CLST while in college
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su evergrad_4 if `x'==1 & passbefore==1
		local simgr=(1 + r(mean))/2
		qui su ever_any if `x'==1 & evergrad_4==1 & passbefore==1
			// license rate among those who pass before *and* earn the degree
		local `x'lic = r(mean)
		qui count if `x'==1 & passbefore==1
			// total number who pass before
		local tsim`x'=r(N)*`simgr'*``x'lic'
			// number who pass before * simulated graduation rate * true Pr(license | pass before and earn degree)
		// now add people who pass CLST after and earn a license 
		qui count if `x'==1 & passbefore==0 & ever_any==1
		local tsim`x'=`tsim`x'' + r(N)
		// and add to total
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[3,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

	// 3. closing gap in subject test taking among those who pass CLST
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su take_other if `x'==1 & teverpass==1
		local simtake=(1 + r(mean))/2
		qui su ever_any if `x'==1 & teverpass==1 & take_other==1 // condition on both passing CLST & taking a subject test
		local `x'lic = r(mean)
		qui count if `x'==1 & teverpass==1 // not closing gap in passing CLST -> restrict to those who passed
		local tsim`x'=r(N)*`simtake'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[4,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 4. closing gap in *passing* subject tests, in combination with taking (not conditional on taking)
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su pass_other if `x'==1 & teverpass==1
		local simpass=(1 + r(mean))/2
		qui su ever_any if `x'==1 & teverpass==1 & pass_other==1
		local `x'lic = r(mean)
		qui count if `x'==1 & teverpass==1
		local tsim`x'=r(N)*`simpass'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[5,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 5. closing gap in licensure conditional on passing CLST (different from simulation in paper, which only conditions on taking for some reason)
		// this also implicitly addresses gaps in subject test behavior, not sure whether that's what I want or not??
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su ever_any if `x'==1 & teverpass==1
		local simlic=(1 + r(mean))/2
		qui count if `x'==1 & teverpass==1
		local tsim`x' = r(N)*`simlic'
		local tot=`tot' + `tsim`x''
		// simpler than other simulations: just apply White likelihood of licensure to those who actually passed the test
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[6,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 6. close all test-related gaps in combination: passing CLST, passing subject tests (which also accounts for taking gap)
	qui count if white==1 & ever_any==1
	local tot=r(N)
	di "White total = " r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su pass_all if `x'==1
		di "`x' pass rate = " r(mean)
		local simpass=(1 + r(mean))/2
		qui su ever_any if `x'==1 & pass_all==1
		local `x'lic = r(mean)
		qui count if `x'==1
		local tsim`x'=r(N)*`simpass'*``x'lic'
		di "`x' simulated new total = " `tsim`x''
		local tot=`tot'+`tsim`x''
		di "New total = " `tot'
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[7,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

	// 7. close all gaps: apply White licensure probability unconditionally
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		qui su ever_any if `x'==1
		local simlic=(1 + r(mean))/2
		qui count if `x'==1 // all CLST takers
		local tsim`x'=r(N)*`simlic' // CLST takers x White licensure rate
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[8,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
********************************************************************************	
	// panel c: retain all lost candidates at each stage
********************************************************************************	
	// in simulations below, simulated pass/take/license rate will just equal 1
	
	local mname "fig`fnum'c"
	mat `mname'=J(8,5,.)
	
	foreach x in black hisp asian oth_mult white {
		qui su `x'
		local s`x'=r(mean)
	}
	
	local c=1
	foreach x in black hisp asian oth_mult white {
		qui su `x' if ever_any==1
		mat `mname'[1,`c']=r(mean)*100
		local ++c
	}
	
	// 1. gap in CLST passing
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simpass=1
		qui su ever_any if `x'==1 & teverpass==1
		local `x'lic = r(mean)
		qui count if `x'==1
		local tsim`x'=r(N)*`simpass'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[2,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 2. gap in earning a 4-year degree | passing CLST while in college
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simgr=1
		qui su ever_any if `x'==1 & evergrad_4==1 & passbefore==1
			// license rate among those who pass before *and* earn the degree
		local `x'lic = r(mean)
		qui count if `x'==1 & passbefore==1
			// total number who pass before
		local tsim`x'=r(N)*`simgr'*``x'lic'
			// number who pass before * simulated graduation rate * true Pr(license | pass before and earn degree)
		// now add people who pass CLST after and earn a license 
		qui count if `x'==1 & passbefore==0 & ever_any==1
		local tsim`x'=`tsim`x'' + r(N)
		// and add to total
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[3,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

	// 3. closing gap in subject test taking among those who pass CLST
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simtake=1
		qui su ever_any if `x'==1 & teverpass==1 & take_other==1 // condition on both passing CLST & taking a subject test
		local `x'lic = r(mean)
		qui count if `x'==1 & teverpass==1 // not closing gap in passing CLST -> restrict to those who passed
		local tsim`x'=r(N)*`simtake'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[4,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 4. closing gap in *passing* subject tests, in combination with taking (not conditional on taking)
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simpass=1
		qui su ever_any if `x'==1 & teverpass==1 & pass_other==1
		local `x'lic = r(mean)
		qui count if `x'==1 & teverpass==1
		local tsim`x'=r(N)*`simpass'*``x'lic'
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[5,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 5. closing gap in licensure conditional on passing CLST (different from simulation in paper, which only conditions on taking for some reason)
		// this also implicitly addresses gaps in subject test behavior, not sure whether that's what I want or not??
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simlic=1
		qui count if `x'==1 & teverpass==1
		local tsim`x' = r(N)*`simlic'
		local tot=`tot' + `tsim`x''
		// simpler than other simulations: just apply White likelihood of licensure to those who actually passed the test
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[6,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	// 6. close all test-related gaps in combination: passing CLST, passing subject tests (which also accounts for taking gap)
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simpass=1
		qui su ever_any if `x'==1 & pass_all==1
		local `x'lic = r(mean)
		qui count if `x'==1
		local tsim`x'=r(N)*`simpass'*``x'lic'
		di "`x' simulated new total = " `tsim`x''
		local tot=`tot'+`tsim`x''
		di "New total = " `tot'
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[7,`c']=(`tsim`x''/`tot')*100
		local ++c
	}

	// 7. close all gaps: apply White licensure probability unconditionally
	qui count if white==1 & ever_any==1
	local tot=r(N)
	foreach x in black hisp asian oth_mult /*white*/ {
		local simlic=1
		qui count if `x'==1 // all CLST takers
		local tsim`x'=r(N)*`simlic' // CLST takers x White licensure rate
		local tot=`tot'+`tsim`x''
	}
	local c=1
	foreach x in black hisp asian oth_mult white {
		mat `mname'[8,`c']=(`tsim`x''/`tot')*100
		local ++c
	}
	
	
	// make figure
	foreach mname in fig`fnum'a fig`fnum'b fig`fnum'c {
		clear
		svmat `mname'
		
		rename (`mname'1 `mname'2 `mname'3 `mname'4 `mname'5) (black hisp asian other white)
		label var black "Black"
		label var hisp "Hispanic"
		label var asian "Asian"
		label var other "Other/multiracial"
		label var white "White"
		
		gen sim=_n
		
		graph bar black hisp asian other, stack over(sim, ///
			relabel(1 `"Actual"' ///
					2 `""CLST" "Passing""' ///
					3 `""4-year" "Degree""' ///
					4 `""Subj. test" "Taking""' ///
					5 `""Subj. test" "Passing""' ///
					6 `""Earned" "License""' ///
					7 `""All test" "Gaps""' ///
					8 "All Gaps") ///
					label(labsize(small))) ///
			/*bar(1, color(navy))*/ bar(1, color(ltblue)) bar(2, color(teal)) bar(3, color(olive_teal)) bar(4, color(ltbluishgray)) ///
			legend(/*label(1 "White")*/ label(1 "Black") label(2 "Hispanic") label(3 "Asian") label(4 "Other/multiple") ///
				rows(1) size(small) region(lstyle(none)) symxsize(.1cm)) ///
			ylabel(0(5)15, grid gmin gmax) ///
			ytitle("Percent") graphregion(color(white)) plotregion(color(white)) name(lc_`mname', replace)
		graph export "$out/lc_`mname'.png", name(lc_`mname') replace
	}
	
}
