cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy of Scope
* Goal: 			Data preparation
* Input data:		SP_total_dataset_1oct2017.dta
*					drugdataset_final_SP2015.dta

* Output: 			nodrug_paper.dta
* Notes:			Most codes are from Xuehao; extracted additional variables for the analysis

* Created by:		Wei Chang
* Date created: 	2Feb2018
*Last Modified:		27 Apr 2018   Sean

***********************

*Preliminaries

*global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Economy of scope" // Wei
global dir = "/Users/sean/Dropbox (Personal)/Research/Papers/Returns to Scope" // Sean


cd "$dir"

global study = "EconomyOfScope"
*log using "$dir/log/$study `c(current_date)'.log",replace

set maxvar 20000
*use "$dir/raw/SP_total_dataset_1oct2017.dta",clear
use "$dir/data/raw/SP_total_dataset_1oct2017.dta",clear


/* 
ID Variables
ID
VillageCode - 251 Distinct
Towncode - 218 distinct

*/


/* Break Out Heuristics Data */

preserve
	
	keep if ruleofthumb==1
	drop *_raw
	
	forvalues i = 1(1)10{
		ren thc_t_i_distypeD`i'  thc_t_i_D`i'
		
		ren vc_a_i_distypeD`i' vc_a_i_D`i'
		
		ren vc_a_i_distypeD`i'a vc_a_i_D`i'a
		
		}
		
	forvalues i = 1(1)10{
		g ROT_disease_`i' = ""
		g ROT_num_`i'=.
			}
			
	g disease_lc = "a" if disease=="A"
		replace disease_lc = "d" if disease=="D"
		replace disease_lc = "t" if disease=="T"
	
	foreach l in a d t{
		forvalues i = 1(1)10{
			replace ROT_disease_`i' = thc_`l'_i_D`i' if level=="Township" & disease_lc=="`l'"
			replace ROT_disease_`i' = vc_`l'_i_D`i' if (level=="Migrant" |  level=="Village") & disease_lc=="`l'"
			
			replace ROT_num_`i' = thc_`l'_i_D`i'a if level=="Township" & disease_lc=="`l'"
			replace ROT_num_`i' = vc_`l'_i_D`i'a if (level=="Migrant" |  level=="Village") & disease_lc=="`l'"
			
			}
	}
	

	keep ID disease level doctorid ROT*

	save "$dir/data/ROT.dta", replace
	
restore



/*-------
Step 1: Get sample readay
--------*/	
	
	drop if ruleofthumb==1 // drop ROT

	drop if CH==1 // drop county
	
*	drop if disease=="T" & THC==1 // Tuberculosis in THCs not in experiment
	
	*Clean up villages
	*drop if dupl_vc_spv_tb==1  // 10 villages have SPs visited two village clinics and keep the largest or finished one
	bys villagecode: egen duplvill_m = max(dupl_vc_spv_tb)
	drop if duplvill_m==1
	
	*Multiple SP or vig...drop odd unmatched
	drop if ID == "SPV_A1106101"  // VC 11061 has a TB visit. drop angina
	drop if ID == "VIG_A1106101" 
	drop if ID == "VIG_A2108201" 
	
	// 210 remaining with both additional 7 odd...
	
	*Townships
	// Towncode 1106 - D only V,SP
	// 1410, 1501, 1510, 2610, 3 SP only
	
	g thc_nd_a = (THCNoDrugTime=="开处方前") & level=="Township"
		replace thc_nd_a=. if level!="Township"

	g thc_nd_b = (THCNoDrugTime=="一开始") & level=="Township"
		replace thc_nd_a=. if level!="Township"
	
	bys level: ta nodrug_b nodrug_a if vignette == 1,m
	replace nodrug_b = . if vignette == 1 & migrant == 1 & nodrug_b == 0
	replace nodrug_a = . if vignette == 1 & migrant == 1 & nodrug_a == 0
	
	replace datainfo = "SPV_VIG_DOC" 	if datainfo == "" & migrant == 1 & (m_datainfo == "SPV_VIG_DOC_FAC_RUL" | m_datainfo == "SPV_VIG_DOC_FAC")
	replace datainfo = "VIG_DOC" 		if datainfo == "" & migrant == 1 & (m_datainfo == "VIG_DOC_FAC_RUL" 	| m_datainfo == "VIG_DOC_FAC")
	replace datainfo = "SPV_DOC" 		if datainfo == "" & migrant == 1 & (m_datainfo == "SPV_DOC_FAC" 		| m_datainfo == "SPV_FAC")
	replace datainfo = "SPV" 			if datainfo == "" & migrant == 1 & m_datainfo == "SPV"

	ta datainfo ,m
	
	ta age male if datainfo == "SPV"
	
	ta nodrug_b nodrug_a if datainfo == "SPV"
	
	drop if datainfo == "VIG" | datainfo == "VIG_DOC" // 13 obs with no SP
	
	
	drop if ID == "SPV_DM111" // too many missing for outcome vars
	
/*	
	The total sample is 1517
	
	In which: 1) 783 in SPs and 2) 734 in vignette
	
	In which: 32 SP visit and 1 vignette do not have provider information
	
*/	
	
/*-------
Step 2: Vignette type 2 - Q10 section 
--------*/	
								// Is this the new drug data??
								// Why only vignette here?
								// Wha is Type 2 v Type 1?? Are Type II the treatment only vignettes?

	preserve
	
			keep if vignette == 1

			keep ///
				diarrhea angina tuberc THC VC MVC doctorid ID towncode countycode disease level ///
				vignette groupcode ///
				Q10_drugpres Q10_numofdrug Q10_antibiotic ///
				Q10_corrdrug Q10_pcorrdrug Q10_corrtreat Q10_pcorrtreat Q10_referral ///
				age male hiedu income pracdoc datainfo
				
			g type = 2

			rename Q10_* *
			
			save "$dir/data/vig_type_2.dta", replace
	restore
	
	
	* append vigentte type 2
	append using "$dir/data/vig_type_2.dta", nolabel
	
	
	replace type = 1 if type == . & vignette == 1 // vignettes
	replace type = 0 if type == . & vignette == 0 // SP
	replace ID = "Q10_" + ID if type == 2 // unique ID
	replace vignette = . if type == 2
	ta type vignette, m
	
	
	label define type 0 "SP" 1 "Vignette type 1" 2 "Vignette type 2"
	label values type type
	
		
	global idvars ID doctorid towncode countycode type level disease datainfo VC THC MVC 
	
	
	
/*-------
Treatmewnt Vars
--------*/	
	
	
gen actual_b = nodrug_b
replace actual_b = 0 if nodrug_b == 1 & nodrug ==0
label var actual_b "actual story_beginning"

gen actual_a = nodrug_a
replace actual_a = 0 if nodrug_a == 1 & nodrug ==0
label var actual_a "actual story_end"	
	
	
global treatvars nodrug_b nodrug_a actual_a actual_b thc_nd_a thc_nd_b THCorder_first-THCNoDrugTime


/*-------
Step 3: Main outcome variables 
--------*/	

	*process vars : diagtime_min diagtime arq arqe irtscore
	global process "diagtime_min diagtime arqe  irtscore"
	
	// irtscore 
	// theta_new missing for migrant
	
		
	* Unncessary/useless drug
	recode corrdrug (1=0) (0=1) if drugpres==1, gen(uselessdrug)
	replace uselessdrug=0 if drugpres==0
	ta corrdrug uselessdrug,m
	label var uselessdrug "Doctor prescribed unnecessary or harmful drugs 1=yes 0=no"
	replace uselessdrug = 1 if drugpres==1 & disease=="T"

	
	*treatment vars : 
		* corrtreat pcorrtreat referral 
		* drugpres numofdrug antibiotic corrdrug pcorrdrug uselessdrug 
		* numedl numnonedl numedlprov numnonprovedl nonedldrug  
	global treatment "corrtreat pcorrtreat referral drugpres numofdrug antibiotic corrdrug pcorrdrug uselessdrug numedl numnonedl numedlprov numnonprovedl nonedldrug chi_med"
	
	foreach x of global treatment { 
			di "missing values for SP or vignette interactions: `x'"
			count if `x' == . & type != 2
		}	
	
	
	ta disease type if corrdrug == ., m
	ta disease type if pcorrdrug == ., m
	* for TB, do not have "corrdrug" & "pcorrdrug" vars
		// SS: There is no correct drug for TB....drugs should not be prescribed
		
		
	*treatment vars including vignette type 2: 
		* corrtreat pcorrtreat referral 
		* drugpres numofdrug antibiotic corrdrug pcorrdrug uselessdrug 
		
	foreach x of varlist ///
		corrtreat pcorrtreat referral ///
		drugpres numofdrug antibiotic corrdrug pcorrdrug uselessdrug ///
		{ 
			count if `x' == .
		}
		
	
	foreach x of varlist ///
		numedl numnonedl numedlprov numnonprovedl nonedldrug ///
		{ 
			count if `x' == . & type != 2
		}
	
	
	* high-profit drugs
		* merge profit rating for each drug (med_code1 - med_code 11)
										// PLEASE PUT THIS DATA IN DROPBOX FOLDER
		foreach n of numlist 1/11 {
			rename med_code`n' med_code
			merge m:1 med_code using "$dir/data/drugdataset_final_SP2015.dta", keepus(high_profit)
			drop if _merge == 2
			drop _merge
			rename med_code med_code`n'
			rename high_profit high_profit`n'
			}
		
		* count number of high_profit* missing 
		egen m_high_profit = rmiss(high_profit*)
		
		
		* generate high-profit drug = 1 if any high-profit drug was given
		egen any_high_profit = anymatch(high_profit*),v(1)
		replace any_high_profit = . if m_high_profit == 11

		label var any_high_profit "any high profit drug"
		
		* generate number of high-profit drugs prescribed
		egen num_high_profit = rowtotal(high_profit*) if m_high_profit != 11
		label var num_high_profit "number of high profit drugs"
		
		sum any_high_profit num_high_profit
		tab any_high_profit, m
		
		
		* generate low-profit drug = 1 if any low-profit drug was given
		egen any_low_profit = anymatch(high_profit*),v(0)
		replace any_low_profit = . if m_high_profit == 11

		label var any_low_profit "any low profit drug on list"
		
		* generate number of high-profit drugs prescribed
		gen num_low_profit = (11 - m_high_profit) - num_high_profit
		label var num_low_profit "number of low profit drugs"
		
		sum any_low_profit num_high_profit
		tab any_low_profit, m
		

		
		// NOT DEFINED FOR TYPE 2
		
/*-------
Step 4: Main control vars
--------*/	

	/* $control1 - clinic level:  
		towncode countycode THC VC MVC angina diarrhea tuberc groupcode 
		doctorid 
		thc_f_b_f04 vc_f_b_d2_6 vc_f_b_d2_14 thc_f_b_f10 (related to revenue)*/
	
	global control1 = " groupcode thc_f_b_f04 vc_f_b_d2_14 thc_f_b_f10 vc_f_b_d2_6"
	
	foreach x of global control1 {
			di "missing count: variable - `x'"
			count if `x' == . 
		}
		* for MVC, some of them do not have "groupcode"
	
	foreach x of varlist thc_f_b_f04 vc_f_b_d2_6 thc_f_b_f10 vc_f_b_d2_6 {
		di "missing count: variable - `x'"
		tab `x' level if missing(`x'),m
		}
		* lots of missing values for revenue variables.
	
	* $control2 - string vars: disease level ID datainfo 
	global control2 = "disease level ID datainfo clinicid"
	foreach x of global control2 { 
			di "missing count: variable - `x'"
			count if `x' == ""
		}
	
	/* $control3 - provider vars: 
		age male hiedu income pracdoc patientload year */
	global control3 = "age male hiedu income pracdoc patientload year"
	foreach x of global control3 { 
			di "missing count: variable - `x'"
			count if `x' == .
		}
		* only SP has "patientload", and there are some missing for provider characteristics	
			//ADD PATIENTLOAD TO VIGNETTE DATA...IT IS CLINICL LEVEL VARIABLE
	
	
/*-------
Step 5: Clean data for nodrug paper
--------*/		

	
	global chi_meds "thc_t_v_Q9_9 vc_t_v_Q9_9 thc_t_v_Q9_10 vc_t_v_Q9_10 " // ch_t_v_Q9_10  ch_t_v_Q9_9 
	
	des $idvars $treatvars  $process $diagnosis $treatment $control1 $control2 $control3 $arm $chi_meds
	

	keep $idvars $treatvars $process $diagnosis $treatment $control1 $control2 $control3 ///
		 patientload drugfee totfee $chi_meds any_high_profit num_high_profit  any_low_profit num_low_profit
					
	order $idvars $treatvars $process $diagnosis $treatment $control1 $control2 $control3 ///
		 patientload drugfee totfee $chi_meds any_high_profit num_high_profit  any_low_profit num_low_profit

	 
		 
	compress
	save "$dir/data/nodrug_paper.dta",replace
