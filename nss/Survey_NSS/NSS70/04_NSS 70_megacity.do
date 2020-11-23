****************************************************************************
* Description: Find mega city
* Date: Nov 19, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 70"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"


****************************************************************************
* Check the stratum with UFS add up to more than 1m
****************************************************************************
use "${r_input}\Visit 1_Block 1&2_Identification of sample household and particulars of field operations.dta",clear

keep if sector == 2

label var Vill_Blk_Slno "FSU No." 

tab Vill_Blk_Slno //each FSU with 14 households. (most them of equal value)
tab Stratum //each stratum have different households, strutum is a district

gen str_fsu = Stratum + Vill_Blk_Slno
duplicates drop str_fsu,force

tab Stratum,sort //stratum contain various number of fsu (from 453 to 8) 
