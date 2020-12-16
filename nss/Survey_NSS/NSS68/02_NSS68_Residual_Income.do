***************************
*** AFH 
*** NSS68-Residual Income Approach
*** Prepared by Aline Weng
*** Date:12/08/2020
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

******************************************************************************
*Step 2: Estimate the non-housing expenditure for household at national pline
******************************************************************************
rename ID hhid
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
   keep if total_rent > 0 & !mi(total_rent) //using households that paid rent for budget standard
   forvalues i = 1/3 {
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
	
	gen unaffordable_`i' = (affordable_`i' == 0)*100
    }
	
save "${r_output}\ria_final.dta",replace

******************************************************************************
*Step 3: stats by consumption quintile 
******************************************************************************
use "${r_output}\ria_final.dta",clear

* the affordability by quintile. 
xtile mpce_qt = mpce_mrp [aw = hhwt] , n(5)
global var_tab_1 "unaffordable_1 unaffordable_2 unaffordable_3"

qui eststo total : estpost summarize $var_tab_1 [aw = hhwt],de
forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab_1 [aw = hhwt] if mpce_qt == `i',de
}
esttab total q1 q2 q3 q4 q5, cells(mean(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 1. Percent of Households with Unaffordable Housing Consumption by Expenditure Quintile in Urban India (2012)") varwidth(40) ///
 addnote("Notes: The data source is NSS 68th Round Household Consumer Expenditure."
 "       Households weighted by survey weights." ///
 "       The analysis is using the Residual Income Approach." ///
 "       The affordable_1 is estimated using renters' non-housing expenses drawn from India's urban national poverty threshold by state as the budget standard." ///
 "       The affordable_2 and affordable_3 are estimated utilizing the similar approach but with the double and triple poverty thresholds." ///
 "       Renters are identified as households paying positive rent." ///
 "       The owner non-housing consumer expenditure is overestimated as the mortgage payment data is not collected nor included in the housing expenditure.")

table mpce_qt [aw = hhwt],c(mean affordable_1 mean affordable_2 mean affordable_3)

* distribution of owner and renter consumption expenditure in urban area 
gen mpce_mrp_ln = ln(mpce_mrp)

twoway kdensity mpce_mrp_ln [aw = hhwt] if total_rent > 0 & !mi(total_rent) || kdensity mpce_mrp_ln [aw = hhwt] if (total_rent == 0 | mi(total_rent)), ///
legend(order(1 "Owner" 2 "Renter")) title("Table 2. Kdensity of Log Monthly per capita Consumer Expenditure (MPCE) for India Urban Household (2012)", size(tiny)) xtitle("Log MPCE") ytitle("Kdensity")
 