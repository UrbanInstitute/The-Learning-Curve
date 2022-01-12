In order to reproduce the results in this blog post, you will need to download the following files from github into the same folder:
- Mackevicius_UIEdDataPortalInputCleanOrgs.do
- Mackevicius_UIEdDataPortalBuildDatasetYearMatch.do
- Mackevicius_UIEdDataPortalAnalysis.do

Create a folder within this folder called "Data Input". At this point, you will need to download two files and save them in the "Data Input" folder:
- coreco.core2017pc, [here](https://nccs-data.urban.org/dl.php?f=core/2017/coreco.core2017pc.csv)
- IL_1819_final_June21, [here](https://edunomicslab.org/wp-content/uploads/2021/10/IL_1819_final_October_8th_21.xlsx); a note that this file is updated routinely, so please revise as needed

After downloading the ncessary data, modify line 12 of each .do file to reflect the folder they are saved in. Please check line 69 of the BuildDataSetYearMatch.do file to see that it matches the most recent file posted on NERD\\$. After doing so, run the .do files in the following order:
1. Mackevicius_UIEdDataPortalInputCleanOrgs.do
2. Mackevicius_UIEdDataPortalBuildDatasetYearMatch.do
3. Mackevicius_UIEdDataPortalAnalysis.do
