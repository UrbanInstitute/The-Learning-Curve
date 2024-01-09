In order to reproduce the analysis in Cody Christensen's piece "Unintended consequences of an accountability test for Master's Degrees Programs," the following steps need to be taken.

First, a user needs to specify a working directory (heretofore called "my_dir"), where analysis scripts and outputs will be stored.

In this directory, the user needs to create the following folders
- Data
	- raw data
		- acs
		- ipeds
		- scorecard
- Output

After doing so, the user needs to perform a data extract using the [IPUMS data service](https://usa.ipums.org/usa-action/variables/group). The years to retrieve are:
- 2014
- 2015
- 2016
- 2017
- 2018
- 2019

And the variables to retrieve are: 
- YEAR
- SAMPLE
- SERIAL
- CBSERIAL
- HHWT
- CLUSTER
- STATEFIP
- STRATA
- GQ
- PERNUM
- PERWT
- SEX
- AGE
- MARST
- RACE
- RACED
- HISPAN
- HISPAND
- CITIZEN
- SCHOOL
- EDUC
- EDUCD
- GRADEATT
- GRADEATTD
- DEGFIELD
- DEGFIELDD
- DEGFIELD2
- DEFFIELD2D
- EMPSTAT
- EMPSTATD
- LABFORCE
- OCC
- OCCSOC
- IND
- INCTOT
- FTOTINC
- INCWAGE

Submit the data request.It will take a few minutes for the file to generate; retrieve it, and save it in the "my_dir"/Data/raw data/acs folder described above as "acs_data.csv"

Save "master_analysis.do" and "analysis.zip" to the "my_dir" directory. Open "master_analysis.do" and edit line 14 with the working directory. After doing so, run to generate outputs.