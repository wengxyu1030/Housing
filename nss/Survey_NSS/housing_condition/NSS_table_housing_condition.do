****************************************************************************
* Description: Generate table for housing condition for all nss
* Date: Nov. 25, 2020
* Version 1.0
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
global r_output "${root}\Data Output Files"

*Define the survey rounds. 
global nss_round "NSS49 NSS76 NSS65" 

log using "${script}\NSS_table_housing_condition.log",replace
****************************************************************************
* Load data
****************************************************************************
use "${root}\NSS49\Data Output Files\NSS49_housing_condition.dta",clear

foreach survey in NSS65 NSS76 {
append using "${root}/`survey'/Data Output Files/`survey'_housing_condition.dta",force
}

drop h20_temp h20_distance h20_exclusive h20b_pip_exl h20b_pip_shr h20b_grd_exl h20b_grd_shr h20b_other h20_cooking ///
san_source san_distance

****************************************************************************
* Generate the time series table of housing conditions
****************************************************************************
local var_summary hh_size in_* h20* san* 

foreach survey in $nss_round {
qui eststo `survey': quietly estpost summarize `var_summary'  [aw=hh_weight] if survey == "`survey'"
}

esttab NSS49 NSS65 NSS76, cells(mean(fmt(%15.0fc))) label collabels(none) varwidth(41) ///
 mtitles("1993" "2008" "2018") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 1 Summary Statistics of Housing Condition (mean)") ///
 addnotes("Notes: The value is missing if the information was not surveyed in the NSS round")
 
log close