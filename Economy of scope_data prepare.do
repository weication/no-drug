cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy of Scope
* Goal: 			Data preparation
* Input data:		SP_total_dataset_1oct2017.dta
* Output: 			nodrug_paper.dta
* Notes:			Most codes are from Xuehao; extracted additional variables for the analysis

* Created by:		Wei Chang
* Date created: 	2Feb2018
***********************


global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Economy of scope"
cd "$dir"

global study = "EconomyOfScope"
log using "$dir/log/$study `c(current_date)'.log",replace

set maxvar 20000
use "$dir/raw/SP_total_dataset_1oct2017.dta",clear


/*-------
Step 1: Get sample readay
--------*/	
	des CH disease ruleofthumb dupl_vc_spv_tb ID nodrug_b nodrug_a vignette datainfo
	

	drop if CH==1
	
	drop if disease=="T" & THC==1
	
	drop if ruleofthumb == 1
	
	drop if dupl_vc_spv_tb==1  // 10 villages have SPs visited two village clinics and keep the largest or finished one

	drop if ID == "SPV_A1106101"  // VC 11061 has a TB visit. To consistent with TB paper, drop this
	
	bys level: ta nodrug_b if vignette == 0, m
	bys level: ta nodrug_a if vignette == 0, m
	
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
	
	drop if datainfo == "VIG" | datainfo == "VIG_DOC"
	
	
	drop if ID == "SPV_DM111" // too many missing for outcome vars
	
	
	ta level vignette,m
	ta datainfo vignette,m
	
	
/*	
	The total sample is 1517
	
	In which: 1) 783 in SPs and 2) 734 in vignette
	
	In which: 32 SP visit and 1 vignette do not have provider information
	
*/	
	
/*-------
Step 2: Vignette type 2 - Q10 section
--------*/	

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
	
	
	replace type = 1 if type == . & vignette == 1
	replace type = 0 if type == . & vignette == 0
	replace ID = "Q10_" + ID if type == 2
	replace vignette = . if type == 2
	ta type vignette, m
	
	g spvig1 = 1 if vignette == 0
	replace spvig1 = 0 if type == 1
	ta spvig1 vignette, m
	
	g spvig2 = 1 if vignette == 0
	replace spvig2 = 0 if type == 2
	ta spvig2 vignette, m
	
	recode vignette (1=0) (0=1), gen(newvignette)
	
	recode type (2=0) if vignette !=0 , gen(vig1vig2)
	ta vig1vig2 vignette, m
	
	label define type 0 "SP" 1 "Vignette type 1" 2 "Vignette type 2"
	label values type type
	
	drop newtype
	
	label var vig1vig2 ""
		

/*-------
Step 3: Main outcome variables 
--------*/	
	
	ta type
	
	list ID corrdrug referral if diagtime_min ==. & type == 0
	
	des arq arqe 
	label list type
	

	*process vars : diagtime_min diagtime arq arqe irtscore
	global process "diagtime_min diagtime arq arqe irtscore"

	foreach x of global process {
			di "missing values for SP or vignette interactions: `x'"
			count if `x' == . & type != 2
		}

	
	*diagnosis vars : gavediag corrdiag wrongdiag 
	global diagnosis "gavediag corrdiag wrongdiag pcorrdiag"

	foreach x of global diagnosis { 
			di "missing values for SP or vignette interactions: `x'"
			count if `x' == . & type != 2
		}
	
	des corrdrug drugpres
	tab corrdrug drugpres
		
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
		
/*-------
Step 4: Main control vars
--------*/	

	/* $control1 - clinic level:  
		towncode countycode THC VC MVC angina diarrhea tuberc groupcode 
		doctorid 
		thc_f_b_f04 vc_f_b_d2_6 vc_f_b_d2_14 thc_f_b_f10 (related to revenue)*/
	
	global control1 = "towncode countycode THC VC MVC angina diarrhea tuberc groupcode doctorid thc_f_b_f04 vc_f_b_d2_14 thc_f_b_f10 vc_f_b_d2_6"
	
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
	
	
/*-------
Step 5: Clean data for nodrug paper
--------*/		

	global arm "nodrug*"
	
	des $process $diagnosis $treatment $control1 $control2 $control3 $arm 
	keep $process $diagnosis $treatment $control1 $control2 $control3 $arm ///
		type patientload drugfee totfee thc_id vc_id


	compress
	save "$dir/data/nodrug_paper.dta",replace
