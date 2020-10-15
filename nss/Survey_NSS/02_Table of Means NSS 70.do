****************************************************************************
* Description: Generate a summary table of NSS 70 
* Date: October 13, 2020
* Version 1.1
* Last Editor: Nadeem 
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

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"


****************************************************************************
* Load the data and replicate the assumption 
****************************************************************************
use "${root}\Data Output Files\NSS70_All.dta",clear


*shares & debentures owned by the household in co operative societies & companies as on 30.06.2012 (financial asset should be positive?)
sum asset b5_1_6 b5_2_6 building_all b7_q5 b8_q5 b9_q4 b10_q3 b11_q6 b12_q3 b13_q4 gold building_resid

replace b5_2_6 = . if b5_2_6<0 //? there's negative value for shares & debentures owned. 

drop asset wealth*
egen double asset = rowtotal(gold b5_1_6 b5_2_6 building_all b7_q5 b8_q5 b9_q4 b10_q3 b11_q6 b12_q3 b13_q4) 
egen double durable_other = rowtotal(b7_q5 b8_q5 b9_q4 b10_q3)
egen double real_estate = rowtotal(building_resid b5_1_6 b5_2_6)

gen double wealth = asset - debt

gen double wealth_ln = ln(wealth)

keep if head_age >= 24

****************************************************************************
* Replicate Number
****************************************************************************

**real estate: building, land
gen re_share = real_estate/asset
gen du_share = durable_other/asset
gen gl_share = gold / asset

*replace re_share = 0 if re_share == . 
*replace du_share = 0 if du_share == . 

sum re_share du_share gl_share
sum re_share du_share gl_share [aw = pwgt]



