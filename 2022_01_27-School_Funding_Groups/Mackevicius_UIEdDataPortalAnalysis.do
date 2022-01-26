/*
********************************************************************************
********************************************************************************
Data-Driven Analysis of Timely Education Policy Topics
Understanding How School-Specific Supplemental Fundraising Organizations Exacerbate Inequitable Resource Distribution

Analysis
********************************************************************************
********************************************************************************
*/
**ADJUST THIS
global path "/Users/clairemackevicius/Box Sync/GRAD SCHOOL/Research/Mackevicius UI Blog PTA Descriptive"

use "${path}/IL_SchoolOrgMerge", clear

cd "${path}/Figures"
/******
FIGURES
*******/
//average spend in per-pupil terms, first histogram
sum Org_PPE if Org_PPE != 0, d
local avg_spend = round(r(mean), .01)
sum Org_PPE if Org_PPE >  r(p75)
local max_spend = round(r(mean), .01)

histogram Org_PPE if Org_PPE > 0, freq title("PTAs Spend on Average $`avg_spend' per Student," "though the top 25% spend an average of $`max_spend'") bin(35) ytitle("Number of Organizations") xscale(range(0(200)1200)) xlabel(0(200)1200) xline(`max_spend') xline(`avg_spend') text(140 450 "Top 25% of Organizations -->", size(small)) text(140 160 "Average", size(small))
graph export ILOrgsSpend_hist.pdf, replace
graph export ILOrgsSpend_hist.png, replace

//count of organizations, second histogram
histogram ShareLI if !missing(Org_PPE ), freq title("There are more PTAs at Wealthier-Serving Schools") xtitle("Share of Students Free- and Reduced-Price-Lunch Eligible") ytitle("Number of Organizations")
graph export ILOrgs_Hist.pdf, replace
graph export ILOrgs_Hist.png, replace

//spend more at wealthier-serving schools, first scatter
preserve
gen LIind = 0
forvalues i = 25(-1)0{
	local lowerRange = 1-(`i'*.04)
	local upperRange = 1.04-(`i'*.04)
	di "Range from `lowerRange' to `upperRange'"
	replace LIind = `i' if ShareLI > `lowerRange' & ShareLI <= `upperRange'
}
replace LIind = abs(LIind - 24)
collapse (mean) Org_PPE (count) ein, by(LIind)
twoway (scatter Org_PPE LIind, msymbol(circle_hollow)) (lfit Org_PPE LIind), title("PTAs Spend More at Wealthier-Serving Schools") ytitle("Organization Per Pupil Expenditure") xtitle("Share of Students Free- and Reduced-Price-Lunch Eligible") yscale(range(0(50)200)) ylabel(0(50)200) xlabel(0 "0" 5 "0.2" 10 "0.4" 15 "0.6" 20 "0.8" 25 "1") legend(off) 
restore
graph export ILOrgs_LIscatter.pdf, replace
graph export ILOrgs_LIscatter.png, replace

//spend more at relatively whiter schools, second scatter
preserve
bysort leaid: egen ventileWhite = xtile(shareWhite), nq(25)
bysort leaid: egen distnumOrgs = sum(hasPTOOrg)
gen distHasatleastPTO = distnumOrgs > 0
keep if distHasatleastPTO
collapse (mean) Org_PPE distnumOrgs, by(ventileWhite)
twoway (scatter Org_PPE ventileWhite ) (lfit Org_PPE ventileWhite), title("PTAs Spend More at Relatively Whiter Schools Within the District") ytitle("Organization Per Pupil Expenditure") xtitle("A Schoool's Relative Racial Composition" "(Within-District)") xlabel(0 " " 1 `" "Relatively"  "Less White" "' 24 `" "Relatively"  "More White" "' 25 " ", noticks) yscale(range(0(50)300)) legend(off) ylabel(0(50)300)
restore
graph export ILOrgs_ShareWhitescatter.pdf, replace
graph export ILOrgs_ShareWhitescatter.png, replace


/******
BENCHMARKING (reference points in text)
*******/
//"some schools receive no extra dollars while others get more than an additional $50,000 from supplemental fundraising"
sum exps

//"they total more than $35 million"
preserve
collapse (sum) exps
sum exps
restore

//"In extreme cases, they already supplement school budgets by more than 10%"
gen shareBudget = Org_PPE/pp_total_raw_IL
sum shareBudget, d

//"spend on average just over $100 per student"
sum Org_PPE

//"I find in my sample that many smaller school-supporting fundraising organizations do still file with the IRS"
count if ass_eoy < 50000

//"Spending by these organizations represents an average extra 7% on top of allocated state and local non-personnel, discretionary funds, and the very largest contribute an additional 20%"
gen shareNonPers = (1-propexp_salben)*pp_total_raw_IL
gen shareDiscretion = Org_PPE/shareNonPers
sum shareDiscretion, d

//"More than half of school-specific fundraising groups (60%) are associated with schools serving the wealthiest 25% of students. Put differently, the wealthiest-serving quarter of schools have a nearly 40% likelihood of having an associated fundraising group, while the poorest-serving have just a 2% chance."
sum ShareLI, d
local richestQuart = r(p25)
local poorestQuart = r(p75)
count if !missing(ein) & ShareLI < `richestQuart'
count if !missing(ein) & ShareLI > `poorestQuart'
count if !missing(ein)
di 344/591
di 21/591

count if ShareLI < `richestQuart'
di 344/r(N)
count if ShareLI > `poorestQuart'
di 21/r(N)

//"organizations associated with the wealthiest quarter of schools and they spend much more, an average of $123 per pupil, than the fewer organizations at the poorest quarter of schools that spend less than $50 per pupil"
sum Org_PPE if ShareLI < `richestQuart'
sum Org_PPE if ShareLI > `poorestQuart'

//as an exemplar consider North Shore School District 112
sort shareWhite
br shareWhite exps Org_PPE ein if lea_name == "North Shore SD 112" & school_level == 1
