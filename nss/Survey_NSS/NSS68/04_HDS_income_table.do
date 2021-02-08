***************************
*** HDS: Estimate Income
*** for 2017-2018
*** Prepared by Aline Weng
***************************

set more off 
clear 

global ROOT "C:\Users\wb500886\OneDrive - WBG\7_Housing\TN_Data\stata"
global raw "${ROOT}\raw\hds"
global inter "${ROOT}\inter"
global final "${ROOT}\final"

************************************************
*****income distribution and thresholds 2018****
************************************************

use "${inter}\income_ie",clear

gen income_ln = ln(income_19)
gen mpce_hh_an_ln =ln(mpce_hh_19*12)

//EWS: <=ln(300,000) = 12.6
gen EWS =(income_19 <= 300000)
tab EWS [aw=hh_wgt] if TN == 1 & urban == 1 //80.6%
tab EWS [aw=hh_wgt] //87.8%

//LIG: <=ln(600,000) = 13.3
gen LIG =(income_19 <=  600000)
tab LIG [aw=hh_wgt] if TN == 1 & urban == 1 //94.5%
tab LIG [aw=hh_wgt] //96.6%

//LIG: 3-6 MIG: 6-18 HI: 18~

//urban TN: old thresholds
twoway kdensity income_ln if TN == 1 & urban == 1  [aw= hh_wgt], xtitle("")  xline(12.6, lc(khaki) lp(dash)) xline(13.3, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln if TN == 1 & urban == 1  [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2018-2019 Tamil Nadu Urban Household Income Distribution" ,size(medium)) ///
text(0.55 12.6 "80.6% Households under EWS", color(khaki)) text(0.35 13.3 "94.5% Households under LIG", color(eltblue)) ///
ytitle("Density")

//whole india: old thresholds
twoway kdensity income_ln [aw= hh_wgt], xtitle("")  xline(12.6, lc(khaki) lp(dash)) xline(13.3, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2018-2019 India Household Income Distribution" , size(medium)) ///
text(0.55 12.6 "87.8% Households under EWS", color(khaki)) text(0.35 13.3 "96.6% Households under LIG", color(eltblue)) ///
ytitle("Density") 

//urban TN: new thresholds
gen cat_new = "<=50,000" 
replace cat_new = "50,000-100,000" if income_19 >= 5e+4 & income_19 < 10e+4
replace cat_new = ">=100,000" if income_19 >=10e+4

table poor [aw=hh_wgt] if state == 33 & sector == 2,c(min income max income)
sum income [aw=hh_wgt] if state == 33 & sector == 2,de

xtile dec_income = income_19 [aw=hh_wgt] if state == 33 & sector == 2,n(100)
table dec_income [aw=hh_wgt],c(min income max income)

tab cat_new [aw=hh_wgt] if TN == 1 & urban == 1
//TN Urban: ln(50000),10.0%, ln(100000) = 30.7%
tab cat_new [aw=hh_wgt] 
//India: ln(50000)= 10.8, 14.0% ln(100000) = 11.5, 44.8%

twoway kdensity income_ln if TN == 1 & urban == 1  [aw= hh_wgt], xtitle("")  xline(10.8, lc(khaki) lp(dash)) xline(11.5, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln if TN == 1 & urban == 1  [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2018-2019 Tamil Nadu Urban Household Income Distribution" , size(medium)) ///
text(0.55 10.8 "10.0% Households under 50,000", color(khaki)) text(0.35 11.5 "30.7% Households under 100,000", color(eltblue)) ///
ytitle("Density")

//whole india: new thresholds
twoway kdensity income_ln  [aw= hh_wgt], xtitle("")  xline(10.8, lc(khaki) lp(dash)) xline(11.5, lc(eltblue) lp(dash)) legend(label( 1 "Log Household Income")) || ///
kdensity mpce_hh_an_ln  [aw=hh_wgt] ,lc(ebblue) legend(label(2 "Log Household Consumption")) ///
title("2018-2019 India Household Income Distribution" , size(medium)) ///
text(0.55 10.8 "14.0% Households under 50,000", color(khaki)) text(0.35 11.5 "44.8% Households under 100,000", color(eltblue)) ///
ytitle("Density")
