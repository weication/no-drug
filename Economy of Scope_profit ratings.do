cap log close
clear all
set more off
set logtype t

***********************
* Project: 			Economy of Scope
* Goal: 			Drug profitability ratingsn
* Input data:		profit_ratings.dta
* Output: 			profit_ratings_agreement.xlsx (for inter-rater reliability)
*					high_profit_drugs.dta (for final ratings for each drug)
* Notes:			Some codes from Sophie Sun (step 1 & 2)

* Created by:		Wei Chang
* Date created: 	14Feb2018
***********************


global dir = "/Users/Wei/Google Drive/PhD/Work/RA for Sean/Economy of scope"
cd "$dir"

global study = "EconomyOfScope"
log using "$dir/log/$study `c(current_date)'.log",replace

use "$dir/raw/profit_ratings.dta",clear



***** 1. Construct the ratings dataset
/* 
import excel "$datadir/Drug Price/药品打分 - 彩石镇.xlsx", clear cellrange(A2:F84) firstrow

save "$datadir/profit_ratings.dta", replace

import excel "$datadir/Drug Price/药品打分－未央宫.xlsx", clear  firstrow

replace 药品名称 = "美托洛尔" if 药品名称 == "美托罗尔"
replace 药品名称 = "硝酸甘油片" if 药品名称 == "硝酸甘油片（消心痛）"

merge 1:1 药品名称 using "$datadir/profit_ratings.dta"

tab 药品名称 if _m != 3
drop if _m != 3 
drop _m 

save "$datadir/profit_ratings.dta", replace
*/



****** 2. Evaluate rater reliability 
global RATERS 未央宫个体诊所1 未央宫村卫生室1 未央宫村卫生室2 未央宫个体诊所2 未央宫社区服务站 彩石镇卫生院 彩石镇村卫生室1 彩石镇村卫生室2 彩石镇村卫生室3


* categorize ratings into high- and low-profit drugs (based on median of each rater)

foreach rater of varlist $RATERS {

	replace `rater' = . if `rater' == 888
	sum `rater', det
	local med = `r(p50)'
	replace `rater' = 0 if `rater' <= `med'
	replace `rater' = 1 if `rater' > `med' &  `rater' != .
	//replace `rater' = 0 if `rater' <= 5
	//replace `rater' = 1 if `rater' > 5 &  `rater' != .

}


putexcel set "$dir/output/profit_ratings_agreement.xlsx", modify
local counter = 3
foreach rater1 of varlist $RATERS {
	local col = upper(substr("`c(alpha)'",`counter',1))
	local row = 4

	putexcel `col'3 = "`rater1'"
	foreach rater2 of varlist $RATERS {
		if "`rater1'" != "`rater2'" {
			kap `rater1' `rater2'
			local kappa = r(kappa)
		}
		else {
			local kappa = 1
		}
		putexcel `col'`row' = `kappa'
		//display "`col'`row' `kappa'"
		putexcel A`row' = "`rater2'"
		local row = `row' + 1 
	}
	local counter = `counter'+2

}

* using 0 as the cutoff, drop ratings from 未央宫社区服务站
drop 未央宫社区服务站



****** 3. create rating index based on "reliable" raters


global raters 未央宫个体诊所1 未央宫村卫生室1 未央宫村卫生室2 未央宫个体诊所2 彩石镇卫生院 彩石镇村卫生室1 彩石镇村卫生室2 彩石镇村卫生室3

* impute missing values in the ratings
	egen rating_mean = rowmean($raters) 
	label var rating_mean "mean of nonmissing ratings"
	
	foreach r of global raters {
		gen `r'_imputed = `r'
		replace `r'_imputed = rating_mean if `r'_imputed ==.
		label var `r'_imputed "`r'-missing replaced with mean"
		}
		

polychoricpca  *_imputed, score(profit_index) nscore(1)


* define high-profit drugs as index score > median
	sum profit_index,d
	local med = `r(p50)'
	gen high_profit = .
	replace high_profit = 1 if profit_index > `med' & !missing(profit_index)
	replace high_profit = 0 if profit_index <= `med'
	label var high_profit "dummy for high profit drugs"
	label define lhigh_profit 1 "profit index > p50" 0 "profit index <= p50"
	label values high_profit lhigh_profit
	tab high_profit
	
* create datafile of drug profit ratings
	rename 药品名称 med_name
	save "$dir/data/high_profit_drugs.dta", replace
		use "$dir/data/high_profit_drugs.dta", clear

******** 4. merge ratings with the drug dataset
	
	use "$dir/raw/drugdataset_final_SP2015.dta",clear
	merge 1:1 med_name using "$dir/data/high_profit_drugs.dta", keepus(high_profit)
	
	***** need to clean the drug names ******


log off
