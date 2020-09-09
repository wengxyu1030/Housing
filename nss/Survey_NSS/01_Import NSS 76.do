****************************************************************************
* Description: Import NSS76 from Raw Files and save dta to Output Folder
* Date: September 1, 2020
* Version 1.0
* Last Editor: Nadeem 
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 76"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS76"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
* Import TXT Files with the DCT files
****************************************************************************


forvalues i=1(1)8 { 

 infile using "${r_input}\R76120L0`i' v2.dct", using("${r_input}\R76120L0`i'.txt") clear
 qui compress 
 save "${r_output}\NSS76_`i'.dta", replace
}
****************************************************************************
* Calculate indicators by file - block number and suffix are not the same
****************************************************************************
use "${r_output}\NSS76_1",clear  
    *id_survey:
	gen id_survey = "76"  //only for nss76 because of raw data encoding. 
	
    *id: common id
	gen id = substr(b1_id,4,.)
	
    *hh_sector: urban or rural sector
    gen hh_sector = substr(b1_id,15,1)
	gen hh_urban = (hh_sector == "2")
	
	label define hh_urbanl 0 "rural" 1 "urban"
	label values hh_urban hh_urbanl
   
    *hh_state, hh_tn: whether the state is Tamil Nadu
    gen hh_state = substr(b1_id,16,2)
	gen hh_tn = (hh_state == "33")
	
	label define hh_tnl 0 "non-TN" 1 "TN"
	label values hh_tn hh_tnl
	
    *multiplier
    gen hh_weight = b1_mtpl
	destring(hh_weight),replace
	qui compress
	
    save "${r_output}\NSS76_1",replace


use "${r_output}\NSS76_2",clear  
    *id: common id
	gen id = substr(b3_id,4,.)
	
	*hh_relation_head: realation to household head. 
	gen hh_relation_head = b3_0_3
	
	*hh_age: age of the individual
	gen hh_age = b3_0_5
	
	*hh_student: the status is attended educational institution
	gen hh_student = (b3_0_8 == 91)
	qui compress
    save "${r_output}\NSS76_2",replace

use "${r_output}\NSS76_3",clear 
    *id: common is
	gen id = substr(b4_id,4,.)

    *hh_size: household size
	gen hh_size = b4_1
	
	*hh_land: land posessed 
	gen hh_land = b4_4
	
	*hh_umce: household monthly consumer expenditure
	gen hh_umce = b4_9/hh_size
	gen hh_umce_ln = ln(hh_umce)
	
	*hq_tenure: the tenurial status
	gen hq_tenure = b4_10
	
	*hq_has_dwell: has dwelling
	gen infra_has_dwell = (hq_tenure != 6)
	
	*hq_tenure_se: Secured Tenure: 
	//owned: freehold-1, leasehold-2; hired: employer quarter-3, hired dwelling units with written contract-4
	gen legal_tenure_se = 0  if (hq_tenure != 6)  //only for household has dwelling.
	replace legal_tenure_se = 1 if inrange(hq_tenure,1,4) //with dwelling and the status is secured
    
	*hq_own: the dwelling is woned
	gen legal_own = (inrange(hq_tenure,1,2))
	
	*hq_rent: the dwelling is woned
	gen legal_rent = (inrange(hq_tenure,3,5))
	
	*hq_nslum: the area type of dwelling unit is not in notified slum/ non-notified slum/ squatter settlement
	gen hq_nslum = 0 if inrange(b4_11,1,3)
	replace hq_nslum = 1 if b4_11 == 9 
	
	*hq_travel: maximum distance travelled to the place of work: male, female, transgender
	gen hq_travel_m = b4_16a
	gen hq_travel_f = b4_16b
	gen hq_travel_t = b4_16c
	//need to code later.
	qui compress
	save "${r_output}\NSS76_3",replace
	
use "${r_output}\NSS76_5",clear 
    *id: common id
	gen id =  substr(b5_id,4,.)
	
	*hq_water: Access to improved drinking water sources 
	//(bottled water - 01, piped water into dwelling - 02)
    gen hq_water = (inrange(b5_1,1,2))
	
	*hq_water_su: Household has sufficient drinking water thgouthout the year from principal source.
    gen hq_water_su = 2- b5_2
	
	*infra_water_di:Distance to the principal source of drinking water
	gen infra_water_di = b5_5
	
	*infra_water_in: Distance to the principal source of drinking water: within dwelling/premises
	gen infra_water_in = 1 if inrange(b5_5,1,2)
	replace infra_water_in = 0 if inrange(b5_5,3,7)
	
	*hq_water_cost: average amount paid per month (Rs.)
	gen hq_water_cost = b5_21b
	
	*hq_san: Access to improved sanitation: 
	//used: flush/pour-flush to: piped sewer system - 01, septic tank - 02, twin leach pit - 03, single pit - 04,
    //elsewhere (open drain, open pit, open field, etc) - 05; ventilated improved pit latrine - 06 */
    gen hq_san = 1 if inrange(b5_26,1,6)
	replace hq_san = 0 if inrange(b5_26,7,19)
	
	*hq_san_in: bathroom and latrine both are within the household premises
	gen hq_san_in = (b5_27 ==1)
	
	*hq_san_cost: amount paid (payable) for emptying the excreta last time (Rs.)
    gen hq_san_cost = b5_31
	qui compress
	save "${r_output}\NSS76_5",replace
	
use "${r_output}\NSS76_6",clear
    *id: common id
	gen id =  substr(b6_i,4,.)
	
	*hq_level: Plinth level of the house 
    gen hq_level = b6_1
	
	*hq_floor_n: Number of floor (s) in the house
	gen hq_floor_n = b6_2
	
	*hq_resid: Use of house as residential only
	gen hq_resid = (b6_3 == 1)
	
	*hq_period: period since built
	gen hq_period = b6_4
	
	*hq_str_good: condition of structure good
	gen hq_str_good = (b6_7 == 1)
	
	*hq_elec: household has electricity for domestic use
	gen hq_elec = (b6_8 == 1)
	
	*hq_drainage: drainage system is pucca structure: underground -1, covered pucca -2, open pucca -3,
	gen infra_pucca_drainage = inrange(b6_10,1,3)
	
	*hq_nflood: did not experience flood in last 5 years
	gen hq_nflood = (b6_15 == 3)
	
	*hq_path: direct opening to approach road/lane/constructed path
	gen hq_path = inrange(b6_16,1,4)
	qui compress
	save "${r_output}\NSS76_6",replace
	
use "${r_output}\NSS76_7",clear
    *id : common id
	gen id =  substr(b7_id,4,.)
	
	*hq_dwell_type: type of dwelling
	gen hq_dwell_type = b7_1
	
	*hq_dwell_indi: type of dwelling is independent house
	gen hq_dwell_indi = (hq_dwell_type == 1)
	
	*hq_room: total number of rooms in the dwelling
	gen infra_room = b7_2 + b7_3
	
	*hq_floor_a: total floor area of the dwelling: in square feet
	gen infra_area = b7_8
	
	*hq_ventilation of the dwelling unit is good 
	gen hq_ventilation = (b7_9 == 1)
	
	*hq_married_sep: there's married couple in the household have separate room
	gen hq_married_sep = 0 if b7_10 == 0
	replace hq_married_sep = 1 if b7_11>=1
	
	*hq_kitchen: with separate kitchen
	gen hq_kitchen = (b7_12 != 3)
	
	*infra_floor_type: 
	gen infra_floor_type = b7_14
	
	*infra_pucca_floor: floor type is pucca: brick / stone / lime stone - 4,cement -5, mosaic / tiles - 6
	gen infra_pucca_floor = inrange(b7_14,4,6)
	
	*infra_imp_floor: the improved material for floor (DHS): bamboo / log - 2, wood / plank - 3, brick / stone / lime stone - 4,cement -5, mosaic / tiles - 6
	gen infra_imp_floor = inrange(b7_14,2,6)
	
	*infra_wall_type:
	gen infra_wall_type = b7_15
	
	*infra_imp_wall: wall type is pucca/ improved material(DHS): 
	//timber - 5, burnt brick /stone/ lime stone - 6,
    //iron or other metal sheet - 7, cement / RBC / RCC - 8, other pucca - 9
	gen infra_imp_wall = inrange(b7_15,5,9)
	
	*infra_roof_type
	gen infra_roof_type = b7_16
	
	*infra_imp_roof: roof type is pucca
	//tiles / slate - 5, burnt brick / stone / lime stone - 6, iron / zinc /other metal
    //sheet /asbestos sheet - 7, cement / RBC / RCC - 8, other pucca - 9
	gen infra_imp_roof = inrange(b7_16,5,9)
	
	*hq_rent_cost: if hired, the monthly rent (Rs.)
	gen cost_rent  = b7_17 //86.37% missing (based on 3,4,5 in b4_10)
	qui compress
	save "${r_output}\NSS76_7",replace

use "${r_output}\NSS76_8",clear
    *id : common id
	gen id =  substr(b8_id,4,.) 
	
	*legal_stay: duration of stay of the household in the present area less than 10 year. (less than 1 year - 01, 1 to 2 years - 02, 2 to 5 years - 03, 5 to 10 years - 04,
	gen legal_stay = b8_1
	
	*legal_stay10: duration of stay of the household in the present area less than 10 year. (less than 1 year - 01, 1 to 2 years - 02, 2 to 5 years - 03, 5 to 10 years - 04,
	gen legal_stay10 = (b8_1 <=4 )
	
	*legal_move: where the household was residing before coming to the present area.
	/* 	(in slum/squatter settlement of the same town - 1, in other areas of the same
	town - 2, in slum/squatter settlement of other town - 3, in other areas of other
	town - 4, village - 5) */
	gen legal_move = b8_2
	
	*legal_move_reason: reason for movement to the present area
	/* 	(free / low rent - 1, independent accommodation - 2, accommodation in
	better locality - 3, employment related reasons: proximity to place of work - 4,
	other employment related reasons - 5; others - 9)*/
	gen legal_move_reason = b8_4
	
	*hq_slum_doc: the head of the household posess documents pertaining to the residence status in the slum
	gen hq_slum_doc = (b8_7 != 5)
	replace hq_slum_doc = . if (b8_7 == .)
	
	*hq_slum_be: the slum household received benefit as slum dweller
	gen hq_slum_be = (b8_8 != 2)
	replace hq_slum_be = . if (b8_8 == .)
	qui compress
	save "${r_output}\NSS76_8",replace

****************************************************************************
* Merge Files - skip 4 
*****************************************************************************
use "${r_output}\NSS76_1",clear

foreach f in 3 5 6 7 8 {
merge 1:1 id using "${r_output}\NSS76_`f'", nogen  //there are section only survyed household with dwelling. 
}

qui compress
save "${r_output}\NSS76_All",replace
