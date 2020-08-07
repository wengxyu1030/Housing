*------------"------------------------------------------------*
*
* Date:7/8/2020
* Desription: Housing ownership by state for census data. 
*------------------------------------------------------------*

*------------------------------------------------------------*
* BASE
*------------------------------------------------------------*


global github "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/census"

use "${github}/census_2011.dta",clear

* consolidate the vars
gen hv025 = 1 if hh_sector == "Urban"
replace hv025 = 0 if hh_sector == "Rural"
replace hv025 = 2 if hh_sector == "Total"

* Generate own_dwelling 

gen d_own = own/total




duplicates drop state_iso,force
keep state_iso d_*

*Save 
save "${github}/census_hse_own_11.dta", replace