*************************************************
* WF Qualifications Project
* Erica Greenberg
* 12.21.2021 - 1.25.2022
*************************************************

clear all

global cleaning = "P:\8939\4001_Greenberg\NORC\Do"
global data = "P:\8939\4001_Greenberg\NORC\Data"
global raw = "P:\8939\4001_Greenberg\NORC\Data\raw"
global review = "P:\8939\4001_Greenberg\NORC\Disclosure review\Files to review"
global build = "P:\8939\4001_Greenberg\NORC\Data\build"
global data19 = "P:\8939\4001_Greenberg\NORC\Data\Public Use Data\Data files\2019"
global output = "P:\8939\4001_Greenberg\NORC\Data\output"



********************************************************
* CLEAN AND IMPORT DATA
********************************************************

do "$cleaning\cleaning.do"

cap: erase "$output\regressions.xls"

* program types: FCC, centers, PK, HS/EHS (any), FCC CCDF (any), centers CCDF (any)
* years: 2012, 2019

foreach year in 2012 2019 {
	
	foreach type in hb cb pk hs hccdf cccdf {
		
		use "$build/`type'_`year'_wreq.dta", clear
		merge m:1 statename year using "$data\Uploaded materials\supplementaldata.dta", keep(match)


********************************************************
* REGRESSIONS BY YEAR
********************************************************

		*svyset `type'_meth_vpsu [pweight = `type'_meth_weight], strata(`type'_meth_vstratum) singleunit(scaled)

		loc controls unemploy poverty femearnings qsetaside teach wagestate

		foreach outcome in education experience ofcolor hispanic motivation1 motivation2 ///
		motivation3 motivation4 wageincome emphins {	 
		 
			reg `outcome' FCCreq CCreq PKreq
			test FCCreq CCreq PKreq
			estadd scalar F_test = r(F)
			estadd scalar P_value = r(p)
			eststo `type'`year'_`outcome'_base

			reg `outcome' FCCreq CCreq PKreq `controls'			
			test FCCreq CCreq PKreq
			estadd scalar F_test = r(F)
			estadd scalar P_value = r(p)
			eststo `type'`year'_`outcome'_wctrl

		}

		estout `type'`year'_education* `type'`year'_experience* `type'`year'_ofcolor* `type'`year'_hispanic* ///
		`type'`year'_motivation* `type'`year'_wageincome* `type'`year'_emphins* ///
			using "$output\regressions_noweight.xls", append ///
			cells(b(fmt(3) star) se(fmt(3) par(`"="("'`")""'))) stats(Controls F_test P_value r2 N) ///
			starlevels (+ 0.10 * 0.05 ** 0.01 *** 0.001) stardetach	
			
	}
}
