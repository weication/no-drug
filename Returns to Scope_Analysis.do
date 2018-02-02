cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Returns to Scope
* Goal: 			Data analysis
* Input data:		nodrug_paper.dta
* Output: 	
* Other files:		Analysis Plan for Econ of Scope.docx (list of tables)

* Created by:		Wei Chang
* Date created: 	23Jan2018
***********************


global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Returns to scope"
cd "$dir"
/*
global study = "ReturnsToScope"
log using "$dir/log/$study `c(current_date)'.log",replace
*/

use "$dir/data/nodrug_paper_stata13.dta",clear


* MERGE ADDITIONAL VARIABLES 
	merge 1:1 ID using "$dir/Data/SP_total_dataset_1oct2017_reduced_stata13.dta", ///
		keepusing(doctorid nodrug nodrug_a clinicid nodrug_b drugfee nodrug)
	drop if _merge == 2
	drop _merge





***********************************
* Table 1 - Distributions/Experimental Designs
***********************************
* distribution of observations by disease
	tabulate level disease,m matcell(freq)
		
	levelsof level, local(levellabels)
	matrix rowname freq = `levellabels'
		
	replace disease = "angina" if disease == "A"
	replace disease = "diarrhea" if disease == "D"
	replace disease = "tb" if disease == "T"
		
	levelsof disease, local(diseaselabels)
	matrix colname freq = `diseaselabels'
		
	putexcel A1 = ("Table 1. Number of observations by experimental arm") ///
		using "$dir/output/nodrug_tables.xls", sheet(table1) replace
		
	putexcel set "$dir/output/nodrug_tables.xls", sheet(table1) modify
	putexcel A3 = matrix(freq,names)
	putexcel clear
			
	
* create treatment indicate ("arm")
	gen byte arm = .
	label var arm "treatment" 
	replace arm = 1 if nodrug_a == 0 & nodrug_b == 0
	replace arm = 2 if nodrug_a == 0 & nodrug_b == 1
	replace arm = 3 if nodrug_a == 1 & nodrug_b == 0
	label define larm 1 "no story" 2 "story after" 3 "story before" 
	label values arm larm

* distribution of observations by level, disease, & treatment
	table level disease arm, contents(freq)
	
* distribution of arm by level
	tabulate level arm,matcell(freq)
	

	



		

		
		
