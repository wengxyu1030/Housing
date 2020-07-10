log using "${final}/output_table_india_6576",replace

*****************************
***Consolidate the Surveys***
*****************************

global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all"
global raw "${ROOT}/raw"

global inter "${ROOT}/inter"
global final "${ROOT}/final"
global do "${ROOT}/script"

/*
This file is to:
1. Consolidate the surveys
2. Calculate the indicators
*/

***Specify the Surveys***
global surveys "nss65 nss76"

*data source
use "${raw}/nss76.dta", clear	
append using "${raw}/nss69.dta"
append using "${raw}/nss65.dta"

*calculate indicators
    *overcrowding measured by dwelling room number 
    gen infra_crowd_r = hh_size / infra_room
    
	*overcrowding measured by dwelling area
    gen infra_crowd_a = infra_area / hh_size
    
	*cost of rent to umce
	gen hq_rent_rate = cost_rent / hh_umce
	
	*cost of rent per square feet
	gen hq_rent_sq = cost_rent / infra_area
	
*chang unit for percentage unit
local tab_mean "infra_imp_roof	infra_imp_wall	infra_imp_floor	infra_water_in	infra_pucca_drainage	legal_tenure_se	legal_own	legal_rent"

foreach var of var `tab_mean' {
replace `var' = `var'*100
}

*data order
order cost_rent	infra_room	infra_crowd_r	infra_area	infra_crowd_a	legal_tenure_se	legal_own	legal_rent	infra_imp_roof	infra_imp_wall	infra_imp_floor	infra_pucca_drainage	infra_water_in

*label and order the vars. 
label var cost_rent "Monthly Rent (Rs.)"
label var infra_room "Number of Room"
label var infra_crowd_r "Persons per Room"
label var infra_area "Floor Area (Sq.Ft.)"
label var infra_crowd_a "Square Feet per Person"
label var legal_tenure_se "With Secure Tenure (%)"
label var legal_own "Own Dwelling (%)"
label var legal_rent "Rent Dwelling (%)"
label var infra_imp_roof "Roof Type is Improved Material (%)"
label var infra_imp_wall "Wall Type is Improved Material (%)"
label var infra_imp_floor "Floor Type is Improved Material (%)"
label var infra_pucca_drainage "Drianage Type is Improved Material (%)" //?
label var infra_water_in "Drinking water in premises (%)"
label var hq_rent_sq "Rent per Sq Foot (Rs./Sq.Ft.)"

save "${final}/master",replace

******************************
***The State GDP *************
******************************
import excel "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\raw\State_series_as_on_15032020_aw.xls", sheet("PC con. (aw)") firstrow clear

keep NSS_69_76 StateUT J
rename NSS_69_76 hh_state
rename J gdp_17 //latest complete gdp (17-18): PC CONSTANT (2011-12) PRICES; BASE YEAR 2011-12
rename StateUT hh_state_name

sort gdp_17
egen rank_hi = rank(-gdp_17)
egen rank_lo = rank(gdp_17)

gen state_hi = (inrange(rank_hi,1,5))
gen state_lo = (inrange(rank_lo,1,5))

keep if state_hi == 1 | state_lo == 1
drop state_hi state_lo rank_hi rank_lo
egen rank_hi = rank(-gdp_17)

replace hh_state_name = "Delhi" if strpos(hh_state_name,"Delhi")
keep hh_state hh_state_name rank_hi 

save "${raw}/state_gdp",replace

******************************
***Calculate the Indicators***
******************************

use "${final}/master",replace

*keep the richest and poorest 
merge m:1 hh_state using "${raw}/state_gdp"
keep if _merge == 3
drop _merge

*specify indicators
local tab_median "cost_rent	infra_crowd_a hq_rent_sq"
local tab_mean "legal_tenure_se legal_rent hq_rent_sq"

*****************descriptive stats******************
foreach var of var `tab_median' {
sum `var',detail
}

*****************India: 08-18***********************
*mean for india state urban nss76, nss65
local tab_list "legal_tenure_se legal_rent cost_rent hq_rent_sq infra_crowd_a"
forval i = 1/10 {
 qui eststo stats76_`i': estpost summarize `tab_list' [aw = hh_weight] if rank_hi == `i' & id_survey == "76" & hh_urban ==1, detail 
 qui eststo stats65_`i': estpost summarize `tab_list' [aw = hh_weight] if rank_hi == `i' & id_survey == "65" & hh_urban ==1, detail 
}

esttab stats76_1 stats76_2 stats76_3 stats76_4 stats76_5 stats76_6 stats76_7 stats76_8 stats76_9 stats76_10, ///
	replace main(mean %6.1fc) label wide varwidth(30) modelwidth(6) onecell not nonotes ///
	title("India Top 5 Richest and Poorest States Urban 2018: Table of Means") ///
	mtitle("Goa"	"Delhi"	"Chandigarh"	"Sikkim"	"Haryana"	"Madhya Pradesh"	"Jharkhand"	"Manipur"	"Uttar Pradesh"	"Bihar") ///
	addnotes("a. The Montly Rent is conditional on rent." ///
	"b. Person per Room is defined as household size divide by total number" ///
    "	of rooms in the dwelling." ///
	"c. Square Feet per Person is defined as total floor area of the dwelling" ///
	"   divide by the household size of the dwelling that measured in square feet." ) 


esttab stats65_1 stats65_2 stats65_3 stats65_4 stats65_5 stats65_6 stats65_7 stats65_8 stats65_9 stats65_10, ///
	replace main(mean %6.1fc) label wide varwidth(30) modelwidth(6) onecell not nonotes ///
	title("India Top 5 Richest and Poorest States Urban 2008: Table of Means") ///
	mtitle("Goa"	"Delhi"	"Chandigarh"	"Sikkim"	"Haryana"	"Madhya Pradesh"	"Jharkhand"	"Manipur"	"Uttar Pradesh"	"Bihar") ///
	addnotes("a. The Montly Rent is conditional on rent." ///
	"b. Person per Room is defined as household size divide by total number" ///
    "	of rooms in the dwelling." ///
	"c. Square Feet per Person is defined as total floor area of the dwelling" ///
	"   divide by the household size of the dwelling that measured in square feet." )
	
*Median for india state urban nss76, nss65
local tab_list "legal_tenure_se legal_rent cost_rent infra_crowd_a"
forval i = 1/10 {
 qui eststo stats76_`i': estpost summarize `tab_median' [aw = hh_weight] if rank_hi == `i' & id_survey == "76" & hh_urban ==1, detail 
 qui eststo stats65_`i': estpost summarize `tab_median' [aw = hh_weight] if rank_hi == `i' & id_survey == "65" & hh_urban ==1, detail 
}

esttab stats76_1 stats76_2 stats76_3 stats76_4 stats76_5 stats76_6 stats76_7 stats76_8 stats76_9 stats76_10, ///
	replace main(p50 %6.1fc) label wide varwidth(30) modelwidth(6) onecell not nonotes ///
	title("India Top 5 Richest and Poorest States Urban 2018: Table of Medians") ///
	mtitle("Goa"	"Delhi"	"Chandigarh"	"Sikkim"	"Haryana"	"Madhya Pradesh"	"Jharkhand"	"Manipur"	"Uttar Pradesh"	"Bihar") ///
	addnotes("a. The Montly Rent is conditional on rent." ///
	"b. Person per Room is defined as household size divide by total number" ///
    "	of rooms in the dwelling." ///
	"c. Square Feet per Person is defined as total floor area of the dwelling" ///
	"   divide by the household size of the dwelling that measured in square feet." )


esttab stats65_1 stats65_2 stats65_3 stats65_4 stats65_5 stats65_6 stats65_7 stats65_8 stats65_9 stats65_10, ///
	replace main(p50 %6.1fc) label wide varwidth(30) modelwidth(6) onecell not nonotes ///
	title("India Top 5 Richest and Poorest States Urban 2008: Table of Medians") ///
	mtitle("Goa"	"Delhi"	"Chandigarh"	"Sikkim"	"Haryana"	"Madhya Pradesh"	"Jharkhand"	"Manipur"	"Uttar Pradesh"	"Bihar") ///
	addnotes("a. The Montly Rent is conditional on rent." ///
	"b. Person per Room is defined as household size divide by total number" ///
    "	of rooms in the dwelling." ///
	"c. Square Feet per Person is defined as total floor area of the dwelling" ///
	"   divide by the household size of the dwelling that measured in square feet." )



log close

translate "${final}/output_table_india_6576.smcl" "${final}/output_table_india_6576.log", replace
