/*
HB729 School Report Card Proportionality LC Piece
Jay Carter
Leonardo Restrepo

8/27/24

*/

clear 
clear all
// Change this line to reflect the current working directory of this code
glo wd "C:\Users\jcarter\Documents\git_repos\HB_729_code\code\"
glo data "${wd}data_files\"

// R file that gets ACS data 0_build_school_county_data.R
do "${wd}1_merging_fips_census_and_school_racial_comp.do"
do "${wd}2_prepare_measures.do"
do "${wd}3_school_level_analyses.do"
do "${wd}4_demographic_analyses.do"