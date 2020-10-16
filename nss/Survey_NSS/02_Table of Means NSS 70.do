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

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"


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



