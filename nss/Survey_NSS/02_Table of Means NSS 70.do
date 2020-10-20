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

log using "${script}\02_Table of Means NSS 70.log"

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

**housing loan 
gen hous_loan_dm = (hous_loan>0)
replace hous_loan_dm = 0 if mi(hous_loan)
bysort urban: tab hous_loan_dm [aw = hhwgt] //8% urban households with housing loan outstanding. 

**loan with secure as immovable property (ip)
gen mortgage_im_pr_dm = (mortgage_im_pr > 0) 
replace mortgage_im_pr_dm = 0 if mi(mortgage_im_pr_dm) 
bysort urban: tab mortgage_im_pr_dm [aw = hhwgt] //70% urban households with ip as security.
tab mortgage_im_pr_dm legal_own [aw = hhwgt] //6,089 households do not own house but has ip mortgage

**summary: housing mortgage, housing loan, ip secure. 
bysort urban: sum hse_loan_mortgage hous_loan mortgage_im_pr [aw = hhwgt],de //majority do not have housing loan with mortgage. 

**housing mortgage to housing loan 
gen mortgage_share_1 = hse_loan_mortgage/hous_loan if hous_loan > 0 
sum mortgage_share_1 [aw = hhwgt],de //average 32% amount housing loan with immovable property as mortgage, median is 0

**housing mortgage to debt. 
gen mortgage_share_2  = hse_loan_mortgage/debt if debt > 0 
bysort urban: sum mortgage_share_2  [aw = hhwgt],de  //urban household 14% of debt is on housing mortgage. 

**households with housing mortgage. 
gen hse_mortgage_dm = (hse_loan_mortgage >0) if !mi(hse_loan_mortgage)
replace hse_mortgage_dm = 0 if mi(hse_mortgage_dm)

bysort urban: tab hse_mortgage_dm  [aw = hhwgt] //3 percetn has housing mortgage. 
log close