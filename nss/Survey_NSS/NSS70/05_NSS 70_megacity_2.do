****************************************************************************
* Description: Check the NSS70 list of state and district code on mega city
* Date: Jan. 12. 2021
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
use "${r_output}\NSS70_All",replace

use "${r_input}\Visit 1_Block 1&2_Identification of sample household and particulars of field operations.dta",clear

tab State_District if State == "33"
tab State_District if State == "2"
