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

keep if Sector == "2"

label var Vill_Blk_Slno "FSU No." 

tab Vill_Blk_Slno //each first stage unit (FSU) with around 14 households. (most them of equal value)
tab Stratum //each stratum have different households, strutum is a district

preserve
gen str_fsu = Stratum + Vill_Blk_Slno //for each strutum, how many unique fsu are there?
duplicates drop str_fsu,force
tab Stratum,sort //stratum contain various number of fsu (from 8 to 453) 
restore

preserve
gen state_str = State_District + Stratum //for each district, how many stratum there?
duplicates drop state_str,force
tab State_District,sort //district has from 1-4 stratum: if more than one stratum is more than 1 million
restore

*check the fsu number for each district: with the assumption that 20,000 population per FSU, district with more than 50 FSU is more than 1000,000 population.

gen state_fsu = State_District + Vill_Blk_Slno //for each district, how many fsu there?
duplicates drop state_fsu,force //eliminate household level duplication 
tab State_District,sort //state district contain various number of fsu (from 2-147 stratum) 

gen n = 1
collapse (sum) n, by(State_District) //count the fsu number for each district

sum n,de
list if State_District == "0830" //kota is the smallest m+ city in cnesus 2011

gen ml_city = (n >= 10) //district kota "0830" is the with 10 fsu
tab ml_city


tab State_District

****************************************************************************
* Check the districts that mapped to two stratums
****************************************************************************
/*within the urban areas of a district, if there are one or more towns with population 10 lakhs 
or more as per population census 2001 in a district, 
each of them forms a separate basic stratum and the remaining urban areas of the district are 
considered as another basic stratum. 
*/
use "${r_input}\Visit 1_Block 1&2_Identification of sample household and particulars of field operations.dta",clear
keep if Sector == "2"

keep State_District Stratum
duplicates drop State_District Stratum,force
egen stratum_n = count(Stratum),by(State_District)

sum stratum_n,de
keep if stratum_n>1
duplicates drop State_District,force 
count //39 districts. 
