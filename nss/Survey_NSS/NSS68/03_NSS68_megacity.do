****************************************************************************
* Description: Find mega city
* Date: Dec 3, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"


****************************************************************************
* Check the districts that mapped to two stratums (Not Completed)
****************************************************************************
/*within the urban areas of a district, if there are one or more towns with population 10 lakhs 
or more as per population census 2001 in a district, 
each of them forms a separate basic stratum and the remaining urban areas of the district are 
considered as another basic stratum. 
*/
use "${r_input}\Visit 1_Block 1&2_Identification of sample household and particulars of field operations.dta",clear

keep District_id Stratum
duplicates drop District_id Stratum,force
egen stratum_n = count(Stratum),by(District_id)

keep if stratum_n>1
duplicates drop District_id,force
count 
