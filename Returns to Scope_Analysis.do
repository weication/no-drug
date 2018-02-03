cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Returns to Scope
* Goal: 			Data analysis
* Input data:		nodrug_paper.dta (in Stata 13 format)
* Output: 	
* Other files:		Analysis Plan for Econ of Scope.docx (list of tables)

* Created by:		Wei Chang
* Date created: 	2Feb2018
***********************


global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Returns to scope"
cd "$dir"
/*
global study = "ReturnsToScope"
log using "$dir/log/$study `c(current_date)'.log",replace
*/

use "$dir/data/nodrug_paper.dta",clear




*************************
* Table 1 - Distributions/Experimental Designs
*************************

* create treatment indicator ("arm")
	gen byte arm = .
	label var arm "treatment" 
	replace arm = 1 if nodrug_a == 0 & nodrug_b == 0
	replace arm = 2 if nodrug_a == 0 & nodrug_b == 1
	replace arm = 3 if nodrug_a == 1 & nodrug_b == 0
	label define larm 1 "no story" 2 "story after" 3 "story before" 
	label values arm larm
	

* distribution of observations by level, disease, & treatment
	table level disease arm, center row col
	
* distribution by level & arm OR by disease & arm
	tabout level disease arm using "$dir/output/randomization.xls", replace
	
	
	
*************************
* Table 2: Balance tables for each experiment
*************************

/* what are the variables we want here? I haven't included any for clinic level */
	
	levelsof(level), local(level)
	
	foreach l of local level {
		table1 if level == "`l'", vars(age contn \ male bin \ hiedu bin \ income contn) ///
			by(arm) format(%2.1f) one percent ///
			saving("$dir/output/nodrug_tables",sheet("balance_`l'", replace))
		}
		

***********************
* Figure 1: Cumulative densities for IRT by arm
***********************

	levelsof(arm), local(arm)
	foreach a of local arm {
		cumul irtscore if arm == `a', gen(cirt`a')
		label var cirt`a'
		}

	line cirt1 cirt2 cirt3 irtscore, sort ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "Control") label(2 "Story after") label(3 "Story before") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash dash solid) 
			
	graph export "$dir/output/irt_score_by_arm.png", replace
	

************************
* Treatment regression
************************
	
/* dummy for covariables: 
	high/low IRT knowledge (?? or "vignette IRT socre")
	salary
	experience (?)
	high patient load (?)
	high clinic net revenue (?)
*/
	
	foreach var of varlist irtscore income {
		egen temp = median(`var')
		gen `var'_dummy = 0
		replace `var'_dummy = 1 if `var' < temp
		label var `var'_dummy "`var'>p50"
		drop temp
		}
	
* recode string variables
	encode disease, gen(diseasecode)
	label define ldiseasecode 1 "angina" 2 "diarrhea" 3 "TB"
	label values diseasecode ldiseasecode
	
	encode level, gen(levelcode)
	label define llevelcode 1 "Migrant" 2 "Township" 3 "Village"
	label values levelcode llevelcode
	

	
/* what are the treatment outcomes?
should we use binary models (logit/probit)? */


/* separate models by disease vs. control for disease fixed effects? */



	global y_treat = "corrtreat pcorrtreat"
	global cvar = "age pracdoc i.irtscore_dummy i.income_dummy"
	
	eststo clear
	foreach out of global y_treat {
		eststo: reg `out' i.arm i.diseasecode $cvar i.groupcode i.countycode i.levelcode, vce(robust)
		test 2.arm 3.arm
		estadd scalar pval_bt_treatarm = `r(p)'
		sum `out' if arm == 1	/* mean of the control arm */
		estadd scalar control_mean = `r(mean)'		
		}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) ///
		drop(*.diseasecode *.groupcode *.countycode *.levelcode) ///
		scalar(pval_bt_treatarm control_mean) label replace nobaselevels ///
		addnote("included disease, county, clinic type, and SP group fixed effects")
		
log off
