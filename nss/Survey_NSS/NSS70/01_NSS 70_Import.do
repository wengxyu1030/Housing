****************************************************************************
* Description: Import NSS70 from Raw Files and save dta to Output Folder
* Date: April 12, 2021
* Version 3
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

*gen date of survey 
use "${r_input}\Visit 1_Block 1&2_Identification of sample household and particulars of field operations.dta",clear
gen month = real(substr(Survey_Date,3,2))
gen year = 2013 //there's 2017 and 2019 should be mistake

gen date_survey = ym(year,month)
format date_survey %tmMCY

rename State_District st_dc_70
merge m:1 st_dc_70 using "${r_input}\mega_st_dc_70.dta"
drop if _merge == 2

gen mega_dc = (_merge == 3)
label var mega_dc "district with more than million population"

rename State state

keep HHID date_survey mega_dc state
save "${r_output}\b2",replace


*gen id, wgt (hhwgt, popwgt) b3
use "${r_input}\Visit 1_Block 3_Household Characteristics.dta",clear

rename (b3q1 Sector) (hhsize sector)
//gen hhwgt = MLT 
gen hhwgt = Weight_SS 

destring(hhsize),replace
gen pwgt = hhwgt * hhsize

destring(sector), replace
gen urban = sector - 1

keep HHID hhwgt pwgt hhsize sector urban Weight_SS Weight_SC
save "${r_output}\b3",replace

*gender from b4 (4)
use "${r_input}\Visit 1 _Block 4_Demographic and other particulars of household members.dta",clear
*Keep head 
keep if b4q3 == "1" // keep heads only 
ren b4q5 head_age 

ren  b4q4 head_gender 
destring head_gender, replace
label define gender 1 "Male" 2 "Female"
label values head_gender gender 
gen head_female = (head_gender == 2)*100

keep HHID head_age head_gender head_female
save "${r_output}\b4",replace 

*Asset non_fin： land from b5.1 & b5.2 (rural & urban) srl 99
use "${r_input}\Visit 1_Block 5pt1_Details of land owned by the household as on 30.06.12.dta",clear
sum b5_1_6
rename State state

egen double land_r = sum(b5_1_6*(b5_1_1 == "99")), by(HHID)
egen double land_r_man = sum(b5_1_6*(b5_1_1 != "99")), by(HHID)
egen double land_r_resid = sum(b5_1_6*(b5_1_1 != "99")*( b5_1_3 == "10")), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if land_r > land_r_man
count if land_r < land_r_man

drop land_r
rename land_r_man land_r 

keep HHID land_r land_r_resid
save "${r_output}\b5_1",replace

use "${r_input}\Visit 1_Block 5pt2_Details of land owned by the household as on 30.06.12.dta",clear
count if b5_2_6 < 0
replace b5_2_6 = . if b5_2_6 < 0

egen double land_u = sum(b5_2_6*(b5_2_1 == "99")), by(HHID)
egen double land_u_man = sum(b5_2_6*(b5_2_1 != "99")), by(HHID)
egen double land_u_resid = sum(b5_2_6*(b5_2_1 != "99")*( b5_2_3 == "10")), by(HHID)

duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if land_u > land_u_man
count if land_u < land_u_man

drop land_u
rename land_u_man land_u

keep HHID land_u land_u_resid
save "${r_output}\b5_2",replace



*Asset non_fin: building and constructions b6 srl 11
use "${r_input}\Visit 1_Block 6_Buildings and other constructions owned by the household as on 30.06.2012.dta",clear
sum b6_q6

egen double building_all = sum(b6_q6*(b6_q3 == "11")), by(HHID)
egen double building_all_man = sum(b6_q6*(b6_q3 != "11")),  by(HHID)

egen double building_resid = sum(b6_q6*(inlist(b6_q3,"01","02","03"))), by(HHID)
egen double building_resid_area = sum(b6_q5*(inlist(b6_q3,"01","02","03"))), by(HHID)

egen double building_dwelling = sum(b6_q6*(b6_q3 == "01")), by(HHID)
egen double building_dwelling_area = sum(b6_q5*(b6_q3 == "01")), by(HHID)

duplicates drop HHID,  force

keep HHID building_all* building_resid building_resid_area building_dwelling building_dwelling_area

*Check the manual (man) sum with survey sum
count if building_resid > building_all
count if building_resid > building_all_man

drop building_all
ren building_all_man building_all 

save "${r_output}\b6",replace

*Asset non_fin: livestock and poultry b7 srl 22 
use "${r_input}\Visit 1_Block 7_Livestock and poultry owned by the household on 30.06.2012.dta",clear
destring b7_q2,replace
sum b7_q5

egen double livestock = sum(b7_q5*(b7_q2 == 22)), by(HHID)
egen double livestock_man = sum(b7_q5*(inrange(b7_q2,17,21))), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if livestock > livestock_man
count if livestock < livestock_man

drop livestock
rename livestock_man livestock

keep HHID livestock
save "${r_output}\b7",replace

*Asset non_fin: transport equipment b8: srl 8
use "${r_input}\Visit 1_Block 8_Transport equipment owned by the household on 30.06.2012.dta",clear
sum b8_q5

egen double trspt = sum(b8_q5*(b8_q2 == "08")), by(HHID)
egen double trspt_man = sum(b8_q5*(b8_q2 != "08")), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if trspt > trspt_man
count if trspt < trspt_man

drop trspt
rename trspt_man trspt

keep HHID trspt
save "${r_output}\b8",replace

*Asset non_fin: agricultural machinery and implements b9: srl 8 
use "${r_input}\Visit 1_Block 9_Agricultural machinery and implements owned by the household on 30.06.2012.dta",clear
sum b9_q4

egen double agri = sum(b9_q4*(b9_q2 == "8")), by(HHID)
egen double agri_man = sum(b9_q4*(b9_q2 != "8")), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if agri > agri_man
count if agri < agri_man

drop agri
rename agri_man agri

keep HHID agri
save "${r_output}\b9",replace

*Asset non_fin: non-farm business equipment b10 srl 15
use "${r_input}\Visit 1_Block 10_Non-farm business equipment owned by the household as on 30.06.2012.dta",clear
destring b10_q2,replace
sum b10_q3 //issue with raw-data.

egen double non_farm = sum(b10_q3*(b10_q2 == 15)), by(HHID)
egen double non_farm_man = sum(b10_q3*inrange(b10_q2,12,14)), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if non_farm > non_farm_man
count if non_farm < non_farm_man

drop non_farm_man
keep HHID non_farm
save "${r_output}\b10",replace

*Asset fin: shares & debentures b11 
use "${r_input}\Visit 1_Block 11_ Shares and debentures owned by the household in co-operative  societies & companies as on 30.06.2012 .dta",clear

 *Check the manual (man) sum with survey sum
  preserve
  egen double shares = sum(b11_q6*(b11_q1 == "5")), by(HHID)
  egen double shares_man = sum(b11_q6*(b11_q1 != "5")), by(HHID)
  duplicates drop HHID, force
  count if shares > shares_man
  count if shares < shares_man
  restore 

sum b11_q6 if b11_q1 != "5" 
replace b11_q6 = . if b11_q6<0 //filter out the non-negative colums. 
egen double shares = sum(b11_q6*(b11_q1 == "5")), by(HHID)
duplicates drop HHID, force

keep HHID shares
save "${r_output}\b11",replace

*Asset fin: other financial assets b12 srl 11 
use "${r_input}\Visit 1_Block 12_Financial assets other than shares and debentures owned by the household as on 30.06.2012.dta",clear

destring b12_q1,replace
count if b12_q3 < 0 
replace b12_q3 = . if b12_q3 <0

egen double gold = sum(b12_q3*(b12_q1 == 12)), by(HHID)
egen double fin_retire = sum(b12_q3*(inlist(b12_q1,6,7))), by(HHID) //retirement account
egen double fin_other = sum(b12_q3*(inrange(b12_q1,1,5) )), by(HHID)

duplicates drop HHID, force
  
  /*
drop fin_other 
ren fin_other_man fin_other
*/

keep HHID fin_other gold fin_retire
save "${r_output}\b12",replace

*Asset fin: amount receivable b13 (mortgage srl 1, total srl 7)
use "${r_input}\Visit 1_Block 13_Amount receivable by the household against different heads as on 30.06.2012.dta",clear
sum b13_q4

egen double fin_rec = sum(b13_q4*(b13_q2 == "7")), by(HHID)
egen double fin_rec_man = sum(b13_q4*(b13_q2 != "7")), by(HHID)
duplicates drop HHID, force

  *Check the manual (man) sum with survey sum
  count if fin_rec > fin_rec_man
  count if fin_rec < fin_rec_man
 
drop fin_rec
ren fin_rec_man fin_rec
keep HHID fin_rec
save "${r_output}\b13",replace

*Debt: cash loands payable b14: Type of loan(8) Purpose of loan (11) Type of mortgage(13) , srl 99 (total)
use "${r_input}\Visit 1_Block 14",clear
 
 *debt 
gen debt = b14_q17 // 17 is the outstanding amount on 30.06.2012
gen debt_todt = b14_q16 //outstanding amount at the date of survey. 
sum debt,de

gen temp_debt =  (b14_q1 == "99")*debt
egen double total_debt = sum(temp_debt), by(HHID)
drop temp_debt

gen temp_debt =  (b14_q1 != "99")*debt_todt
egen double total_debt_m = sum(temp_debt),by(HHID)
drop temp_debt

gen temp_debt_todt =  (b14_q1 == "99")*debt_todt
egen double total_debt_todt = sum(temp_debt_todt), by(HHID)
drop temp_debt_todt

gen temp_debt_todt = (b14_q1 == "99")*debt_todt //to date of survey the total debt. 
egen double total_debt_todt_m = sum(temp_debt_todt), by(HHID)
drop temp_debt_todt

 *check the manual total and the survey total
count if total_debt > total_debt_m
count if total_debt < total_debt_m // manual has 568 observations where it is larger 

tab b14_q1
sort HHID
br HHID b14* if total_debt == total_debt_m //there are hosueholds with no total liability coded.  
//need to use the 99 total and not the manual to match the paper 

 *generate type of liabilty
gen gold_loan = (b14_q12 == "05")*debt
gen oth_secure_loan = (inlist(b14_q12,"01","02","06","07","08","09"))*debt
gen mrtg_loan = (inlist(b14_q12,"03","04"))*debt

gen unsecure_loan = (b14_q12 == "10")*debt
egen double secure_loan = rowtotal(mrtg_loan gold_loan oth_secure_loan) 

 *collapse at household level. 
foreach type in secure_loan mrtg_loan gold_loan oth_secure_loan unsecure_loan { 
egen double total_`type' = sum(`type'), by(HHID)
} 

keep HHID total*
bys HHID: keep if _n == 1 // keep only one observation for each HH

mdesc total*

save "${r_output}\b14",replace

*Debt: kind of loan payable b15 col 11: housing 11
use "${r_input}\Visit 1_Block 15_kind loans payable by the household.dta",replace
save "${r_output}\b15",replace //late housing info


*******merge to master data******************************
use "${r_output}\b2",clear
local flist "b3 b14 b13 b12 b11 b10 b9 b8 b7 b6 b5_1 b5_2 b4"

foreach f of local flist{
merge 1:1 HHID using "${r_output}/`f'"
drop _merge
}

*clean up missing value
global asset "land_r land_u building_all livestock trspt agri non_farm shares fin_other fin_retire gold fin_rec building_resid building_dwelling land_r_resid land_u_resid"
global debt "total_debt total_debt_m total_debt_todt total_debt_todt_m total_secure_loan total_mrtg_loan total_gold_loan total_oth_secure_loan total_unsecure_loan"

mdesc $asset 
mdesc $debt 

foreach var in $asset $debt {
replace `var' = 0 if mi(`var')
}

*generate asset value by type
egen double asset = rowtotal(land_r land_u building_all livestock trspt agri non_farm shares fin_other fin_retire gold fin_rec) 

egen double durable_other = rowtotal(livestock trspt agri non_farm)

egen double land_resid = rowtotal(land_r_resid land_u_resid)

egen double real_estate = rowtotal(building_all land_r land_u)

egen double real_estate_dwelling = rowtotal(building_dwelling land_resid)

egen double asset_non_fin = rowtotal(real_estate gold durable_other)

egen double asset_fin = rowtotal(shares fin_other fin_rec) 

*generate wealth data
gen double wealth = asset - total_debt
sum wealth,de
gen double wealth_ln = ln(wealth) //1% negative 

xtile qtl = wealth [aw = hhwgt],n(5)

*identify districts that located in mega U.A. (URBAN AGGLOMERATIONS) more than ie6 population
replace mega_dc = 0 if urban == 0

*house keeping
mdesc *

qui compress
save "${r_output}\NSS70_All",replace
