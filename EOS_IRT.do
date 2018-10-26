cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy to Scope
* Goal: 			IRT Generation and Analysis
* Input data:		nodrug_paper.dta

*Oct 23
***********************

*Preliminaries

global dir = "/Users/sean/Dropbox (Personal)/Research/Papers/Returns to Scope" // Sean

cd "$dir"


*Bring in Data
use "$dir/data/nodrug_paper.dta",clear


/*-------
Angina IRT 
--------*/	


*SP
keep if disease=="A" & type==0
keep doctorid rq1_ang-rq13_ang re1_ang-re5_ang nodrug_b nodrug_a

	* Selecting items with positive response>=0.06 plus Angina_test
	/*Items with positive response >=0.06*/
	des rq1_ang-rq13_ang re1_ang-re5_ang,varlist
	local varlist "`r(varlist)'"

	capture drop newvarlist
	foreach v of varlist rq1_ang-rq13_ang  { // re1_ang-re5_ang
	sum `v'
	if r(mean)>=0.05 {
	local newvarlist `newvarlist' `v'
	}
	}

	di in ye "`newvarlist'" 
	local newvarlist `newvarlist'
	di in white "`newvarlist'" 

	*correlation
	pwcorr `newvarlist'
	* Reliability
	alpha `newvarlist'
	local alpha="`r(alpha)'"

	* Unidimensionality 
	quietly factor `newvarlist',pcf	
	
	mat eigenval=e(Ev)'
	svmat eigenval, names(eigenval)
	format eigenval1 %9.2f
	replace eigenval1=. if eigenval1<1
	screeplot, mlabel(eigenval1) mlabangle(forty_five) yline(1) note("Alpha=`alpha'") name(item_selected, replace) title("Selected Items", color(blue) size(medium))
*  graph export "spv_angina_screelpot.pdf",replace
	drop  eigenval1

	* Loevinger's H coefficients
	loevh `newvarlist'
	mat a= r(loevHj)'
	mat list a

	* Rename variable for IRT calculation
	local i 1
	foreach v of local newvarlist {
		local lab`v' : variable label `v'
		gen item`i' = `v'
		lab var item`i' "`lab`v''"
		local i = `i'+1
    }

	* Save data with items
	preserve
	keep doctorid item*
	save "spv_angina_selected_items_list.dta", replace
	restore

	* Estimate theta for selected items
	preserve
	set seed 19901018
	openirt, id(doctorid) item_prefix(item) save_item_parameters ("spv_angina_items.dta") save_trait_parameters ("spv_angina_traits.dta") // model(2pl)
	restore

	* Merge data with Theta Score (selected items but all providers)
	gen id=doctorid
	merge 1:1 id using "spv_angina_traits.dta", keepus(theta_mle theta_mle_se)
	drop id _merge

	* Histogram
	gen lower = theta_mle-1.96*theta_mle_se
	gen upper = theta_mle+1.96*theta_mle_se

	#delimit ;
	twoway (histogram theta_mle, percent) 
	(line theta_mle theta_mle, sort yaxis(2)) 
	(line upper theta_mle, sort yaxis(2)) 
	(line lower theta_mle, sort yaxis(2)), 
	name(theta_selected, replace) xlabel(-5(1)3.5) title("Selected Items");
	#delimit cr
	graph export "spv_angina_theta_selected.pdf", replace
	drop upper lower   

* Construct Ability groups
	egen theta_mle_cut = cut(theta_mle), group(13)
	bys theta_mle_cut: egen mean_theta=mean(theta_mle)

	* Average Observed responses per item
	forvalues i =1/9 {
		bys theta_mle_cut: egen obs_resp_item`i'=mean(item`i')
		}

	* Save temporal file to create graph
	egen tag=tag(theta_mle_cut mean_theta)
	keep if tag==1
	drop doctorid-theta_mle_se tag

	* Need items parameters
	preserve
	use "spv_angina_items", clear
	mkmat  id a_eap b_eap c_eap, matrix(item_parameters)
	restore
	mat dir
	 
	* Item characteristic curves
	svmat item_parameters
	rename item_parameters2 a
	rename item_parameters3 b
	rename item_parameters4 c
	forvalues n=1/9 {
	twoway (function c[`n'] + (1-c[`n'])/(1+exp(-1.7*a[`n']*(x-b[`n']))), range(-5 3)) ///
		 (scatter obs_resp_item`n' mean_theta), xlabel(-4(2)2) legend(off) scheme(s2mono) ylabel(0(.2)1) ///
		 xtitle("Theta") ytitle("Probability Correct") title("Item `n'") name(item`n', replace) nodraw
		 }

	graph combine item1 item2 item3 item4 item5 item6 item7 item8 item9, ///
	col(4) name(graph1, replace) scheme(s2mono) ysize(12) xsize(8)
	graph export "spv_angina_selected_items.pdf", replace

	*======================================================*
	* Difficulty and Discrimination of Items
	*======================================================*
	use "spv_angina_items", clear
	twoway (scatter a_eap b_eap, msymbol(smtriangle) mlabel(id)  mcolor(black) mlabposition(12) mlabsize(vsmall)), ///
			  xtitle("Item Difficulty") ytitle("Item Discrimination") title("Selected Items", color(blue) size(medium))
	graph export "spv_angina_item_parameters.pdf", replace

stop 

/*-------
Step 3: Diarrhea IRT socre
--------*/	
	
	clear all
	
	/*--------
	Step 3.1: Diarrhea_SPV
	--------*/

	use "$dir/data/nodrug_paper.dta",clear
	set more off
	keep if disease=="D" & type==0
	keep doctorid rq2_dia-rq18_dia

	* Selecting items with positive response>=0.06 plus Diarrhea_test
	/*Items with positive response >=0.06*/
	des rq2_dia-rq18_dia,varlist
	local varlist "`r(varlist)'"

	capture drop newvarlist
	foreach v of varlist rq2_dia rq3_dia rq4_dia rq5_dia rq6_dia rq7_dia rq8_dia rq9_dia rq10_dia rq11_dia rq12_dia rq13_dia rq14_dia rq15_dia rq18_dia{
	sum `v'
	if r(mean)>=0.05 {
	local newvarlist `newvarlist' `v'
	}
	}
	
	di in ye "`newvarlist'" 
	local newvarlist `newvarlist'
	di in white "`newvarlist'" 

	* Reliability
	alpha `newvarlist'
	local alpha="`r(alpha)'"

	* Unidimensionality 
	quietly factor `newvarlist',pcf	
	
	mat eigenval=e(Ev)'
	svmat eigenval, names(eigenval)
	format eigenval1 %9.2f
	replace eigenval1=. if eigenval1<1
	screeplot, mlabel(eigenval1) mlabangle(forty_five) yline(1) note("Alpha=`alpha'") name(item_selected, replace) title("Selected Items", color(blue) size(medium))
	graph export "spv_diarrhea_screelpot.pdf",replace
	drop  eigenval1

	* Loevinger's H coefficients
	loevh `newvarlist'
	mat a= r(loevHj)'
	mat list a

	* Rename variable for IRT calculation
	local i 1
	foreach v of local newvarlist {
		local lab`v' : variable label `v'
		gen item`i' = `v'
		lab var item`i' "`lab`v''"
		local i = `i'+1
    }

	* Save data with items
	preserve
	keep doctorid item*
	save "spv_diarrhea_selected_items_list.dta", replace
	restore

	* Estimate theta for selected items in TB
	preserve
	set seed 19901018
	openirt, id(doctorid) item_prefix(item) save_item_parameters ("spv_diarrhea_items.dta") save_trait_parameters ("spv_diarrhea_traits.dta") // model(2pl)
	restore
	  
	* Merge data with Theta Score (selected items but all providers)
	gen id=doctorid
	merge 1:1 id using "spv_diarrhea_traits.dta", keepus(theta_mle theta_mle_se)
	drop id _merge

	* Histogram
	gen lower = theta_mle-1.96*theta_mle_se
	gen upper = theta_mle+1.96*theta_mle_se

	#delimit ;
	twoway (histogram theta_mle, percent) 
	(line theta_mle theta_mle, sort yaxis(2)) 
	(line upper theta_mle, sort yaxis(2)) 
	(line lower theta_mle, sort yaxis(2)), 
	name(theta_selected, replace) xlabel(-5(1)3.5) title("Selected Items");
	#delimit cr
	graph export "spv_diarrhea_theta_selected.pdf", replace
	drop upper lower   

	* Construct Ability groups
	egen theta_mle_cut = cut(theta_mle), group(11)
	bys theta_mle_cut: egen mean_theta=mean(theta_mle)

	  
	* Average Observed responses per item
	forvalues i =1/10 {
		bys theta_mle_cut: egen obs_resp_item`i'=mean(item`i')
		}

	* Save temporal file to create graph
	egen tag=tag(theta_mle_cut mean_theta)
	keep if tag==1
	drop doctorid-theta_mle_se tag

	* Need items parameters
	preserve
	use "spv_diarrhea_items", clear
	mkmat  id a_eap b_eap c_eap, matrix(item_parameters)
	restore
	mat dir
	 
	* Item characteristic curves
	svmat item_parameters
	rename item_parameters2 a
	rename item_parameters3 b
	rename item_parameters4 c
	forvalues n=1/10 {
	twoway (function c[`n'] + (1-c[`n'])/(1+exp(-1.7*a[`n']*(x-b[`n']))), range(-5 3)) ///
		 (scatter obs_resp_item`n' mean_theta), xlabel(-4(2)2) legend(off) scheme(s2mono) ylabel(0(.2)1) ///
		 xtitle("Theta") ytitle("Probability Correct") title("Item `n'") name(item`n', replace) nodraw
		 }

	graph combine item1 item2 item3 item4 item5 item6 item7 item8 item9 item10 , ///
	col(4) name(graph1, replace) scheme(s2mono) ysize(12) xsize(8)
	graph export "spv_diarrhea_selected_items.pdf", replace

	*======================================================*
	* Difficulty and Discrimination of Items
	*======================================================*

	use "spv_diarrhea_items", clear
	twoway (scatter a_eap b_eap, msymbol(smtriangle) mlabel(id)  mcolor(black) mlabposition(12) mlabsize(vsmall)), ///
			  xtitle("Item Difficulty") ytitle("Item Discrimination") title("Selected Items", color(blue) size(medium))
	graph export "spv_diarrhea_item_parameters.pdf", replace

/*-------
Step 4: append IRT score together
--------*/	

	clear all
	capture log close
	set maxvar  30000
	set more off
	
	
	/*--------
	Step 4.1: Append IRT resutls together
	--------*/
	use "spv_diarrhea_traits.dta", clear

	gen disease="D"
	gen type=0


	/*append Angina*/
	append using spv_angina_traits.dta
	replace type=0 if type==.
	replace disease="A" if disease==""
	

	/*--------
	Step 4.2: gen ID
	--------*/
	order type disease id
	gen ID=""
	label var ID "individual case ID for each doctor with SPV"
	tostring id,replace
	
	* MVC doctorid have been changed
	replace id = "M" + substr(id,-3,3) if substr(id,1,2)=="99"
	
	replace ID="SPV_"+disease+id if type==0
	*replace ID="VIG_"+disease+id if vignette==1
	order ID 
	
	keep ID theta_mle theta_mle_se
	rename theta_mle irtscore
	rename theta_mle_se irtscore_se
	label var irtscore "IRT score"
	label var irtscore_se "IRT score standard error"
	
	save "IRT_score_nodrug.dta",replace
