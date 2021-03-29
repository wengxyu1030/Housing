****************************************************************************
* Description: Generate table for housing condition for all nss 
* Date: March 29, 2021
* Version 4.3
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


log using "${script}\2_NSS_table_housing_condition.log",replace
set linesize 255


********************
*produce the table**
********************

**prepare the master data
use "${r_output}\NSS_housing_condition.dta",clear
local var_list hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
keep  `var_list' hh_weight hh_urban survey 
merge m:1 survey using "${r_output}\NSS_housing_condition_final_dt.dta"
keep `var_list' *_d_1_mn *_d_2_mn *_d_3_mn *_d_1_md *_d_2_md *_d_3_md hh_weight hh_urban survey year

//label the delta
foreach var in `var_list' {
 local label_old: var label `var'
 local label = " Delta 	Q5 & Q1" + ": `label_old'" 
 
 foreach stat in mn md {
  forvalues q = 1(1)3 {
  label var `var'_d_`q'_`stat' "`label'"
  }
 }
}

save "${r_output}\NSS_housing_condition_final.dta",replace



use "${r_output}\NSS_housing_condition_final.dta",clear


*All, Urban, Rural India housing condition****
local var_summary hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

foreach survey in `nss_round' {
  qui eststo `survey': quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'",de
  qui eststo `survey'_u: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 1,de
  qui eststo `survey'_r: quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 0,de
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0fc)) /// 
 title("Table 1.1 Summary Statistics of Housing Condition in India (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0fc)) /// 
 title("Table 1.2 Summary Statistics of Housing Condition in India (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")

esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 2.1 Summary Statistics of Housing Condition in Urban India (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 2.2 Summary Statistics of Housing Condition in Urban India (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 3.1 Summary Statistics of Housing Condition in Rural India (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 3.2 Summary Statistics of Housing Condition in Rural India (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")

*All housing condition and quntile delta*****
local var_summary hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

foreach var in `var_summary' {
qui clonevar `var'_stat = `var'
}

//table of means
local var_summary_mn *_stat *_d_1_mn //all
local var_summary_mn_u *_stat *_d_2_mn //urban 
local var_summary_mn_r *_stat *_d_3_mn //rural 

foreach survey in `nss_round' {
qui eststo `survey': quietly estpost summarize `var_summary_mn'  [aw=hh_weight] if survey == "`survey'"
qui eststo `survey'_u: quietly estpost summarize `var_summary_mn_u'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 1
qui eststo `survey'_r: quietly estpost summarize `var_summary_mn_r'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 0
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4.1 Summary Statistics of Housing Condition in India, Delta between Consumption Quintile 1 and 5 (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")
		  
esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4.2 Summary Statistics of Housing Condition in Urban India, Delta between Consumption Quintile 1 and 5 (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")

esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 4.3 Summary Statistics of Housing Condition in Rural India, Delta between Consumption Quintile 1 and 5 (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")
		  
//table of medians. 
local var_summary hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private
local nss_round "NSS49 NSS58 NSS65 NSS69 NSS76" 

local var_summary_md *_stat *_d_1_md
local var_summary_md_u *_stat *_d_2_md //urban 
local var_summary_md_r *_stat *_d_3_md //rural 
 
foreach survey in `nss_round' {
qui eststo `survey': quietly estpost summarize `var_summary_md' [aw=hh_weight] if survey == "`survey'",de
qui eststo `survey'_u: quietly estpost summarize `var_summary_md_u'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 1,de
qui eststo `survey'_r: quietly estpost summarize `var_summary_md_r'  [aw=hh_weight] if survey == "`survey'" & hh_urban == 0,de
}

esttab NSS49 NSS58 NSS65 NSS69 NSS76, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 5.1 Summary Statistics of Housing Condition in India, Delta between Consumption Quintile 1 and 5 (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")

esttab NSS49_u NSS58_u NSS65_u NSS69_u NSS76_u, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 5.2 Summary Statistics of Housing Condition in Urban India, Delta between Consumption Quintile 1 and 5 (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")

esttab NSS49_r NSS58_r NSS65_r NSS69_r NSS76_r, cells(p50(fmt(%15.1fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2002" "2009" "2012" "2018") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 5.3 Summary Statistics of Housing Condition in Rural India, Delta between Consumption Quintile 1 and 5 (med)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round" ///
          "       The consumption quintile is the generated from the monthly per capita consumer expenditure." ///
		  "       The delta is the between the statistics for the fifth quintile and the first quintile.")


***general trend of housing condition for q1 and q5 (All, Rural, Urban)***
use "${r_output}\NSS_housing_condition_final.dta",replace
gen id = _n

local var_summary hh_size in_room in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat in_size in_ppl_room in_ppl_area h20_improved san_improved san_flush_private

local j = 1
foreach var in `var_summary' {
 qui clonevar value_`j' = `var' //rename to numeric var name. 
 local j = `j' + 1
}

keep value_* hh_urban hh_weight survey year id

reshape long value_,i(id) j(ind) 

*Gen location 
local if1 "< 2" //all India 
local if2 "==1" //urban
local if3 "==0" //rural

local mkt1 "All"
local mkt2 "Urban"
local mkt3 "Rural"

*regression
forvalues q = 1(1)3 {
 qui areg value_ year if hh_urban `if`q'' [aw=hh_weight], absorb(ind) vce(cluster ind)
 qui estadd local mkt `mkt`q''
 eststo m`q'
}

    esttab m1 m2 m3, nose not label b("%9.2f")	r2 ///
	stats(mkt N r2 , label(Region Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
	title("Regression of Housing Condition on Year (mean and median)") ///
	addnotes("Regressions are weighted by survey weights. Regressions include housing condition indicator fixed effects.")
	
	  
***converging trend of housing condition for q1 and q5 (All, Rural, Urban)***
use "${r_output}\NSS_housing_condition_final_dt.dta",replace //use the dt_file instead

local var_list in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent in_sep_kitch in_flat h20_improved san_improved san_flush_private
local nss_round "49 58 65 69 76" 


foreach var in `var_list' {
 foreach survey in `nss_round' {
   foreach stat in mn md {
   forvalues q = 1(1)3 {
   qui gen t_`var'_`survey'_d_`q'_`stat' = (`var'_5_`survey'_`q'_`stat'- `var'_1_`survey'_`q'_`stat')
   qui replace `var'_d_`q'_`stat' = t_`var'_`survey'_d_`q'_`stat'  if survey == "NSS`survey'" 
   drop t*
   }
  }
 }
}

local j = 0
foreach var in `var_list' {
 local j = `j' + 1
  forvalues q = 1(1)3 {
   foreach stat in mn md {
   rename `var'_d_`q'_`stat'  d_`q'_`stat'`j'
  }
 }
}

keep year d_*

***reshape to get general trend with variable as fixed effect (All, Rural, Urban and Mean, Median, Delta)
reshape long d_1_md d_2_md d_3_md d_1_mn d_2_mn d_3_mn ,i(year) j(ind) 

local mkt1 "All"
local mkt2 "Urban"
local mkt3 "Rural"

foreach stat in mn md {
forvalues q = 1(1)3 {
 qui areg d_`q'_`stat' year, absorb(ind) vce(cluster ind)
 qui estadd local mkt `mkt`q''_`stat'
 eststo d`q'_`stat'
}
}

	esttab d1_mn d2_mn d3_mn d1_md d2_md d3_md, nose not label b("%9.2f")	r2 ///
	stats(mkt N r2 , label(Region Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
	title("Regression of Housing Condition Equality between Q1 and Q5 on Year (mean and median)") ///
	addnotes("Regressions are weighted by survey weights. Regressions include housing condition indicator fixed effects.")


**housekeeping
erase "${r_output}\NSS_housing_condition_final_dt.dta"
log close
