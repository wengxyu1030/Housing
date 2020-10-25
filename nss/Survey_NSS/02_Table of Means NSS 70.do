****************************************************************************
* Description: Generate a summary table of NSS 70 
* Date: October 16, 2020
* Version 1.2
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

****************************************************************************
* Asset allocation on real_estate, durable good, gold
****************************************************************************
keep if head_age >= 24

**share of real estate on 
gen re_share = real_estate/asset
gen du_share = durable_other/asset
gen gl_share = gold / asset

sum re_share du_share gl_share
sum re_share du_share gl_share [aw = hhwgt] //gold is 11% consistent with paper. 


**residential building ownership
codebook building_resid 

gen legal_own = (building_resid > 0)
replace legal_own = 0 if mi(building_resid) //treat missing as household do not own real estate assets.

bysort urban: sum legal_own [aw = hhwgt],de 

****************************************************************************
* Liabilitiy allocation on gold, unsecured loan, mortgage loan (4%, 55%, 23% with population weight)
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

foreach type in gold_loan unsecure_loan mrtg_loan { 
egen double total_`type' = sum(`type'), by(HHID)
} 
keep HHID total*
bys HHID: keep if _n == 1 // keep only one observation for each HH

*collapse (sum) gold_loan (sum) unsecure_loan (sum) mrtg_loan (mean) total_debt,by(HHID)
 
*merge with households information
merge 1:1 HHID using "${root}\Data Output Files\NSS70_All.dta"

*in paper: keep households with head older than 24.
keep if head_age >= 24
keep if total_debt > 0 

*generate share of gold loan on total liability
gen double gold_loan_share = total_gold_loan/total_debt
gen double unsecure_share = total_unsecure_loan/total_debt
gen mrtg_loan_share = total_mrtg_loan/total_debt
*Need to match 55%, 23% and 5%
sum gold_loan_share unsecure_share mrtg_loan_share [aw = pwgt] //gold 6.8%, unsecured loan 56%, mortgage loan 23%
sum gold_loan_share unsecure_share mrtg_loan_share [aw = hhwgt]
sum gold_loan_share unsecure_share mrtg_loan_share // Need to use unweighted to match paper 

log close
