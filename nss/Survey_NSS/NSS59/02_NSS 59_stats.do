****************************************************************************
* Description: Cross check the stats with the report
* Date: April 20, 2021
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 59"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS59"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
//source: C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS59\doc\report\500_Household Assets and Liabilities in India.pdf
use "${r_output}\NSS59_All",clear

/*
Almost all the households in India owned some physical and financial assets as on 30.06.02.
Average value of assets (AVA) owned by a household was Rs. 2.66 lakh for the rural areas
and Rs. 4.17 lakh for the urban areas.
*/
sum land building_all livestock trspt agri non_farm shares fin_other fin_retire gold fin_rec

replace asset = asset/1e5 //set the unit as 100,000 (lakh)
table urban [pw = hhwgt] if asset > 0 , c(mean asset) f(%9.2f) //rural 2.67 urban 4.19, close to report. 
sum asset,de


/*
About 27% of the rural households and 18% of the urban households reported debt (cash
loan) outstanding as on 30.6.02. The average amount of debt (AOD) for a rural household
was Rs. 7,539 and that for an urban household was Rs. 11,771.
*/

replace total_debt = total_debt //set the unit as 100,000 (lakh)
table urban [pw = hhwgt] if total_debt > 0 , c(mean total_debt) f(%9.0fc) 
table urban [pw = hhwgt], c(mean total_debt) f(%9.0fc) //AOD: rural 7,539 urban 11,993, close to report.

sum total_debt,de
