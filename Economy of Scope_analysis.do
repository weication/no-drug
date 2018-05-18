cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy to Scope
* Goal: 			Data analysis
* Input data:		nodrug_paper.dta

* Output tables: 	economyofscope_results.csv
* Result:			Econ_of_Scope_results.docx
* Other files:		Analysis Plan for Econ of Scope.docx 

* Created by:		Wei Chang
* Date created: 	2Feb2018
*Last Modified:		21 Apr 2018   Sean
***********************


*Preliminaries

*global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Economy of scope" // Wei
global dir = "/Users/sean/Dropbox (Personal)/Research/Papers/Returns to Scope" // Sean


cd "$dir"


*Bring in Data
use "$dir/data/nodrug_paper.dta",clear



/**********************************************************************/
/*  SECTION 1: Experiment 1 - Township Health Centers 	 			
    Notes: Experiement in THCs 
  			Interactions randomized to control, start, before diagnosis
  			TB interactions not included
  			Within each clinic either diarrhea or angina randomized to one of treatment groups
  			Which treatment in each clinic was random*/
/**********************************************************************/

 
/*----------------------------------------------------*/
   /* [>   Table 1.  Experimental Design   <] */ 
/*----------------------------------------------------*/




/*------------------------------------ End of SECTION 1 ------------------------------------*/








	

	
*************************
* Table 1 - Distributions/Experimental Designs
*************************


	

* distribution of observations by level, disease, & treatment
	
	* logout, save($dir/output/distribution) excel replace: table diseasecode arm, by(levelcode) row center
	
/*
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
*/

	

	
*************************
* Table 2: Balance tables for each experiment
*************************






/* balance table by experiment*/
	
	levelsof(level), local(level)
	
	foreach l of local level {
		table1 if level == "`l'", vars(age contn \ male bin \ hiedu bin \ ///
			income contn \ experience contn \ patientload contn \ totrev contn \ net_rev contn) ///
			by(arm) format(%2.1f) one percent ///
			saving("$dir/output/nodrug_tables",sheet("balance_`l'", replace))
		}
		

/***********************
* Figure 1: Cumulative densities for IRT by arm
***********************


*THCs
distplot irtscore if THC==1 & diseasecode!=3 & thc_nd_a==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_end")  ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash) 
			
distplot irtscore if THC==1 & diseasecode!=3 & thc_nd_b==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash)
			
g irt_norm = .
	
	su irtscore if arm==1 & THC==1 & diseasecode!=3 & type==0, det
	replace irt_norm = (irtscore - `r(mean)')/`r(sd)' if THC==1 & diseasecode!=3 & type==0
	
	su irtscore if arm==1 & MVC==1 & type==0, det
	replace irt_norm = (irtscore - `r(mean)')/`r(sd)' if  MVC==1 & type==0
	
	su irtscore if arm==1 & VC==1 & type==0, det
	replace irt_norm = (irtscore - `r(mean)')/`r(sd)' if  VC==1 & type==0

distplot irt_norm if THC==1 & diseasecode!=3 & thc_nd_a==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") label(3 "treat_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash) 
			
distplot irt_norm if THC==1 & diseasecode!=3 & thc_nd_b==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") label(3 "treat_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash)
				
			
*MVCs
distplot irtscore if MVC==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") label(3 "treat_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash) 
			
distplot irt_norm if MVC==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") label(3 "treat_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash) 
			
*VCs

distplot irtscore if VC==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") label(3 "treat_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash) 
			
distplot irt_norm if VC==1 & type==0, over (arm) ///
		title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
		legend(label(1 "control") label(2 "treat_beginning") label(3 "treat_end") ///
			rows(1) size(small)) lcolor(gray black black) ///
			lpattern(shortdash solic dash) 

			

**************************/
* Table 3. Effects on drug prescriptions
**************************


	


	
/*---------------THC------------------*/
global prescription = "drugpres numofdrug totfee numedl numnonedl any_high_profit num_high_profit any_low_profit num_low_profit antibiotic chi_med"
global spcase = "i.diseasecode i.groupcode"	

eststo clear
foreach y of global prescription {
		eststo, title(TFE - "`y'"): areg `y' nodrug_b nodrug_a  i.diseasecode if THC==1 & diseasecode!=3 & type==0, vce(robust) absorb(towncode)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
					
		eststo, title(CFE+SPFE - "`y'"): areg `y' nodrug_b nodrug_a  i.diseasecode i.groupcode  if THC==1 & diseasecode!=3 & type==0, vce(robust) absorb(countycode)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}

esttab using "$dir/output/THC_Drug.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab contmean) label replace nobase nogap mti ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include township and case fixed effects.")
		

		
/* TOT	
		eststo, title(TOT - "`y'"): ivregress gmm `y' (nodrug_b nodrug_a = actual_b actual_a) i.diseasecode  i.towncode if THC==1 & diseasecode!=3 & type==0, vce(robust)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
*/

*tobit numofdrug nodrug_b nodrug_a  $spcase if THC==1 & diseasecode!=3 & type==0, vce(robust) ll(0)

		
/*	
	eststo: areg `y' nodrug_b  		   $spcase if THC==1 & diseasecode!=3 & thc_nd_b==1 & type==0, vce(robust) absorb(towncode)
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
				estadd scalar conmean = `r(mean)'
	eststo: areg `y' 		 nodrug_a  $spcase if THC==1 & diseasecode!=3 & thc_nd_a==1 & type==0, vce(robust) absorb(towncode)
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
				estadd scalar conmean = `r(mean)'
		eststo: ivregress gmm `y' (nodrug_b  = actual_b )   $spcase if THC==1 & diseasecode!=3 & thc_nd_b==1 & type==0, vce(robust) 
					su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		eststo: ivregress gmm `y' ( nodrug_a =  actual_a)  $spcase if THC==1 & diseasecode!=3 & thc_nd_a==1 & type==0, vce(robust) 
					su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)
*/

*Conditional on prescription
*OLS
eststo clear
foreach y of varlist $prescription{ // numofdrug totfee numedl numnonedl any_high_profit num_high_profit antibiotic chi_med{
		eststo: areg `y' nodrug_b nodrug_a   i.diseasecode  if THC==1 & diseasecode!=3 & type==0 & drugpres==1, vce(robust) absorb(towncode)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
					
		eststo: areg `y' nodrug_b nodrug_a   i.diseasecode i.groupcode  if THC==1 & diseasecode!=3 & type==0 & drugpres==1, vce(robust) absorb(countycode)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}
		
		foreach y of varlist any_high_profit num_high_profit any_low_profit num_low_profit{
		
			eststo: areg `y' nodrug_b nodrug_a   i.diseasecode i.groupcode  if THC==1 & diseasecode!=3 & type==0 & (any_high_profit==1 | any_low_profit==1), vce(robust) absorb(countycode)
							test nodrug_b = nodrug_a 
							estadd scalar pval_ab = `r(p)'
							su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
							estadd scalar conmean = `r(mean)'
			}

esttab using "$dir/output/THC_Drug.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab contmean) label append nobase nogap ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include township and case fixed effects.")


/*---------------MVC------------------*/

eststo clear
foreach y of global prescription {
		eststo, title(ITT NOFE - "`y'"): reg `y' nodrug_b nodrug_a  i.diseasecode if MVC==1 & diseasecode!=3 & type==0, vce(robust)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		eststo, title(ITT DOCFE - "`y'"): areg `y' nodrug_b nodrug_a  i.diseasecode if MVC==1 & diseasecode!=3 & type==0, vce(robust) absorb(doctorid)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}

esttab using "$dir/output/MVC_Drug.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab contmean) label replace nobase nogap mti ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include case fixed effects.")
		
eststo clear
foreach y of global prescription {
		eststo, title(ITT NOFE - "`y'"): reg `y' nodrug_b nodrug_a  i.diseasecode if MVC==1 & diseasecode!=3 & type==0 & drugpres==1, vce(robust)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		eststo, title(ITT DOCFE - "`y'"): areg `y' nodrug_b nodrug_a  i.diseasecode if MVC==1 & diseasecode!=3 & type==0 & drugpres==1, vce(robust) absorb(doctorid)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}

		
		reg any_high_profit nodrug_b nodrug_a   i.diseasecode i.groupcode  if MVC==1 & type==0 & (any_high_profit==1 | any_low_profit==1), vce(robust) 
		reg any_high_profit nodrug_b nodrug_a   i.diseasecode i.groupcode  if MVC==1 & type==0 , vce(robust) 
		areg any_high_profit nodrug_b nodrug_a   i.diseasecode  if MVC==1 & type==0 , vce(robust) absorb(doctorid)
		
		areg any_high_profit nodrug_b nodrug_a   i.diseasecode  if MVC==1 & type==0 & drugpres==1, vce(robust) absorb(doctorid)
		areg any_high_profit nodrug_b nodrug_a   i.diseasecode  if MVC==1 & type==0  & (any_high_profit==1 | any_low_profit==1), vce(robust) absorb(doctorid)
		
		
esttab using "$dir/output/MVC_Drug.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab contmean) label append nobase nogap mti ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include case fixed effects.")
		
		
/*---------------VC------------------*/
		
eststo clear
foreach y of global prescription {
		eststo, title(ITT - "`y'"): reg `y' nodrug_b   i.diseasecode if VC==1 & diseasecode!=3 & type==0, vce(robust) 
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		eststo, title(TOT - "`y'"): ivregress gmm `y' (nodrug_b  = actual_b ) i.diseasecode if VC==1 & diseasecode!=3 & type==0, vce(robust)
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}

esttab using "$dir/output/VC_Drug.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b) ///
		scalar(contmean) label replace nobase nogap mti ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include case fixed effects.")
		
		
eststo clear
foreach y of varlist numofdrug totfee numedl numnonedl any_high_profit num_high_profit antibiotic chi_med{
		
		eststo, title(ITT - "`y'"): reg `y' nodrug_b   i.diseasecode if VC==1 & diseasecode!=3 & type==0 & drugpres==1, vce(robust) 
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		eststo, title(TOT - "`y'"): ivregress gmm `y' (nodrug_b  = actual_b ) i.diseasecode if VC==1 & diseasecode!=3 & type==0 & drugpres==1, vce(robust)
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}

esttab using "$dir/output/VC_DrugCond.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b) ///
		scalar(contmean) label replace nobase nogap mti ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include case fixed effects.")
		

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
	global process = "diagtime_min arqe irtscore"
	
	label var diagtime_min "diagnosis time"
	label var arqe "checklist completion % (questions and exam)"
	
	
/*---------------THC------------------*/
						

eststo clear
foreach y of global process{
		eststo, title(ITT - "`y'"): areg `y' nodrug_b nodrug_a  i.diseasecode if THC==1 & diseasecode!=3 & type==0, vce(robust) absorb(towncode)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		eststo, title(TOT - "`y'"): ivregress gmm `y' (nodrug_b nodrug_a = actual_b actual_a) i.diseasecode  i.towncode if THC==1 & diseasecode!=3 & type==0, vce(robust)
				test nodrug_b = nodrug_a 
					estadd scalar pval_ab = `r(p)'
				su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
					estadd scalar conmean = `r(mean)'
		}

esttab using "$dir/output/THC_Proc.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab contmean) label replace nobase nogap mti ///
		title("Effects on drug prescriptions") ///
		addnote("Regressions include township and case fixed effects.")						
						

						
						
reg irtscore nodrug_b  i.diseasecode  i.towncode if THC==1 & diseasecode!=3 & type==0 & thc_nd_b==1, vce(robust)							
reg irtscore nodrug_a  i.diseasecode  i.towncode if THC==1 & diseasecode!=3 & type==0 & thc_nd_a==1, vce(robust)							
areg irtscore nodrug_b nodrug_a  i.diseasecode if THC==1 & diseasecode!=3 & type==0, vce(robust) absorb(towncode)		
						
						
ivregress gmm irtscore ( nodrug_a = actual_a) i.diseasecode  i.towncode if THC==1 & diseasecode!=3 & type==0 & thc_nd_a==1, vce(robust)						
						
						eststo clear
					foreach y of global process {
					
						eststo: reg `y' nodrug_b nodrug_a i.diseasecode  if THC==1 & disease!="T", robust
							test nodrug_b = nodrug_a
						eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) i.diseasecode  if THC==1 & disease!="T", robust
							test actual_b = actual_a 
							}
								
	
	
	
					* Sean 20 Mar
					
					*Village
					eststo clear
					foreach y of global process {
						
						eststo: reg `y' nodrug_b i.diseasecode if VC==1, robust
						eststo: ivregress gmm `y' (actual_b = nodrug_b ) i.diseasecode if VC==1, robust
					}
	
					*Township
	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
* define covariates
	global cvar_fe = "i.diseasecode i.group i.countycode"
	global cvar = "i.irtscore_v_high i.income_high i.experience_high i.patientload_high i.totrev_high"
	
	


					* Sean 20 Mar
					
					*Village
					eststo clear
					foreach y of global prescription {
						
						eststo: reg `y' nodrug_b i.diseasecode if VC==1, robust
						eststo: ivregress gmm `y' (actual_b = nodrug_b ) i.diseasecode if VC==1, robust
					}


	
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
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster towncode)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
				
			
			* IV - arm assignment --> actual treatment (three arms) - THC
			if "`l'" == "Township" & `y' != any_high_profit & `y' != num_high_profit {
				eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) $cvar $cvar_fe if level == "`l'", robust
				test actual_b = actual_a
				estadd scalar pval_bt_treatarm = `r(p)'
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
				
			* IV - arm assignment --> actual treatment (three arms) - Migrant (too many missing for totfee)
			if "`l'" == "Migrant" & `y' != totfee & `y' != any_high_profit & `y' != num_high_profit {
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
			if "`l'" == "Village" & `y' != any_high_profit & `y' != num_high_profit {
				eststo: ivregress gmm `y' (actual_b = nodrug_b) $cvar $cvar_fe if level == "`l'", robust
				
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "robust"
				estadd local MODEL = "IV"
				}
			
			}
	}
	
	esttab using "$dir/output/economyofscope_results.csv", b(%9.3fc) se(%9.3fc) ///
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
	global process = "diagtime_min arqe irtscore"
	
	label var diagtime_min "diagnosis time"
	label var arqe "checklist completion % (questions and exam)"
	
	
					* Sean 20 Mar
					
					*Village
					eststo clear
					foreach y of global process {
						
						eststo: reg `y' nodrug_b i.diseasecode if VC==1, robust
						eststo: ivregress gmm `y' (actual_b = nodrug_b ) i.diseasecode if VC==1, robust
					}
	
					*Township
					eststo clear
					foreach y of global process {
					
						eststo: reg `y' nodrug_b nodrug_a i.diseasecode  if THC==1 & disease!="T", robust
							test nodrug_b = nodrug_a
						eststo: ivregress gmm `y' (actual_b actual_a = nodrug_b nodrug_a) i.diseasecode  if THC==1 & disease!="T", robust
							test actual_b = actual_a 
							}
							
							
* OLS & IV
	

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
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster towncode)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms)
			if "`l'" == "Migrant" | "`l'" == "Township" {
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
	
	esttab using "$dir/output/economyofscope_results.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level SE MODEL) label append nobase nogap ///
		title("Effects on process quality") ///
		addnote("Included county and SP group fixed effects.")
	

		
	* checklist completion rate by arm for THC
		* average arqe by arm for THC
		mean arqe if level == "Township", over(arm)
		* average arqe by actual arm for THC
		mean arqe if level == "Township" & nodrug == 1, over(arm_actual) 
		
	* IRT score by arm
		mean irtscore, over(arm)
		mean irtscore, over(arm_actual)


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
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster towncode)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms)
			if "`l'" == "Migrant" | "`l'" == "Township" {
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
	
	esttab using "$dir/output/economyofscope_results.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level SE MODEL) label append nobase nogap ///
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
				eststo: reg `y' i.arm $cvar $cvar_fe if level == "`l'", vce(cluster towncode)
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'
				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local level = "`l'"
				estadd local SE = "clustered"
				estadd local MODEL = "OLS"
				}
			
			* IV - arm assignment --> actual treatment (three arms) - THC
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
				
			* IV - arm assignment --> actual treatment (three arms) - Migrant (corrdrug == 0 for all)
			if "`l'" == "Migrant" & `y' != corrdrug {
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
	
	esttab using "$dir/output/economyofscope_results.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean level SE MODEL) label append nobase nogap ///
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
	
* excluded treatment!!!
	
foreach y of varlist numofdrug totfee numedl numnonedl $process $diagnosis {
	foreach d of local disease {
		* three arms, including only MC & THC
				* OLS - parsimonious
				eststo: reg `y' i.arm $cvar_fe2 if disease == "`d'", vce(robust) 
				test 2.arm = 3.arm 
				estadd scalar pval_bt_treatarm = `r(p)'

				sum `y' if arm == 1 & e(sample) == 1 /* mean of the control arm */
				estadd scalar control_mean = `r(mean)'	
				estadd local disease = "`d'"
				estadd local SE = "robust"
				estadd local MODEL = "OLS"
				estadd local level = "MC & THC"
			
				* OLS - full
				eststo: reg `y' i.arm $cvar $cvar_fe2 if disease == "`d'", vce(robust) 
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
	
	esttab using "$dir/output/economyofscope_results.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) drop(*.groupcode *.countycode) ///
		scalar(pval_bt_treatarm control_mean disease SE MODEL level) label append nobase nogap ///
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
