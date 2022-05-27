********************************************************************************
*Title: National Strike Analysis, Urban Institute
*Author:  M Lyon
*Date: 3/29/2022
*Description: National strike analysis

********************************************************************************

gl main "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_05_27-teacher_strikes"
gl data "${main}\data"
gl raw "${data}\raw"
gl out "${data}\output"

cd "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_05_27-teacher_strikes" 

set more off
clear all
cap set scheme cleanplots
cap set level 95, perm

unzipfile "${main}\data.zip", replace

* Descriptives for "Increase in coordinated strikes after 2017"
estimates clear

use "${raw}\nationalstrikes", clear
replace indiv=0 if indiv==.
tab school_year indiv

* Cleaning 
use "${raw}\urban_SEDA", clear

unique leaid year if indiv!=.

*make strike categorical variable
	gen strike_cat = 0 
	replace strike_cat =1 if indiv==1
	replace strike_cat =2 if coorstrike==1
	bysort leaid: egen strike_cat_dist = max(strike_cat)
	label define strike_cat 0 "No Strike" 1 "District Strike" 2 "Coordinated Strike"
	label values strike_cat strike_cat
	tab strike_cat
	
*code regions 1=Northeast; 2=Midwest; 3= South; 4=West
gen northeast=(state_fips==9| state_fips==23 | state_fips==25 | state_fips==33 | state_fips==44 | state_fips==50| state_fips==34| state_fips==36| state_fips==42) 
gen midwest=(state_fips==18 | state_fips==17 | state_fips==26 | state_fips==39 | state_fips==55 | state_fips==19 | state_fips==20 | state_fips==27 | state_fips==29 | state_fips==31 | state_fips==38 | state_fips==46)
gen south =(state_fips==10 | state_fips==11 | state_fips==12 | state_fips==13 | state_fips==24 | state_fips==37 | state_fips==45 | state_fips==51 | state_fips==54 | state_fips==1 | state_fips==21 | state_fips==28 | state_fips==47 | state_fips==5 | state_fips==22 | state_fips==40 | state_fips==48)
gen west=(state_fips==4 | state_fips==8 | state_fips==16 | state_fips==35 | state_fips==30 | state_fips==49 | state_fips==32 | state_fips==56 | state_fips==02 | state_fips==06 | state_fips==15 | state_fips==41 | state_fips==53)

	
*remove major outliers
drop if r_exp_perpupil<1
drop if r_exp_perpupil> 1000000 & r_exp_perpupil!=.
drop if member<20 | member==.
unique leaid year if indiv!=.

local list member teachratio schadmratio suppratio totguiratio r_exp_perpupil r_instruction_total_pp r_salben_pp percentschagepoverty  percentspeced percentell perwht perind perhsp perblk perasn perfrl urban-rural mn_math mn_ela northeast midwest south west

unique leaid if strike_cat_dist==0 // 18724
unique leaid if strike_cat_dist==1 // 106
unique leaid if strike_cat_dist==2 // 449

tab year if strike_cat>0 
tab year strike_cat

*Collapse and Export to Generate Figures in Excel 
collapse (mean) `list' (count) leaid, by (strike_cat_dist)
		rename leaid number_of_districts
		replace number_of_districts=18724 if strike_cat==0
		
		xpose, clear varname
		rename v1 no_strike
		rename v2 indiv_strike
		rename v3 coor_strike
		drop if _n==1
		order _varname
		
export excel using "${out}Urban Institute Data Export v2.xlsx", firstrow(variables) replace  
