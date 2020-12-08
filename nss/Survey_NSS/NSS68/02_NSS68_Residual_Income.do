***************************
*** AFH 
*** NSS68-Residual Income Approach
*** Prepared by Aline Weng
*** Date:12/01/2020
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

log using "${script}\NSS68\02_NSS68_Residual_Income_Affordability.log",replace
set linesize 255

***************************************************************
*Step 1: Estimate the housing consumption per household member. 
***************************************************************
use "${r_input}\bk_12.dta",clear
merge m:1 ID using "${r_input}\bk_3.dta"

gen hh_size = B3_v01
   
/* poverty line is by state and by sector */

    *estimate housing related expenditure:
	  *?water charge (10:540)
	  
	  *Rent (12: 26, 30 days recall period)
	  gen double rent = B12_v06*(B12_v01 == 26)
	  
	  *Fuel and light (12: 18, 30 days recall period)
	  gen double fuel = B12_v06*(B12_v01 == 18)
      
	*Total housing expenditure
	egen double exp_housing = rowtotal(rent fuel)
	
	*Collapse at household level 
	foreach var in rent fuel exp_housing { 
	egen double total_`var' = sum(`var'), by(ID)
	} 
	bys ID: keep if _n == 1 // keep only one observation for each HH
    
	*Housing consumption per capita
	gen double total_exp_housing_pp = total_exp_housing/hh_size

rename ID hhid
drop _merge

******************************************************************************
*Step 2: Estimate the non-housing expenditure for household at national pline
******************************************************************************
merge 1:1 hhid using "${r_input}\poverty68.dta"
keep if _merge == 3
drop _merge

   gen urban = (B1_v05 == 2) 
   keep if urban == 1
   
   *different budget scenario: pline, double pline, triple pline.    
   forvalues i = 1/3 {
   gen pline_`i' = pline*`i'
   gen delta_pline_`i' = (abs(mpce_mrp - pline_`i')/pline_`i' * 100 <= 10) //find households around poverty line
   tab delta_pline_`i'
   }
   
   *Non-housing consumption per capita
   gen double exp_non_housing_pp = mpce_mrp - total_exp_housing_pp
   
save "${r_output}\ria_1.dta",replace

   *find the median non_housing consumption by state by scenario
   forvalues i = 1/3{
   use "${r_output}\ria_1.dta",clear
   
   keep if delta_pline_`i' == 1 
   egen double exp_non_housing_pp_line_`i' = median(exp_non_housing_pp), by(state)
   
   bys state: keep if _n == 1
   keep state exp_non_housing_pp_line_`i'
 
   save "${r_output}\ria_non_housing_line_`i'.dta",replace
   }
   
   use "${r_output}\ria_non_housing_line_1.dta",clear
   forvalues i = 2/3{
   merge 1:1 state using "${r_output}\ria_non_housing_line_`i'.dta"
   drop _merge
   }
   
save "${r_output}\ria_non_housing_line.dta",replace
   
merge 1:m state using "${r_output}\ria_1.dta"
keep if _merge == 3 //only on urban sector
drop _merge  

	*find the affordable housings
	forvalues i = 1/3 {
    gen affordable_`i' = (exp_non_housing_pp > exp_non_housing_pp_line_`i')*100
    tab affordable_`i' [aw = hhwt]
    }
	
save "${r_output}\ria_final.dta",replace

******************************************************************************
*Step 3: stats by consumption quintile 
******************************************************************************
use "${r_output}\ria_final.dta",clear

xtile mpce_qt = mpce_mrp [aw = hhwt] , n(5)
global var_tab_1 "affordable_1 affordable_2 affordable_3"

qui eststo total : estpost summarize $var_tab_1 [aw = hhwt],de
forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab_1 [aw = hhwt] if mpce_qt == `i',de
}
esttab total q1 q2 q3 q4 q5, cells(mean(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 1. Share of Households Living in Affordable Houses by Consumption Expenditure Quintile in Urban India") varwidth(40) ///
 addnote("Notes: Households weighted by survey weights." ///
 "       The analysis is using the Residual Income Approach." ///
 "       The affordable_1 is estimated using non-housing expenses drawn from India's urban national poverty threshold by state." ///
 "       The affordable_2 and affordable_3 are estimated utilizing the similar approach but with the double and triple poverty thresholds.")

table mpce_qt [aw = hhwt],c(mean affordable_1 mean affordable_2 mean affordable_3)
