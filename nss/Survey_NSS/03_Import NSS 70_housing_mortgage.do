****************************************************************************
* Description: Generate tables for homeowners, liability, and housing mortgage. 
* Date: Nov 10, 2020
* Version 3.1
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
* Housing mortgage loan features
****************************************************************************
log using "${script}\03_Import NSS70_housing_mortgage.log",replace

use "${r_input}\Visit 1_Block 14",clear
drop if b14_q1 == "99" //drop the total amount

*debt, borrowed amount, repay amount.
gen debt = b14_q17 //outstanding amout at end of June 2012
gen debt_todt = b14_q16 //outstanding amout at the date of survey
gen borrow = b14_q5 //original borrowed amount
gen repay = b14_q14 //amount (`) repaid (including interest) during 01.07.2012 to date of survey


*** Two housing mortgage definitions 
tab b14_q12
gen secure_type = b14_q12

tab b14_q11
gen loan_purpose = b14_q11

* (A) Conservative (let's label 1)housing loan with immovable property as secure type: B14_Q11 == 11 & (B14_Q12 == 3 | B14_Q12 == 4)
gen mrtg_1_dm = (loan_purpose == "11" & (secure_type == "04"|secure_type == "03"))

* (B) Less conservative (let's label 2) housing loan with mortgage: B14_Q11 == 11 & B14_13 != 4
gen mrtg_2_dm = (loan_purpose == "11" & (b14_q13 != "4"& b14_q13 != ""))

*** Housing mortgage features 
*houseing mortgage amount
forvalues i = 1/2 {
  foreach var in debt debt_todt borrow repay {
  gen mrtg_`i'_`var' = mrtg_`i'_dm*`var'
  }
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
sum intst_rate [aw = Weight_SS],de
replace intst_rate  = . if intst_rate > r(p95)

*loan borrowing date. 
gen month = real(b14_q2)
gen year = b14_q3

gen date_loan = ym(year,month)
format date_loan %tmMCY

merge m:1 HHID using "${root}\Data Output Files\NSS70_All.dta"
gen loan_age = date_survey - date_loan //laon from borrow to date of survey, in month.
replace loan_age = . if loan_age < 0 

sum loan_age [aw = Weight_SS],de
replace loan_age  = . if loan_age > r(p99)

*household feature
replace urban = urban*100 

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

*loan period estimation 
forvalues i = 1/2 {
gen double loan_period_`i'= - ln(1 - mrtg_`i'_borrow *intst_rate * (1/repay_mt_`i')) / ln(1+ intst_rate)
sum loan_period_`i' [aw = Weight_SS],de
replace loan_period_`i' = . if loan_period_`i' > r(p99)
}

sum loan_period_*

*the loan is subsidized 
gen loan_sub = (b14_q7 != "09")*100 

*asset and wealth feature (household level)
egen double asset = rowtotal(land_r land_u building_all livestock trspt agri non_farm shares fin_other gold fin_rec) 
egen double real_estate = rowtotal(building_dwelling land_r_resid land_u_resid) 
egen double land_resid = rowtotal(land_r_resid land_u_resid)
gen double wealth = asset - debt

gen temp_debt =  (b14_q1 == "99")*debt
egen total_debt = sum(temp_debt), by(HHID)

*label variables
label var urban "Urban Household (%)"
label var hhsize "Houshold Size"
label var head_age "Household Head Age"
label var head_female "Female Household Head (%)"
label var loan_sub "Subsidized (%)"

save "${r_output}\b14_hse_mortgage",replace

***********************************************
***Table 1. Homewoners
***********************************************
use "${r_output}\b14_hse_mortgage",clear

keep if building_dwelling > 0 //only focus on home owner.

foreach type in mrtg_1_dm mrtg_2_dm mrtg_1_debt mrtg_2_debt mrtg_1_borrow mrtg_2_borrow mrtg_1_repay mrtg_2_repay{ 
egen double total_`type' = sum(`type'), by(HHID)
} 
//keep HHID total* real_estate wealth asset debt_total hhwgt building_dwelling_area
bys HHID: keep if _n == 1 // keep only one observation for each HH

foreach var in total_mrtg_1_dm total_mrtg_2_dm total_mrtg_1_debt total_mrtg_2_debt total_mrtg_1_borrow total_mrtg_2_borrow total_mrtg_1_repay total_mrtg_2_repay { //only focusing on real estate owner. 
replace `var' = 0 if mi(`var') 
}

/* Table Content:
a. Value of Residential Real Estate where HH is Dwelling
b. Value of Land Associated with #a
c. Value of Building with #a
d. Size in square of feet of building of #a
e. Total assets of these people (median median)
f. Percent of assets of residential RE in total assets 
g) Who are these people? (i) urban, (ii) hh size, (iii) gender, (iv) age
h. How many (%) of these had a mortgage (paid off)
i. how many (%) of these _have_ a mortgage (not paid off)
*/

*Variables to generate
replace building_dwelling_area = building_dwelling_area*10.76 //change unit from sq me to sq ft

gen real_estate_share = real_estate/asset*100 //f. Percent of assets of residential RE in total assets 

forvalues i=1/2  {
gen total_mrtg_`i' = (total_mrtg_`i'_dm > 0)*100 //h. How many (%) of these had a mortgage (paid off)
}

forvalues i=1/2  {
gen total_mrtg_`i'_debt_dm = (total_mrtg_`i'_debt > 0)*100 //i. how many (%) of these _have_ a mortgage (not paid off)
}

*label the key variables
label var real_estate "Value of Residential Real Estate where HH is Dwelling"
label var land_resid "Value of Land Associated"
label var building_dwelling "Value of Building"
label var building_dwelling_area "Size of Dwelling in sq ft"
label var asset "Total asset"
label var real_estate_share "Residential RE in Total Assets (%)"
label var total_mrtg_1 "Had a mortgage_1 (%)"
label var total_mrtg_2 "Had a mortgage_2 (%)"
label var total_mrtg_1_debt_dm  "Have a mortgage_1 (%)"
label var total_mrtg_2_debt_dm  "Have a mortgage_2 (%)"

*create the table 
global var_tab_1 "building_dwelling land_resid building_resid building_dwelling_area real_estate_share urban hhsize head_female head_age total_mrtg_1 total_mrtg_2 total_mrtg_1_debt_dm total_mrtg_2_debt_dm"

xtile qtl = asset [aw=hhwgt] , n(5)

qui eststo total : estpost summarize $var_tab_1 [aw = hhwgt],de
forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab_1 [aw = hhwgt] if qtl == `i',de
}

esttab total q1 q2 q3 q4 q5, cells(mean(fmt(%9.1fc))) label collabels(none) ///
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%9.0gc)) ///
 title("Tabel 1.1 Summary Statistics of Homeowners (mean)")

esttab total q1 q2 q3 q4 q5, cells(p50(fmt(%9.1fc))) label collabels(none) ///
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%9.0gc)) ///
 title("Tabel 1.2 Summary Statistics of Homeowners (med)")

***********************************************
***Table 2. Table of Mortgages
***********************************************
use "${r_output}\b14_hse_mortgage",clear

*all of the mortgages are those active during survey period. 
forvalues i = 1/2 {
sum mrtg_`i'_debt mrtg_`i'_debt_todt mrtg_`i'_repay if mrtg_`i'_borrow > 0,de 
}

tab year if mrtg_1_debt_todt == 0 & mrtg_1_borrow > 0
tab year if mrtg_2_debt_todt == 0 & mrtg_2_borrow > 0

forvalues i = 1/2 {
count if mrtg_`i'_debt_todt == 0 & mrtg_`i'_borrow > 0 & mrtg_`i'_repay<0
} //though no outstanding value at the date of survey, there's repay.

/*
a) value of loan taken at inception (mortgage value) - amount borrowed
b) Term of loan (calculated) 
c) Interest rate (given)
d) Monthly payment (calculate)
e) Is it subsidized (column 7)
f) count of mortgages - 100? 200? N. Number of observations 
g) Who are these people? (i) urban, (ii) hh size, (iii) gender, (iv) age
*/

replace intst_rate = intst_rate*100*12

label var mrtg_1_borrow "Mortgage Value_1"
label var mrtg_2_borrow "Mortgage Value_2"
label var loan_period_1 "Term of Loan_1 (mt)"
label var loan_period_2 "Term of Loan_2 (mt)"
label var intst_rate "Interest rate"
label var repay_mt_1 "Monthly Payment_1"
label var repay_mt_2 "Monthly Payment_2"

*create the table 
global var_tab_2 "intst_rate loan_sub urban hhsize head_female head_age"

forvalues i = 1990(6)2013 {
local j = `i' + 5 
dis `i' "-"`j'
  forvalues x = 1/2 {
  qui eststo total_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if mrtg_`x'_borrow > 0,de
  qui eststo yr_`j'_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if inrange(year,`i',`j') & mrtg_`x'_borrow > 0,de
  qui eststo yr_1990_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if year<1990 & mrtg_`x'_borrow > 0,de
  }
}

forvalues x = 1/2 {
esttab total_`x' yr_2013_`x' yr_2007_`x' yr_2001_`x' yr_1995_`x' yr_1990_`x', cells(mean(fmt(%9.1fc))) label collabels(none) ///
 mtitles("All" "2013-2008" "2007-2002" "2001-1996" "1995-1990" "<1990") stats(N, label("Observations") fmt(%9.0gc)) ///
 title("Tabel 2.1 Summary Statistics of Mortgages (mean)_`x'")
}

forvalues x = 1/2 {
esttab total_`x' yr_2013_`x' yr_2007_`x' yr_2001_`x' yr_1995_`x' yr_1990_`x', cells(p50(fmt(%9.1fc))) label collabels(none) ///
 mtitles("All" "2013-2008" "2007-2002" "2001-1996" "1995-1990" "<1990") stats(N, label("Observations") fmt(%9.0gc)) ///
 title("Tabel 2.1 Summary Statistics of Mortgages (med)_`x'")
}
 
log close
