****************************************************************************
* Description: Import NSS70 Secton 14 on housing loan
* Date: Oct 22, 2020
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

use "${r_input}\Visit 1_Block 14",clear
drop if b14_q1 == "99" //drop the total amount

*debt
gen debt = b14_q17
gen b14 = debt


*** LET'S try two housing mortgage definitions 
* (A) Conservative (let's label 1):       B14_Q11 == 11 & (B14_Q12 == 3 | B14_Q12 == 4)
* (B) Less conservative (let's label 2):  B14_Q11 == 11 & B14_13 != 4

*housing loan with immovable property as secure type
tab b14_q12
gen secure_type = b14_q12

gen hse_mortgage_1_dm = (b14_q11 == "11" & (b14_q12 == "04"|b14_q12 == "04"))
gen hse_mortgage_1 = hse_mortgage_1_dm*debt

*housing loan with mortgage
gen hse_mortgage_2_dm = (b14_q11 == "11" & b14_q13 != "4")
gen hse_mortgage_2 =  hse_mortgage_2_dm*debt

*aggregate at household level. *** When you collapse, check if any HH has two housing loans - we don't want to combine them. In fact we should try and do all this in file 03_Mortgage so we can keep file 01 clean while we play around with this data
keep if hse_mortgage_1_dm == 1 | hse_mortgage_2_dm == 1

label var hse_mortgage_1 "housing loan with immovable property as secure"
label var hse_mortgage_2 "housing loan with mortgage"

save "${r_output}\b14_hse_mortgage",replace


***stats
use "${r_output}\b14_hse_mortgage",clear

sum hse_mortgage_1 hse_mortgage_2[aw = MLT],de //hse_mortgage_2 is much higher than hse_mortgage_1 on both median and mean by single loan level.

collapse (sum) hse_mortgage_1_dm (sum) hse_mortgage_2_dm (sum) hse_mortgage_1 (sum) hse_mortgage_2 (mean) MLT,by(HHID)
sum hse_mortgage_1_dm hse_mortgage_2_dm  hse_mortgage_1 hse_mortgage_2 [aw = MLT],de //more hse_mortgage_2, hse_mortgage_2 is much higher than hse_mortgage_1 on both median and mean at hh level
