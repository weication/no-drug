 


* Eyeglass data cleaning

	global dir = "/Users/sean/Dropbox (Personal)/Research/Papers/Returns to Scope" // Sean
	cd "$dir"

 	use  "$dir/data/eyesp_clean_full.dta",clear

 	*DATA CLEANING

	 *************Prepare the variables*******************


	***1.treatment:
	gen nosale=0 if treatment!=.
	    replace nosale=1 if treatment==12|treatment==22
		      
	gen nosale_pu=nosale*public
	   label var nosale "nosale"
	   label var nosale_pu "nosale*public"
	   
	gen second_c=(treatment==23)
	gen second_w=(treatment==24)
	  label var second_c "second opinion: correct prescription"
	  label var second_w "second opinion: wrong prescription"
	  

	***Facility features

	gen ownshop=esp_04
	tab ownshop,mi
	    recode ownshop (2=0) (.=0)
		label var ownshop "having its own optical shop"
		
	gen ownshop_order=ownshop
	    replace ownshop_order=2 if ownshop==1
		replace ownshop_order=1 if ownshop==0&public==1
		replace ownshop_order=0 if ownshop==0&public==0
		label var ownshop_order "having its own optical shop"


	 **
	  destring chain,replace
	  recode chain (2=0)
	  replace chain=0 if public==1
	  label var chain "chain stores"
	  
	  gen chain_order=chain
	      replace chain_order=2 if chain_order==1
		  replace chain_order=1 if chain_order==0&public==0
		  replace chain_order=0 if chain_order==0&public==1
	  
		
	  recode location3 (2=0)
	  clonevar city_big=citysize
	  recode city_big (2=0) (3=0) (4=0)
	  
	  gen highincome=(per_capita>28844)   //高于全国平均
	  
	  
	  
	***Staff features	

	  clonevar nolocal_ac=esp_08_1
	  recode nolocal_ac (2=0)
	  label var nolocal_ac "nonlocal accent"
	  
	  
	  gen local_p=(esp_09_1b==prefecture)
	  label var local_p "local person"
	  
	  
	  clonevar male_check=esp_06_1
	  recode male_check (2=0)
	  label var male_check "gender of staff conducting check"
	  
	  clonevar age_check=esp_07_1
	  recode age_check  (4=3)
	  label var age_check "age of staff conducting check" 
		

	***Outcome 1: Process

	clonevar un_screen=esp_11
	    recode un_screen (2=0) (.=0)
	    label var un_screen  "是否检查裸眼视力"
	 
	clonevar cr_screen=esp_10
	    recode cr_screen (2=0)  (3=0)
	    label var cr_screen "是否用E表检查戴镜视力"
	   
	gen e_chart=(un_screen==1|cr_screen==1)
	    label var e_chart "Check vision using E-chart?"

	   
	clonevar auto_screen=esp_13
	    recode auto_screen (2=0)
	    label var auto_screen "Conducted auto-refraction test?"

	     
	clonevar auto_ph_d=esp_14_1
	    replace auto_ph_d=1 if auto_ph_d!=.&auto_ph_d!=.n
	    replace auto_ph_d=0 if auto_ph_d==.|auto_ph_d==.n
	    label var auto_ph_d "Conducted eye-distance check using auto-refraction?"
	  
	clonevar m_ph_d=esp_18
	    recode m_ph_d (2=0)
	    label var m_ph_d "Conducted eye-distance check using rulers?"

	gen ph_d=(auto_ph_d==1|m_ph_d==1)
	    tab ph_d,mi
		label var ph_d "Conducted eye-distance check?"
	       
	clonevar dialate=esp_15
	    recode dialate (2=0)
	   
	   
	clonevar ob_screen=esp_16
	    recode ob_screen (2=0)
	   
	clonevar gl_screen=esp_20
	    recode gl_screen (2=0) (3=.)
	   
	clonevar sc_time=esp_23

	clonevar sc_other=esp_24
	    recode sc_other (2=0)
	   
	clonevar sc_reject=esp_35
	    recode sc_reject (2=0)
	   
	clonevar sc_reject_e=esp_36

	   
	***Outcome 2: Expense

	clonevar ex_screen=esp_26
	clonevar ex_medicine=esp_27
	clonevar ex_total=esp_28
	clonevar ex_regular=esp_29
	clonevar ex_300=esp_30
	clonevar ex_cheast=esp_33

	**保修期
	**镜架是否有保修
	  clonevar warranty1=esp_31
		         replace warranty1=0 if warranty1==0
				 replace warranty1=1 if warranty1!=0&warranty1!=.n
			
		clonevar warranty2=esp_32
		         replace warranty2=0 if warranty2==0
				 replace warranty2=1 if warranty2!=0&warranty2!=.n


	***Outcome3: Accuracy

	*1.uncorrected vision: right, left, better eye, worse eye (relative to ZOC)
	   gen vdd_unc_right=abs(esp_12a-6/zoc_ec_right)
	   gen vdd_unc_left=abs(esp_12b-6/zoc_ec_left)
	   
	   
	*1.1. 瞳距
	    gen esp_ph=esp_14_1  
		    replace esp_ph=esp_19 if (esp_14_1==.|esp_14_1==.n)&esp_19!=.&esp_19!=.n
			
		gen vdd_ph=abs(esp_ph-zoc_eyeph)
		

	**2.The auto refraction: right, left, better eye, worse eye (relative to ZOC)
	     **local shop: auto refrection
		 gen se_right_auto_1=auto_right_sph+auto_right_cyl/2
		 gen se_left_auto_1=auto_left_sph+auto_left_cyl/2
		 gen j0_right_auto_1=-(auto_right_cyl/2)*cos(2*auto_right_ax*_pi/180)
		 gen j0_left_auto_1=-(auto_left_cyl/2)*cos(2*auto_left_ax*_pi/180)
		 gen j45_right_auto_1=-(auto_right_cyl/2)*sin(2*auto_right_ax*_pi/180)
		 gen j45_left_auto_1=-(auto_left_cyl/2)*sin(2*auto_left_ax*_pi/180)

	     
		 **ZOC: auto refrection	 
		 gen se_right_auto_2=zoc_ar_sph_right+zoc_ar_cyl_right/2
		 gen se_left_auto_2=zoc_ar_sph_left+zoc_ar_cyl_left/2
		 gen j0_right_auto_2=-(zoc_ar_cyl_right/2)*cos(2*zoc_ar_ax_right*_pi/180)
		 gen j0_left_auto_2=-(zoc_ar_cyl_left/2)*cos(2*zoc_ar_ax_left*_pi/180)
		 gen j45_right_auto_2=-(zoc_ar_cyl_right/2)*sin(2*zoc_ar_ax_right*_pi/180)
		 gen j45_left_auto_2=-(zoc_ar_cyl_left/2)*sin(2*zoc_ar_ax_left*_pi/180)
		  
		 	 
		 **自动验光检查结果对比
		 
		 gen vdd_right_auto=sqrt(2)*sqrt((se_right_auto_1-se_right_auto_2)^2+(j0_right_auto_1-j0_right_auto_2)^2+ ///
		 (j45_right_auto_1-j45_right_auto_2)^2)
		 
		 gen vdd_left_auto=sqrt(2)*sqrt((se_left_auto_1-se_left_auto_2)^2+(j0_left_auto_1-j0_left_auto_2)^2+ ///
		 (j45_left_auto_1-j45_left_auto_2)^2)
		 
		  **sign vdd
		 
		 foreach var in right left {
		 gen vdd_`var'_auto_s=vdd_`var'_auto
		     replace vdd_`var'_auto_s=-vdd_`var'_auto if se_`var'_auto_2<se_`var'_auto_1
		 label var vdd_`var'_auto_s "vdd of `var' auto-refraction with sign"
		 }
		 
		 **split it by 1d 2d 3d
		 foreach var in right left {
		 forvalue num=1/3 {
		 gen vdd_`var'_auto_`num'd=(vdd_`var'_auto>=`num') if vdd_`var'_auto!=.
		 label var vdd_`var'_auto_`num'd "vdd of `var' auto-refraction:`num'd"
		 }
		 }
		 
		
		 
		 **drop the variables no need
		 drop se_right_auto_1 se_left_auto_1 j0_right_auto_1 j0_left_auto_1 j45_right_auto_1 ///
		 j45_left_auto_1 se_right_auto_2 se_left_auto_2 j0_right_auto_2 j0_left_auto_2 ///
		 j45_right_auto_2 j45_left_auto_2
		 

	**3. The prescription/sub-refraction: right, left, better eye, worse eye (relative to ZOC)  
	     **local shop
		 gen se_right_sub_1=sub_right_sph+sub_right_cyl/2
		 gen se_left_sub_1=sub_left_sph+sub_left_cyl/2
		 gen j0_right_sub_1=-(sub_right_cyl/2)*cos(2*sub_right_ax*_pi/180)
		 gen j0_left_sub_1=-(sub_left_cyl/2)*cos(2*sub_left_ax*_pi/180)
		 gen j45_right_sub_1=-(sub_right_cyl/2)*sin(2*sub_right_ax*_pi/180)
		 gen j45_left_sub_1=-(sub_left_cyl/2)*sin(2*sub_left_ax*_pi/180)
		 	 
		 
		 
		 **ZOC 插片结果
		 gen se_right_sub_2=zoc_mr_sph_right+zoc_mr_cyl_right/2
		 gen j0_right_sub_2=-(zoc_mr_cyl_right/2)*cos(2*zoc_mr_ax_right*_pi/180)
		 gen j45_right_sub_2=-(zoc_mr_cyl_right/2)*sin(2*zoc_mr_ax_right*_pi/180)
		 gen se_left_sub_2=zoc_mr_sph_left+zoc_mr_cyl_left/2
		 gen j0_left_sub_2=-(zoc_mr_cyl_left/2)*cos(2*zoc_mr_ax_left*_pi/180)
		 gen j45_left_sub_2=-(zoc_mr_cyl_left/2)*sin(2*zoc_mr_ax_left*_pi/180)
		 
		 
		 **ZOC final prescription 最终处方（远用）
		 gen se_right_final_2=zoc_final_sph_right+zoc_final_cyl_right/2
		 gen se_left_final_2=zoc_final_sph_left+zoc_final_cyl_left/2
		 gen j0_right_final_2=-(zoc_final_cyl_right/2)*cos(2*zoc_final_ax_right*_pi/180)
		 gen j0_left_final_2=-(zoc_final_cyl_left/2)*cos(2*zoc_final_ax_left*_pi/180)
		 gen j45_right_final_2=-(zoc_final_cyl_right/2)*sin(2*zoc_final_ax_right*_pi/180)
		 gen j45_left_final_2=-(zoc_final_cyl_left/2)*sin(2*zoc_final_ax_left*_pi/180)
		 
		 
		 
		 **右、左眼插片验光与ZOC的差异
		 gen vdd_right_sub=sqrt(2)*sqrt((se_right_sub_1-se_right_sub_2)^2+(j0_right_sub_1-j0_right_sub_2)^2+ ///
		 (j45_right_sub_1-j45_right_sub_2)^2) 
		 
		 gen vdd_left_sub=sqrt(2)*sqrt((se_left_sub_1-se_left_sub_2)^2+(j0_left_sub_1-j0_left_sub_2)^2+ ///
		 (j45_left_sub_1-j45_left_sub_2)^2)
		 
		 **with sign
		 foreach var in right left {
		 gen vdd_`var'_sub_s=vdd_`var'_sub
		     replace vdd_`var'_sub_s=-vdd_`var'_sub if se_`var'_sub_2<se_`var'_sub_1
		 label var vdd_`var'_sub_s "vdd of `var' sub-refraction with sign"
		 }
		 
		  **split it by 1d 2d 3d
		 foreach var in right left {
		 forvalue num=1/3 {
		 gen vdd_`var'_sub_`num'd=(vdd_`var'_sub>=`num') if vdd_`var'_sub!=.
		 label var vdd_`var'_sub_`num'd "vdd of `var' sub-refraction:`num'd"
		 }
		 }
		 
		 
		 
		 **右、左眼插片验光与ZOC处方的差异
		  gen vdd_right_final=sqrt(2)*sqrt((se_right_sub_1-se_right_final_2)^2+(j0_right_sub_1-j0_right_final_2)^2+ ///
		 (j45_right_sub_1-j45_right_final_2)^2) 
		 
		 gen vdd_left_final=sqrt(2)*sqrt((se_left_sub_1-se_left_final_2)^2+(j0_left_sub_1-j0_left_final_2)^2+ ///
		 (j45_left_sub_1-j45_left_final_2)^2) 

		
		**with sign
		 foreach var in right left {
		 gen vdd_`var'_final_s=vdd_`var'_final
		     replace vdd_`var'_final_s=-vdd_`var'_final if se_`var'_final_2<se_`var'_sub_1
		 label var vdd_`var'_final_s "vdd of `var' final/sub-refraction with sign"
		 }
		
		
		  **split it by 1d 2d 3d
		 foreach var in right left {
		 forvalue num=1/3 {
		 gen vdd_`var'_final_`num'd=(vdd_`var'_final>=`num') if vdd_`var'_final!=.
		 label var vdd_`var'_final_`num'd "vdd of `var' sub-refraction/final:`num'd"
		 }
		 }
		 
		 
		 

	**4. The eyeglasses :right, left, better eye, worse eye (relative to the real prescription)
	     **local shop: SP's eyeglasses
		 gen se_right_gl_1=gl_right_sph+gl_right_cyl/2
		 gen se_left_gl_1=gl_left_sph+gl_left_cyl/2
		 gen j0_right_gl_1=-(gl_right_cyl/2)*cos(2*gl_right_ax*_pi/180)
		 gen j0_left_gl_1=-(gl_left_cyl/2)*cos(2*gl_left_ax*_pi/180)
		 gen j45_right_gl_1=-(gl_right_cyl/2)*sin(2*gl_right_ax*_pi/180)
		 gen j45_left_gl_1=-(gl_left_cyl/2)*sin(2*gl_left_ax*_pi/180)
		 
		  
		 **学生戴的眼镜与眼镜检查结果的对比
		 foreach var in right left {    //make sure which glasses the students wear that days
		 foreach num in sph cyl ax {
		 gen zoc_gl_`num'_`var'=.
		     replace zoc_gl_`num'_`var'=zoc_in_`num'_`var' if inlist(treatment,11,12,21,22,24)!=0
			 replace zoc_gl_`num'_`var'=zoc_final_`num'_`var' if treatment==23
			 label var zoc_gl_`num'_`var' "SP戴的眼镜：`var':`num'"
			 }
			 }
		
		
		 gen se_right_gl_2=zoc_gl_sph_right+zoc_gl_cyl_right/2
		 gen se_left_gl_2=zoc_gl_sph_left+zoc_gl_cyl_left/2
		 gen j0_right_gl_2=-(zoc_gl_cyl_right/2)*cos(2*zoc_gl_ax_right*_pi/180)
		 gen j0_left_gl_2=-(zoc_gl_cyl_left/2)*cos(2*zoc_gl_ax_left*_pi/180)
		 gen j45_right_gl_2=-(zoc_gl_cyl_right/2)*sin(2*zoc_gl_ax_right*_pi/180)
		 gen j45_left_gl_2=-(zoc_gl_cyl_left/2)*sin(2*zoc_gl_ax_left*_pi/180)
		 
	     	
		 
		 **眼镜检查结果与学生所戴眼镜的差异
		 gen vdd_right_gl=sqrt(2)*sqrt((se_right_gl_1-se_right_gl_2)^2+(j0_right_gl_1-j0_right_gl_2)^2+ ///
		 (j45_right_gl_1-j45_right_gl_2)^2) 
		 
		 gen vdd_left_gl=sqrt(2)*sqrt((se_left_gl_1-se_left_gl_2)^2+(j0_left_gl_1-j0_left_gl_2)^2+ ///
		 (j45_left_gl_1-j45_left_gl_2)^2) 
		 

		**with sign
		 foreach var in right left {
		 gen vdd_`var'_gl_s=vdd_`var'_gl
		     replace vdd_`var'_gl_s=-vdd_`var'_gl if se_`var'_gl_2<se_`var'_gl_1
		 label var vdd_`var'_gl_s "vdd of `var' glasses prescription with sign"
		 }
		
		
		  **split it by 1d 2d 3d
		  
		 foreach var in right left {
		 forvalue num=1/3 {
		 gen vdd_`var'_gl_`num'd=(vdd_`var'_gl>=`num') if vdd_`var'_gl!=.
		 label var vdd_`var'_gl_`num'd "vdd of `var' glasses:`num'd"
		 }
		 }
		 
		
		**drop the variables no need
		drop se_right_gl_1 se_left_gl_1 j0_right_gl_1 j0_left_gl_1 ///
		j45_right_gl_1 j45_left_gl_1 se_right_gl_2 se_left_gl_2 j0_right_gl_2 ///
		j0_left_gl_2 j45_right_gl_2 j45_left_gl_2
		 

	**5. The eyeglasses which the students purchased :right, left, better eye, worse eye (relative to ZOC)
	    
		gen se_right_ma_1=ma_right_sph+ma_right_cyl/2
		gen se_left_ma_1=ma_left_sph+ma_left_cyl/2
		gen j0_right_ma_1=-(ma_right_cyl/2)*cos(2*ma_right_ax*_pi/180)
	    gen j0_left_ma_1=-(ma_left_cyl/2)*cos(2*ma_left_ax*_pi/180)
	    gen j45_right_ma_1=-(ma_right_cyl/2)*sin(2*ma_right_ax*_pi/180)
	    gen j45_left_ma_1=-(ma_left_cyl/2)*sin(2*ma_left_ax*_pi/180)
		
		
		**对ZOC正确处方对比
		gen vdd_right_ma_z=sqrt(2)*sqrt((se_right_ma_1-se_right_final_2)^2+(j0_right_ma_1-j0_right_final_2)^2+ ///
		 (j45_right_ma_1-j45_right_final_2)^2) 
		 
		gen vdd_left_ma_z=sqrt(2)*sqrt((se_left_ma_1-se_left_final_2)^2+(j0_left_ma_1-j0_left_final_2)^2+ ///
		 (j45_left_ma_1-j45_left_final_2)^2) 
		
		
		
		**with sign
		 foreach var in right left {
		 gen vdd_`var'_ma_z_s=vdd_`var'_ma_z
		     replace vdd_`var'_ma_z_s=-vdd_`var'_ma_z if se_`var'_final_2<se_`var'_ma_1
		 label var vdd_`var'_ma_z_s "vdd of `var' manufacture glass with sign compared with ZOC"
		 }
		 
		
		
		  **split it by 1d 2d 3d
		  
		 foreach var in right left {
		 forvalue num=1/3 {
		 gen vdd_`var'_ma_z_`num'd=(vdd_`var'_ma_z>=`num') if vdd_`var'_ma_z!=.
		 label var vdd_`var'_ma_z_`num'd "vdd of `var' manufacture glass:`num'd"
		 }
		 }
		
		
		
		
		**与眼镜店自己的结果作对比
		gen vdd_right_ma_l=sqrt(2)*sqrt((se_right_ma_1-se_right_sub_1)^2+(j0_right_ma_1-j0_right_sub_1)^2+ ///
		 (j45_right_ma_1-j45_right_sub_1)^2) 
		 
		gen vdd_left_ma_l=sqrt(2)*sqrt((se_left_ma_1-se_left_sub_1)^2+(j0_left_ma_1-j0_left_sub_1)^2+ ///
		 (j45_left_ma_1-j45_left_sub_1)^2) 
		 
		
		
		 **with sign
		 foreach var in right left {
		 gen vdd_`var'_ma_l_s=vdd_`var'_ma_l
		     replace vdd_`var'_ma_l_s=-vdd_`var'_ma_l if se_`var'_sub_1<se_`var'_ma_1
		 label var vdd_`var'_ma_l_s "vdd of `var' manufacture glass with sign compared with local"
		 }
		 
		
		
		  **split it by 1d 2d 3d
		  
		 foreach var in right left {
		 forvalue num=1/3 {
		 gen vdd_`var'_ma_l_`num'd=(vdd_`var'_ma_l>=`num') if vdd_`var'_ma_l!=.
		 label var vdd_`var'_ma_l_`num'd "vdd of `var' manufacture glass with local:`num'd"
		 }
		 }
		
	    
		
		**drop the variables no need
		  drop  se_right_sub_1 se_left_sub_1 j0_right_sub_1 j0_left_sub_1 j45_right_sub_1 ///
		 j45_left_sub_1 se_right_sub_2 j0_right_sub_2 j45_right_sub_2 se_left_sub_2 ///
		 j0_left_sub_2 j45_left_sub_2 se_right_final_2 se_left_final_2 j0_right_final_2 ///
		 j0_left_final_2 j45_right_final_2 j45_left_final_2
		
		
		drop se_right_ma_1 se_left_ma_1 j0_right_ma_1 j0_left_ma_1 j45_right_ma_1 j45_left_ma_1


	 
	  **better seeing eye and worse seeing eye
	 
	 foreach var in auto sub final gl ma_z ma_l {
	 gen vdd_better_`var'=vdd_right_`var' if zoc_ec_right<=zoc_ec_left
	 replace vdd_better_`var'=vdd_left_`var' if zoc_ec_right>zoc_ec_left
	 
	 gen vdd_better_`var'_s=vdd_right_`var'_s if zoc_ec_right<=zoc_ec_left
	 replace vdd_better_`var'_s=vdd_left_`var'_s if zoc_ec_right>zoc_ec_left
	 
	 gen vdd_worse_`var'=vdd_right_`var' if zoc_ec_right>zoc_ec_left
	 replace vdd_worse_`var'=vdd_left_`var' if zoc_ec_right<=zoc_ec_left
	 
	 gen vdd_worse_`var'_s=vdd_right_`var'_s if zoc_ec_right>zoc_ec_left
	 replace vdd_worse_`var'_s=vdd_left_`var'_s if zoc_ec_right<=zoc_ec_left
	 }
	 
	 
	 
	 foreach var in auto sub final gl ma_z ma_l {
	 gen vdd_better_`var'_1d=(vdd_better_`var'>=1) if vdd_better_`var'!=.
	 gen vdd_better_`var'_2d=(vdd_better_`var'>=2) if vdd_better_`var'!=.
	 gen vdd_better_`var'_3d=(vdd_better_`var'>=3) if vdd_better_`var'!=.
	 
	 gen vdd_worse_`var'_1d=(vdd_better_`var'>=1) if vdd_worse_`var'!=.
	 gen vdd_worse_`var'_2d=(vdd_better_`var'>=2) if vdd_worse_`var'!=.
	 gen vdd_worse_`var'_3d=(vdd_better_`var'>=3) if vdd_worse_`var'!=.
	 }
	 
	 
	 global check_balance ex_regular ex_300 warranty1 warranty2 ///
	 un_screen auto_screen dialate auto_ph_d ob_screen m_ph_d gl_screen sc_time ///
	 ex_screen ex_total ///
	 vdd_right_auto_1d  vdd_right_sub_1d vdd_right_final_1d vdd_right_ma_z_1d vdd_right_ma_l_1d 


	 keep if treatment==11|treatment==12|treatment==21|treatment==22

**Effect on eyeglass sales
clonevar require_glasses = esp_37
recode require_glasses (2=0)
label var require_glasses "1/0;1=recommends buying glasses after exam"

destring ex_regular, replace force
label var ex_medicine 	"prescription fee"
label var ex_screen 	"exam fee"
label var ex_total 		"total fee excluding glasses"
label var ex_regular 	"price of first pair when asked for regularly priced glasses"
label var ex_300 		"price of first pair when asked for glasses priced around 300"
label var ex_cheast 	"price of cheapest pair if purchased"

foreach var of varlist ex_* {
replace `var' = log(`var'+1)
}


		ren nosale nobuy

		drop nosale_pu

		g nb_pub = nobuy*public



save  "$dir/data/eyesp_clean_proc.dta", replace
