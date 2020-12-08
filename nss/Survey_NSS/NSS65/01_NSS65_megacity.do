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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 65"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS65"

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
use "${r_input}\Block-1-2-Identification-household-records.dta",clear

*get the regional office in the FOD list. 
gen FOD_Regional_Office = substr(FODSub_Region,1,3)
keep if Sector == "2" //urban only

*distinct district code
gen district_uniq = FODSub_Region + District

*find the mega cities
duplicates drop district_uniq Stratum,force

egen stratum_n = count(Stratum),by(district_uniq)
sum stratum_n,de //10% with district with more than 1 stratum

sort FOD_Regional_Office FODSub_Region district_uniq District Stratum
br FOD_Regional_Office FODSub_Region district_uniq District Stratum stratum_n

keep if stratum_n>1
duplicates drop district_uniq,force //only keep districts that mapped to more than 1 stratum
count //334 districts (total urban 568 districts)

preserve
duplicates drop FODSub_Region,force 
count //156 sub_regional office. (total urban 191)
restore

preserve
duplicates drop FOD_Regional_Office,force 
count //49 regional office. 
tab FOD_Regional_Office
restore
