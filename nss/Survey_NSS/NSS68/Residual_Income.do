***************************
*** AFH 
*** NSS68-Residual Income Approach
*** Prepared by Aline Weng
*** Date:12/01/2020
***************************
clear 
set more off 

global ROOT "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
cd "${ROOT}"

global raw "${ROOT}\raw"
global inter "${ROOT}\inter"
global final "${ROOT}\final"


*Step 1: Estimate the housing consumption per household member. 
use "${raw}\bk_12.dta",clear
merge m:1 ID using "${raw}\bk_3.dta"

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


*Step 2: Estimate the non-housing expenditure for household at national pline
merge 1:1 hhid using "${raw}\poverty68.dta"
keep if _merge == 3
drop _merge

   gen urban = (B1_v05 == 2) 
   keep if urban == 1
   
   gen delta_pline = (abs(mpce_mrp - pline)/pline * 100 <= 10) //find households around poverty line
   tab delta_pline
   
   *Non-housing consumption per capita
   gen double exp_non_housing_pp = mpce_mrp - total_exp_housing_pp
   
save "${inter}\ria_1.dta",replace
   
use "${inter}\ria_1.dta",clear
   
   keep if delta_pline == 1 
   egen double exp_non_housing_pp_line = median(exp_non_housing_pp), by(state)
   bys state: keep if _n == 1
   keep state exp_non_housing_pp_line
 
save "${inter}\ria_non_housing_line.dta",replace
merge 1:m state using "${inter}\ria_1.dta"
keep if _merge == 3 //only on urban sector
drop _merge  
	*find the affordable housings
    gen affordable = (exp_non_housing_pp > exp_non_housing_pp_line)*100
    tab affordable [aw = hhwt]

save "${final}\ria_final.dta",replace

*Step 3: stats by consumption quintile 
use "${final}\ria_final.dta",clear

xtile mpce_qt = mpce_mrp [aw = hhwt] , n(5)

tab affordable [aw = hhwt]

table mpce_qt [aw = hhwt],c(mean affordable)

table mpce_qt,c(med exp_non_housing_pp med exp_non_housing_pp_line)