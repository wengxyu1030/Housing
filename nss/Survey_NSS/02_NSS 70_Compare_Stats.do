****************************************************************************
* Description: Generate a summary table of NSS 70, compare to published stats
* Date: Nov 15, 2020
* Version 3
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 70\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

log using "${script}\02_Table of Means NSS 70.log",replace

 
****************************************************************************
* Compare with official NSS70 report. 
****************************************************************************
 
 **Official NSS70 Report
/* Statement 3.1
Households owning asset: rural 98.3% urban 93.5%
Averate value of total assets (AVA) owned: rural: 1,006,985 urban 2,285,135
*/

/* Statement 3.4
Households owning debt: rural 31.44% urban 22.37%
Average amount of debt (AOD) owned: rural: 32522 urban 84625 (all households)
*/
use "${root}\Data Output Files\NSS70_All.dta",clear

gen asset_dm = (asset > 0)*100
gen debt_dm = (total_debt > 0)*100 

forvalues i = 0/1{
eststo tab_urban_`i': estpost sum asset_dm asset debt_dm total_debt [aw = hhwgt] if urban == `i'
}

label var asset_dm "Own Asset (%)"
label var debt_dm "Own Debt (%)"
label var asset "Average Asset"
label var total_debt "Average Debt"

esttab tab_urban_0 tab_urban_1,cells(mean(fmt(%15.0fc))) label collabels(none) ///
 mtitles("Rural" "Urban")

 
clear matrix
global pdf_tab "asset_dm asset debt_dm total_debt"
eststo all: quietly estpost summarize $pdf_tab [aw=hhwgt]

unab vars : $pdf_tab 
local num : word count `vars'
matrix m = J(`num',4,0)
local i = 1

foreach var in $pdf_tab {
qui sum `var' [aw=hhwgt] if urban == 0,de
matrix m[`i',1] = `r(mean)'
qui sum `var' if urban == 0,de
matrix m[`i',2] = `r(mean)'
qui sum `var' [aw=hhwgt] if urban == 1,de
matrix m[`i',3] = `r(mean)'
qui sum `var' if urban == 1,de
matrix m[`i',4] = `r(mean)'
local i = `i' + 1
}


matrix rownames m = $pdf_tab
matrix colnames m = Rural_w Rural_uw Urban_w Urban_uw
matrix list m

svmat m,names(col)
gen name = _n

keep name Rural* Urban*
drop if mi(Rural_w)

save "${r_output}\m_ast_lbt_pdf",replace

import excel "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70\Raw Data & Dictionaries\pdf_tab.xlsx", sheet("Sheet1") firstrow clear
save "${r_output}\tab_pdf",replace

merge 1:1 name using  "${r_output}\m_ast_lbt_pdf"
drop _merge

foreach sector in Rural Urban {
gen `sector'_w_dt = (`sector'_w  - `sector'_pdf)/`sector'_pdf *100
gen `sector'_uw_dt = (`sector'_uw - `sector'_pdf)/`sector'_pdf *100
format `sector'* %9.1fc
}

drop name

list


****************************************************************************
* Compare to Housing Finance Landscape paper. 
* https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2797680
****************************************************************************
use "${root}\Data Output Files\NSS70_All.dta",clear

*summary statistics
sum asset land_r land_u building_all building_resid livestock trspt agri non_farm shares fin_other gold fin_rec  

****************************************************************************
* Asset allocation
****************************************************************************

**Indian Household Finance Landscape (share)
/*share of real estate on 
real_estate (77%), durable good (7%), gold (11%) */

gen double re_share = real_estate/asset *100
gen double du_share = durable_other/asset*100
gen double gl_share = gold /asset*100

sum re_share du_share gl_share if head_age >= 24 & asset > 0  //gold is 11% closest with paper. 
sum re_share du_share gl_share [aw = hhwgt] if head_age >= 24 & asset > 0 

**Indian Household Financing Landscape (Table 1)
*Unweighted 
tabstat asset, s(mean p50) format("%9.0fc")
*Weighted
global asset_table "asset_fin fin_retire asset_non_fin real_estate durable_other gold asset"

tabstat $asset_table [aw=hhwgt], s(mean p50) format("%15.0fc") 
tabstat $asset_table [aw=pwgt], s(mean p50) format("%15.0fc") 

*write to the matrix
preserve

keep if head_age >= 24 & asset > 0 

clear matrix
eststo all: quietly estpost summarize $asset_table  [aw=hhwgt]

unab vars : $asset_table 
local num : word count `vars'
matrix m = J(`num',2,0)
local i = 1

foreach var in $asset_table {
qui sum `var' [aw=hhwgt],de
matrix m[`i',1] = `r(mean)'
matrix m[`i',2] = `r(p50)'
local i = `i' + 1
}

matrix rownames m = $asset_table
matrix colnames m = mean p50
matrix list m

svmat m,names(col)
keep mean p50
keep if !mi(mean) | !mi(p50)
gen name = _n
save "${r_output}\m_asset",replace


*table 1 data to compare
import excel "${r_input}\paper_tab_1.xlsx", sheet("Sheet1") firstrow clear
save "${r_input}\tab_1.dta",replace

keep if type == "asset"
ren (mean p50)(mean_tb p50_tb)

merge 1:1 name using "${r_output}\m_asset"
drop _merge

foreach v in mean p50 {
gen double delta_`v' = (`v' - `v'_tb)/`v'_tb * 100
format delta_`v' %9.0fc
}

drop name type

list

restore




****************************************************************************
* Liabilitiy allocation
****************************************************************************
use "${r_output}\NSS70_All.dta",clear

**Indian Household Financing Landscape (share)
//Liability allocation gold (4%), unsecured loan (55%), mortgage loan (23%)

*generate share of gold loan on total liability
gen double gold_loan_share = total_gold_loan/total_debt
gen double unsecure_share = total_unsecure_loan/total_debt
gen mrtg_loan_share = total_mrtg_loan/total_debt

*Need to match 4%, 55% and 23% (only for households the date of survey liability is positive) 
sum gold_loan_share unsecure_share mrtg_loan_share total_gold_loan total_unsecure_loan total_mrtg_loan [aw = pwgt] if head_age >= 24 & total_debt > 0
sum gold_loan_share unsecure_share mrtg_loan_share total_gold_loan total_unsecure_loan total_mrtg_loan [aw = hhwgt] if head_age >= 24 & total_debt > 0
sum gold_loan_share unsecure_share mrtg_loan_share total_gold_loan total_unsecure_loan total_mrtg_loan if head_age >= 24 & total_debt > 0

**Indian Household Financing Landscape (Table 1)
global lbt_table "total_secure_loan total_mrtg_loan total_gold_loan total_oth_secure_loan total_unsecure_loan total_debt"

*Unweighted 
tabstat total_debt_todt total_debt total_gold_loan total_unsecure_loan total_mrtg_loan , s(mean p50) format("%9.0fc") 
*Weighted
tabstat total_debt_todt total_debt total_gold_loan total_unsecure_loan total_mrtg_loan [aw=hhwgt], s(mean p50) format("%9.0fc") 

*write to the matrix
preserve

keep if head_age >= 24 & total_debt > 0 //in paper: keep households with head older than 24.

clear matrix
eststo all: quietly estpost summarize $lbt_table  [aw=hhwgt]

unab vars : $lbt_table 
local num : word count `vars'
matrix m = J(`num',2,0)
local i = 1

foreach var in $lbt_table {
qui sum `var' [aw=hhwgt],de
matrix m[`i',1] = `r(mean)'
matrix m[`i',2] = `r(p50)'
local i = `i' + 1
}

matrix rownames m = $lbt_table
matrix colnames m = mean p50
matrix list m

svmat m,names(col)
keep mean p50
keep if !mi(mean) | !mi(p50)
gen name = _n
save "${r_output}\m_liability",replace

**Table 1. 
import excel "${r_input}\paper_tab_1.xlsx", sheet("Sheet1") firstrow clear
save "${r_input}\tab_1.dta",replace

keep if type == "liability"
ren (mean p50)(mean_tb p50_tb)

merge 1:1 name using "${r_output}\m_liability"
drop _merge

foreach v in mean p50 {
gen double delta_`v' = (`v' - `v'_tb)/`v'_tb * 100
format delta_`v' %9.0fc
}

drop name type

list
restore



****************************************************************************
* Liabilitiy allocation (value weighted) on 
* unsecured and gold (35% written in paper), mortgage loan (46% extract using )
****************************************************************************

use "${r_input}\Visit 1_Block 14",clear

*debt 
gen debt = b14_q17 // 17 is on 30.06.2012

gen temp_debt_todt = (b14_q1 == "99")*b14_q16 //to date of survey the total debt. 
egen double total_debt_todt = sum(temp_debt_todt), by(HHID)
drop temp_debt_todt

*merge with households information
merge m:1 HHID using "${root}\Data Output Files\NSS70_All.dta"

*in paper: keep households with head older than 24.
drop if b14_q1 == "99"
keep if head_age >= 24
keep if total_debt_todt > 0 & !mi(total_debt_todt) //the date of survey liability is positive. 


*Recode security type 
gen liability_type = real(b14_q12)
recode liability_type (1 2 6 7 8 9 = 1) (3 4 = 2) (5 =3) (10=4)
label define liability_type 1 "Secured" 2 "Mortgage" 3 "Gold" 4 "Unsecured"

*Unweighted Sums
egen double debt_type_total = sum(debt), by(liability_type)
egen double debt_total = sum(debt)
gen debt_share_panel_b = 100 * debt_type_total / debt_total
table liability_type, c(mean debt_share_panel_b sd debt_share_panel_b ) format("%9.0f") // get 16, 49 (mortgage), 4, 32 => so gold+unsec = 36

*Weighted Sums  
egen double debt_type_total_wt = sum(debt * hhwgt), by(liability_type)
egen double debt_total_wt = sum(debt*hhwgt)
gen debt_share_panel_b_wt = 100 * debt_type_total_wt/ debt_total_wt
table liability_type, c(mean debt_share_panel_b_wt sd debt_share_panel_b_wt ) format("%9.0f") // get 13, 48 (mortgage), 6, 33 => so gold+unsec = 39


log close
