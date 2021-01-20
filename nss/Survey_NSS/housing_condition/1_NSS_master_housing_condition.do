****************************************************************************
* Description: Generate data for table on housing condition for all nss (this version use manual weight)
* Date: Jan. 20, 2021
* Version 4.2
* Last Editor: Aline 
****************************************************************************

****************************************************************************
clear 
clear matrix
****************************************************************************

****************************************************************************
* Determine Whose Machine is running the code and set the global directory
****************************************************************************
if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 65\" //please correct accordingly
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\housing_condition"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\housing_condition"
di "${r_output}"



****************************************************************************
* Load data
****************************************************************************
use "${root}\NSS49\Data Output Files\NSS49_housing_condition.dta",clear

foreach survey in NSS58 NSS65 NSS69 NSS76 {
qui append using "${root}/`survey'/Data Output Files/`survey'_housing_condition.dta",force
}

drop h20_temp h20_distance h20_exclusive h20b_pip_exl h20b_pip_shr h20b_grd_exl h20b_grd_shr h20b_other h20_cooking ///
san_source san_distance

replace in_ppl_room = 1/in_ppl_room
label var in_ppl_room "Room per person" //convert so the greater value is positive. 

save "${r_output}\NSS_housing_condition.dta",replace

****************************************************************************
* Generate the time series table of housing conditions
****************************************************************************
use "${r_output}\NSS_housing_condition.dta",clear

********************
*prepare the data***
********************

*By survey generate consumption quintile for All India households****
xtile qt = hh_umce [aw = hh_weight] if survey == "NSS49", nq(5) 

foreach survey in NSS58 NSS65 NSS69 NSS76 {
  xtile temp_qt_`survey' = hh_umce [aw = hh_weight] if survey == "`survey'", nq(5) 
  qui replace qt = temp_qt_`survey' if survey == "`survey'" 
}
drop temp*

//sample 5, by(survey hh_urban qt) //5% of the observation. option: by

*produce delta between q1 and q5 for each variable****

local var_list hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "49 58 65 69 76" 
keep  `var_list' hh_weight hh_urban survey qt

//sort out the first and fifth quintile
foreach var in `var_list' {
 forvalues i = 1(4)5 {
 qui gen `var'_`i' = `var' *(qt == `i')
 qui replace `var'_`i'  = . if (qt != `i')
 }
}


*gen the stats by survey, quntile, and location

// location 
local if1 "< 2" //All india 
local if2 "==1" //urban
local if3 "==0" //Rural 


//calculate the weighted mean and not-weighted median (though manual, still costing more than 10 min.)
 foreach var in `var_list' {
  forvalues q = 1(1)3 {
     qui egen double temp_numerator = total(hh_weight*`var') if hh_urban `if`q'',by(survey qt)
     qui egen double temp_denominator = total(hh_weight) if hh_urban `if`q'',by(survey qt)
     qui gen double `var'_`q'_mn = (temp_numerator/temp_denomi)
	 
	 qui egen double `var'_`q'_md = median(`var') if hh_urban `if`q'',by(survey qt)
     drop temp*
  }
 }

//generate the weighted mean and not weighted median by survey and location (more than 10 min)
foreach survey in `nss_round' {
 forvalues i = 1(4)5 {
  forvalues q = 1(1)3 {
   foreach stat in mn md {
    foreach var in `var_list' {
     qui gen `var'_`i'_`survey'_`q'_`stat' = `var'_`q'_`stat' if survey == "NSS`survey'" & qt == `i'
    }
   }
  }
 }
}


local var_list hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "49 58 65 69 76" 

//generate the delta
foreach var in `var_list' {
 foreach stat in mn md {
  forvalues q = 1(1)3 {
  qui gen `var'_d_`q'_`stat' = . 
  }
 }
}


keep if qt == 1 | qt ==5
collapse (mean) *1_md *2_md *3_md *1_mn *2_mn *3_mn,by(survey)

//calculate the delta
foreach var in `var_list' {
 foreach survey in `nss_round' {
   foreach stat in mn md {
   forvalues q = 1(1)3 {
   qui gen t_`var'_`survey'_d_`q'_`stat' = (`var'_5_`survey'_`q'_`stat'- `var'_1_`survey'_`q'_`stat')/`var'_1_`survey'_`q'_`stat'
   qui replace `var'_d_`q'_`stat' = t_`var'_`survey'_d_`q'_`stat'  if survey == "NSS`survey'" 
   }
  }
 }
}

drop t*

gen year = .
replace year = 1993 if survey == "NSS49"
replace year = 2002 if survey == "NSS58"
replace year = 2009 if survey == "NSS65"
replace year = 2012 if survey == "NSS69"
replace year = 2018 if survey == "NSS76"

save "${r_output}\NSS_housing_condition_final_dt.dta",replace
