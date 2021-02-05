
****************************************************************************
* Description: Use NSS68 and UMD HDS data estimate income
* Date: Jan. 27, 2021
* Version 1
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68\" //please correct accordingly
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\NSS68"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
di "${r_output}"

set more off 
clear 


*******************************************
*******Estimate income expenditure ratio
*******************************************

use "${r_input}\DS0002\36151-0002-Data.dta",clear //UMD DHS data

foreach var of var * {
rename `var' `= lower("`var'")'
}

replace income = 0 if income < 0 

egen con_1 = rowtotal(co1x co2x co3x co4x co5x co6x co7x co8x co9x co10x co11x co12x ///
co13x co14x) //constructed
egen con_2 = rowtotal(co15-co30) 
egen con_3 = rowtotal(co31-co33)
egen con_4 = rowtotal(co34-co52) //annual

replace cototal= (con_1+con_2+con_3)*12+con_4
drop con_1-con_4
sum cototal [aw = wt]
rename cototal exp

gen exp_ind = exp/npersons 
gen income_ind = income/npersons

label var income "Income"
label var exp "Expenditure"
label var npersons "Household size"

//the relation between income and exp (regression)
foreach i in 5 10 100 {
xtile exp_p_`i' = exp [aw = wt],n(`i')
xtile exp_p_`i'_u = exp [aw = wt] if urban2011 == 1,n(`i') 
}
scatter income exp

forvalues i = 1/5 {
 qui reg income exp  [aw = wt] if exp_p_5 == `i', noconstant
 eststo q`i'
}

 esttab q1 q2 q3 q4 q5, nose not label b("%9.2f") r2 ///
 stats(N r2 , label(Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
 title("Regression of Income on Expenditure by Decile") ///
 addnotes("Regressions are weighted by survey weights.")


//the relation between income and exp (descriptive stats)
gen in_exp = income/exp

table exp_p_10 [aw = wt],c(mean in_exp med in_exp sd in_exp) row //all India
table exp_p_10_u [aw = wt] ,c(mean in_exp med in_exp sd in_exp) row //urban only

//get the median hh level urban income to exp ratio by percentile
preserve

collapse (median) in_exp [aw = wt],by(exp_p_100_u) //egen with weight for median to be discussed. 
rename (exp_p_100_u in_exp) (exp_p hat_ie_u)
save "${r_output}\hat_ie_u",replace

restore

//get the percentile for income and expenditure separately, and mathing the percentiles to get the ratio (not at hh level but percentile, assume income and exp positively correlated and linear)
xtile income_p = income[aw=wt],n(100)
xtile exp_p= exp [aw=wt],n(100)

gen income_ln = ln(income)
gen exp_ln = ln(exp)

kdensity income_ln
twoway kdensity income_ln|| kdensity exp_ln, title(Income and Expenditure distribution)

tempfile income exp

preserve
keep income income_p wt
collapse (mean) income [aw=wt],by(income_p)
rename income_p decile
save `income'
restore

preserve
keep exp exp_p wt
collapse (mean) exp [aw=wt],by(exp_p)
rename exp_p decile
save `exp',replace
restore

use `income',clear
merge 1:1 decile using `exp'
gen i_e = income/exp
drop _merge
rename decile exp_p

scatter i_e exp_p
replace i_e = (1+i_e)/2 if i_e<1

codebook income,c
scatter income exp exp_p

keep exp_p i_e
rename i_e hat_ie

save "${r_output}\hat_ie",replace

//compare the two hat_ie (all at percentile level and urban at hh level )
use  "${r_output}\hat_ie",clear
merge 1:1 exp_p using "${r_output}\hat_ie_u"
label var hat_ie_u "Urban HH Level"
label var hat_ie "All Percentile Level"
scatter  hat_ie hat_ie_u exp_p,title("Income to Exp. Ratio by Exp. Percentile")

****************************************************************************
* Description: Use NSS68 and UMD HDS data estimate income
* Date: Jan. 27, 2021
* Version 1
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68\" //please correct accordingly
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\NSS68"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
di "${r_output}"

set more off 
clear 


*******************************************
*******Estimate income expenditure ratio
*******************************************

use "${r_input}\DS0002\36151-0002-Data.dta",clear //UMD DHS data

foreach var of var * {
rename `var' `= lower("`var'")'
}

replace income = 0 if income < 0 

egen con_1 = rowtotal(co1x co2x co3x co4x co5x co6x co7x co8x co9x co10x co11x co12x ///
co13x co14x) //constructed
egen con_2 = rowtotal(co15-co30) 
egen con_3 = rowtotal(co31-co33)
egen con_4 = rowtotal(co34-co52) //annual

replace cototal= (con_1+con_2+con_3)*12+con_4
drop con_1-con_4
sum cototal [aw = wt]
rename cototal exp

gen exp_ind = exp/npersons 
gen income_ind = income/npersons

xtile income_p = income[aw=wt],n(100)
xtile exp_p= exp [aw=wt],n(100)

gen income_ln = ln(income)
gen exp_ln = ln(exp)

kdensity income_ln
twoway kdensity income_ln|| kdensity exp_ln, title(Income and Expenditure distribution)


tempfile income exp

preserve
keep income income_p wt
collapse (mean) income [aw=wt],by(income_p)
rename income_p decile
save `income'
restore

preserve
keep exp exp_p wt
collapse (mean) exp [aw=wt],by(exp_p)
rename exp_p decile
save `exp',replace
restore

use `income',clear
merge 1:1 decile using `exp'
gen i_e = income/exp
drop _merge
rename decile exp_p

scatter i_e exp_p
replace i_e = (1+i_e)/2 if i_e<1

codebook income,c
scatter income exp exp_p

keep exp_p i_e
rename i_e hat_ie

save "${r_output}\hat_ie",replace

****************************************************
*******Estimate income in 2011 and 2018****
****************************************************

*project 2012-2019 growth rate
import excel "${r_input}\growth_rate.xlsx", sheet("Sheet1") firstrow clear
keep if Quarter == "Q4          "          

replace Rate = (Rate/100)+1

drop if Year < 2013

reshape wide Rate,i(Quarter) j(Year)
gen gr_19 = Rate2013* Rate2014* Rate2015* Rate2016* Rate2017* Rate2018
sum gr_19 
local gr_rate = r(mean)

*estimate income 2011
use "${r_output}\nss68_master",clear
drop if mi(ID)

xtile exp_p = mpce_hh [aw=hh_wgt],n(100)

merge m:1 exp_p using "${r_output}\hat_ie"
keep if _merge == 3
drop _merge

gen income = mpce_hh*12*hat_ie

gen income_19 = income*`gr_rate'
gen mpce_hh_19 = mpce_hh*`gr_rate'

sum income,de 

save "${r_output}\income_ie",replace

************************************************
*****income distribution and thresholds 2011****
************************************************

use "${r_output}\income_ie",clear

gen income_ln = ln(income)
gen mpce_hh_an_ln =ln(mpce_hh*12)

//statistics
table sector if state == 33,c(mean income med income)
table poor if state == 33 & sector == 2,c(min income max income)

//poverty line for urban TN (is at the population level not household level, can't be mapped in the kdensity)
l income_ln if mpce == 880
tab poor [aw=hh_wgt] if TN == 1 & urban == 1 //5.1%
table poor [aw=hh_wgt] if TN == 1 & urban == 1,c(median income_ln mean income_ln) 
sum hhsize_n if TN == 1 & urban == 1 & poor == 1 //average poor hhsize in TN Urban 4.3

//EWS: <=ln(300,000) = 12.6
gen EWS =(income <= 300000)
tab EWS [aw=hh_wgt] if TN == 1 & urban == 1 //93.01%
tab EWS [aw=hh_wgt] //98.5%

//LIG: <=ln(600,000) = 13.3
gen LIG =(income <=  600000)
tab LIG [aw=hh_wgt] if TN == 1 & urban == 1 //98.5%
tab LIG [aw=hh_wgt] //99.0%

//MIG: 3-6 LIG 6-12 LIG_1 12-18 MIG2

twoway kdensity income_ln if TN == 1 & urban == 1  [aw= hh_wgt], xtitle("")  xline(12.6, lc(khaki) lp(dash)) xline(13.3, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln if TN == 1 & urban == 1  [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2011-2012 Tamil Nadu Urban Household Income Distribution" , size(medium)) ///
text(0.55 12.6 "93.0% Households under EWS", color(khaki)) text(0.35 13.3 "98.5% Households under LIG", color(eltblue)) ///
ytitle("Density") 

//new thresholds
gen cat_new = "<=50,000" 
replace cat_new = "50,000-100,000" if income >= 5e+4 & income < 10e+4
replace cat_new = ">=100,000" if income >=10e+4

table poor [aw=hh_wgt] if state == 33 & sector == 2,c(min income max income)
sum income [aw=hh_wgt] if state == 33 & sector == 2,de

xtile dec_income = income [aw=hh_wgt] if state == 33 & sector == 2,n(100)
table dec_income [aw=hh_wgt],c(min income max income)


tab cat_new [aw=hh_wgt] if TN == 1 & urban == 1 & poor == 1

tab cat_new [aw=hh_wgt] if TN == 1 & urban == 1

//TN Urban: ln(50000),26.1%, ln(100000) = 62.8%
tab cat_new [aw=hh_wgt] 
//India: ln(50000)= 10.8, 39.0% ln(100000) = 11.5, 74.4%

twoway kdensity income_ln if TN == 1 & urban == 1  [aw= hh_wgt], xtitle("")  xline(10.8, lc(khaki) lp(dash)) xline(11.5, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln if TN == 1 & urban == 1  [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2011-2012 Tamil Nadu Urban Household Income Distribution" , size(medium)) ///
text(0.55 10.8 "26.1% Households under 50,000", color(khaki)) text(0.35 11.5 "62.8% Households under 100,000", color(eltblue)) ///
ytitle("Density")

//whole india: old thresholds
twoway kdensity income_ln [aw= hh_wgt], xtitle("")  xline(12.6, lc(khaki) lp(dash)) xline(13.3, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2011-2012 India Household Income Distribution" , size(medium)) ///
text(0.55 12.6 "98.5% Households under EWS", color(khaki)) text(0.35 13.3 "99.0% Households under LIG", color(eltblue)) ///
ytitle("Density") 

//whole india: new thresholds
twoway kdensity income_ln  [aw= hh_wgt], xtitle("")  xline(10.8, lc(khaki) lp(dash)) xline(11.5, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln  [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2011-2012 India Household Income Distribution" , size(medium)) ///
text(0.55 10.8 "39.0% Households under 50,000", color(khaki)) text(0.35 11.5 "74.4% Households under 100,000", color(eltblue)) ///
ytitle("Density")
