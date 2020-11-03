****************************************************************************
* Description: Generate a summary table of NSS 70 
* Date: October 28, 2020
* Version 1.3
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
* Load the data and replicate the assumption https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2797680
****************************************************************************
use "${root}\Data Output Files\NSS70_All.dta",clear


egen double asset = rowtotal(land_r land_u building_all livestock trspt agri non_farm shares fin_other gold fin_rec) 
egen double durable_other = rowtotal(livestock trspt agri non_farm)
egen double real_estate = rowtotal(building_resid land_r land_u)

gen double wealth = asset - debt
gen double wealth_ln = ln(wealth)

sum asset land_r land_u building_all livestock trspt agri non_farm shares fin_other gold fin_rec building_resid 

** USE TABLE 1 to try and match mean and median of assets. Paper has Mean of 1,581,228 and Median of 501,880

*Unweighted 
tabstat asset, s(mean p50) format("%9.0fc") // Mean = 1,782,862   Median = 585,225
tabstat asset [aw=hhwgt], s(mean p50) format("%9.0fc") // Mean = 1,501,012  Median =  459,959
tabstat asset [aw=pwgt], s(mean p50) format("%9.0fc") // Mean = 1,732,348   Median = 558,622

****************************************************************************
* Asset allocation on 
* real_estate (77%), durable good (7%), gold (11%)
****************************************************************************
keep if head_age >= 24

**share of real estate on 
gen re_share = real_estate/asset
gen du_share = durable_other/asset
gen gl_share = gold / asset

sum re_share du_share gl_share //gold is 11% closest with paper. 
sum re_share du_share gl_share [aw = hhwgt] 
sum re_share du_share gl_share [aw = pwgt] //gold is 11% closest with paper. 

** USE TABLE 1 to try and match mean and median of assets. Paper has Mean of 1,581,228 and Median of 501,880

*Unweighted 
tabstat asset, s(mean p50) format("%9.0fc") // 1,813,187   602,800
*Weighted
tabstat asset [aw=hhwgt], s(mean p50) format("%9.0fc") // 1,561,322   490,570
tabstat asset [aw=pwgt], s(mean p50) format("%9.0fc") // 1,754,928   567,775

**residential building ownership
codebook building_resid 

gen legal_own = (building_resid > 0)
replace legal_own = 0 if mi(building_resid) //treat missing as household do not own real estate assets.

bysort urban: sum legal_own [aw = hhwgt],de 

****************************************************************************
* Liabilitiy allocation on 
* gold (4%), unsecured loan (55%), mortgage loan (23%)
****************************************************************************
use "${r_input}\Visit 1_Block 14",clear

*debt -- paper says liabilities on date of survey. pp16: "Panel A of Figure 2 reports the average allocation of liabilities across all households that carry a positive amount of debt at the date of the survey."
gen debt = b14_q17 // 17 is on 30.06.2012
sum debt,de

*in paper: keep households with total liability >0 
gen temp_debt =  (b14_q1 == "99")*debt
egen double total_debt = sum(temp_debt), by(HHID)
drop temp_debt

gen temp_debt =  (b14_q1 != "99")*debt
egen double total_debt_m = sum(temp_debt),by(HHID)
drop temp_debt

gen temp_debt_todt = (b14_q1 == "99")*b14_q16 //to date of survey the total debt. 
egen double total_debt_todt = sum(temp_debt_todt ), by(HHID)
drop temp_debt_todt

count if total_debt > total_debt_m
count if total_debt < total_debt_m // manual has 568 observations where it is larger 

tab b14_q1
sort HHID
br HHID b14* if total_debt == total_debt_m //there are hosueholds with no total liability coded.  

*need to use the 99 total and not the manual to match the paper 
*drop total_debt
*rename total_debt_m total_debt 

*generate share of gold loan, unsecured debt
gen gold_loan = (b14_q12 == "05")*debt
gen unsecure_loan = (b14_q12 == "10")*debt
gen mrtg_loan = (inlist(b14_q12,"03","04"))*debt

*collapse at household level. 

foreach type in gold_loan unsecure_loan mrtg_loan { 
egen double total_`type' = sum(`type'), by(HHID)
} 
keep HHID total*
bys HHID: keep if _n == 1 // keep only one observation for each HH
 
*merge with households information
merge 1:1 HHID using "${root}\Data Output Files\NSS70_All.dta"

*in paper: keep households with head older than 24.
keep if head_age >= 24
keep if total_debt_todt > 0 & !mi(total_debt_todt) //the date of survey liability is positive. 

** USE TABLE 1 to try and match mean and median of liabilities. Paper has Mean of 180,153 and Median of 51,614

*Unweighted 
tabstat total_debt_todt, s(mean p50) format("%9.0fc") // 152,686    39,586
*Weighted
tabstat total_debt_todt [aw=hhwgt], s(mean p50) format("%9.0fc") // 143,652    40,400
tabstat total_debt_todt [aw=pwgt], s(mean p50) format("%9.0fc") // 143,273    43,600


*generate share of gold loan on total liability
gen double gold_loan_share = total_gold_loan/total_debt
gen double unsecure_share = total_unsecure_loan/total_debt
gen mrtg_loan_share = total_mrtg_loan/total_debt

*Need to match 4%, 55% and 23%
sum gold_loan_share unsecure_share mrtg_loan_share [aw = pwgt] 
sum gold_loan_share unsecure_share mrtg_loan_share [aw = hhwgt]
sum gold_loan_share unsecure_share mrtg_loan_share 


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


/*
gen secure_type = b14_q12
egen double debt_type = sum(debt), by(secure_type)

egen double hhwgt_type = sum(hhwgt), by(secure_type)
egen double pwgt_type = sum(pwgt), by(secure_type)

keep secure_type debt_type* pwgt_type hhwgt_type
bys secure_type: keep if _n == 1 // keep only one observation for each type of loan

egen double temp_hhwgt_total = sum(hhwgt_type)
replace hhwgt_type = hhwgt_type/temp_hhwgt_total

egen double temp_pwgt_total = sum(pwgt_type)
replace pwgt_type = pwgt_type/temp_pwgt_total

*stats
egen double debt_type_total = sum(debt)
gen double type_share = debt_type/debt_type_total*100 //not weighted. 

egen double debt_type_total_wgt = sum(debt_type*hhwgt_type)
gen double type_share_wgt = (debt_type*hhwgt_type)/debt_type_total_wgt*100 //weighted uisng household weight. 

total(type_share)
total(type_share_wgt)

*match the paper number (not weighted while the paper "Appropriately weighted p15.")
total(type_share) if inlist(secure_type,"10","05") //unsecured loan and gold 35%, same as paper stats. (not weighted)
total(type_share) if inlist(secure_type,"03","04") //mortgage loan 49% higher than paper stat at 46% (might be the WbPlot measure error?) (not weighted)

keep secure_type type_share type_share_wgt
*/

log close
