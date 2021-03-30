****************************************************************************
* Description: Generate housing condition for nss65
* Date: Nov. 24, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 65\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS65"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
* Get the Variable List for Housing Condition
****************************************************************************
use "${r_input}\b12",clear  
    *id_survey:
	gen id_survey = Round
	
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
    gen hh_weight = Wgt_combined
	destring(hh_weight),replace

    save "${r_output}\b1",replace

use "${r_input}\b3",clear 
    *id: common is
	gen id = Key_hhold

    *hh_size: household size
	gen hh_size = B3_q3
	
	*hq_tenure: the tenurial status
	gen hq_tenure = B3_q11
	destring(hq_tenure),replace
	
	*infra_has_dwell: has dwelling
	gen infra_has_dwell = (hq_tenure != 6)
	
	*hq_tenure_se: Secured Tenure: 
	//owned: freehold-1, leasehold-2; hired: employer quarter-3, hired dwelling units with written contract-4
	gen legal_tenure_se = 0  if (hq_tenure != 6)  //only for household has dwelling.
	replace legal_tenure_se = 1 if inrange(hq_tenure,1,4) //with dwelling and the status is secured
    
	*legal_own: the dwelling is woned
	gen legal_own = (inrange(hq_tenure,1,2))
	
	*legal_rent: the dwelling is woned
	gen legal_rent = (inrange(hq_tenure,3,5))
	
/* 	*hh_land: land posessed 
	gen hh_land = b3_q13
	
	*hq_nslum: the area type of dwelling unit is not in notified slum/ non-notified slum/ squatter settlement
	gen hq_nslum = 0 if inrange(b3_q15,1,3)
	replace hq_nslum = 1 if b3_q15 == 9  */
	
/* 	save "${r_output}\b3",replace	

use "${r_input}\b3_1",clear 
    *id: common is
	gen id = Key_hhold */
	
	*hh_umce: household monthly consumer expenditure
	gen hh_umce = B3_q19 
	gen hh_umce_ln = ln(hh_umce)
	
	/* //missing b3_q16 (travel distance) datapoint in the raw data. 
	*hq_travel: maximum distance travelled to the place of work: male, female, transgender
	gen hq_travel_m = b4_16a
	gen hq_travel_f = b4_16b
	gen hq_travel_t = b4_16c
	*/
	
	save "${r_output}\b3",replace	
	
use "${r_input}\b4",clear 

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id: common id
	gen id =  Key_hhold
	
	*infra_water_in: Distance to the principal source of drinking water: within dwelling/premises
	gen infra_water_in = 1 if inrange(B4_q5,1,2)
	replace infra_water_in = 0 if inrange(B4_q5,3,7)
	
/* 	*hq_water: Access to improved drinking water sources 
	//(bottled water - 01, piped water into dwelling - 02)
    gen hq_water = (inrange(b4_q1,1,2))
	
	*hq_water_su: Household has sufficient drinking water thgouthout the year from principal source.
    gen hq_water_su = b4_q2
	
	*hq_water_cost: average amount paid per month (Rs.)
	gen hq_water_cost = b4_q19_2
	
	*hq_san: Access to improved sanitation: 
	//used: flush/pour-flush to: piped sewer system - 01, septic tank - 02, twin leach pit - 03, single pit - 04,
    //elsewhere (open drain, open pit, open field, etc) - 05; ventilated improved pit latrine - 06 
    gen hq_san = 1 if inrange(b4_q24,1,6)
	replace hq_san = 0 if inrange(b4_q24,7,19)
		
	*hq_elec: household has electricity for domestic use
	gen hq_elec = (b4_q31 == 1)  */

	
	save "${r_output}\b4",replace
	
use "${r_input}\b5",clear

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id: common id
	gen id =  Key_hhold	
	
	*hq_drainage: drainage system is pucca structure: underground -1, covered pucca -2, open pucca -3,
	gen infra_pucca_drainage = inrange(B5_q8,1,3)
	
/* 	*hq_nflood: did not experience flood in last 5 years
	gen hq_nflood = (b5_q14 == 3)
	
	*hq_level: Plinth level of the house 
    gen hq_level = b5_q1
	
	*hq_floor_n: Number of floor (s) in the house
	gen hq_floor_n = b5_q2
	
	*hq_resid: Use of house as residential only
	gen hq_resid = (b5_q3 == 1)
	
	*hq_period: period since built
	gen hq_period = b5_q4
	
	*hq_str_good: condition of structure good
	gen hq_str_good = (b5_q7 == 1)
	
	*hq_path: direct opening to approach road/lane/constructed path
	gen hq_path = inrange(b5_q15,1,4) 
*/
	
	save "${r_output}\b5",replace
	

use "${r_input}\b6",clear

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id : common id
	gen id =  Key_hhold
	
	*infra_room: total number of rooms in the dwelling
	gen infra_room = B6_q2 + B6_q3
	
	*infra_area: total floor area of the dwelling: in square feet
	gen infra_area = B6_q8
	
	*infra_pucca_floor: floor type is pucca: brick / stone / lime stone - 4,cement -5, mosaic / tiles - 6
	gen infra_pucca_floor = inrange(B6_q14,4,6)
	
	*infra_imp_floor: the improved material for floor (DHS): bamboo / log - 2, wood / plank - 3, brick / stone / lime stone - 4,cement -5, mosaic / tiles - 6
	gen infra_imp_floor = inrange(B6_q14,2,6)
	
	*infra_imp_wall: wall type is pucca/ improved material(DHS): 
	//timber - 5, burnt brick /stone/ lime stone - 6,
    //iron or other metal sheet - 7, cement / RBC / RCC - 8, other pucca - 9
	gen infra_imp_wall = inrange(B6_q15,5,9)
	
	*infra_imp_roof: roof type is pucca
	//tiles / slate - 5, burnt brick / stone / lime stone - 6, iron / zinc /other metal
    //sheet /asbestos sheet - 7, cement / RBC / RCC - 8, other pucca - 9
	gen infra_imp_roof = inrange(B6_q16,5,9)
	
	*cost_rent: if hired, the monthly rent (Rs.)
	gen cost_rent  = B6_q17 
	
	*in_room: total number of rooms
	egen in_room = rowtotal(B6_q2 B6_q3)
	label var in_room "Number of Rooms"
	replace in_room =1 if in_room == 0
		
/* 	*hq_dwell_type: type of dwelling
	gen hq_dwell_type = b6_q1
	
	*hq_dwell_indi: type of dwelling is independent house
	gen hq_dwell_indi = (hq_dwell_type == 1)
	
	*hq_ventilation of the dwelling unit is good 
	gen hq_ventilation = (b6_q9 == 1)
	
	*hq_married_sep: there's married couple in the household have separate room
	gen hq_married_sep = 0 if b6_q11 == 0
	replace hq_married_sep = 1 if b6_q11 >=1
	
	*hq_kitchen: with separate kitchen
	gen hq_kitchen = (b6_q12 != 3) */
	
	
	save "${r_output}\b6",replace

/* use "${r_input}\b7",clear

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id : common id
	gen id =  Key_hhold 
	
	*hq_slum_doc: the head of the household posess documents pertaining to the residence status in the slum
	gen hq_slum_doc = (b7_q8 != 5)
	replace hq_slum_doc = . if (b7_q8 == .)
	
	*hq_slum_be: the slum household received benefit as slum dweller
	gen hq_slum_be = (b7_q9 != 2)
	replace hq_slum_be = . if (b7_q9 == .)
	
	keep id hq_*
	sort id
	save "${r_output}\b7",replace */
	
*****merge to master file*****
use "${r_output}\b1",clear

global FILE "b3 b4 b5 b6"

foreach file in $FILE {
merge 1:1 id using "${r_output}/`file'", nogen  force //there are section only survyed household with dwelling. 
}

*variables utilized in the hosuing condition code (double)
clonevar wall = B6_q15 //wall material 
clonevar roof = B6_q16 //roof mateiral
clonevar floor = B6_q14 //floor material
clonevar kitch = B6_q13 //separate kitchen
clonevar flat = B6_q1 //is a flat no data in this round
clonevar size = B6_q8 //dwelling size. 

clonevar h20_temp = B4_q1_1 //Principal source of drinking water (the marjor one selected)
gen h20_exclusive = (B4_q4==1) //Access to principal source of drinking waterm(water exclusive use)
//clonevar h20_cooking = b5_17 //Principal source of water excluding drinking (not available in this data)
clonevar h20_distance = B4_q5 //Distance of the principal source of drinking water

clonevar san_source = B4_q9 //type of latrine used by the household
clonevar san_distance = B4_q8 //Access of the household to latrine

*******save file*****  
save "${r_output}/nss65_housing_condition",replace
