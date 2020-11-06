****************************************************************************
* Description: Import NSS70 Secton 14 on housing loan
* Date: Oct 27, 2020
* Version 3.0
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 70"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
log using "${script}\03_Import NSS70_housing_mortgage.log",replace

use "${r_input}\Visit 1_Block 14",clear
drop if b14_q1 == "99" //drop the total amount

*debt, borrowed amount, repay amount.
gen debt = b14_q17 //outstanding amout at end of June 2012
gen borrow = b14_q5 //original borrowed amount
gen repay = b14_q14 //amount (`) repaid (including interest) during 01.07.2012 to date of survey

codebook debt borrow repay

*** Two housing mortgage definitions 
tab b14_q12
gen secure_type = b14_q12

tab b14_q11
gen loan_purpose = b14_q11

* (A) Conservative (let's label 1)housing loan with immovable property as secure type: B14_Q11 == 11 & (B14_Q12 == 3 | B14_Q12 == 4)
gen mrtg_1_dm = (loan_purpose == "11" & (secure_type == "04"|secure_type == "03"))

* (B) Less conservative (let's label 2) housing loan with mortgage: B14_Q11 == 11 & B14_13 != 4
gen mrtg_2_dm = (loan_purpose == "11" & (b14_q13 != "4"& b14_q13 != ""))

*houseing mortgage amount
foreach var in debt borrow repay {
gen mrtg_1_`var' = mrtg_1_dm*`var'
gen mrtg_2_`var' = mrtg_2_dm*`var'
}

*aggregate at household level. 
egen double debt_total = sum(debt),by(HHID)
egen double borrow_total = sum(borrow),by(HHID)
drop debt borrow

*** Other laon features
tab b14_q3 [aw = Weight_SS]
tab b14_q2 [aw = Weight_SS]

*interest rate and type
gen intst_rate = b14_q10/100/12
gen intst_type = b14_q9

*loan borrowing date. 
gen month = real(b14_q2)
gen year = b14_q3

gen date_loan = ym(year,month)
format date_loan %tmMCY

merge m:1 HHID using "${root}\Data Output Files\NSS70_All.dta"
gen loan_age = date_survey - date_loan //laon from borrow to date of survey, in month.
replace loan_age = . if loan_age < 0 

*monthly payment. 
gen date_temp = ym(2012,7)
gen pay_mt = date_survey - date_temp
drop date_temp
tab pay_mt 

gen repay_mt = pay_mt

forvalues i=1/2  {
gen double repay_mt_`i' = mrtg_`i'_repay/pay_mt
}

sum repay_mt*

*year estimation 
forvalues i = 1/2 {
gen double loan_period_`i'= - ln(1 - mrtg_`i'_borrow *intst_rate * (1/repay_mt_`i')) / ln(1+ intst_rate)
}

sum loan_period_*

*asset and wealth feature (household level)
egen double asset = rowtotal(land_r land_u building_all livestock trspt agri non_farm shares fin_other gold fin_rec) 
egen double real_estate = rowtotal(building_resid land_r land_u)
gen double wealth = asset - debt

gen temp_debt =  (b14_q1 == "99")*debt
egen total_debt = sum(temp_debt), by(HHID)

save "${r_output}\b14_hse_mortgage",replace

***********************************************
***stats: individual loans
***********************************************
use "${r_output}\b14_hse_mortgage",clear

forvalues i=1/2 {
tabstat real_estate mrtg_`i'_borrow mrtg_`i'_debt mrtg_`i'_repay loan_age intst_rate if mrtg_`i'_dm >0 [aw = Weight_SS], s(mean median sd) format(%10.0fc) 
}

***********************************************
***stats: household aggregate. (narrow the sample to residential house owners)
***********************************************
use "${r_output}\b14_hse_mortgage",clear

foreach type in mrtg_1_dm mrtg_2_dm mrtg_1_debt mrtg_2_debt mrtg_1_borrow mrtg_2_borrow mrtg_1_repay mrtg_2_repay{ 
egen double total_`type' = sum(`type'), by(HHID)
} 
keep HHID total* real_estate wealth debt_total hhwgt 
bys HHID: keep if _n == 1 // keep only one observation for each HH

foreach var in total_mrtg_1_dm total_mrtg_2_dm total_mrtg_1_debt total_mrtg_2_debt total_mrtg_1_borrow total_mrtg_2_borrow total_mrtg_1_repay total_mrtg_2_repay { //only focusing on real estate owner. 
replace `var' = 0 if mi(`var') & real_estate > 0  //only focus on real estate owner. 
}

*liability allocation to mortgage. 
forvalues i = 1/2 {
gen double mrtg_`i'_debt_share =  (total_mrtg_`i'_debt /debt_total)*100
}

*borrowed mortgage to real estate value. 
forvalues i = 1/2 {
gen double mrtg_`i'_re_share =  (total_mrtg_`i'_borrow /real_estate)*100
}

*stats
forvalues i=1/2 { //household with housing mortgage
tabstat real_estate total_mrtg_`i'_borrow total_mrtg_`i'_debt total_mrtg_`i'_repay  ///
mrtg_`i'_re_share mrtg_`i'_debt_share if total_mrtg_`i'_dm >0 [aw = hhwgt], s(mean median sd) format(%10.0fc) 
}

foreach var in total_mrtg_1_dm total_mrtg_2_dm  { 
replace `var' = 100 if `var'>0 & real_estate > 0  //only focus on real estate owner. 
replace `var' = 0 if `var' == 0 & real_estate > 0
}

forvalues i=1/2 { //all real estate owner
tabstat real_estate total_mrtg_`i'_borrow total_mrtg_`i'_debt total_mrtg_`i'_repay  ///
mrtg_`i'_re_share mrtg_`i'_debt_share total_mrtg_`i'_dm if real_estate >0 [aw = hhwgt], s(mean median sd) format(%10.0fc) 
}

***********************************************
***stats: housing value (uint value) quntile and other indicators (scenario) 
***********************************************
use "${r_output}\b14_hse_mortgage",clear
xtile qtl = real_estate [aw=hhwgt] if mrtg_1_borrow >0, n(5)

table qtl, c(p50 real_estate p50 mrtg_1_borrow p50 loan_period_1 ) format("%9.0f") //by wealth 
table qtl, c(p50 real_estate p50 mrtg_2_borrow p50 loan_period_2 ) format("%9.0f") 

log close
