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

*Oct 18
***********************

*Preliminaries

global dir = "/Users/sean/Dropbox (Personal)/Research/Papers/Returns to Scope" // Sean

cd "$dir"


*Bring in Data
use "$dir/data/nodrug_paper.dta",clear


*Sample
keep if type==0
drop if diseasecode==3


*************
*Effort Indexes
*************

*Merge in new IRT score
drop irt*
sort ID
merge 1:1 ID using IRT_score_nodrug.dta
drop _merge


*Using only questions
egen pct_cl = rowtotal(rq1_ang-rq13_ang) if diseasecode==1
	replace pct_cl = pct_cl/13 if diseasecode==1
egen pct_cl_d=rowtotal(rq2_dia-rq15_dia rq17_dia rq18_dia) if diseasecode==2
	replace pct_cl_d = pct_cl_d/17  if diseasecode==2
replace pct_cl= pct_cl_d if diseasecode==2

*Excluding rq16&18
egen pct_cl2 = rowtotal(rq1_ang-rq13_ang re1_ang re2_ang re3_ang re4_ang re5_ang) if diseasecode==1
	replace pct_cl2 = pct_cl2/13 if diseasecode==1
egen pct_cl_d2=rowtotal(rq2_dia rq3_dia rq4_dia rq5_dia rq6_dia rq7_dia rq8_dia rq9_dia rq10_dia rq11_dia rq12_dia rq13_dia rq14_dia rq15_dia rq18_dia) if diseasecode==2
	replace pct_cl_d2 = pct_cl_d2/15  if diseasecode==2
replace pct_cl2= pct_cl_d2 if diseasecode==2


*Globals
global treatment = "corrtreat pcorrtreat corrdrug pcorrdrug referral"
global effort = "diagtime_min pct_cl pct_cl2 irtscore "
global effort_item_a = "rq1_ang rq2_ang rq3_ang rq4_ang rq5_ang rq6_ang rq7_ang rq8_ang rq9_ang rq10_ang rq11_ang rq12_ang rq13_ang re1_ang re2_ang re3_ang re4_ang re5_ang"
global effort_item_d = "rq2_dia rq3_dia rq4_dia rq5_dia rq6_dia rq7_dia rq8_dia rq9_dia rq10_dia rq11_dia rq12_dia rq13_dia rq14_dia rq15_dia rq18_dia"
global prescription1 = "drugpres numofdrug uselessdrug numedl numnonedl antibiotic chi_med"
global prescription2 = "any_high_profit num_high_profit any_low_profit num_low_profit"


eststo clear
		qui foreach y of global effort {		
				eststo, title("`y'"): reghdfe `y' nodrug_b nodrug_a if (THC==1 | MVC==1 | VC==1), vce(robust) absorb(i.levelcode i.diseasecode)
						test nodrug_b = nodrug_a 
							estadd scalar pval_ab = `r(p)'
						su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
							estadd scalar conmean = `r(mean)'
				}

		esttab using "MainEffort.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab conmean) label replace nobase nogap mti compress  ///
		title("Effects on effort") ///
		addnote("Regressions include level and case fixed effects.")


eststo clear
		qui foreach y of global effort_item_a {		
				eststo, title("`y'"): reghdfe `y' nodrug_b nodrug_a if (THC==1 | MVC==1 | VC==1) & diseasecode==1, vce(robust) absorb(i.levelcode i.diseasecode)
						test nodrug_b = nodrug_a 
							estadd scalar pval_ab = `r(p)'
						su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
							estadd scalar conmean = `r(mean)'
				}

		esttab using "Angina_items.csv" , b(%9.3fc) se(%9.3fc)  ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab conmean) label replace nobase nogap mti compress  ///
		title("Effects on effort - Angina Items") ///
		addnote("Regressions include level and case fixed effects.")

eststo clear
		qui foreach y of global effort_item_d {		
				eststo, title("`y'"): reghdfe `y' nodrug_b nodrug_a if (THC==1 | MVC==1 | VC==1) & diseasecode==2, vce(robust) absorb(i.levelcode i.diseasecode)
						test nodrug_b = nodrug_a 
							estadd scalar pval_ab = `r(p)'
						su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
							estadd scalar conmean = `r(mean)'
				}

		esttab using "Diarrhea_items.csv", b(%9.3fc) se(%9.3fc)  ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab conmean) label replace nobase nogap mti compress  ///
		title("Effects on effort - Diarrhea Items") ///
		addnote("Regressions include level and case fixed effects.")

eststo clear
		qui foreach y of global prescription1 {		
				eststo, title("`y'"): reghdfe `y' nodrug_b nodrug_a if (THC==1 | MVC==1 | VC==1), vce(robust) absorb(i.levelcode i.diseasecode)
						test nodrug_b = nodrug_a 
							estadd scalar pval_ab = `r(p)'
						su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
							estadd scalar conmean = `r(mean)'
				}

		esttab using "Main_Pres.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab conmean) label replace nobase nogap mti compress  ///
		title("Effects on Prescriptions 1") ///
		addnote("Regressions include level and case fixed effects.")

eststo clear
		qui foreach y of global prescription2 {		
				eststo, title("`y'"): reghdfe `y' nodrug_b nodrug_a if (THC==1 | MVC==1 | VC==1), vce(robust) absorb(i.levelcode i.diseasecode)
						test nodrug_b = nodrug_a 
							estadd scalar pval_ab = `r(p)'
						su `y' if nodrug_b==0 & nodrug_a==0 & e(sample)==1
							estadd scalar conmean = `r(mean)'
				}

		esttab using "Main_Drugprof.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(nodrug_b nodrug_a) ///
		scalar(pval_ab conmean) label replace nobase nogap mti compress  ///
		title("Effects on Prescriptions 2") ///
		addnote("Regressions include level and case fixed effects.")



*************
*Correlation between effort and treatment
*************
eststo clear
		qui foreach y of global treatment {		
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==0 & nodrug_a==0, vce(robust) absorb(i.levelcode i.diseasecode)
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==1 & nodrug_a==0, vce(robust) absorb(i.levelcode i.diseasecode)
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==0 & nodrug_a==1, vce(robust) absorb(i.levelcode i.diseasecode)
				}

		esttab using "Effort-TreamtentCorr.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(irtscore) ///
		label replace nobase nogap mti compress  ///
		title("Effort-Treatment Correlations") ///
		addnote("Regressions include level and case fixed effects.")

eststo clear
		qui foreach y of global prescription1 {		
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==0 & nodrug_a==0, vce(robust) absorb(i.levelcode i.diseasecode)
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==1 & nodrug_a==0, vce(robust) absorb(i.levelcode i.diseasecode)
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==0 & nodrug_a==1, vce(robust) absorb(i.levelcode i.diseasecode)
				}

		esttab using "Effort-PrescriptionCorr.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(irtscore) ///
		label replace nobase nogap mti compress  ///
		title("Effort-Prescription Correlations") ///
		addnote("Regressions include level and case fixed effects.")

eststo clear
		qui foreach y of global prescription2 {		
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==0 & nodrug_a==0, vce(robust) absorb(i.levelcode i.diseasecode)
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==1 & nodrug_a==0, vce(robust) absorb(i.levelcode i.diseasecode)
				eststo, title("`y'"): reghdfe `y' irtscore if nodrug_b==0 & nodrug_a==1, vce(robust) absorb(i.levelcode i.diseasecode)
				}

		esttab using "Effort-DrugproffCorr.csv", b(%9.3fc) se(%9.3fc) ///
		starlevels( * 0.1 ** 0.05 *** 0.01) ar2(2) keep(irtscore) ///
		label replace nobase nogap mti compress  ///
		title("Effort-Prescription Correlations 2") ///
		addnote("Regressions include level and case fixed effects.")


distplot irtscore , over (arm) ///
	title("Cumulative densities of IRT scores by treatment arm", size(medium)) ///
	legend(label(1 "control") label(2 "pre-diagnosis") label(3 "post-diagnosis") rows(1) size(small)) ///
	lcolor(gray black black) lpattern(shortdash solic dash) 

	graph export fig1a.png, width(300) replace


twoway (lpoly pcorrtreat pct_cl2) (kdensity pct_cl2, yaxis(2))
twoway (lpoly pcorrtreat pct_cl2 if nodrug_b==0 & nodrug_a==0) ///
(lpoly pcorrtreat pct_cl2 if nodrug_b==1 & nodrug_a==0) ///
(lpoly pcorrtreat pct_cl2 if nodrug_b==0 & nodrug_a==1) ///
(kdensity pct_cl2, yaxis(2)), ///
legend(label(1 "control") label(2 "pre-diagnosis") label(3 "post-diagnosis") rows(1) size(small)) 


twoway (lpoly pcorrtreat pct_cl if nodrug_b==0 & nodrug_a==0) ///
(lpoly pcorrtreat pct_cl if nodrug_b==1 & nodrug_a==0) ///
(lpoly pcorrtreat pct_cl if nodrug_b==0 & nodrug_a==1) ///
(kdensity pct_cl, yaxis(2)), ///
legend(label(1 "control") label(2 "pre-diagnosis") label(3 "post-diagnosis") rows(1) size(small)) 	


twoway (lpoly uselessdrug pct_cl2) (kdensity pct_cl2, yaxis(2))
twoway (lpoly uselessdrug pct_cl2 if nodrug_b==0 & nodrug_a==0) ///
(lpoly uselessdrug pct_cl2 if nodrug_b==1 & nodrug_a==0) ///
(lpoly uselessdrug pct_cl2 if nodrug_b==0 & nodrug_a==1) ///
(kdensity pct_cl2, yaxis(2)), ///
legend(label(1 "control") label(2 "pre-diagnosis") label(3 "post-diagnosis") rows(1) size(small)) 

twoway (lpoly any_high_profit pct_cl2 if nodrug_b==0 & nodrug_a==0) ///
(lpoly any_high_profit pct_cl2 if nodrug_b==1 & nodrug_a==0) ///
(lpoly any_high_profit pct_cl2 if nodrug_b==0 & nodrug_a==1) ///
(kdensity pct_cl2, yaxis(2)) if pct_cl2<0.7, ///
legend(label(1 "control") label(2 "pre-diagnosis") label(3 "post-diagnosis") rows(1) size(small)) 

twoway (lpoly any_low_profit pct_cl2 if nodrug_b==0 & nodrug_a==0) ///
(lpoly any_low_profit pct_cl2 if nodrug_b==1 & nodrug_a==0) ///
(lpoly any_low_profit pct_cl2 if nodrug_b==0 & nodrug_a==1) ///
(kdensity pct_cl2, yaxis(2)) if pct_cl2<0.7, ///
legend(label(1 "control") label(2 "pre-diagnosis") label(3 "post-diagnosis") rows(1) size(small)) 






		
