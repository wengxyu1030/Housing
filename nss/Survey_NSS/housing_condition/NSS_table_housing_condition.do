****************************************************************************
* Description: Generate table for housing condition for all nss
* Date: Dec. 30, 2020
* Version 3.0
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


log using "${script}\NSS_table_housing_condition.log",replace
set linesize 255


****************************************************************************
* Load data
****************************************************************************
use "${root}\NSS49\Data Output Files\NSS49_housing_condition.dta",clear

foreach survey in NSS58 NSS65 NSS69 NSS76 {
append using "${root}/`survey'/Data Output Files/`survey'_housing_condition.dta",force
}

drop h20_temp h20_distance h20_exclusive h20b_pip_exl h20b_pip_shr h20b_grd_exl h20b_grd_shr h20b_other h20_cooking ///
san_source san_distance

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

*produce delta between q1 and q5 for each variable****
//ssc inst asgen  //the package for weighted mean 

local var_list hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

foreach var in `var_list' {
//sort out the first and fifth quintile
 forvalues i = 1(4)5 {
 qui gen `var'_`i' = `var' *(qt == `i')
 qui replace `var'_`i'  = . if (qt != `i')
 }
}

foreach var in `var_list' {
qui gen `var'_dt = .
 foreach survey in `nss_round' {
  forvalues i = 1(4)5 {
   qui asgen `var'_`i'_`survey'_mean = `var'_`i' if survey == "`survey'",w(hh_weight)     
  }
  qui gen temp_`var'_`survey'_dt = (`var'_5_`survey'_mean  - `var'_1_`survey'_mean)/`var'_1_`survey'_mean 
  qui replace `var'_dt = temp_`var'_`survey'_dt if survey == "`survey'"
 }
}

foreach var in `var_list' {
 local label_old: var label `var'
 local label = " Delta 	Q5 & Q1" + ": `label_old'" 
 label var `var'_dt "`label'"
}

save "${r_output}\NSS_housing_condition_final.dta",replace

********************
*produce the table**
********************

use "${r_output}\NSS_housing_condition_final.dta",replace

*All, Urban, Rural India housing condition****
local var_summary hh_size* in_* h20* san* 
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 
foreach survey in `nss_round' {
  qui eststo `survey': quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'"
  qui eststo `survey'_u: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 1
  qui eststo `survey'_r: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 0
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0fc)) /// 
 title("Table 1 Summary Statistics of Housing Condition in India (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")

esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 2 Summary Statistics of Housing Condition in Urban India (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 3 Summary Statistics of Housing Condition in Rural India (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")

*All housing condition and quntile delta*****
drop temp* *_mean *_1 *_5

foreach var in `var_list' {
clonevar `var'_mean = `var'
}

local var_summary *mean *dt
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 
foreach survey in `nss_round' {
qui eststo `survey': quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'"
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4 Summary Statistics of Housing Condition in India, Delta between Consumption Quintile 1 and 5 (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")


***converging trend of housing condition for q1 and q5 (All)***
use "${r_output}\NSS_housing_condition_final.dta",replace
collapse (mean) *_mean,by(survey)   

local var_list in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

foreach var in `var_list' {
qui gen dt_`var' = . 
 foreach survey in `nss_round' {
 qui gen temp_`var'_`survey'_dt = `var'_5_`survey'_mean - `var'_1_`survey'_mean //calculate the percentage delta
 qui replace dt_`var' = temp_`var'_`survey'_dt if survey == "`survey'"
 }
}

drop temp*

gen year = .
replace year = 1993 if survey == "NSS49"
replace year = 2002 if survey == "NSS58"
replace year = 2009 if survey == "NSS65"
replace year = 2012 if survey == "NSS69"
replace year = 2018 if survey == "NSS76"

keep year dt*

*by variable the time trend of housing quality equality
estimates clear
local var_list in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat h20_improved san_improved san_flush_private

foreach var in `var_list' {
qui reg dt_`var' year
eststo `var'
}

esttab `var_list' , nose not label b("%9.2f")	r2 /// fmt( %9.0gc %9.0gc %9.2f)) ///
title("Regression of Housing Condition Equality between Q1 and Q5 on Year (Urban India)") ///
addnotes("Note: Regressions dependent variables are the delta of housing condition indicator measures" ///
         "      between quintile 5 and 1.")	

*reshape to get general trend with variable as fixed effect
reshape long dt_,i(year) j(ind) string

areg dt_ year, absorb(ind) vce(cluster ind)

log close
