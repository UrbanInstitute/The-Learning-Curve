cap ssc install excelcol

// Change this line to be directory you have all scripts and the raw_data.zip file saved in
glo main "***"

cd "${main}"

glo int "${main}/int_data"
glo raw "${main}/raw_data"
glo fin "${main}/fin_data"

cap n mkdir "${int}"
cap n mkdir "${fin}"


do "${main}/clean.do"
do "${main}/analysis.do"