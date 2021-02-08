***************************
*** AFH 
*** NSS61-Residual Income Approach (2004)
*** Prepared by Aline Weng
*** Date:2/8/2021
***************************

/*
The definition of renter changes to match Nadeem's renter tables. 
*/

clear 
set more off 

if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 61"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS61"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

cd "${root}"

global r_input "${root}\Raw Data & Dictionaries"
global r_output "${root}\Data Output Files"

***************************************************************
*Step 1: Estimate the housing consumption per household member. 
***************************************************************
use "${r_input}\Block 10_Monthly expenditure on miscellaneous goods and services including medical (non-institutional), rents and taxes.dta",clear
merge m:1 HHID using "${r_input}\Block 3.dta"
drop _merge
merge m:1 HHID using "${r_input}\Block 3 Part 2_Household Characteristics.dta"
drop _merge

gen hh_size = B3_q1
   
/* poverty line is by state and by sector */

    *estimate housing related expenditure:
	  
	  *Rent (10: code = 529, 30 days recall period)
	  gen double rent = B10_q4*(B10_q1 == "520")
	  
	  *Water charge(10: 540, 30 days recall period)
	  gen double water = B10_q4*(B10_q1 == "540")
	  
	  *Collapse at household level for water ant rent
	  foreach var in rent water { 
	  egen double total_`var' = sum(`var'), by(HHID)
	  } 
	  bys HHID: keep if _n == 1 // keep only one observation for each HH

merge 1:m HHID using "${r_input}\Block 6_Monthly consumption of fuel & light.dta"
drop _merge
	  
	  *Fuel and light (12: 18, 30 days recall period)
	  gen double fuel = B6_q6*(B6_q1 == "359")
	  egen double total_fuel = sum(fuel), by(HHID)
	  bys HHID: keep if _n == 1

	*Total housing expenditure
	egen double exp_housing = rowtotal(total_rent total_fuel total_water)

    *Housing consumption per capita
	gen double total_exp_housing_pp = exp_housing/hh_size 
	
    *Identify renters
	gen renter = (B3_q16 == "2")*100 //rent is positive and tenure status is hire. 

******************************************************************************
*Step 2: Estimate the non-housing expenditure for household at national pline
******************************************************************************
rename HHID hhid
merge 1:1 hhid using "${r_input}\NSS_61_Poverty_For_Aline.dta"
keep if _merge == 3
drop _merge
   
   *different budget scenario: pline, double pline, triple pline.    
   forvalues i = 1/3 {
   gen pline_`i' = pline*`i'
   }
   
   *Non-housing consumption per capita
   gen double exp_non_housing_pp = mpce_mrp - total_exp_housing_pp //all poverty line data are compiled using the MRP metho
   
   *Expenditure quintile (for all india, urban and rural sector)
   xtile mpce_qt = mpce [aw = hhwt] , n(5)
   xtile mpce_qt_tn = mpce [aw = hhwt] if state == 33, n(5)
   
   *take log of expenditure
   gen mpce_mrp_ln = ln(mpce_mrp)
   
   *only focusing on urban households
   gen urban = (sector == 2) 
   keep if urban == 1

   *renter table
   table renter, c(mean mpce median mpce) format(%9.2f) row
   table mpce_qt, c(mean renter) format(%9.2f) row

******************************************************************************
*Use data from datalibweb only 
******************************************************************************
 use "${r_input}\NSS_61_Poverty_For_Aline.dta",clear
 
     *Expenditure quintile (for all india, urban and rural sector)
     xtile mpce_qt = mpce [aw = hhwt] , n(5)
     xtile mpce_qt_tn = mpce [aw = hhwt] if state == 33, n(5)
   
     *only focusing on urban households
     gen urban = (sector == 2) 
     keep if urban == 1
       
	 *renter
	 gen renter = (dwellingowned ! =1) * 100
   
     *renter table
     table renter, c(mean mpce_mrp median mpce_mrp) format(%9.2f) row
     table mpce_qt, c(mean renter) format(%9.2f) row
