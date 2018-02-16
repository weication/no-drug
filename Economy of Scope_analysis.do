cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy to Scope
* Goal: 			Data analysis
* Input data:		nodrug_paper.dta
* Result:			Econ_of_Scope_results.docx
* Other files:		Analysis Plan for Econ of Scope.docx 

* Created by:		Wei Chang
* Date created: 	2Feb2018
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
	
* create variable for Chinese modern/herbal drugs
	gen chi_med_h = .
	replace chi_med_h = 0 if thc_t_v_Q9_9 == 0 | vc_t_v_Q9_9==0 | ch_t_v_Q9_9==0
	replace chi_med_h = 1 if thc_t_v_Q9_9 == 1 | vc_t_v_Q9_9==1 | ch_t_v_Q9_9==1
	label var chi_med_h "Chinese herbal medicine"
	label define yesno 0 no 1 yes
	label values chi_med_h yesno
	
	gen chi_med_m = .
	replace chi_med_m = 0 if thc_t_v_Q9_10 == 0 | vc_t_v_Q9_10==0 | ch_t_v_Q9_10==0
	replace chi_med_m = 1 if thc_t_v_Q9_10 == 1 | vc_t_v_Q9_10==1 | ch_t_v_Q9_10==1
	label var chi_med_h "Chinese modern medicine"
	label values chi_med_h yesno 

 	
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
	
	* logout, save($dir/output/distribution) excel replace: table diseasecode arm, by(levelcode) row center
	
	
* treatment implementation fidelity check - % of treatment arm not treated
	tab arm nodrug, m row
	
	gen treat_fail =.
	replace treat_fail = 1 if nodrug == 0 & inlist(arm, 2, 3)
	replace treat_fail = 0 if nodrug == 1 & inlist(arm, 2, 3)
	label var treat_fail "assigned to treatment but not treated"
	
	tab arm treat_fail,row nofreq
	
	* % not treated by level
	bysort level: tab arm treat_fail,row nofreq
	
* arm assignment as treated

	gen arm_actual = .
	replace arm_actual = 1 if !missing(arm) & nodrug == 0
	replace arm_actual = 2 if arm == 2 & nodrug == 1
	replace arm_actual = 3 if arm == 3 & nodrug == 1
	label var arm_actual "arm as treated" 
	label values arm_actual larm
	note arm_actual: arm_actual = 1 if assigned to treatment but not actually treated. 
	
	gen actual_b = nodrug_b
	replace actual_b = 0 if nodrug_b == 1 & nodrug ==0
	label var actual_b "actual story_beginning"
	
	gen actual_a = nodrug_a
	replace actual_a = 0 if nodrug_a == 1 & nodrug ==0
	label var actual_a "actual story_end"
	

*************************
* Table 2: Balance tables for each experiment
*************************


* calculate clinic net revenue
	* for THC
	des thc* vc*
	gen net_rev = .
	replace net_rev = thc_f_b_f04 - thc_f_b_f10 if levelcode == 2
	label var net_rev "clinic net revenue in 10k 2014 RMB"
	
	* for village & migrant clinics, we asked net revenue directly
	replace net_rev = vc_f_b_d2_14/10000 if inlist(levelcode, 1, 3)
	
* create var. for total revenue
	gen totrev = .
	replace totrev = thc_f_b_f04 if levelcode == 2 /* township unit in raw data: wan yuan */
	replace totrev = vc_f_b_d2_6/10000 if inlist(levelcode, 1, 3) /* change unit to wan yuan */
	label var totrev "clinic total revenue in 10k 2014 RMB"
	tabstat totrev net_rev, by(levelcode) stat(mean sd n)



/* balance table by experiment*/
	
	levelsof(level), local(level)
	
	foreach l of local level {
		table1 if level == "`l'", vars(age contn \ male bin \ hiedu bin \ ///
			income contn \ experience contn \ patientload contn \ totrev contn \ net_rev contn) ///
			by(arm) format(%2.1f) one percent ///
			saving("$dir/output/nodrug_tables",sheet("balance_`l'", replace))
		}
		

***********************
* Figure 1: Cumulative densities for IRT by arm
***********************

	distplot irtscore, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "no story") label(2 "story_beginning") label(3 "story_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash)
	
	graph export "$dir/output/irt_score_by_arm.png", replace
	
**************************
* Table 3. Effects on drug prescriptions
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
	high clinic total revenue */
	
	foreach var of varlist irtscore_v income experience patientload {
		egen temp = median(`var')
		gen `var'_high = .
		replace `var'_high = 0 if `var' <= temp
		replace `var'_high = 1 if `var' > temp & !missing(`var')
		label var `var'_high "`var'>p50"
		label define l`var'_high 0 "`var'<=p50" 1 "`var'>p50"
		label values `var'_high l`var'_high
		drop temp
		}
		
	* for high clinic total revenue, generate dummies by level
	
	gen totrev_high = .
	label var totrev_high "totrev>p50"
	label define ltotrev_high 0 "totrev<=p50" 1 "totrev>p50
	label values totrev_high ltotrev_high
	
	levelsof(level), local(level)
	foreach l of local level {
		egen temp = median(totrev) if level == "`l'" 
		replace totrev_high = 0 if totrev <= temp & level == "`l'" 
		replace totrev_high = 1 if totrev > temp & level == "`l'" & !missing(totrev)
		drop temp
		}
	tab totrev_high
		
/* PRESCRIPTION outcomes:
	number of drugs
	cost of drugs --> cost of visit
	# on EDL/Zero-profit drugs (national)
	# off EDL/Zero-profit drugs (national)
	Chinese modern
	Chinese herbal
	"High profit" Meds ??
	*/
	
	* check the distribution of "number of drugs" - number of zeros
	gen numofdrug_zero = (numofdrug == 0)
	replace numofdrug_zero = . if numofdrug == .
	sum numofdrug_zero
	di "% of interactions where no drug was prescribed: " r(mean)*100 "%"
	tab level numofdrug_zero,row nofreq
	
	* drugfee vs. totfee
	sum drugfee totfee
	misstable sum drugfee totfee if arm != .
	* drugfee: missing ~35% --> use total SP visit fee as outcome 
	
	
	
	global prescription = "numofdrug totfee numedl numnonedl"
	
* define covariates
	global cvar_fe = "i.diseasecode i.group i.countycode"
	global cvar = "i.irtscore_v_high i.income_high i.experience_high i.patientload_high i.totrev_high"
	
	
* OLS & IV
	
	eststo clear
	
	levelsof(level), local(level)
	
	foreach y of global prescription {
		foreach l of local level {
			* OLS - parsimonious
			eststo: reg `y' i.arm $cvar_fe if level == "`l'", vce(robust) 
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - full
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust) /* OLS including covariates */
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - cluster at THC level for THC interactions
			if "`l'" == "Township" {
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster thc_id)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms)
			if "`l'" == "Township" {
				eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) $cvar $cvar_fe if level == "`l'", robust
				test actual_b = actual_a
				estadd scalar pval_bt_treatarm = `r(p)'
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			* IV - arm assignment --> actual treatment (two arms)
			if "`l'" == "Village" {
				eststo: ivregress gmm `y' (actual_b = nodrug_b) $cvar $cvar_fe if level == "`l'", robust
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level SE MODEL) label replace nobase nogap ///
		title("Effects on drug prescriptions") ///
		addnote("Included county and SP group fixed effects.")


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
	
* OLS & IV
	
	eststo clear
	
	levelsof(level), local(level)
	
	
	foreach y of global process {
		foreach l of local level {
			* OLS - parsimonious
			eststo: reg `y' i.arm $cvar_fe if level == "`l'", vce(robust) 
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - full
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust) /* OLS including covariates */
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - cluster at THC level for THC interactions
			if "`l'" == "Township" {
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster thc_id)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms)
			if "`l'" == "Township" {
				eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) $cvar $cvar_fe if level == "`l'", robust
				test actual_b = actual_a
				estadd scalar pval_bt_treatarm = `r(p)'
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			* IV - arm assignment --> actual treatment (two arms)
			if "`l'" == "Village" {
				eststo: ivregress gmm `y' (actual_b = nodrug_b) $cvar $cvar_fe if level == "`l'", robust
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level MODEL) label append nobase nogap ///
		title("Effects on process quality") ///
		addnote("Included county and SP group fixed effects.")
	

**************************
* Table 5. Effects on diagnosis outcomes (Township, Village, Migrant Clinics)
**************************
	
		
/* DIAGNOSIS outcomes:
	diagnosis correct
	diagnosis partially correct
	*/
	global diagnosis = "gavediag corrdiag pcorrdiag"
	
	
* OLS & IV
	
	eststo clear
	
	levelsof(level), local(level)
	
foreach y of global diagnosis {
		foreach l of local level {
			* OLS - parsimonious
			eststo: reg `y' i.arm $cvar_fe if level == "`l'", vce(robust) 
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - full
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust) /* OLS including covariates */
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - cluster at THC level for THC interactions
			if "`l'" == "Township" {
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster thc_id)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms)
			if "`l'" == "Township" {
				eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) $cvar $cvar_fe if level == "`l'", robust
				test actual_b = actual_a
				estadd scalar pval_bt_treatarm = `r(p)'
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			* IV - arm assignment --> actual treatment (two arms)
			if "`l'" == "Village" {
				eststo: ivregress gmm `y' (actual_b = nodrug_b) $cvar $cvar_fe if level == "`l'", robust
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level MODEL) label append nobase nogap ///
		title("Effects on diagnosis outcomes") ///
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
	
	
* OLS & IV	
	
	eststo clear
	
	levelsof(level), local(level)
	
foreach y of global treatment {
		foreach l of local level {
			* OLS - parsimonious
			eststo: reg `y' i.arm $cvar_fe if level == "`l'", vce(robust) 
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - full
			eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(robust) /* OLS including covariates */
			if "`l'" != "Village" {
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				}
			
			sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
			estadd scalar control_mean = `r(mean)'	
			estadd local level = "`l'"
			estadd local SE = "robust"
			estadd local MODEL = "OLS"
			
			* OLS - cluster at THC level for THC interactions
			if "`l'" == "Township" {
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster thc_id)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms)
			if "`l'" == "Township" {
				eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) $cvar $cvar_fe if level == "`l'", robust
				test actual_b = actual_a
				estadd scalar pval_bt_treatarm = `r(p)'
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			* IV - arm assignment --> actual treatment (two arms)
			if "`l'" == "Village" {
				eststo: ivregress gmm `y' (actual_b = nodrug_b) $cvar $cvar_fe if level == "`l'", robust
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level MODEL) label append nobase nogap ///
		title("Effects on treatment outcomes") ///
		addnote("Included county and SP group fixed effects." ///
			"Partially correct treatment includes prescribing unnecessary drugs.")
	

	
*****************
*  Table 7. Effects by disease
*****************

* OLS	
	
	eststo clear
	
	levelsof(disease), local(disease)

	global cvar_fe2 = "i.groupcode i.levelcode i.countycode"
	
* not including treatment!!!!!!!
	
foreach y of varlist $prescription $process $diagnosis {
	foreach d of local disease {
		* three arms, including only MC & THC
				* OLS - parsimonious
				eststo: reg `y' i.arm $cvar_fe2 if disease == "`d'" & level != "Village", vce(robust) 
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'

				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local disease = "`d'"
				estadd local SE = "robust"
				estadd local MODEL = "OLS"
				estadd local level = "MC & THC"
			
				* OLS - full
				eststo: reg `y' i.arm $cvar $cvar_fe2 if disease == "`d'" & level != "Village", vce(robust) 
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
			
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local disease = "`d'"
				estadd local SE = "robust"
				estadd local MODEL = "OLS"
				estadd local level = "MC & THC"
				
		
		* two arms, including MC, THC, and VC
				* OLS - parsimonious
				eststo: reg `y' i.nodrug_b $cvar_fe2 if disease == "`d'", vce(robust) 

				sum `y' if nodrug_b == 0 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local disease = "`d'"
				estadd local SE = "robust"
				estadd local MODEL = "OLS"
				estadd local level = "all"
			
				* OLS - full
				eststo: reg `y' i.nodrug_b $cvar $cvar_fe2 if disease == "`d'", vce(robust) 
			
				sum `y' if nodrug_b == 0 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local disease = "`d'"
				estadd local SE = "robust"
				estadd local MODEL = "OLS"
				estadd local level = "all"		
	
			}
	}
	
	esttab using "$dir/output/nodrug_diagnosis_treatment.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean disease MODEL level) label append nobase nogap ///
		title("Effects by disease") ///
		addnote("Included level, county and SP group fixed effects." ///
			"Partially correct treatment includes prescribing unnecessary drugs.")
	



******************
* adjusted p-value 
******************

* p-value adjusted for multiple hypotheses across treatments within domain

preserve

foreach d in prescription process diagnosis treatment {
	di "domain: `d'"
	rwolf $`d', indepvar(arm) controls(irtscore_v_high income_high experience_high ///
		patientload_high totrev_high groupcode diseasecode countycode) ///
		reps(250) method(reg) 
	}
restore


log off
