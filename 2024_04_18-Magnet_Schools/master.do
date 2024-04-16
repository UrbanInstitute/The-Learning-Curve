capture log close
set more off

cap n ssc install educationdata

glo wd "****"

glo raw "${wd}/analysis"

global data		"${wd}/data"
global int "${data}/int"
global fin "${data}/fin"
global vis "${data}/vis"


global results 	"${wd}/updated"
global logs 	"${wd}/logs"

foreach z in raw data int fin vis results logs{
	cap n mkdir "${`z'}"
}

graph set window fontface "Lato"

cd "${raw}"

cap n unzipfile "${wd}/analysis.zip"

do "${raw}/application_data_prep.do"
do "${raw}/enrollment_prep.do"
do "${raw}/analysis_file_main_figures.do"
do "${raw}/analysis_file_graphs_10_13_2023.do"
do "${raw}/analysis_file_appendix_figures_and_tables.do"


