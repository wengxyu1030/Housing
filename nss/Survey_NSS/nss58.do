**********************************
***NSS58 for housing condition****
**********************************

//This file is to consolidate the surveys

global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/nss/Survey_NSS"
global root_survey "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/nss_data/NSS58"

global raw "${root_survey}/raw"
global inter "${root_survey}/inter"
global final "${root_survey}/final"

global raw_batch "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/nss/MASTER_NSS/raw"




*****calculate indicators by file*****

use "${raw}\Block3-records.dta",clear  
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

    save "${inter}\b3",replace

use "${raw}\Block6-records.dta",clear 
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
	
	*hq_room: total number of rooms in the dwelling
	gen infra_room = B6_q9 + B6_q10
	
	*hq_floor_a: total floor area of the dwelling: in square feet
	gen infra_area = B6_q15
	
	*hq_ventilation of the dwelling unit is good 
	gen hq_ventilation = (B6_q16 == 1)
	
/* 	*hq_married_sep: there's married couple in the household have separate room
	gen hq_married_sep = 0 if b6_q11 == 0
	replace hq_married_sep = 1 if b6_q11 >=1 
	
	*hq_kitchen: with separate kitchen
	gen hq_kitchen = (b6_q12 != 3)*/
	
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
	
	save "${inter}\b6",replace	

	

/* use "${raw}\b4",clear 

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id: common id
	gen id =  Key_hhold
	*tostring(id),replace
	
	*hq_water: Access to improved drinking water sources 
	//(bottled water - 01, piped water into dwelling - 02)
    gen hq_water = (inrange(b4_q1,1,2))
	
	*hq_water_su: Household has sufficient drinking water thgouthout the year from principal source.
    gen hq_water_su = b4_q2
	
	*hq_water_in: Distance to the principal source of drinking water: within dwelling/premises
	gen infra_water_in = 1 if inrange(b4_q5,1,2)
	replace infra_water_in = 0 if inrange(b4_q5,3,7)
	
	*hq_water_cost: average amount paid per month (Rs.)
	gen hq_water_cost = b4_q19_2
	
	*hq_san: Access to improved sanitation: 
	//used: flush/pour-flush to: piped sewer system - 01, septic tank - 02, twin leach pit - 03, single pit - 04,
    //elsewhere (open drain, open pit, open field, etc) - 05; ventilated improved pit latrine - 06 */
    //gen hq_san = 1 if inrange(b4_q24,1,6)
	//replace hq_san = 0 if inrange(b4_q24,7,19)
	 
	/* //no data in nss69
	*hq_san_in: bathroom and latrine both are within the household premises
	gen hq_san_in = (b5_27 ==1)
	*/
	
	/* //no data in nss69
	*hq_san_cost: amount paid (payable) for emptying the excreta last time (Rs.)
    gen hq_san_cost = b5_31
    */
	
	*hq_elec: household has electricity for domestic use
	//gen hq_elec = (b4_q31 == 1)
	
	//save "${inter}\b4",replace 
 */
	
/* use "${raw}\b5",clear

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id: common id
	gen id =  Key_hhold
	
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
	
	*hq_drainage: drainage system is pucca structure: underground -1, covered pucca -2, open pucca -3,
	gen infra_pucca_drainage = inrange(b5_q8,1,3)
	
	*hq_nflood: did not experience flood in last 5 years
	gen hq_nflood = (b5_q14 == 3)
	
	*hq_path: direct opening to approach road/lane/constructed path
	gen hq_path = inrange(b5_q15,1,4)

	save "${inter}\b5",replace  */
	
/* use "${raw}\b6",clear

unab var_all: _all
local exclude "Key_hhold"
local var: list var_all - exclude
disp "`var'"
destring `var',replace  

    *id : common id
	gen id =  Key_hhold
	
	*hq_dwell_type: type of dwelling
	gen hq_dwell_type = b6_q1
	
	*hq_dwell_indi: type of dwelling is independent house
	gen hq_dwell_indi = (hq_dwell_type == 1)
    
	save "${inter}\b6",replace */


/* use "${raw}\b7",clear

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
	save "${inter}\b7",replace
*/ 

*****merge to master file*****
use "${inter}\b3",clear

global FILE " b6"

foreach file in $FILE {
merge 1:1 id using "${inter}/`file'", nogen  force //there are section only survyed household with dwelling. 
}

	
keep id* infra_* cost_* legal_* hh_*
codebook,c
mdesc 


*******save file*****  

save "${final}/nss58",replace
save "${raw_batch}/nss58",replace
//export excel using "${final}/nss69.xlsx", sheet("nss69") sheetreplace firstrow(var)





