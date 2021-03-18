****************************************************************************
* Description: Generate tables for homeowners, liability, and housing mortgage. 
* Date: Jan 12, 2021
* Version 4
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

log using "${script}\NSS70\03_NSS70_Table of Means.log",replace
set linesize 255
****************************************************************************
* Summary table for asset and liability: Table 0
****************************************************************************
use "${root}\Data Output Files\NSS70_All.dta",clear

*whether the households have asset of debt
gen asset_dm = (asset > 0)*100
gen debt_dm = (total_debt > 0)*100 

*narrow the scope to households with positive debt/asset 
gen asset_pos =  asset if asset > 0
gen total_debt_pos = total_debt if total_debt > 0

*home ownership
gen own_home = (building_dwelling > 0)*100
replace own_home = 0 if mi(building_dwelling)

*urban hosuehold unit
replace urban = urban*100

/*
Quantile of wealth
Asset: Real Estate, Total Asset
Liability: Mortgage, Total Liabilities
*/

global var_tab "asset asset_pos asset_dm total_debt total_debt_pos debt_dm own_home urban hhsize head_female head_age"
//mdesc $var_tab

table qtl [aw = hhwgt], c(med wealth) format(%15.0fc)

//not restrcting the sample to positive asset or liability.

qui eststo total : estpost summarize $var_tab [aw = hhwgt] ,de
qui eststo urban : estpost summarize $var_tab [aw = hhwgt] if urban == 100,de
qui eststo mega : estpost summarize $var_tab [aw = hhwgt] if mega_dc == 1,de
qui eststo rural : estpost summarize $var_tab [aw = hhwgt] if urban == 0,de

forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab [aw = hhwgt] if qtl == `i',de
}

label var asset "Average HH. Assets"
label var asset_pos "Average Assets for HHs. Owning Assets"

label var total_debt "Average HH. Debt"
label var total_debt_pos "Average Debt for Indebted HHs."

label var asset_dm "Own Asset (%)"
label var debt_dm "In Debt (%)"

label var own_home "Dwelling Ownership (%)"

label var urban "Urban Household (%)"
label var hhsize "Household Size"
label var head_age "Household Head Age"
label var head_female "Female Household Head (%)"

*household feature
esttab total urban mega rural q1 q2 q3 q4 q5, cells(mean(fmt(%15.0fc))) label collabels(none) varwidth(40) ///
 mtitles("All" "Urban" "Mega City" "Rural" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 0.1 Summary Statistics of Assets and Liabilities by Wealth Quintile (mean)") ///
 addnotes("Notes: Wealth is defined as total assests net total debt." ///
          "       HHs. with asset on residential building that used as dwelling is defined as owning dwelling." ///
		  "       Mega cities are identified as districts located in U.A. with population more than 1e6 (based on census).")

esttab total urban mega rural q1 q2 q3 q4 q5, cells(p50(fmt(%15.0fc))) label collabels(none) varwidth(40) ///
 mtitles("All" "Urban" "Mega City" "Rural" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 0.2 Summary Statistics of Assets and Liabilities by Wealth Quintile (med)") ///
 addnotes("Notes: Wealth is defined as total assests net total debt." ///
          "       HHs. with asset on residential building that used as dwelling is defined as owning dwelling" ///
		  "       Mega cities are identified as districts located in U.A. with population more than 1e6 (based on census).")
 
****************************************************************************
* Housing mortgage loan features
****************************************************************************
use "${r_input}\Visit 1_Block 14",clear
drop if b14_q1 == "99" //drop the total amount

*debt, borrowed amount, repay amount.
gen debt = b14_q17 //outstanding amout at end of June 2012
gen debt_todt = b14_q16 //outstanding amout at the date of survey
gen borrow = b14_q5 //original borrowed amount
gen repay = b14_q14 //amount (`) repaid (including interest) during 01.07.2012 to date of survey

*** Two housing mortgage definitions 
//tab b14_q12
gen secure_type = b14_q12

//tab b14_q11
gen loan_purpose = b14_q11

* (A) Conservative (label 1)housing loan with immovable property as secure type: B14_Q11 == 11 & (B14_Q12 == 3 | B14_Q12 == 4)
gen mrtg_1_dm = (loan_purpose == "11" & (secure_type == "04"|secure_type == "03"))

* (B) Less conservative (let's label 2) housing loan with mortgage: B14_Q11 == 11 & B14_13 != 4
gen mrtg_2_dm = (loan_purpose == "11" & (b14_q13 != "4"& b14_q13 != ""))

*** Housing mortgage features 

*aggregate at household level. 
egen double debt_total = sum(debt),by(HHID)
egen double borrow_total = sum(borrow),by(HHID)

*** Other laon features
//tab b14_q3 [aw = Weight_SS]
//tab b14_q2 [aw = Weight_SS]

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
drop _merge

gen loan_age = date_survey - date_loan //laon from borrow to date of survey, in month.
replace loan_age = . if loan_age < 0 

sum loan_age [aw = Weight_SS],de
replace loan_age  = . if loan_age > r(p99)

*houseing mortgage amount
foreach var in debt debt_todt borrow {
  replace `var' = 0 if mi(`var')
}

forvalues i = 1/2 {
  foreach var in debt debt_todt borrow repay{
  replace mrtg_`i'_dm = 0 if mi(mrtg_`i'_dm)
  gen mrtg_`i'_`var' = mrtg_`i'_dm*`var'
  }
}

//mdesc mrtg_*

*household feature
replace urban = urban*100 

*monthly payment. 
gen date_temp = ym(2012,7)
gen repay_mt = date_survey - date_temp //01.07.2012 to date of survey

drop date_temp
//tab repay_mt 

forvalues i=1/2  {
gen double repay_mt_`i' = mrtg_`i'_repay/repay_mt //monthly payment calculation
}

forvalues i = 1/2 {
mdesc repay_mt_`i' repay_mt mrtg_`i'_repay //check missing values. 54% on repay information
}

*loan period estimation 
forvalues i = 1/2 {
gen double loan_period_`i'= - ln(1 - mrtg_`i'_borrow *intst_rate * (1/repay_mt_`i')) / ln(1+ intst_rate)
sum loan_period_`i' [aw = Weight_SS],de
replace loan_period_`i' = . if loan_period_`i' > r(p99) //exclude the ourliers 
}

sum loan_period_*

forvalues i = 1/2 {
mdesc loan_period_`i' mrtg_`i'_borrow intst_rate repay_mt_`i' if mrtg_`i'_borrow > 0  //check missing value: 97% loan period missing. 
}


*the loan is subsidized 
gen loan_sub = (b14_q7 != "09")*100 

*label variables
label var urban "Urban Household (%)"
label var hhsize "Household Size"
label var head_age "Household Head Age"
label var head_female "Female Household Head (%)"
label var loan_sub "Subsidized (%)"

save "${r_output}\b14_hse_mortgage",replace

***********************************************
***Table 1. Homewoners
***********************************************
use "${r_output}\b14_hse_mortgage",clear

//keep if building_dwelling > 0 //only focus on home owner.

foreach type in mrtg_1_dm mrtg_2_dm mrtg_1_debt mrtg_2_debt mrtg_1_borrow mrtg_2_borrow mrtg_1_repay mrtg_2_repay{ 
egen double total_`type' = sum(`type'), by(HHID)
} 

bys HHID: keep if _n == 1 // keep only one observation for each HH

/* Table Content:
a. Value of Residential Real Estate where HH is Dwelling
b. Value of Land Associated with #a
c. Value of Building with #a
d. Size in square of feet of building of #a
e. Total assets of these people (median median) //using as quintile. 
f. Percent of assets of residential RE in total assets 
g) Who are these people? (i) urban, (ii) hh size, (iii) gender, (iv) age
h. How many (%) of these had a mortgage (paid off) /Mortgage holders
*/

*Variables to generate
replace building_dwelling_area = building_dwelling_area*10.76 //change unit from sq me to sq ft

gen double real_estate_dwelling_share = real_estate_dwelling/asset*100 //f. Percent of assets of residential RE in total assets 

gen double land_re_share = land_resid/real_estate_dwelling*100 //percent of land to RE value

gen double dwell_sqft = building_dwelling/building_dwelling_area*100 //value of dwelling per sq.ft

forvalues i=1/2  {
gen total_mrtg_`i' = (total_mrtg_`i'_dm > 0)*100 //h. How many (%) of these had a mortgage during the survey period. 
}

*label the key variables //Primary Residential Real Estate (PRRE)
label var real_estate_dwelling "Total PRRE Value"
label var land_resid "Land PRRE Value"
label var land_re_share "Share of Land PRRE Value in Total PRRE Value (%)"
label var building_dwelling "Building PRRE Value"
label var building_dwelling_area "Size of Builing of PRRE"
label var dwell_sqft "PRRE Value in INR / Sq Ft (Sq ft is of building value)"
label var asset "Total Assets"
label var real_estate_dwelling_share "PRRE Value in Total Assets (%)"
label var total_mrtg_1 "Mortgage Holders_1 (%)"
label var total_mrtg_2 "Mortgage Holders_2 (%)"


*create the table 
global var_tab_1 "real_estate_dwelling land_resid land_re_share building_dwelling building_dwelling_area dwell_sqft real_estate_dwelling_share urban hhsize head_female head_age total_mrtg_1 total_mrtg_2"

foreach var in $var_tab_1  {
replace `var' = . if building_dwelling == 0 | mi(building_dwelling) //only focus on home owner.
}

mdesc $var_tab_1 //check missing valuee

gen owner = (building_dwelling > 0 & !mi(building_dwelling))*100
replace owner = 0 if mi(building_dwelling)

//tab owner //obvservations with none of the value mssing. 
label var owner "Home Ownership (%)"

qui eststo total : estpost summarize $var_tab_1 owner [aw = hhwgt],de
qui eststo urban : estpost summarize $var_tab_1 owner [aw = hhwgt] if sector == 2,de
qui eststo mega : estpost summarize $var_tab_1 owner [aw = hhwgt] if mega_dc == 1,de
qui eststo rural : estpost summarize $var_tab_1 owner [aw = hhwgt] if sector == 1,de
forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab_1 owner [aw = hhwgt] if qtl == `i',de
}

esttab total urban mega rural q1 q2 q3 q4 q5, cells(mean(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "Urban" "Mega City" "Rural" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 1.1 Summary Statistics of Homeowners by Wealth Quintile(mean)") varwidth(40) ///
 addnote("Notes: Households weighted by survey weights." ///
 "       Homeowners are households own residential building used as dwelling by household members." ///
 "       Real estate includes dwelling and urban and rural land used as residential area." ///
 "       Mega cities are identified as districts located in U.A. with population more than 1e6 (based on census).")

esttab total urban mega rural q1 q2 q3 q4 q5, cells(p50(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "Urban" "Mega City" "Rural"  "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) /// 
 title("Table 1.2 Summary Statistics of Homeowners by Wealth Quintile (med)") varwidth(40) ///
 addnote("Notes: Households weighted by survey weights." ///
 "       Homeowners are households own residential building used as dwelling by household members." ///
 "       Real estate includes dwelling and urban and rural land used as residential area." ///
 "       Mega cities are identified as districts located in U.A. with population more than 1e6 (based on census).")


***********************************************
*** Table 2. Table of Mortgages
***********************************************
use "${r_output}\b14_hse_mortgage",clear

*all of the mortgages are those active during survey period.
forvalues i = 1/2 {
egen closed_`i' = rowtotal(mrtg_`i'_debt mrtg_`i'_debt_todt mrtg_`i'_repay)
replace closed_`i' = (closed_`i' == 0)*100 //less than 1 percent loan is paid off. 
sum  closed_`i' if mrtg_`i'_borrow > 0  
drop closed_`i'
}

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

label var mrtg_1_borrow "Mortgage Value at Inception_1"
label var mrtg_2_borrow "Mortgage Value at Inception_2"
label var loan_period_1 "Term of Loan_1 (mt)"
label var loan_period_2 "Term of Loan_2 (mt)"
label var intst_rate "Interest rate (%)"
label var repay_mt_1 "Monthly Payment_1"
label var repay_mt_2 "Monthly Payment_2"

*create the table 
global var_tab_2 "intst_rate loan_sub urban hhsize head_female head_age"

forvalues x = 1/2 {
mdesc intst_rate mrtg_`x'_borrow loan_period_`x' repay_mt_`x'
}

forvalues x = 1/2 {
gen double obs_`x' = (intst_rate + loan_sub + urban + hhsize + head_female + head_age + mrtg_`x'_borrow + loan_period_`x' + repay_mt_`x') != . //obsevations will full loan information
mdesc intst_rate loan_sub urban hhsize head_female head_age mrtg_`x'_borrow loan_period_`x' repay_mt_`x' if mrtg_`x'_borrow > 0 & obs_`x' == 1
}

tab year,sort //select the year cut for loan borrow year. 

forvalues i = 2002(2)2013 {
local j = `i' + 1 
dis `i' "-"`j'
  forvalues x = 1/2 {
  qui eststo total_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if mrtg_`x'_borrow > 0 & obs_`x' == 1,de
  qui eststo yr_`j'_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if inrange(year,`i',`j') & mrtg_`x'_borrow > 0 & obs_`x' == 1,de
  qui eststo yr_2002_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if year<2002 & mrtg_`x'_borrow > 0 & obs_`x' == 1,de
  }
}

forvalues x = 1/2 {
esttab total_`x' yr_2013_`x' yr_2011_`x' yr_2009_`x' yr_2007_`x' yr_2005_`x' yr_2003_`x' yr_2002_`x', cells(mean(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "2012-2013" "2010-2011" "2008-2009" "2006-2007" "2004-2005" "2002-2003" "<2002") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 2.1 Summary Statistics of Mortgages (mean)_`x' by Borrowed Year") varwidth(25) ///
 addnotes("Notes: Households weighted by survey weights."  ///
          "       The term of loan is imputed by monthly payment, interest rate, and the mortgage value at inception." ///
		  "       The monthly payment is estimated by the amount repaid divide during 7/1/2012 to date of survey.")
}

forvalues x = 1/2 {
esttab total_`x' yr_2013_`x' yr_2011_`x' yr_2009_`x' yr_2007_`x' yr_2005_`x' yr_2003_`x' yr_2002_`x', cells(p50(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "2012-2013" "2010-2011" "2008-2009" "2006-2007" "2004-2005" "2002-2003" "<2002") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 2.2 Summary Statistics of Mortgages (med)_`x' by Borrowed Year") varwidth(25) ///
 addnotes("Notes: Households weighted by survey weights." ///
          "       The term of loan is imputed by monthly payment, interest rate, and the mortgage value at inception." ///
		  "       The monthly payment is estimated by the amount repaid divide during 7/1/2012 to date of survey.")
}



*******************************************************************
*** Table 3. Table of Mortgages feature by wealth quintile
*******************************************************************
/*
*check the cases where one household have several mortgages. 
use "${r_output}\b14_hse_mortgage",clear

forvalues i = 1/2 { 
egen double mrtg_`i'_n = sum(mrtg_`i'_dm) if mrtg_`i'_borrow > 0, by(HHID)
} 


forvalues i = 1/2 { 
tab mrtg_`i'_n if mrtg_`i'_borrow > 0 //more than 70% only with 1 housing mortgage
}

br HHID mrtg_1_borrow if mrtg_1_n > 1 & mrtg_1_borrow  > 0 //there are cases with multiple same amount mortgages.
*/

*generate the mortgage status by household wealth status. 
use "${r_output}\b14_hse_mortgage",clear

label var mrtg_1_borrow "Mortgage Value at Inception_1"
label var mrtg_2_borrow "Mortgage Value at Inception_2"
label var loan_period_1 "Term of Loan_1 (mt)"
label var loan_period_2 "Term of Loan_2 (mt)"
label var intst_rate "Interest rate (%)"
label var repay_mt_1 "Monthly Payment_1"
label var repay_mt_2 "Monthly Payment_2"

replace intst_rate = intst_rate*100*12

*check the missings. 
forvalues x = 1/2 {
gen double obs_`x' = (intst_rate + loan_sub + urban + hhsize + head_female + head_age + mrtg_`x'_borrow + loan_period_`x' + repay_mt_`x') != . //obsevations will full loan information
mdesc intst_rate loan_sub urban hhsize head_female head_age mrtg_`x'_borrow loan_period_`x' repay_mt_`x' if mrtg_`x'_borrow > 0 & obs_`x' == 1
}

*creat the tables. 
forvalues i = 1(1)5 {
  forvalues x = 1/2 {
    qui eststo total_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if mrtg_`x'_borrow > 0 & obs_`x' == 1,de
    qui eststo qtl_`i'_`x' : estpost summarize mrtg_`x'_borrow loan_period_`x' repay_mt_`x' $var_tab_2 [aw = hhwgt] if qtl == `i' & mrtg_`x'_borrow > 0 & obs_`x' == 1,de
  }
}

forvalues x = 1/2 {
esttab total_`x' qtl_1_`x' qtl_2_`x' qtl_3_`x' qtl_4_`x' qtl_5_`x', cells(mean(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 3.1 Summary Statistics of Mortgages (mean)_`x' by Wealth Quintile") varwidth(40) ///
 addnotes("Notes: Households weighted by survey weights.",  ///
          "       The term of loan is imputed by monthly payment, interest rate, and the mortgage value at inception.")
}

forvalues x = 1/2 {
esttab total_`x' qtl_1_`x' qtl_2_`x' qtl_3_`x' qtl_4_`x' qtl_5_`x', cells(p50(fmt(%15.0fc))) label collabels(none) ///
 mtitles("All" "Q1" "Q2" "Q3" "Q4" "Q5") stats(N, label("Observations") fmt(%15.0gc)) ///
 title("Table 3.2 Summary Statistics of Mortgages (med)_`x' by Wealth Quintile") varwidth(40) ///
 addnotes("Notes: Households weighted by survey weights.",  ///
          "       The term of loan is imputed by monthly payment, interest rate, and the mortgage value at inception.")
}

*******************************************************************
*** Table 4. creat the tables for the imputed 
*******************************************************************
use "${r_output}\b14_hse_mortgage",clear

label var mrtg_1_borrow "Mortgage Value at Inception_1"
label var mrtg_2_borrow "Mortgage Value at Inception_2"
label var loan_period_1 "Term of Loan_1 (mt)"
label var loan_period_2 "Term of Loan_2 (mt)"
label var intst_rate "Interest rate (%)"
label var repay_mt_1 "Monthly Payment_1"
label var repay_mt_2 "Monthly Payment_2"

keep if mrtg_1_borrow > 0 | mrtg_2_borrow > 0 //only keep housing mortgage

**check missing values
//loan features: repay_mt_`i' intst_rate loan_period_`i'

forvalues i = 1/2 {
gen repay_intst_`i' = (repay_mt_`i' + intst_rate)
label var repay_intst_`i' "Both payment and interest exist_`i'"

gen repay_term_`i' = (repay_mt_`i' + loan_period_`i') 
label var repay_term_`i' "Both payment and term of loan exist_`i'"

gen intst_term_`i' = (intst_rate + loan_period_`i') 
label var intst_term_`i' "Both interest and term of loan exist_`i'"

gen repay_intst_term_`i' = (repay_mt_`i' + intst_rate + loan_period_`i') 
label var repay_intst_term_`i' "All the three features exist_`i'"
}

forvalues i = 1/2 {
//combination missing status. 
mdesc repay_mt_`i' intst_rate loan_period_`i' repay_intst_`i' repay_term_`i' intst_term_`i' repay_intst_term_`i' 
}

**impute borrowed amont using payment and insterest rate and demography
forvalues i = 1/2 {
areg mrtg_`i'_borrow repay_mt_`i' intst_rate urban head_age qtl hhsize,a(year) r
predict mrtg_`i'_borrow_est
replace mrtg_`i'_borrow_est  = . if mrtg_`i'_borrow > 0 | mrtg_`i'_borrow_est<0 //only keep the estimate when the original value is missing. 
sum mrtg_`i'_borrow*
}

forvalues i = 1/2 {
br mrtg_`i'_borrow_est intst_rate repay_mt_`i' if mrtg_`i'_borrow_est > 0
replace intst_rate = . if intst_rate == 0
replace repay_mt_`i' = . if repay_mt_`i' == 0
gen double obs_`i' = (intst_rate + mrtg_`i'_borrow_est + repay_mt_`i') != . //obsevations have enough information to impute loan period
tab obs_`i' //no complete data for imputation. 
}

log close
