****************************************************************************
* Description: Generate housing condition for NSS 76 
* Date: Nov. 20, 2020
* Version 1.0
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 76\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS76"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"


****************************************************************************
* Load the data
****************************************************************************
use "${root}\Data Output Files\NSS76_All.dta" //from the script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\NSS76\01_NSS76_Import.do"

****************************************************************************
* Get the Variable List for Housing Condition
****************************************************************************

*variables utilized in the following code (double)
clonevar wall = b7_15 //wall material 
clonevar roof = b7_16 //roof mateiral
clonevar floor = b7_14 //floor material
clonevar kitch = b7_12 //separate kitchen
clonevar flat = b7_1 //is a flat
clonevar size = b7_8 //dwelling size. 

clonevar h20_temp = b5_1 //Principal source of drinking water 
gen h20_exclusive = (b5_4==1) //Access to principal source of drinking waterm(water exclusive use)
clonevar h20_cooking = b5_17 //Principal source of water excluding drinking
clonevar h20_distance = b5_5 //Distance of the principal source of drinking water

clonevar san_source = b5_26 //type of latrine used by the household
clonevar san_distance = b5_25 //Access of the household to latrine

*******save file*****  
save "${r_output}/nss76_housing_condition",replace
