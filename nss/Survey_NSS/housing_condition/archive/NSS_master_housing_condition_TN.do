****************************************************************************
* Description: Generate table for housing condition for all nss (TN only)
* Date: Jan. 13, 2021
* Version 4.1
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


log using "${script}\NSS_table_housing_condition_tn.log",replace
set linesize 255


****************************************************************************
* Generate the time series table of housing conditions
****************************************************************************
use "${r_output}\NSS_housing_condition.dta",clear

keep if hh_state == "33" //keep only TN data.

********************
*prepare the data***
********************

*By survey generate consumption quintile for TN households****
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
 foreach stat in mn md {
   qui gen `var'_d_`stat' = .
 }
 
 foreach survey in `nss_round' {
  forvalues i = 1(4)5 {
   //calculate the weighted mean
   qui asgen `var'_`i'_`survey'_mn = `var'_`i' if survey == "`survey'",w(hh_weight)  
   
   //calculate the weighted median
   qui gen `var'_`i'_`survey'_md = . if survey == "`survey'"
   qui summarize `var'_`i' [aw = hh_weight] if survey == "`survey'",de
   qui replace `var'_`i'_`survey'_md = r(p50) if survey == "`survey'"
  }
  
  foreach stat in mn md {
   qui gen tp_`var'_`survey'_d_`stat' = (`var'_5_`survey'_`stat'  - `var'_1_`survey'_`stat')/`var'_1_`survey'_`stat'
   qui replace `var'_d_`stat'  = tp_`var'_`survey'_d_`stat'  if survey == "`survey'"
  }
 }
}

local var_list hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
foreach var in `var_list' {
 local label_old: var label `var'
 local label = " Delta 	Q5 & Q1" + ": `label_old'" 
 
 foreach stat in mn md {
  label var `var'_d_`stat' "`label'"
 }
}

drop tp*
save "${r_output}\NSS_housing_condition_final_tn.dta",replace

********************
*produce the table**
********************

use "${r_output}\NSS_housing_condition_final_tn.dta",replace

*All, Urban, Rural TN housing condition****
local var_summary hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 
foreach survey in `nss_round' {
  qui eststo `survey': quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'",de
  qui eststo `survey'_u: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 1,de
  qui eststo `survey'_r: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 0,de
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0fc)) /// 
 title("Table 1.1 Summary Statistics of Housing Condition in TN (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0fc)) /// 
 title("Table 1.2 Summary Statistics of Housing Condition in TN (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")

esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 2.1 Summary Statistics of Housing Condition in Urban TN (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 2.2 Summary Statistics of Housing Condition in Urban TN (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 3.1 Summary Statistics of Housing Condition in Rural TN (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 3.2 Summary Statistics of Housing Condition in Rural TN (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")

*All housing condition and quntile delta*****
drop *_1 *_5

foreach var in `var_list' {
clonevar `var'_mean = `var'
}

//table of means
local var_summary_mn *_mean *_d_mn
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 
foreach survey in `nss_round' {
qui eststo `survey': quietly estpost summarize `var_summary_mn'  [aw=hh_weight] if survey == "`survey'"
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4.1 Summary Statistics of Housing Condition in TN, Delta between Consumption Quintile 1 and 5 (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")

//table of medians. 
local var_summary_md *_mean *_d_md
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 
foreach survey in `nss_round' {
qui eststo `survey': quietly estpost summarize `var_summary_md' [aw=hh_weight] if survey == "`survey'",de
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4.2 Summary Statistics of Housing Condition in TN, Delta between Consumption Quintile 1 and 5 (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")
		  
***converging trend of housing condition for q1 and q5 (All)***
use "${r_output}\NSS_housing_condition_final_tn.dta",replace
collapse (mean) *_mn *_md,by(survey)   

local var_list in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

foreach var in `var_list' {
qui gen d_mn_`var' = . 
qui gen d_md_`var' = . 

 foreach survey in `nss_round' {
  foreach stat in mn md {
  qui gen tp_`var'_`survey'_d_`stat' = `var'_5_`survey'_`stat' - `var'_1_`survey'_`stat' //calculate the percentage delta
  qui replace d_`stat'_`var' = tp_`var'_`survey'_d_`stat' if survey == "`survey'"
  }
 }
}

drop tp*

gen year = .
replace year = 1993 if survey == "NSS49"
replace year = 2002 if survey == "NSS58"
replace year = 2009 if survey == "NSS65"
replace year = 2012 if survey == "NSS69"
replace year = 2018 if survey == "NSS76"

keep year d*

*by variable the time trend of housing quality equality (only regression on mean is done, med is not done yet. )
estimates clear
local var_list in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat h20_improved san_improved san_flush_private

foreach var in `var_list' {
qui reg d_mn_`var' year
eststo `var'
}

esttab `var_list' , nose not label b("%9.2f")	r2 /// fmt( %9.0gc %9.0gc %9.2f)) ///
title("Regression of Housing Condition Equality between Q1 and Q5 on Year (TN)") ///
addnotes("Note: Regressions dependent variables are the delta of housing condition indicator measures" ///
         "      between quintile 5 and 1.")	

foreach var in `var_list' {
qui reg d_md_`var' year
eststo `var'
}

esttab `var_list' , nose not label b("%9.2f")	r2 /// fmt( %9.0gc %9.0gc %9.2f)) ///
title("Regression of Housing Condition Equality between Q1 and Q5 on Year (TN)") ///
addnotes("Note: Regressions dependent variables are the delta of housing condition indicator measures" ///
         "      between quintile 5 and 1.")	
		 
*reshape to get general trend with variable as fixed effect
reshape long d_mn d_md,i(year) j(ind) string
areg d_mn year, absorb(ind) vce(cluster ind)
areg d_md year, absorb(ind) vce(cluster ind)

log close
