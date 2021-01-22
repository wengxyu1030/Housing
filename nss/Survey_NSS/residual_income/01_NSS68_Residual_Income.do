***************************
*** AFH 
*** NSS68-Residual Income Approach (2012)
*** Prepared by Aline Weng
*** Date:1/22/2021
***************************

clear 
set more off 

if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

cd "${root}"

global r_input "${root}\Raw Data & Dictionaries"
global r_output "${root}\Data Output Files"

log using "${script}\NSS68\01_NSS68_Residual_Income_Affordability.log",replace
set linesize 255

***************************************************************
*Step 1: Estimate the housing consumption per household member. 
***************************************************************
use "${r_input}\bk_12.dta",clear
merge m:1 ID using "${r_input}\bk_3.dta"
drop _merge

gen hh_size = B3_v01
   
/* poverty line is by state and by sector */

    *estimate housing related expenditure:
	  
	  *Rent (12: 26, 30 days recall period)
	  gen double rent = B12_v06*(B12_v01 == 26)
	  
	  *Fuel and light (12: 18, 30 days recall period)
	  gen double fuel = B12_v06*(B12_v01 == 18)
	
	  *Collapse at household level 
	  foreach var in rent fuel { 
	  egen double total_`var' = sum(`var'), by(ID)
	  } 
	  bys ID: keep if _n == 1 // keep only one observation for each HH
	
      merge 1:m ID using "${r_input}\bk_10.dta"
      drop _merge
     
	  *water charge(10: 540, 30 days recall period)
	  keep if B10_v02 == 540
	  egen double total_water = sum(B10_v03), by(ID)
	  bys ID: keep if _n == 1 // keep only one observation for each HH
	
	*Total housing expenditure
	egen double exp_housing = rowtotal(total_rent total_fuel total_water)

    *Housing consumption per capita
	gen double total_exp_housing_pp = exp_housing/hh_size 
	
    *Identify renters
	gen renter = (total_rent > 0 & !mi(total_rent))

******************************************************************************
*Step 2: Estimate the non-housing expenditure for household at national pline
******************************************************************************
rename ID hhid
merge 1:1 hhid using "${r_input}\poverty68.dta"
keep if _merge == 3
drop _merge

   gen urban = (B1_v05 == 2) 
   keep if urban == 1 //only focusing on urban households
   
   *different budget scenario: pline, double pline, triple pline.    
   forvalues i = 1/3 {
   gen pline_`i' = pline*`i'
   }
   
   *Non-housing consumption per capita
   gen double exp_non_housing_pp = mpce_mrp - total_exp_housing_pp //all poverty line data are compiled using the MRP metho
   
   *Expenditure quintile (for all india, urban and rural sector)
   xtile mpce_qt = mpce_mrp [aw = hhwt] , n(5)
   xtile mpce_qt_tn = mpce_mrp [aw = hhwt] if state == 33, n(5)
   
   *take log of expenditure
   gen mpce_mrp_ln = ln(mpce_mrp)
   
save "${r_output}\ria_1.dta",replace

//get the poverty line by state for the urban sector
use "${r_output}\ria_1.dta",replace

keep if urban == 1
gen state_n = state

collapse (mean) pline_1 pline_2 pline_3,by(state state_n) 
gen _Istate_ = 1

reshape wide _Istate_,i(state pline_1 pline_2 pline_3) j(state_n)
qui mvencode _all, mv(0) //change missing values to zero

reshape long pline_,i(state) j(levels)

rename pline mpce_mrp
gen exp_non_housing_pp = . 

save "${r_output}\temp.dta",replace

//fit renter's non-housing and total expenditure to linear model
use "${r_output}\ria_1.dta",replace
gen state_r = state 

drop if renter != 1 //only focusing on renters. 
reg exp_non_housing_pp mpce_mrp i.state

qui xi : reg exp_non_housing_pp mpce_mrp i.state

//estimate the non-housing expenditure budget standard (non-housing expenditure poverty line)
use "${r_output}\temp.dta",clear
predict exp_non_housing_pp_line_

rename mpce_mrp pline_
keep state levels pline exp_non_housing_pp_line_
reshape wide pline exp_non_housing_pp_line_, i(state) j(level)

save "${r_output}\ria_non_housing_line.dta",replace
erase "${r_output}\temp.dta"

//merge the alternative poverty lines to the master data.    
merge 1:m state using "${r_output}\ria_1.dta"

keep if _merge == 3 //only on urban sector
drop _merge  
drop if total_rent == 0 & !mi(total_rent) //only focusing on renters. 

	*find the affordable housings
	forvalues i = 1/3 {
    gen affordable_`i' = (exp_non_housing_pp > exp_non_housing_pp_line_`i')*100
    tab affordable_`i' [aw = hhwt]
	
	gen unaffordable_`i' = (affordable_`i' == 0)*100
    }

// hosue keeping
forvalues i = 1/3 {
label var unaffordable_`i' "Hs. in Unaffordable Housing `i'pline"
label var affordable_`i' "Hs. in Affordable Housing `i'pline"
}

label var exp_non_housing_pp "Mth. PC. Non-Housing Exp."
label var total_exp_housing_pp "Mth. PC. Housing Exp."

save "${r_output}\ria_final.dta",replace

******************************************************************************
*Step 3: stats by consumption quintile 
******************************************************************************
 
* distribution of owner and renter consumption expenditure in urban area: renters are in higher quintiles. 
use "${r_output}\ria_1.dta",clear //with both renter and owner. 


twoway kdensity mpce_mrp_ln [aw = hhwt] if renter == 1 || kdensity mpce_mrp_ln [aw = hhwt] if renter == 0, ///
legend(order(1 "Renter" 2 "Owner")) title("Table 2. Kdensity of Log Monthly per capita Consumer Expenditure (MPCE) for India Urban Household (2012)", size(tiny)) xtitle("Log MPCE") ytitle("Kdensity")

gen tn = (state == 33)
 
table renter, c(mean mpce_mrp median mpce_mrp) format(%9.2f)
table mpce_qt, c(mean renter) format(%9.2f)

table renter if tn == 1, c(mean mpce_mrp median mpce_mrp) format(%9.2f)
table mpce_qt_tn if tn == 1, c(mean renter) format(%9.2f)

*affordability and the share of housing expenditure to total expenditure (RIA and Ratio Approach)
use "${r_output}\ria_final.dta",replace

gen h_t_exp_mn = total_exp_housing_pp/mpce_mrp*100 
label var h_t_exp_mn "Mean of Housing Exp. / Total Exp. (%)"

egen h_t_exp_r_md_q = median(h_t_exp_mn),by(mpce_qt)
egen h_t_exp_r_md_all = median(h_t_exp_mn)

egen h_t_exp_r_md_q_tn = median(h_t_exp_mn) if state == 33,by(mpce_qt_tn)
egen h_t_exp_r_md_all_tn = median(h_t_exp_mn) if state == 33

foreach var in h_t_exp_r_md_all {
label var `var' "Med.of Housing Exp. / Total Exp. (%)" 
label var `var'_tn "Med.of Housing Exp. / Total Exp. (%)" 
}

global var_tab_1 "h_t_exp_mn unaffordable_1 unaffordable_2 unaffordable_3"

qui eststo total : estpost summarize h_t_exp_r_md_all $var_tab_1 [aw = hhwt],de
replace h_t_exp_r_md_all = h_t_exp_r_md_q 

qui eststo total_tn : estpost summarize h_t_exp_r_md_all_tn $var_tab_1 [aw = hhwt] if state == 33,de
replace h_t_exp_r_md_all_tn = h_t_exp_r_md_q_tn

forvalues i = 1/5 {
qui eststo q`i' : estpost summarize h_t_exp_r_md_all $var_tab_1 [aw = hhwt] if mpce_qt == `i',de
qui eststo q`i'_tn : estpost summarize h_t_exp_r_md_all_tn $var_tab_1 [aw = hhwt] if mpce_qt_tn == `i' & state == 33,de
}

//table for all India
esttab total q1 q2 q3 q4 q5, cells(mean(fmt(%15.1fc))) label collabels(none) /// 
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 1. Percent of Renter Households with Unaffordable Housing Expenditure by Expenditure Quintile in Urban India (2012)") varwidth(40) ///
 addnote("Notes: The data source is NSS 68th Round Household Consumer Expenditure." ///
 "       Households weighted by survey weights." ///
 "       The analysis is using the Residual Income Approach." ///
 "       The affordability at 1pline is estimated using renters' non-housing expenses drawn from India's urban national poverty threshold by state as the budget standard." ///
 "       The affordabiiity at 2pline and 3pline are estimated utilizing the similar approach but with the double and triple poverty thresholds." ///
 "       Renters are identified as households paying positive rent." ///
 "       The owner non-housing consumer expenditure is not in the scope as the mortgage payment data is not collected in the the survey.")

//table for TN: higher affordability than india. 
esttab total_tn q1_tn q2_tn q3_tn q4_tn q5_tn, cells(mean(fmt(%15.1fc))) label collabels(none) /// 
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 2. Percent of Renter Households with Unaffordable Housing Expenditure by Expenditure Quintile in Urban Tamil Nadu (2012)") varwidth(40) ///
 addnote("Notes: The data source is NSS 68th Round Household Consumer Expenditure." ///
 "       Households weighted by survey weights." ///
 "       The analysis is using the Residual Income Approach." ///
 "       The affordability at 1pline is estimated using renters' non-housing expenses drawn from India's urban national poverty threshold by state as the budget standard." ///
 "       The affordabiiity at 2pline and 3pline are estimated utilizing the similar approach but with the double and triple poverty thresholds." ///
 "       Renters are identified as households paying positive rent." ///
 "       The owner non-housing consumer expenditure is not in the scope as the mortgage payment data is not collected in the the survey.")

* k-density for affordability: housing/expenditure around. 
gen exp_non_housing_pp_ln = ln(exp_non_housing_pp)

sum pline_1 pline_2 pline_3 if state == 33

forvalues i = 1/3 {
qui sum pline_`i' if state == 33
local pline_`i'_ln = ln(r(mean))
dis `pline_`i'_ln'
}

kdensity exp_non_housing_pp_ln if state == 33 [aw=hhwt], xline(`pline_1_ln' `pline_2_ln' `pline_3_ln') ///
title("NSS68 - 2012, Residual Income vs. Minimum Standard by Scenario in Urban Tamil Nadu", size(small)) ///
xtitle("Ln of Non-housing Exp. PC.")
 
log close
