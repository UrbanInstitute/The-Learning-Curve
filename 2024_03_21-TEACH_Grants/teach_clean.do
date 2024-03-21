/*******************************************************************************
********************************************************************************
Project			: TEACH Grant
Author			: DS               
Last Update		: February 2024
Purpose         : Learning curve analysis file
********************************************************************************
*******************************************************************************/
clear all
set more off

/*------------------------------------------------------------------------------
Set globals/directory structure
------------------------------------------------------------------------------*/

gl ds   	 "*****"


gl data		 "${ds}/data/"
gl graphs    "${ds}/vis/"

foreach var in data graphs {
	cap n mkdir "${`var'}"
}

graph set window fontface "Lato"


/*------------------------------------------------------------------------------
Analysis
------------------------------------------------------------------------------*/
use "${ds}/teach_grant_s1.dta" , clear

*figure 1 and corresponding stats: trends in TEACH recipients, BA and MA ed awards

preserve

collapse (sum) teach_recipients ba_edu_all ma_edu_all , by(year)

tw (line teach_recipients year, lcolor("22 150 210") msymbol(i)) ///
   (line ba_edu_all year, lcolor("0 0 0") msymbol(i)) ///
   (line ma_edu_all year, lcolor("253 191 17") msymbol(i)), legend(order(1 "TEACH recipients" 2 "Bachelor's Degrees" 3 "Master's Degrees") size(1.5)) ///
   yti("Number of Awards/Recipients", si(small)) ///
   ti("Trends in Education Awards & TEACH Grant Recipients", si(small))
   
   graph export "${graphs}figure_1.png" , replace

egen edu_all = rowtotal(ba_edu_all ma_edu_all)
gen teach_pct = teach_recipients / edu_all
tabstat teach_pct , by(year) /*as a percentage of bachelor's and master's degrees in teaching, the proportion of teach recipients was 11 percent in 2022, down from a high of 16 percent in 2017. */

tabstat teach_recipients ba_edu_all ma_edu_all , by(year)
	
restore

preserve
	
	keep if teacher_cert_state_approved==1 & title_iv_indicator==1
	recode teach_recipients pell_recipients (.=0)
	gen teach = (teach_recipients>0)
	gen pell = (pell_recipients>0)
	tabstat teach pell, by(year) /*the TEACH grant participiation rate among institutions with approved teacher certification programs and that participate in title iv aid has similarly stagnated around 50 percent */

	egen edu_all = rowtotal(ba_edu_all ma_edu_all)
	collapse (sum) edu_all , by(year teach)
	bys year: egen all = sum(edu_all)
	gen edu_pct = edu_all / all
	tabstat edu_pct if teach==1, by(year) /*participating institutions are responsible for ~70 percent of ba and ma awards in teaching  */
	
restore

*figure 2 and corresponding stats: institutional participation rates by sector
preserve

keep if teacher_cert_state_approved==1 & title_iv_indicator==1

recode teach_recipients (.=0)
gen teach = (teach_recipients>0)

egen edu_all = rowtotal(ba_edu_all ma_edu_all)
gen teach_amt = teach_disb / edu_all

forval i = 2008(1)2022 {
tabstat teach if year==`i', by(SchoolType) stats(mean n)
	}

tab inst_name if SchoolType=="PROPRIETARY" & teach==1
tabstat teach_recipients teach_disb if SchoolType=="PROPRIETARY" & teach==1, by(inst_name) 

tab SchoolType if teach==1
tab SchoolType if teach==1 & year==2022

collapse teach teach_amt (sum) teach_disb edu_all , by(year SchoolType)

bys year : egen teach_disb_total = sum(teach_disb)
gen teach_disb_pct = teach_disb / teach_disb_total
bys year : egen edu_all_total = sum(edu_all)
gen edu_all_pct = edu_all / edu_all_total

tw (line teach year if SchoolType=="PRIVATE-NONPROFIT", lcolor("22 150 210") msymbol(i)) ///
   (line teach year if SchoolType=="PROPRIETARY", lcolor("0 0 0") msymbol(i)) ///
   (line teach year if SchoolType=="PUBLIC", lcolor("253 191 17") msymbol(i)), legend(order(1 "Private" 2 "For profit" 3 "Public")) ///
   yti("participation rate", si(small)) ti("Institutional Participation Rates in TEACH, by Sector", si(small)) ///
   ylab(0(.1)1)
  
   graph export "${graphs}figure_2.png" , replace
   
   tabstat teach if SchoolType=="PUBLIC", by(year)
   tabstat teach if SchoolType=="PRIVATE-NONPROFIT", by(year)
   tabstat teach if SchoolType=="PROPRIETARY", by(year)
   
   
tw (connect teach_disb_pct year if SchoolType=="PRIVATE-NONPROFIT", lcolor("22 150 210") msymbol(i)) ///
   (connect teach_disb_pct year if SchoolType=="PROPRIETARY", lcolor("0 0 0") msymbol(i)) ///
   (connect teach_disb_pct year if SchoolType=="PUBLIC", lcolor("253 191 17") msymbol(i)), legend(order(1 "Private" 2 "For profit" 3 "Public")) ///
   yti("proportion", si(small)) ti("Proportion of TEACH Disbursements, by Sector", si(small)) ///
   ylab(0(.1)1)
   
     graph export "${graphs}figure_2a.png" , replace
	 
	 *appendix table 1 stats for % of education awards and TEACH disbursements
	 tabstat edu_all_pct teach_disb_pct if SchoolType=="PUBLIC", by(year)
	 tabstat edu_all_pct teach_disb_pct if SchoolType=="PRIVATE-NONPROFIT", by(year)
	 tabstat edu_all_pct teach_disb_pct if SchoolType=="PROPRIETARY", by(year)
   
tw (connect teach_amt year if SchoolType=="PRIVATE-NONPROFIT", lcolor("22 150 210") msymbol(i)) ///
   (connect teach_amt year if SchoolType=="PROPRIETARY", lcolor("0 0 0") msymbol(i)) ///
   (connect teach_amt year if SchoolType=="PUBLIC", lcolor("253 191 17") msymbol(i)), legend(order(1 "Private" 2 "For profit" 3 "Public")) ///
   yti("TEACH Awards", si(small)) ti("TEACH Awards per Degree Completer, by Sector", si(small))
   
     graph export "${graphs}figure_2b.png" , replace
   
restore


*figure 3: tuition at participating and non-participating institutions
preserve
keep if teacher_cert_state_approved==1 & title_iv_indicator==1

recode teach_recipients (.=0)
gen teach = (teach_recipients>0)

xtile quartile=tuition_fees_istateug,n(4)
tabstat teach , by(quartile)
keep if year==2021
collapse tuition_fees_istateug tuition_fees_istategrad , by(teach)
graph bar tuition_fees_istateug tuition_fees_istategrad , over(teach) legend(order(1 "Undergraduate tuition" 2 "Graduate tuition")) ///
blabel(total,format(%9.0gc)) ///
bar(1, fcolor("22 150 210") lcolor("22 150 210")) ///
bar(2, fcolor("0 0 0") lcolor("0 0 0"))

graph export "${graphs}figure_4.png" , replace

restore

*figure 4: tcli schools within county
preserve
keep if teacher_cert_state_approved==1 & title_iv_indicator==1

recode teach_recipients (.=0)
gen teach = (teach_recipients>0)

keep if year==2022

gen tcli_cat = 1 if tcli_county_pct>=0 & tcli_county_pct<.25
replace tcli_cat = 2 if tcli_county_pct>=.25 & tcli_county_pct<.5
replace tcli_cat = 3 if tcli_county_pct>=.5 & tcli_county_pct<.75
replace tcli_cat = 4 if tcli_county_pct>=.75 & tcli_county_pct<=1

label define tcli_cat 1 "0-25%" 2 "25-50%" 3 "50-75%" 4 "75-100%"
label values tcli_cat tcli_cat 
tab tcli_cat /*<13% of schools are in counties with <50% tcli schools */

collapse teach , by(tcli_cat)
graph bar teach , over(tcli_cat) yti("Participation Rate", si(small)) ///
blabel(total,format(%12.2f)) ///
bar(1, fcolor("22 150 210") lcolor("22 150 210"))


graph export "${graphs}figure_5.png" , replace

restore


*appendix figure 1: weighted institutional participation rates by sector
		
preserve

keep if teacher_cert_state_approved==1 & title_iv_indicator==1

recode teach_recipients (.=0)
gen teach = (teach_recipients>0)

egen edu_all = rowtotal(ba_edu_all ma_edu_all)
gen teach_amt = teach_disb / edu_all

collapse teach teach_amt (sum) teach_disb [fweight=edu_all], by(year SchoolType)

bys year : egen teach_disb_total = sum(teach_disb)
gen teach_disb_pct = teach_disb / teach_disb_total

tw (line teach year if SchoolType=="PRIVATE-NONPROFIT", lcolor("22 150 210") msymbol(i)) ///
   (line teach year if SchoolType=="PROPRIETARY", lcolor("0 0 0") msymbol(i)) ///
   (line teach year if SchoolType=="PUBLIC", lcolor("253 191 17") msymbol(i)), legend(order(1 "Private" 2 "For profit" 3 "Public")) ///
   yti("participation rate", si(small)) ti("Institutional Participation Rates in TEACH, by Sector", si(small)) ///
   ylab(0(.1)1)

graph export "${graphs}figure_2_weights.png" , replace

tw (connect teach_disb_pct year if SchoolType=="PRIVATE-NONPROFIT", lcolor("22 150 210") msymbol(i)) ///
   (connect teach_disb_pct year if SchoolType=="PROPRIETARY", lcolor("0 0 0") msymbol(i)) ///
   (connect teach_disb_pct year if SchoolType=="PUBLIC", lcolor("253 191 17") msymbol(i)), legend(order(1 "Private" 2 "For profit" 3 "Public")) ///
   yti("proportion", si(small)) ti("Proportion of TEACH Disbursements, by Sector", si(small)) ///
   ylab(0(.1)1)

tw (connect teach_amt year if SchoolType=="PRIVATE-NONPROFIT", lcolor("22 150 210") msymbol(i)) ///
   (connect teach_amt year if SchoolType=="PROPRIETARY", lcolor("0 0 0") msymbol(i)) ///
   (connect teach_amt year if SchoolType=="PUBLIC", lcolor("253 191 17") msymbol(i)), legend(order(1 "Private" 2 "For profit" 3 "Public")) ///
   yti("TEACH Awards", si(small)) ti("TEACH Awards per Degree Completer, by Sector", si(small))

*appendix stats
tabstat teach if SchoolType=="PUBLIC", by(year)
tabstat teach if SchoolType=="PRIVATE-NONPROFIT", by(year)
tabstat teach if SchoolType=="PROPRIETARY", by(year)

restore


*appendix figure 2 and corresponding stats: institutional participation rates by msi status
preserve

bys unitid  : replace min_serving_predominant_black = min_serving_predominant_black[_n-1] /// 
if missing(min_serving_predominant_black)
bys unitid  : replace min_serving_historic_black = min_serving_historic_black[_n-1] /// 
if missing(min_serving_historic_black)
bys unitid  : replace min_serving_hispanic = min_serving_hispanic[_n-1] /// 
if missing(min_serving_hispanic)

bys unitid  : replace min_serving_annh = min_serving_annh[_n-1] /// 
if missing(min_serving_annh)

bys unitid  : replace min_serving_tribal = min_serving_tribal[_n-1] /// 
if missing(min_serving_tribal)

bys unitid  : replace min_serving_aanipi = min_serving_aanipi[_n-1] /// 
if missing(min_serving_aanipi)

bys unitid  : replace min_serving_na_nontribal = min_serving_na_nontribal[_n-1] /// 
if missing(min_serving_na_nontribal)

   
gen min_serving = (min_serving_hispanic==1 | min_serving_predominant_black==1 | min_serving_historic_black==1 | min_serving_annh==1 | min_serving_tribal==1 | min_serving_aanipi==1 | min_serving_na_nontribal==1)

keep if teacher_cert_state_approved==1 & title_iv_indicator==1

recode teach_recipients (.=0)
gen teach = (teach_recipients>0)

egen edu_all = rowtotal(ba_edu_all ma_edu_all)
gen teach_amt = teach_disb / edu_all

forval i = 2008(1)2022 {
tabstat teach if year==`i', by(min_serving) stats(mean n)
	}

collapse teach teach_amt (sum) teach_disb edu_all , by(year min_serving)

bys year : egen teach_disb_total = sum(teach_disb)
gen teach_disb_pct = teach_disb / teach_disb_total

tw (line teach year if min_serving==1, lcolor("22 150 210") msymbol(i)) ///
   (line teach year if min_serving==0, lcolor("0 0 0") msymbol(i)), legend(order(1 "MSI" 2 "non-MSI")) ///
   yti("participation rate", si(small)) ti("Institutional Participation Rates in TEACH, by MSI Status", si(small)) ///
   ylab(0(.1)1)
  
   graph export "${graphs}figure_3.png" , replace
  
tw (connect teach_disb_pct year if min_serving==1, lcolor("22 150 210") msymbol(i)) ///
   (connect teach_disb_pct year if min_serving==0, lcolor("0 0 0") msymbol(i)), legend(order(1 "MSI" 2 "non-MSI")) ///
   yti("proportion", si(small)) ti("Proportion of TEACH Disbursements, by Sector", si(small)) ///
   ylab(0(.1)1)
   
tw (connect teach_amt year if min_serving==1, lcolor("22 150 210") msymbol(i)) ///
   (connect teach_amt year if min_serving==0, lcolor("0 0 0") msymbol(i)), legend(order(1 "MSI" 2 "non-MSI")) ///
   yti("TEACH Awards", si(small)) ti("TEACH Awards per Degree Completer, by Sector", si(small))
   
bys year: egen edu_total = sum(edu_all)
gen edu_pct = edu_all / edu_total
tabstat edu_pct teach_disb_pct if min_serving==1, by(year)

   tabstat teach if min_serving==1, by(year)
   tabstat teach if min_serving==0, by(year)
   
restore


preserve 
bys unitid  : replace min_serving_predominant_black = min_serving_predominant_black[_n-1] /// 
if missing(min_serving_predominant_black)
bys unitid  : replace min_serving_historic_black = min_serving_historic_black[_n-1] /// 
if missing(min_serving_historic_black)
bys unitid  : replace min_serving_hispanic = min_serving_hispanic[_n-1] /// 
if missing(min_serving_hispanic)
bys unitid  : replace min_serving_annh = min_serving_annh[_n-1] /// 
if missing(min_serving_annh)
bys unitid  : replace min_serving_tribal = min_serving_tribal[_n-1] /// 
if missing(min_serving_tribal)
bys unitid  : replace min_serving_aanipi = min_serving_aanipi[_n-1] /// 
if missing(min_serving_aanipi)
bys unitid  : replace min_serving_na_nontribal = min_serving_na_nontribal[_n-1] /// 
if missing(min_serving_na_nontribal)

gen min_serving = (min_serving_hispanic==1 | min_serving_predominant_black==1 | min_serving_historic_black==1 | min_serving_annh==1 | min_serving_tribal==1 | min_serving_aanipi==1 | min_serving_na_nontribal==1)

keep if teacher_cert_state_approved==1 & title_iv_indicator==1

recode teach_recipients (.=0)
gen teach = (teach_recipients>0)

egen edu_all = rowtotal(ba_edu_all ma_edu_all)
gen teach_amt = teach_disb / edu_all

collapse (sum) teach_recipients teach_disb ba_edu_all ma_edu_all, by(year min_serving)

bys year : egen teach_rec_total = sum(teach_recipients)
gen teach_rec_pct = teach_recipients / teach_rec_total

bys year : egen teach_disb_total = sum(teach_disb)
gen teach_disb_pct = teach_disb / teach_disb_total

bys year: egen ba_total = sum(ba_edu_all)
gen ba_edu_pct = ba_edu_all / ba_total

bys year: egen ma_total = sum(ma_edu_all)
gen ma_edu_pct = ma_edu_all / ma_total

keep if min_serving==1
  
tw (connect teach_disb_pct year, lcolor("22 150 210") msymbol(i)) ///
   (connect ba_edu_pct year, lcolor("0 0 0") msymbol(i)) ///
   (connect ma_edu_pct year, lcolor("253 191 17") msymbol(i)), legend(order(1 "TEACH Disbursements" 2 "BA Awards" 3 "MA Awards"))  ///
   yti("Proportion of Disbursements/Awards", si(small)) ylab(0(.05).25)
	graph export "${graphs}teach_disb_urm.png" , replace
	
restore
