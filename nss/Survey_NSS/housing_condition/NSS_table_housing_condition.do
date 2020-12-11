****************************************************************************
* Description: Generate table for housing condition for all nss
* Date: Dec. 10, 2020
* Version 1.0
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
global r_output "${root}\Data Output Files"

*Define the survey rounds. 
global nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

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

replace in_room = 1 if in_room == 0

****************************************************************************
* Generate the time series table of housing conditions
****************************************************************************
local var_summary hh_size in_* h20* san* 

*All, Urban, Rural India housing condition****

foreach survey in $nss_round {
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
 
*By quintile for All, Urban, Rural India housing condition****

//ssc install egenmore //this is a package with more function with egen
gen mpce = hh_umce/hh_size //per capita consumer expenditure
egen qt=xtile(mpce), n(5) by(survey)
egen qt_u =xtile(mpce) if hh_urban == 1, n(5) by(survey)
egen qt_r =xtile(mpce) if hh_urban == 0, n(5) by(survey)

local var_list hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
 
foreach var in `var_list' {
gen `var'_1 = `var' *(qt == 1)
replace `var'_1  = . if (qt != 1)

gen `var'_5 = `var' *(qt == 5)
replace `var'_5  = . if (qt != 5)
}

*label variables by quintile
label var hh_size_1  "Size of household_1"
label var in_room_1  "Number of rooms_1"
label var in_wall_permanent_1  "Wall: Cement or Stone (%)_1"
label var in_roof_permanent_1  "Roof: Cement or Stone (%)_1"
label var in_floor_permanent_1  "Floor: Cement or Stone (%)_1"
label var in_all_permanent_1  "All Materials: Cement or Stone (%)_1"
label var in_sep_kitch_1  "Separate Kitchen (%)_1"
label var in_flat_1  "Flat (%)_1"
label var in_size_1  "Dwelling Size (sq ft)_1"
label var in_ppl_room_1  "People per room_1"
label var in_ppl_area_1  "Area (sq ft per person)_1"
label var h20_improved_1  "Water: Improved Source (%)_1"
label var san_improved_1  "Sanitation: Improved Source (%)_1"
label var san_flush_private_1  "Sanitation: Exclusive Flush (%)_1"
label var hh_size_5  "Size of household_5"
label var in_room_5  "Number of rooms_5"
label var in_wall_permanent_5  "Wall: Cement or Stone (%)_5"
label var in_roof_permanent_5  "Roof: Cement or Stone (%)_5"
label var in_floor_permanent_5  "Floor: Cement or Stone (%)_5"
label var in_all_permanent_5  "All Materials: Cement or Stone (%)_5"
label var in_sep_kitch_5  "Separate Kitchen (%)_5"
label var in_flat_5  "Flat (%)_5"
label var in_size_5  "Dwelling Size (sq ft)_5"
label var in_ppl_room_5  "People per room_5"
label var in_ppl_area_5  "Area (sq ft per person)_5"
label var h20_improved_5  "Water: Improved Source (%)_5"
label var san_improved_5  "Sanitation: Improved Source (%)_5"
label var san_flush_private_5  "Sanitation: Exclusive Flush (%)_5"

keep qt* hh_size* in_* h20* san* hh_weight survey hh_urban

local var_summary hh_size_1	hh_size_5	in_floor_permanent_1	in_floor_permanent_5	in_wall_permanent_1	in_wall_permanent_5	in_floor_permanent_1	in_floor_permanent_5	in_all_permanent_1	///
in_all_permanent_5	in_room_1	in_room_5	in_ppl_room_1	in_ppl_room_5	in_size_1	in_size_5	in_ppl_area_1	in_ppl_area_5	in_sep_kitch_1	in_sep_kitch_5	in_flat_1	in_flat_5	///
h20_improved_1	h20_improved_5	san_improved_1	san_improved_5	san_flush_private_1	san_flush_private_5


foreach survey in $nss_round {
qui eststo `survey': quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'"

  foreach var in `var_list' {
  replace `var'_1 = `var' *(qt_u == 1)
  replace `var'_1  = . if (qt_u != 1)

  replace `var'_5 = `var' *(qt_u == 5)
  replace `var'_5  = . if (qt_u != 5)
  }
qui eststo `survey'_u: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 1

  foreach var in `var_list' {
  replace `var'_1 = `var' *(qt_r == 1)
  replace `var'_1  = . if (qt_r != 1)

  replace `var'_5 = `var' *(qt_r == 5)
  replace `var'_5  = . if (qt_r != 5)
  }
qui eststo `survey'_r: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 0
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4 Summary Statistics of Housing Condition in India by Wealth Quintile (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The wealth quintile is estimated from the monthly per capita consumer expenditure." ///
		  "       Variables end with _1 represent the statistics for the first quintile, _5 for the fifth quintile.")

esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 5 Summary Statistics of Housing Condition in Urban India by Wealth Quintile (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
           "       The wealth quintile is estimated from the monthly per capita consumer expenditure." ///
		   "       Variables end with _1 represent the statistics for the first quintile, _5 for the fifth quintile.")
		   
esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 6 Summary Statistics of Housing Condition in Rural India by Wealth Quintile (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
           "       The wealth quintile is estimated from the monthly per capita consumer expenditure." ///
		   "       Variables end with _1 represent the statistics for the first quintile, _5 for the fifth quintile.")



***converging trend of housing condition for q1 and q5 (Urban)***

foreach var in `var_list' {
  replace `var'_1 = `var' *(qt_u == 1)
  replace `var'_1  = . if (qt_u != 1)

  replace `var'_5 = `var' *(qt_u == 5)
  replace `var'_5  = . if (qt_u != 5)
 }
 
collapse (mean) *_1 *_5,by(survey)  


foreach var in `var_list' {
gen `var'_dt = (`var'_5 - `var'_1)/`var'_1
}

gen year = .
replace year = 1993 if survey == "NSS49"
replace year = 2002 if survey == "NSS58"
replace year = 2009 if survey == "NSS65"
replace year = 2012 if survey == "NSS69"
replace year = 2018 if survey == "NSS76"

estimates clear
foreach var in `var_list' {
qui reg `var'_dt year 
eststo `var'
}

esttab `var_list' , nose not label b("%9.2f")	r2 /// fmt( %9.0gc %9.0gc %9.2f)) ///
title("Regression of Housing Condition Equality between Q1 and Q5 on Year (Urban India)") ///
addnotes("Note: Regressions dependent variables are the delta of housing condition indicator measures" ///
         "      between quintile 5 and 1.")	
log close
