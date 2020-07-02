log using "${final}/output_table_india",replace

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
global surveys "nss69 nss76"

*data source
use "${raw}/nss76.dta", clear	
append using "${raw}/nss69.dta"

******************************
***Calculate the Indicators***
******************************

*label and order the vars. 
label var cost_rent "Monthly Rent (Rs.)"
label var infra_room "Number of Room"
label var infra_crowd_r "Persons per Room"
label var infra_area "Floor Area (ft2.)"
label var infra_crowd_a "Square Feet per Person"
label var legal_tenure_se "With Secure Tenure (%)"
label var legal_own "Own Dwelling (%)"
label var legal_rent "Rent Dwelling (%)"
label var infra_pucca_roof "Roof Type is Pucca (%)"
label var infra_pucca_wall "Wall Type is Pucca (%)"
label var infra_pucca_floor "Floor Type is Pucca (%)"
label var infra_pucca_drainage "Drianage Type is Pucca (%)"
label var infra_water_in "Drinking water in premises (%)"

*specify indicators
local tab_median "cost_rent	infra_room	infra_crowd_r	infra_area	infra_crowd_a"
local tab_mean "infra_pucca_roof	infra_pucca_wall	infra_pucca_floor	infra_water_in	infra_pucca_drainage	legal_tenure_se	legal_own	legal_rent"
local tab_list "infra_pucca_roof	infra_pucca_wall	infra_pucca_floor	infra_water_in	infra_pucca_drainage	legal_tenure_se	legal_own	legal_rent cost_rent infra_room	infra_crowd_r	infra_area	infra_crowd_a"


*****************India: 12-18***********************

*mean for all india nss76
eststo stats_76: estpost summarize `tab_list' [aw = hh_weight] if id_survey == "76", detail 

*mean for all india nss69
eststo stats_69: estpost summarize `tab_list' [aw = hh_weight] if id_survey == "69", detail

*Means mean
esttab stats_69 stats_76 , ///
	replace main(mean %6.2f) label wide varwidth(40) modelwidth(4) onecell not ///
	mtitle("India 69" "India 76") nonotes /// 
	title("2012 to 2018: Table of Means")

*Means median
esttab stats_69 stats_76 , ///
	replace main(p50 %6.2f) label wide varwidth(40) modelwidth(4) onecell not ///
	mtitle("India 69" "India 76") nonotes /// 
	title("India 2012 to 2018: Table of Medians") append drop(`tab_mean')

*****************India: rural-urban***********************

*mean for all india nss76 urban
eststo stats_76_u: estpost summarize `tab_list' [aw = hh_weight] ///
if id_survey == "76" & hh_urban == 1, detail 

*mean for all india nss76 rural
eststo stats_76_r: estpost summarize `tab_list' [aw = hh_weight] ///
if id_survey == "76" & hh_urban == 0, detail

*Means mean
esttab stats_76_u stats_76_r , ///
	replace main(mean %6.2f) label wide varwidth(40) modelwidth(4) onecell not ///
	mtitle("Urban" "Rural") nonotes /// 
	title("India 2018 Urban and Rural: Table of Means")

*Means median
esttab stats_76_u stats_76_r , ///
	replace main(p50 %6.2f) label wide varwidth(40) modelwidth(4) onecell not ///
	mtitle("Urban" "Rural") nonotes /// 
	title("India 2018 Urban and Rural: Table of Medians") append drop(`tab_mean')


log close

translate "${final}/output_table_india.smcl" "${final}/output_table_india.log", replace
