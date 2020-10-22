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
* Load the data and replicate the assumption 
****************************************************************************
use "${root}\Data Output Files\NSS70_All.dta",clear

//replace b5_2_6 = . if b5_2_6<0 //? there's negative value for urban land owned?
//replace b11_q6 = . if b11_q6<0 //? there's negative value for shares & debentures owned. 

egen double asset = rowtotal(land_r land_u building_all livestock trspt agri non_farm shares fin_other gold fin_rec) 
egen double durable_other = rowtotal(livestock trspt agri non_farm)
egen double real_estate = rowtotal(building_resid land_r land_u)

gen double wealth = asset - debt

gen double wealth_ln = ln(wealth)

sum asset land_r land_u building_all livestock trspt agri non_farm shares fin_other gold fin_rec building_resid

keep if head_age >= 24

****************************************************************************
* Calculate stats for housing mortgage and loan (outstanding)
****************************************************************************

**stats to compare with published paper
gen re_share = real_estate/asset
gen du_share = durable_other/asset
gen gl_share = gold / asset

sum re_share du_share gl_share
sum re_share du_share gl_share [aw = pwgt]

**residential building ownership
codebook building_resid 

gen legal_own = (building_resid > 0)
replace legal_own = 0 if mi(building_resid) //treat missing as household do not own real estate assets.

bysort urban: sum legal_own [aw = hhwgt],de //69% households in urban own residential building, compare to nss 61.2% house ownership in 2011 consumption survey. 

**mortgage debt
use "${r_input}\Visit 1_Block 14",clear
drop if b14_q1 == "99" //drop the total amount

*debt
gen debt = b14_q17
codebook debt
drop if debt == .

gen mortgage_debt = (b14_q13 != "4"& b14_q13 != "")*debt
collapse (sum) mortgage_debt,by(HHID)

merge 1:1 HHID using "${root}\Data Output Files\NSS70_All.dta"

keep if head_age >= 24
 
gen double mortgage_debt_share = mortgage_debt/debt
replace mortgage_debt_share = 0 if mortgage_debt == .

sum mortgage_debt_share //14%
sum mortgage_debt_share [aw = pwgt] //10%

log close