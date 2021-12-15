*Figure 1: Overall differences;

bysort catholic_next: su readgain_next mathgain_next;
reg readgain_next catholic_next;
reg mathgain_next catholic_next;

*Figure 2: Comparisons with/without controls;

g firstgroup="TOP THIRD" if firstobserved~=.;
replace firstgroup="MIDDLE THIRD" if firstobserved<66.7;
replace firstgroup="BOTTOM THIRD" if firstobserved<33.4;

g povgroup="OVER 185%" if pctpov~=.;
replace povgroup="130-185%" if pctpov<=1.85;
replace povgroup="80-130%" if pctpov<=1.3;
replace povgroup="UNDER 80%" if pctpov<=.8;

g marsep="NEITHER" if married~=.;
replace marsep="MARRIED" if married==1;
replace marsep="SEPARATED" if separated==1;

g fsgroup="6+ PEOPLE" if famsize~=.;
replace fsgroup="3-5 PEOPLE" if famsize<=5;
replace fsgroup="2 PEOPLE" if famsize<=2;

ta race, gen(rrr);
ta sex, gen(sss);
ta firstgroup, gen(fff);
ta povgroup, gen(ppp);
ta marsep, gen(mmm);
ta fsgroup, gen(ggg);

reg readgain_next catholic_next;
reg readgain_next catholic_next rrr* sss* fff* ppp* mmm* ggg*;
reg mathgain_next catholic_next;
reg mathgain_next catholic_next rrr* sss* fff* ppp* mmm* ggg*;

*Figure 3: Breakdown by initial test score;

bysort firstgroup: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==1;
bysort firstgroup: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==0;
bysort firstgroup: reg readgain_next catholic_next;
bysort firstgroup: reg mathgain_next catholic_next; 

*Figure 4: Breakdown by income as fraction of poverty line;

bysort povgroup: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==1;
bysort povgroup: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==0;
bysort povgroup: reg readgain_next catholic_next;
bysort povgroup: reg mathgain_next catholic_next; 

*Appendix figure: Breakdown by household size;

bysort fsgroup: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==1;
bysort fsgroup: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==0;
bysort fsgroup: reg readgain_next catholic_next;
bysort fsgroup: reg mathgain_next catholic_next; 

*Appendix figure: Breakdown by parental marital status;

bysort marsep: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==1;
bysort marsep: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==0;
bysort marsep: reg readgain_next catholic_next;
bysort marsep: reg mathgain_next catholic_next; 

*Appendix figure: Breakdown by student race/ethnicity;

bysort race: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==1;
bysort race: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==0;
bysort race: reg readgain_next catholic_next;
bysort race: reg mathgain_next catholic_next; 

*Appendix figure: Breakdown by student gender;

bysort sex: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==1;
bysort sex: su readgain_next mathgain_next readgain_sameschool mathgain_sameschool if catholic_next==0;
bysort sex: reg readgain_next catholic_next;
bysort sex: reg mathgain_next catholic_next; 