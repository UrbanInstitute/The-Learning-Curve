/***********************************
* A0: Master Do File 
* Mark Murphy
* Kiley Oeda
* University of Hawaii at Manoa
* Regional and Temporal Patterns of Pandemic Enrollment Declines in Hawai`i Public Schools
* Created: November 25, 2021
* Last Modified: March 10, 2022
************************************/

	
	/// Change line 14: Specify file path
	********
	global path "C:\Users\lrestrepo\Documents\Github_repos\The-Learning-Curve\2022_03_31-Enrollment_Decline"

	cd "${path}"
	
	// Setting up macros
	global data = "data"
	global input = "${data}\input_data"
	global output = "${data}\output_data"
	global vis = "${output}\vis"

	cap n unzipfile "analysis"
	
	cap n mkdir "${output}"
	cap n mkdir "${vis}"
		
	//Graphing
	graph set window fontface "lato"
	
	/// Data Preparation
	********************
	
		do "${path}/A1.Import.Sch.Enr.1920_2122.do"								// Import school-level HI enrollment data (Fall 2019, 2020, 2021)
		do "${path}/A2.Merge.Sch.Enr.1920_2122.do"								// Merges the 3 Fall Enrollment Data years into one file.
		do "${path}/A3.Panel.Prep.1920_2122.do"									// Prepared the panel of enrollment data (wide)
		do "${path}/A4.Over.Time.PctChg.Prep.Fall15-Fall21.do"					// Prepared the panel of enrollment data (wide)
	
	/// Data Analysis (Included in Paper)
	*************************************
	
		do "${path}/B1.Figure1_03102022.do"			// Annual Enrollment by Island and Statewide Fall 2015-Fall 2021
		do "${path}/B2.Figure2_03102022.do"			// Percent Change by Island and Statewide Fall 2015-Fall 2021
		do "${path}/B3.Figure3_03102022.do"			// Percent Change between Fall 2019 and Fall 2021, by Sector and Grade Level
		do "${path}/B4.Figure4_03102022.do"			// Percent of Elementary Schools with K-4 Declines from Fall 2019 to Fall 2021, by Island and Severity
	
	// Appendix (Supplemental Materials)
	************************************
		do "${path}/C1.AppFig1_03102022.do"			// Percent Change by School Fall 2019 to Fall 2021