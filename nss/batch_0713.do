/* This file is to consolidate the survey and produce the tables */

*****************************
***Consolidate the Surveys***
*****************************

global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all"
global do "${ROOT}/script"

***run files by survey****
do "${do}/nss65.do"
do "${do}/nss69.do"
do "${do}/nss76.do"
do "${do}/nss49.do"

***set the environment****
global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all"
global raw "${ROOT}/raw"
global inter "${ROOT}/inter"
global final "${ROOT}/final"
global github "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/nss"


/*
This file is to:
1. Consolidate the surveys
2. Calculate the indicators
*/

***Specify the Surveys***
global surveys "nss49 nss65 nss69 nss76"

//log using "${final}/output_table_india_6576",replace

*data source
use "${raw}/nss76.dta", clear	
append using "${raw}/nss58.dta"
append using "${raw}/nss69.dta"
append using "${raw}/nss65.dta"
append using "${raw}/nss49.dta"

*calculate indicators
    *pucca structure: roof, wall, and floor. 
	gen infra_pucca_strct = 0 if infra_has_dwell == 1
	replace infra_pucca_strct = 1 if infra_imp_wall == 1 & infra_imp_roof == 1 & infra_pucca_floor == 1 & infra_has_dwell == 1
	
    *overcrowding measured by dwelling room number 
    gen infra_crowd_r = hh_size / infra_room
    
	*overcrowding measured by dwelling area
    gen infra_crowd_a = infra_area / hh_size
    
	*cost of rent to umce
	gen cost_rent_rate = cost_rent / hh_umce
	
	*cost of rent per square feet
	replace cost_rent = . if cost_rent == 0 | legal_rent != 1
	gen cost_rent_sq = cost_rent / infra_area
	
	
*chang unit for percentage unit
local tab_mean "infra_imp_roof	infra_imp_wall	infra_imp_floor	infra_water_in	infra_pucca_drainage	legal_tenure_se	legal_own	legal_rent cost_rent_rate"

foreach var of var `tab_mean' {
replace `var' = `var'*100
}

*label and order the vars. 
label var cost_rent "Monthly Rent (Rs.)"
label var infra_room "Number of Room"
label var infra_crowd_r "Persons per Room"
label var infra_area "Floor Area (Sq.Ft.)"
label var infra_crowd_a "Square Feet per Person"
label var infra_pucca_strct "Household in Pucca Structure (%)"
label var legal_tenure_se "With Secure Tenure (%)"
label var legal_own "Own Dwelling (%)"
label var legal_rent "Rent Dwelling (%)"
label var legal_move "Where resid before move to present area"
label var legal_move_reason "Reason for movement to the present area"
label var legal_stay10 "Duration of stay in the present area"
label var infra_imp_roof "Roof Type is Improved Material (%)"
label var infra_imp_wall "Wall Type is Improved Material (%)"
label var infra_imp_floor "Floor Type is Improved Material (%)"
label var infra_pucca_drainage "Drianage Type is Improved Material (%)" //?
label var infra_water_in "Drinking water in premises (%)"
label var cost_rent_sq "Rent per Sq Foot (Rs./Sq.Ft.)"
label var hh_size "Household Size"
label var cost_rent_rate "Rent to Consumption (%）"
label var hh_sector "Household Sector"
label var hh_urban "Household in Urban Sector"
label var hh_state "Household State"
label var hh_tn "Household in Tamil Nadu" 
label var hh_weight "Household Weight" 

*consolidate the states
do "${github}/01_Add State Names to Housing NSS Rounds v2.do"

*merge with the iso code
merge m:1 hh_state using "${raw}/state_code.dta"
keep if _merge == 1
drop _merge

save "${final}/nss",replace
save "${github}/nss",replace
