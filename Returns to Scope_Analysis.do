cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Returns to Scope
* Goal: 			Data analysis
* Input data:		nodrug_paper.dta
* Result:			Econ_of_Scope_results.docx
* Other files:		Analysis Plan for Econ of Scope.docx 

* Created by:		Wei Chang
* Date created: 	2Feb2018
***********************


global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Returns to scope"
cd "$dir"

global study = "ReturnsToScope"
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


* replace drugfee with totfee if missing
	replace drugfee = totfee if drugfee ==. & !missing(totfee)
	
	
*************************
* Table 1 - Distributions/Experimental Designs
*************************

* create treatment indicator ("arm")
	gen byte arm = .
	label var arm "treatment" 
	replace arm = 1 if nodrug_a == 0 & nodrug_b == 0
	replace arm = 2 if nodrug_a == 0 & nodrug_b == 1
	replace arm = 3 if nodrug_a == 1 & nodrug_b == 0
	label define larm 1 "no_story" 2 "story_beginning" 3 "story_end" 
	label values arm larm
	

* distribution of observations by level, disease, & treatment
	table diseasecode arm, by(levelcode) row center

	
	
*************************
* Table 2: Balance tables for each experiment
*************************


* calculate clinic net revenue
	* for THC
	des thc* vc*
	gen net_rev = .
	replace net_rev = thc_f_b_f04 - thc_f_b_f10 if levelcode == 2
	label var net_rev "clinic net revenue in 2014"
	
	* for village - assuming net revenue = revenue
	replace net_rev = vc_f_b_d2_14 if inlist(levelcode, 1, 3)
	
	* for migrant clinices, do we have revenue data? 



/* balance table by experiment*/
	
	levelsof(level), local(level)
	
	foreach l of local level {
		table1 if level == "`l'", vars(age contn \ male bin \ hiedu bin \ ///
			income contn \ experience contn \ patientload contn \ net_rev contn) ///
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
		legend(label(1 "no story") label(2 "story_beginning") label(3 "story_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash)
			
	graph export "$dir/output/irt_score_by_arm.png", replace
	

	
**************************
* Table 3. Effects on drug prescriptions by level
**************************

* match IRT score from vignette
	preserve
	keep if type == 1
	isid doctorid disease
	keep doctorid disease irtscore
	rename irtscore irtscore_v
	label var irtscore_v "IRT score from vigenette"
	save "$dir/data/irtscore_vignette1.dta", replace
	restore
	
	merge m:1 doctorid disease using "$dir/data/irtscore_vignette1.dta"
	* dataset in memory includes both SP and vignette (type 1) interactions
	drop _merge
	
	
/* generate dummies for higher than median values for covars.: 
	high/low IRT knowledge 
	salary
	experience
	high patient load
	high clinic net revenue (?) */
	

	
	foreach var of varlist irtscore_v income experience patientload net_rev {
		egen temp = median(`var')
		gen `var'_high = .
		replace `var'_high = 0 if `var' <= temp
		replace `var'_high = 1 if `var' > temp & !missing(`var')
		label var `var'_high "`var'>p50"
		label define l`var'_high 0 "`var'<=p50" 1 "`var'>p50"
		label values `var'_high l`var'_high
		drop temp
		}


		
/* PRESCRIPTION outcomes:
	number of drugs
	cost of drugs
	number of unnecessary drugs ?? we don't have this var.??
	# on EDL/Zero-profit drugs (national)
	Chinese medicines
	Western medicines ??
	"High profit" Meds ??
	*/
	global prescription = "numofdrug drugfee numedl chi_med"
	
* define covariates
	global cvar_fe = "i.diseasecode i.group i.countycode"
	global cvar = "i.irtscore_v_high i.income_high i.experience_high i.patientload_high i.net_rev_high"
	
	
* OLS	
	
	eststo clear
	
	levelsof(level), local(level)
	
	foreach y of global prescription {
		foreach l of local level {
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust)
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & level == "`l'" /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
		}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.rtf", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level) label replace nobase nogap ///
		title("Effects on drug prescriptions (OLS) - Township, Village, Migrant Clinics") ///
		addnote("Included county and SP group fixed effects." ///
			"Used total visit fee if drugfee is missing.")

			

**************************
* Table 4. Effects on process quality
**************************
	
		
/* PROCESS outcomes:
	time
	checklist completion %: 
		average % recommended questions asked
		average % recommended questions and examination performed
	IRT score
	*/
	global process = "diagtime_min arq arqe irtscore"
	
	label var diagtime_min "diagnosis time"
	label var arq " checklist completion % (questions)"
	label var arqe "checklist completion % (questions and exam)"
	
* OLS	
	
	eststo clear
	
	levelsof(level), local(level)
	
	foreach y of global process {
		foreach l of local level {
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust)
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & level == "`l'" /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
		}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.rtf", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level) label append nobase nogap ///
		title("Effects on process quality (OLS) - Township, Village, Migrant Clinics") ///
		addnote("Included county and SP group fixed effects.")
	

**************************
* Table 5. Effects on diagnosis outcomes (Township, Village, Migrant Clinics)
**************************
	
		
/* DIAGNOSIS outcomes:
	diagnosis correct
	diagnosis partially correct
	*/
	global diagnosis = "gavediag corrdiag pcorrdiag"
	
	
* OLS	
	
	eststo clear
	
	levelsof(level), local(level)
	
	foreach y of global diagnosis {
		foreach l of local level {
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust)
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & level == "`l'" /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
		}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.rtf", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level) label append nobase nogap ///
		title("Effects on diagnosis outcomes (OLS) - Township, Village, Migrant Clinics") ///
		addnote("Included county and SP group fixed effects.")



**************************
* Table 6. Effects on treatment outcomes (Township, Village, Migrant Clinics)
**************************
	
		
/* TREATMENT outcomes:
	treatment correct (no unnecessary)
	treatment correct + unnecessary
	drugs correct (i.e. ignore referral behavior)
	referrals
	*/
	global treatment = "corrtreat pcorrtreat corrdrug referral"
	label var corrtreat "correct treatment"
	label var pcorrtreat "partially correct treatment"
	label var corrdrug "correct drug"
	label var referral "referral"
	

	foreach x of global treatment {
		label define l`x' 0 "`x'=0" 1 "`x'=1"
		label values `x' l`x'
		}
	
	
* OLS	
	
	eststo clear
	
	levelsof(level), local(level)
	
	foreach y of global treatment {
		foreach l of local level {
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust)
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & level == "`l'" /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
		}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.rtf", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level) label append nobase nogap ///
		title("Effects on treatment outcomes (OLS) - Township, Village, Migrant Clinics") ///
		addnote("Included county and SP group fixed effects." ///
			"Partially correct treatment includes prescribing unnecessary drugs.")
	
	
******************
* adjusted p-value 
******************

* p-value adjusted for multiple hypotheses across treatments within domain

preserve

foreach d in prescription process diagnosis treatment {
	di "domain: `d'"
	rwolf $`d', indepvar(arm) controls(irtscore_v_high income_high experience_high ///
		patientload_high net_rev_high groupcode diseasecode countycode) ///
		reps(250) method(reg) 
	}
restore


log off
