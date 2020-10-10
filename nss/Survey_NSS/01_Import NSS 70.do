****************************************************************************
* Description: Import NSS70 from Raw Files and save dta to Output Folder
* Date: Oct 6, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 70"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************

*gen id, wgt (hhwgt, popwgt) b3
use "${r_input}\Visit 1_Block 3_Household Characteristics.dta",clear

rename (b3q1 Sector) (hhsize sector)
gen hhwgt = MLT //or weight_sc for combined sub-sample?
destring(hhsize),replace
gen pwgt = MLT * hhsize

keep HHID hhwgt pwgt hhsize sector Weight_SS Weight_SC
save "${r_output}\b3",replace

*Asset non_fin： land from b5.1 & b5.2 (rural & urban) srl 99
use "${r_input}\Visit 1_Block 5pt1_Details of land owned by the household as on 30.06.12.dta",clear
keep if b5_1_1 == "99"
keep HHID State b5_1_6
rename State state
codebook,c
save "${r_output}\b5_1",replace

use "${r_input}\Visit 1_Block 5pt2_Details of land owned by the household as on 30.06.12.dta",clear
keep if b5_2_1 == "99"
keep HHID b5_2_6
codebook,c
save "${r_output}\b5_2",replace

*Asset non_fin: building and constructions b6 srl 11
use "${r_input}\Visit 1_Block 6_Buildings and other constructions owned by the household as on 30.06.2012.dta",clear
<<<<<<< Updated upstream
keep if b6_q3 == "11"
keep HHID b6_q6
=======

gen building_all =  b6_q6*(b6_q3 == "11")
gen building_resid =  b6_q6*(!inlist(b6_q3,"10","11"))

collapse (sum) building_all (sum) building_resid, by(HHID)

keep HHID building_all building_resid 
>>>>>>> Stashed changes
codebook,c
save "${r_output}\b6",replace

*Asset non_fin: livestock and poultry b7 srl 22 
use "${r_input}\Visit 1_Block 7_Livestock and poultry owned by the household on 30.06.2012.dta",clear
keep if b7_q2 == "22"
keep HHID b7_q5
codebook,c
save "${r_output}\b7",replace

*Asset non_fin: transport equipment b8: srl 8
use "${r_input}\Visit 1_Block 8_Transport equipment owned by the household on 30.06.2012.dta",clear
keep if b8_q2 == "08"
keep HHID b8_q5
codebook,c
save "${r_output}\b8",replace

*Asset non_fin: agricultural machinery and implements b9: srl 8 
use "${r_input}\Visit 1_Block 9_Agricultural machinery and implements owned by the household on 30.06.2012.dta",clear
keep if b9_q2 == "8"
keep HHID b9_q4
codebook,c
save "${r_output}\b9",replace

*Asset non_fin: non-farm business equipment b10 srl 15
use "${r_input}\Visit 1_Block 10_Non-farm business equipment owned by the household as on 30.06.2012.dta",clear
keep if b10_q2== "15"
keep HHID b10_q3
codebook,c
save "${r_output}\b10",replace

*Asset fin: shares & debentures b11 srl 5 
use "${r_input}\Visit 1_Block 11_ Shares and debentures owned by the household in co-operative  societies & companies as on 30.06.2012 .dta",clear
keep if b11_q1 == "5"
keep HHID b11_q6
codebook,c
save "${r_output}\b11",replace

*Asset fin: other financial assets b12 srl 11 
use "${r_input}\Visit 1_Block 12_Financial assets other than shares and debentures owned by the household as on 30.06.2012.dta",clear
keep if b12_q1 == "11"
keep HHID  b12_q3
codebook,c
save "${r_output}\b12",replace

*Asset fin: amount receivable b13 (mortgage srl 1, total srl 7)
use "${r_input}\Visit 1_Block 13_Amount receivable by the household against different heads as on 30.06.2012.dta",clear
keep if b13_q2 == "7"
keep HHID b13_q4
codebook,c
save "${r_output}\b13",replace

*Debt: cash loands payable b14: Type of loan(8) Purpose of loan (11) Type of mortgage(13) , srl 99 (total)
use "${r_input}\b14",clear
drop if b14_q1 == "99" //drop the total amount

*debt
gen debt = b14_q17
gen b14 = debt

*loan purpose
gen loan_purpose = b14_q11
gen hous_loan = (b14_q11 == "11")*debt

*credit agency
gen credit_agency = b14_q6

destring(b14_q6),replace
gen credit_formal = (!inrange(b14_q6,12,17)& b14_q6!=9)*debt

*mortgage
gen mortgage_type = b14_q13
gen has_mortgage =  (b14_q13 != "4")*debt

*borrowed amount
gen br_amount = b14_q5

*aggregate at household level. 
collapse (sum) hous_loan (sum) credit_formal (sum) has_mortgage (sum) br_amount (sum) debt,by(HHID)

save "${r_output}\b14",replace

*Debt: kind of loan payable b15 col 11: housing 11
use "${r_input}\Visit 1_Block 15_kind loans payable by the household.dta",replace
save "${r_output}\b15",replace //late housing info

*gender from b4 (4)
use "${r_input}\Visit 1 _Block 4_Demographic and other particulars of household members.dta",clear
keep HHID b4q4 b4q3
save "${r_output}\b4",replace //later gender info

*******merge to master data******************************
use "${r_output}\b3",clear
local flist "b14 b13 b12 b11 b10 b9 b8 b7 b6 b5_1 b5_2"

foreach f of local flist{
merge 1:1 HHID using "${r_output}/`f'"
drop _merge
}

foreach var in b5_1_6 b5_2_6 b6_q6 b7_q5 b8_q5 b9_q4 b10_q3 b11_q6 b12_q3 b13_q4{
replace `var' = 0 if mi(`var')
} 

egen asset = rowtotal(b5_1_6 b5_2_6 b6_q6 b7_q5 b8_q5 b9_q4 b10_q3 b11_q6 b12_q3 b13_q4) 

gen wealth = asset - debt

gen wealth_ln = ln(wealth)
 
qui compress
save "${r_output}\NSS70_All",replace


