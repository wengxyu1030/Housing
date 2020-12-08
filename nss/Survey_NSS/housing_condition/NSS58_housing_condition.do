****************************************************************************
* Description: Generate housing condition for nss58
* Date: Dec. 7, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 58\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS58"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
* Get the Variable List for Housing Condition
****************************************************************************
*****calculate indicators by file*****

use "${r_input}\Block3-records.dta",clear  
    *id_survey:
	gen id_survey = "58"
	
    *id: common id
	gen id = Key_hhold
	
    *hh_sector: urban or rural sector
    gen hh_sector = Sector
	gen hh_urban = (hh_sector == "2")
	
	label define hh_urbanl 0 "rural" 1 "urban"
	label values hh_urban hh_urbanl
   
    *hh_state, hh_tn: whether the state is Tamil Nadu
    gen hh_state = State
	gen hh_tn = (hh_state == "33")
	
	label define hh_tnl 0 "non-TN" 1 "TN"
	label values hh_tn hh_tnl
	
    *multiplier
    gen hh_weight = Wgt_Combined
	destring(hh_weight),replace
	
	*hh_size: household size
	gen hh_size = B3_q3
	
	*hh_land: land posessed 
	gen hh_land = B3_q6
	
	*hh_umce: household monthly consumer expenditure
	gen hh_umce = B3_q9
	gen hh_umce_ln = ln(hh_umce)

    save "${r_output}\b3",replace

use "${r_input}\Block6-records.dta",clear 
unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  
    *id: common is
	gen id = Key_hhold

	*hq_tenure: the tenurial status
	gen hq_tenure = B6_q1
	
	*hq_has_dwell: has dwelling
	gen infra_has_dwell = (B6_q1 != 4)
	
	/* *hq_tenure_se: Secured Tenure:  no info in 58.
	//owned: freehold-1, leasehold-2; hired: employer quarter-3, hired dwelling units with written contract-4
	gen legal_tenure_se = 0  if (hq_tenure != 6)  //only for household has dwelling.
	replace legal_tenure_se = 1 if inrange(hq_tenure,1,4) //with dwelling and the status is secured
     */
	 
	*hq_own: the dwelling is woned
	gen legal_own = (hq_tenure == 1)
	
	*hq_rent: the dwelling is woned
	gen legal_rent = (inrange(hq_tenure,2,3))
	
/* 	*hq_nslum: the area type of dwelling unit is not in notified slum/ non-notified slum/ squatter settlement
	gen hq_nslum = 0 if inrange(b3_q15,1,3)
	replace hq_nslum = 1 if b3_q15 == 9  */
	
	*hq_floor_a: total floor area of the dwelling: in square feet
	gen infra_area = B6_q15
	
	*hq_ventilation of the dwelling unit is good 
	gen hq_ventilation = (B6_q16 == 1)
	
	*in_room: total number of rooms in the dwelling
	egen in_room =  rowtotal(B6_q9 B6_q10)
	
	*infra_pucca_floor: floor type is pucca: brick / stone / lime stone - 4,cement -5, mosaic / tiles - 6
	gen infra_pucca_floor = inrange(B6_q21,4,6)
	
	*infra_imp_floor: the improved material for floor (DHS): bamboo / log - 2, wood / plank - 3, brick / stone / lime stone - 4,cement -5, mosaic / tiles - 6
	gen infra_imp_floor = inrange(B6_q21,2,6)
	
	*infra_imp_wall: wall type is pucca/ improved material(DHS): 
	//timber - 5, burnt brick /stone/ lime stone - 6,
    //iron or other metal sheet - 7, cement / RBC / RCC - 8, other pucca - 9
	gen infra_imp_wall = inrange(B6_q22,5,9)
	
	*infra_imp_roof: roof type is pucca
	//tiles / slate - 5, burnt brick / stone / lime stone - 6, iron / zinc /other metal
    //sheet /asbestos sheet - 7, cement / RBC / RCC - 8, other pucca - 9
	gen infra_imp_roof = inrange(B6_q23,5,9)
	
	*hq_rent_cost: if hired, the monthly rent (Rs.)
	gen cost_rent  = B6_q2 //86.37% missing (based on 3,4,5 in b4_10)
	replace cost_rent = . if B6_q2 == 0 
	
	save "${r_output}\b6",replace	

	

use "${r_input}\Block4-records.dta",clear 

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id: common id
	gen id =  Key_hhold

	
save "${r_output}\b4",replace 




*****merge to master file*****
use "${r_output}\b3",clear

global FILE "b4 b6"

foreach file in $FILE {
merge 1:1 id using "${r_output}/`file'", nogen  force //there are section only survyed household with dwelling. 
}

*******save file*****  

*variables utilized in the hosuing condition code (double)
clonevar wall = B6_q22 //wall material 
clonevar roof = B6_q23 //roof mateiral
clonevar floor = B6_q21 //floor material
clonevar kitch = B6_q20 //separate kitchen
clonevar flat = B6_q8 //type of dwelling
clonevar size = B6_q15 //dwelling size. 

clonevar h20_temp = B4_q1 //Principal source of drinking water (the marjor one selected)
gen h20_exclusive = (B4_q3==1) //Access to principal source of drinking waterm(water exclusive use)
//clonevar h20_cooking = b5_17 //Principal source of water excluding drinking (not available in this data)
clonevar h20_distance = B4_q4 //Distance of the principal source of drinking water

clonevar san_source = B4_q7 //type of latrine used by the household
//clonevar san_distance = B4_q8 //Access of the household to latrine: no date in round 58

*******save file*****  
save "${r_output}/nss58",replace