****************************************************************************
* Description: Import NSS59 from Raw Files and save dta to Output Folder
* Date: April 12, 2021
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

*gen date of survey 
use "${r_input}\Visit 1_Blocks 1&2_Identification of sample household.dta",clear
gen month = real(substr(Survey_Date,3,2))
gen year = 2003 //there's 2017 and 2019 should be mistake

gen date_survey = ym(year,month)
format date_survey %tmMCY

rename State state

keep HHID date_survey state
save "${r_output}\b2",replace

*gen id, wgt (hhwgt, popwgt) b3
use "${r_input}\Visit 1_Block 3_Household characteristics.dta",clear

rename (B3_q1 Sector Weight) (hhsize sector hhwgt)

destring(hhsize),replace
gen pwgt = hhwgt * hhsize

destring(sector), replace
gen urban = sector - 1

keep HHID hhwgt pwgt hhsize sector urban  
save "${r_output}\b3",replace

*gender from b4 (4)
use "${r_input}\Visit 1_Block 4_demographic and other particulars of household members.dta",clear
*Keep head 
keep if B4_q3 == "1" // keep heads only 
ren B4_q5 head_age 

ren  B4_q4 head_gender 
destring head_gender, replace
label define gender 1 "Male" 2 "Female"
label values head_gender gender 
gen head_female = (head_gender == 2)*100

keep HHID head_age head_gender head_female
save "${r_output}\b4",replace 

*Asset non_fin： land from b5 (rural & urban) srl 99
use "${r_input}\Visit 1_Block 5_land owned by the household as on the date of survey and related transactions during 01-07-2002 to date of survey.dta",clear

rename State state

egen double land = sum(B5_q11*(B5_q1 == "99")), by(HHID)
egen double land_man = sum(B5_q11*(B5_q1 != "99")), by(HHID)
egen double land_resid = sum(B5_q11*(B5_q1 == "98")), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if land > land_man
count if land< land_man

drop land
rename land_man land

keep HHID land land_resid
save "${r_output}\b5",replace

*Asset non_fin: building and constructions b6 srl 11
use "${r_input}\Visit 1_Block 6 part 2_buildings and other constructions owned by the household.dta",clear

egen double building_all = sum(B6_q14*(B6_q1 == "11")), by(HHID)
egen double building_all_man = sum(B6_q14*(B6_q1 != "11")),  by(HHID)

egen double building_resid = sum(B6_q14*(B6_q1 == "01")), by(HHID)
egen double building_resid_area = sum(B6_q13*(B6_q1 == "01")), by(HHID)

egen double building_dwelling = sum(B6_q14*(B6_q1 == "01")), by(HHID)
egen double building_dwelling_area = sum(B6_q13*(B6_q1 == "01")), by(HHID)

duplicates drop HHID,  force

keep HHID building_all* building_resid building_resid_area building_dwelling building_dwelling_area

*Check the manual (man) sum with survey sum
count if building_all > building_all_man
count if building_all < building_all_man

drop building_all
ren building_all_man building_all 

save "${r_output}\b6",replace

*Asset non_fin: livestock and poultry b7 srl 22 
use "${r_input}\Visit 1_Block 7_livestock and poultry owned by the household  on the date of survey and related transactions during 01-07-2002 to date of survey.dta",clear
destring B7_q1,replace
sum B7_q10

egen double livestock = sum(B7_q10*(B7_q1 == 44)), by(HHID)

duplicates drop HHID, force

keep HHID livestock
save "${r_output}\b7",replace

*Asset non_fin: agricultural machinery and implement b8: srl 8
use "${r_input}\Visit 1_Block 8_agricultural machinery and implement owned by the household as on the date of survey and related transactions.dta",clear

egen double agri = sum(B8_q10*(B8_q1 == "17")), by(HHID)
egen double agri_man = sum(B8_q10*(B8_q1 != "17")), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if agri > agri_man
count if agri < agri_man

drop agri
rename agri_man agri

keep HHID agri
save "${r_output}\b8",replace


*Asset non_fin: non-farm business equipment 
use "${r_input}\Visit 1_Block 9_non-farm business equipment owned by the household as on date of survey and related transactions.dta",clear
destring B9_q1,replace

egen double non_farm = sum(B9_q10*(B9_q1 == 21)), by(HHID)
egen double non_farm_man = sum(B9_q10*inrange(B9_q1,18,20)), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if non_farm > non_farm_man
count if non_farm < non_farm_man

drop non_farm_man
keep HHID non_farm
save "${r_output}\b9",replace

*Asset non_fin: transport
use "${r_input}\Visit 1_Block 10_transport  equipment owned by  the  household as on the date of  survey and  related tnansactions.dta",clear

egen double trspt = sum(B10_q10*(B10_q1 == "10")), by(HHID)
egen double trspt_man = sum(B10_q10*(B10_q1 != "8")), by(HHID)
duplicates drop HHID, force

*Check the manual (man) sum with survey sum
count if trspt > trspt_man
count if trspt < trspt_man

drop trspt
rename trspt_man trspt

keep HHID trspt
save "${r_output}\b10",replace

*Asset non-fin: other durable b11 (TV, Radio etc. Not exist in NSS70?!)
use "${r_input}\Visit 1_Block 11_durable assets owned by the household as on the date of survey and related transactions.dta",clear

egen double durable = sum(B11_q10*(B11_q1 == "15")), by(HHID)
egen double durable_man = sum(B11_q10*(B11_q1 != "15")), by(HHID)
duplicates drop HHID, force

egen double gold = sum(B11_q10*(B11_q1 == "13")), by(HHID)

*Check the manual (man) sum with survey sum
count if durable > durable_man
count if durable < durable_man

drop durable
rename durable_man durable 

keep HHID durable gold
save "${r_output}\b11",replace

*Asset fin: shares & debentures b12
use "${r_input}\Visit 1_Block 12_shares & debentures owned by the household in co operative societies & companies as on the date  of  survey and  related  transactions.dta",clear

 *Check the manual (man) sum with survey sum
  preserve
  egen double shares = sum(B12_q6*(B12_q1 == "8")), by(HHID)
  egen double shares_man = sum(B12_q6*(B12_q1 != "8")), by(HHID)
  duplicates drop HHID, force
  count if shares > shares_man
  count if shares < shares_man
  restore 

replace B12_q6 = . if B12_q6<0 //filter out the non-negative colums. 
egen double shares = sum(B12_q6*(B12_q1 == "8")), by(HHID)
duplicates drop HHID, force

keep HHID shares
save "${r_output}\b12",replace

*Asset fin: other financial assets b13 
use "${r_input}\Visit 1_Block 13_financial assets other than shares & debentures owned by the household as on the date  of  survey and  related  transactions.dta",clear

destring B13_q1,replace
replace B13_q1 = . if B13_q1 <0

egen double fin_retire = sum(B13_q8*(inlist(B13_q1,8,10))), by(HHID) //retirement account
egen double fin_other = sum(B13_q8*(inrange(B13_q1,1,7))|inlist(B13_q1 == 9,11,12 )), by(HHID)

duplicates drop HHID, force

keep HHID fin_other  fin_retire
save "${r_output}\b13",replace

*Asset fin: amount receivable b14
use "${r_input}\Visit 1_Block 14_cash loans and kind loans receivable by household against different securities or heads on the date of survey and related transactions.dta",clear

egen double fin_rec = sum(B14_q6*(B14_q1 == "8")), by(HHID)
egen double fin_rec_man = sum(B14_q6*(B14_q1 != "8")), by(HHID)
duplicates drop HHID, force

  *Check the manual (man) sum with survey sum
  count if fin_rec > fin_rec_man
  count if fin_rec < fin_rec_man
 
drop fin_rec
ren fin_rec_man fin_rec
keep HHID fin_rec
save "${r_output}\b14",replace

*Debt: cash loands payable b1: Type of loan(8) Purpose of loan (11) Type of mortgage(13) , srl 99 (total)
use "${r_input}\Visit 1_Block 15pt2 part 2.dta",clear
merge 1:1 HHID B15_2_q1 using "${r_input}\Visit 1_Block 15pt2 part 1.dta"

 *debt 
gen debt = B15_2_q24 // the outstanding amount on 30.06.2012
gen debt_todt = B15_2_q23 //outstanding amount at the date of survey. 
sum debt,de

egen double total_debt = sum(debt),by(HHID)
egen double total_debt_todt = sum(debt_todt), by(HHID)

 *generate type of liabilty (missing raw data for type of security)
gen gold_loan = (B15_2_q12 == "06")*debt
gen oth_secure_loan = (!inlist(B15_2_q12,"05","04","06"))*debt
gen mrtg_loan = (inlist(B15_2_q12,"05","04"))*debt

gen unsecure_loan = (B15_2_q12 == "01")*debt
egen double secure_loan = rowtotal(mrtg_loan gold_loan oth_secure_loan) 

 *collapse at household level. 
foreach type in secure_loan mrtg_loan gold_loan oth_secure_loan unsecure_loan { 
egen double total_`type' = sum(`type'), by(HHID)
} 

keep HHID total*
bys HHID: keep if _n == 1 // keep only one observation for each HH

mdesc total*

save "${r_output}\b15",replace

*Debt: kind of loan payable b16 
use "${r_input}\Visit 1_Block 16_kind loans and other liabilities payable by the household.dta",replace
save "${r_output}\b16",replace //late housing info


*******merge to master data******************************
use "${r_output}\b2",clear
local flist "b15 b14 b13 b12 b11 b10 b9 b8 b7 b6 b5 b4 b3"

foreach f of local flist{
merge 1:1 HHID using "${r_output}/`f'"
drop _merge
}

*clean up missing value
global asset "land building_all livestock trspt agri non_farm shares fin_other fin_retire gold fin_rec building_resid building_dwelling land_resid durable"
global debt "total_debt total_debt_todt total_secure_loan total_mrtg_loan total_gold_loan total_oth_secure_loan total_unsecure_loan"

mdesc $asset 
mdesc $debt 

foreach var in $asset $debt {
replace `var' = 0 if mi(`var')
}

*generate asset value by type
egen double asset = rowtotal(land building_all livestock trspt agri non_farm shares fin_other fin_retire gold fin_rec durable) //added durable here where the nss70 missing

egen double durable_other = rowtotal(livestock trspt agri non_farm durable) //added durable here where the nss70 missing

egen double real_estate = rowtotal(building_all land)

egen double real_estate_dwelling = rowtotal(building_dwelling land_resid)

egen double asset_non_fin = rowtotal(real_estate gold durable_other durable) //added durable here where the nss70 missing

egen double asset_fin = rowtotal(shares fin_other fin_rec) 

*generate wealth data
gen double wealth = asset - total_debt
sum wealth,de
gen double wealth_ln = ln(wealth) //1% negative 

xtile qtl = wealth [aw = hhwgt],n(5)

*house keeping
mdesc *

qui compress
save "${r_output}\NSS59_All",replace
