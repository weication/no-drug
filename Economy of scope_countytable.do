
cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy to Scope
* Goal: 			Create a table to report ICC, num of docs, and SD of outcomes 
* Note: 			Trello task on Feb 28, 2018
* Input data:		nodrug_paper.dta

* Output file: 		economyofscope_county_table.xlsx

* Created by:		Wei Chang
* Date created: 	28Feb2018
***********************


global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Economy of scope"
cd "$dir"

global study = "EconomyOfScope"
log using "$dir/log/$study `c(current_date)'.log",replace


use "$dir/data/nodrug_paper.dta",clear


* drop vignette type 2/Q10 observations
	label list type
	drop if type == 2
	

* recode string variables
	encode disease, gen(diseasecode)
	label define ldiseasecode 1 "angina" 2 "diarrhea" 3 "TB"
	label values diseasecode ldiseasecode
	label var diseasecode disease
	
	encode level, gen(levelcode)
	label define llevelcode 1 "Migrant" 2 "Township" 3 "Village"
	label values levelcode llevelcode
	label var levelcode "clinic level"
	
* rename variables
	des year
	rename year experience
	label var experience experience
	
	label var patientload "patient load"
	
	label var chi_med "Chinese medicine"
	
	label var numofdrug "Number of medicines prescribed"

	

/***** Define Globals ******

- % recommended exams: are
- % recommended questions: arq
- % recommended questions and exams: arqe
- Correct diagnosis: corrdiag
- Correct treatment: corrtreat
*/ 
	des are arq arqe corrdiag corrtreat
	global y "are arq arqe corrdiag corrtreat"

* drop migrant clinics
tab level 
drop if level == "Migrant"

****************
* County level ICC 
****************

* set column headings in Excel 
	putexcel set "$dir/output/economyofscope_county_table.xlsx", sheet(tables) replace
		putexcel B5 = "County-level ICC"
		
		* levels
		putexcel C3 = "Township"
		putexcel D3 = "Township"
		putexcel E3 = "VIllage"
		putexcel F3 = "VIllage"
		putexcel G3 = "VIllage"
		
		* disease
		putexcel C4 = "Angina"
		putexcel D4 = "Diarrhea"
		putexcel E4 = "Angina"
		putexcel F4 = "Diarrhea"
		putexcel G4 = "TB"	
		
		* outcomes
		putexcel B6 = "% recommended exams"
		putexcel B7 = "% recommended questions"
		putexcel B8 = "% recommended questions and exams"
		putexcel B9 = "Correct diagnosis"
		putexcel B10 = "Correct treatment"

* save ICC to Excel 
local n = 6
foreach y of global y {
		loneway `y' countycode if disease == "A" & level == "Township"
		putexcel C`n' = `r(rho)'
	
		loneway `y' countycode if disease == "D" & level == "Township"
		putexcel D`n' = `r(rho)'
	
		loneway `y' countycode if disease == "A" & level == "Village"
		putexcel E`n' = `r(rho)'

		loneway `y' countycode if disease == "D" & level == "Village"
		putexcel F`n' = `r(rho)'

		loneway `y' countycode if disease == "T" & level == "Village"
		putexcel G`n' = `r(rho)'
		
		local n = `n' + 1		
}		


********************
* number of providers per county
********************

	putexcel B12 = "# of providers"
		
	* unique number of doctors
		unique doctorid if disease == "A" & level == "Township"
		putexcel C12 = `r(unique)'
		
		unique doctorid if disease == "D" & level == "Township"
		putexcel D12 = `r(unique)'
		
		unique doctorid if disease == "A" & level == "Village"
		putexcel E12 = `r(unique)'
		
		unique doctorid if disease == "D" & level == "Village"
		putexcel F12 = `r(unique)'
		
		unique doctorid if disease == "T" & level == "Village"
		putexcel G12 = `r(unique)'
		
		
***************
* Standard deviation in the sample
***************
	putexcel B14 = "Standard deviation in the sample" 
	
	local n = 15
	foreach y of global y {
		sum `y' if disease == "A" & level == "Township"
		putexcel C`n' = `r(sd)'
		
		sum `y' if disease == "D" & level == "Township"
		putexcel D`n' = `r(sd)'
		
		sum `y' if disease == "A" & level == "Village"
		putexcel E`n' = `r(sd)'
		
		sum `y' if disease == "D" & level == "Village"
		putexcel F`n' = `r(sd)'
		
		sum `y' if disease == "T" & level == "Village"
		putexcel G`n' = `r(sd)'
		
		local n = `n' + 1
		}
		
	* outcome lables
		putexcel B15 = "% recommended exams"
		putexcel B16 = "% recommended questions"
		putexcel B17 = "% recommended questions and exams"
		putexcel B18 = "Correct diagnosis"
		putexcel B19 = "Correct treatment"

		
		
* number format
	putexcel C5:G10, nformat(number_d2) overwritefmt
	putexcel C15:G19, nformat(number_d2) overwritefmt
	

log off
