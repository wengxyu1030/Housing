****************************************************************************
* Description: Generate housing condition for all nss
* Date: Nov. 20, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 76\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\housing_condition_master"

di "$root"
global r_script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\housing_condition"

/*
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
*/
global r_output "${root}\Data Output Files"


*Define the survey rounds. 
global nss_round "NSS49 NSS76" 

// write a loop on the nss number here. 

foreach survey in $nss_round {

do "${r_script}/`survey'_housing_condition.do"

****************************************************************************
* Load the data
****************************************************************************
//use "${root}\Data Output Files\NSS76_All.dta"

****************************************************************************
* Get the Variable List for Housing Condition
****************************************************************************
label var hh_size "Size of Household"


**** MATERIALS ****

gen in_wall_permanent = 100*(wall== 6 | wall== 8 | wall== 9) // exclude timber and metal sheet
label var in_wall_permanent "Wall: Cement or Stone (%)"

gen in_roof_permanent = 100*(roof== 6 | roof== 8 | roof== 9) // exclude metal and asbestos sheets
label var in_roof_permanent "Roof: Cement or Stone (%)"

gen in_floor_permanent = 100*(inrange(floor,3,6)) // exclude mud, bamboo and log
label var in_floor_permanent "Floor: Cement or Stone (%)"

sum *permanent

gen in_all_permanent = (in_wall_permanent*in_roof_permanent*in_floor_permanent) / 1e4
label var in_all_permanent "All Materials: Cement or Stone (%)"

gen in_sep_kitch = 100*inrange(kitch,1,2) 
label var in_sep_kitch "Separate Kitchen (%)" 

capture confirm var flat
 if _rc==0 {
    gen in_flat = 100 * (flat == 2)
 }
 if _rc!= 0 {
    gen in_flat = . 
  }  
  label var in_flat "Flat (%)"

gen in_size = size 
label var in_size "Dwelling Size (sq ft)"

gen in_ppl_room = hh_size / in_room
label var in_ppl_room "People per room"

gen in_ppl_area = in_size / hh_size
label var in_ppl_area "Area in sq ft per person"

**** WATER and SANITATION ****
* Source: https://www.who.int/water_sanitation_health/monitoring/oms_brochure_core_questionsfinal24608.pdf
/*
***************************************
“Improved” sources of drinking-water 
***************************************
• Piped water into dwelling, also called a household connection, is defined as a water service pipe connected with in-house plumbing to one or more taps (e.g. in the kitchen and bathroom). • Piped water to yard/plot, also called a yard connection, is defi ned as a piped water connection to a tap placed in the yard or plot outside the house. • Public tap or standpipe is a public water point from which people can collect water. A standpipe is also known as a public fountain or public tap. Public standpipes can have one or more taps and are typically made of brickwork, masonry or concrete.  
• Tubewell or borehole is a deep hole that has been driven, bored or drilled, with the purpose of reaching groundwater supplies. Boreholes/tubewells are constructed with casing, or pipes, which prevent the small diameter hole from caving in and protects the water source from infi ltration by run-off water. Water is delivered from a tubewell or borehole through a pump, which may be powered by human, animal, wind, electric, diesel or solar means. Boreholes/tubewells are usually protected by a platform around the well, which leads spilled water away from the borehole and prevents infi ltration of run-off water at the well head.  
• Protected dug well is a dug well that is protected from runoff water by a well lining or casing that is raised above ground level and a platform that diverts spilled water away from the well. A protected dug well is also covered, so that bird droppings and animals cannot fall into the well.  
• Protected spring. The spring is typically protected from runoff, bird droppings and animals by a “spring box”, which is constructed of brick, masonry, or concrete and is built around the spring so that water fl ows directly out of the box into a pipe or cistern, without being exposed to outside pollution.  
• Bottled water is considered an improved source of drinking-water only when there is a secondary source of improved water for other uses such as personal hygiene and cooking. Production of bottled water should be overseen by a competent national surveillance body.  
• Rainwater refers to rain that is collected or harvested from surfaces (by roof or ground catchment) and stored in a container, tank or cistern until used. 

*************************
“Unimproved” sources of drinking-water  
***************************
• Unprotected spring. This is a spring that is subject to runoff, bird droppings, or the entry of animals. Unprotected springs typically do not have a “spring box”.  
• Unprotected dug well. This is a dug well for which one of the following conditions is true: 1) the well is not protected from runoff water; or 2) the well is not protected from bird droppings and animals. If at least one of these conditions is true, the well is unprotected.  
• Cart with small tank/drum. This refers to water sold by a provider who transports water into a community. The types of transportation used include donkey carts, motorized vehicles and other means.  
• Tanker-truck. The water is trucked into a community and sold from the water truck.  
• Surface water is water located above ground and includes rivers, dams, lakes, ponds, streams, canals, and irrigation channels.
*/


label define water 7 "Hand Pump" 2 "Piped Dwelling" 3 "Piped Yard" 5 "Public Tap" 6 "Tube Well" 1 "Bottled" 9 "Unprotected Well" 8 "Protected Well" 19 "Other"

//gen h20_temp = b5_1
label values h20_temp water
*From neighbor=piped dwelling, protected spring = protected well
recode h20_temp (4 = 2) (12=8) (11 15 16 13 10 14 = 19)

//gen h20_exclusive = b5_4 == 1 

*Gen Piped-Exclusive Piped-Shared Ground-Exclusive Ground-Shared Other
gen h20b_pip_exl = inrange(h20_temp,2,5) * h20_exclusive
gen h20b_pip_shr = inrange(h20_temp,2,5) * (h20_exclusive == 0)
gen h20b_grd_exl = inrange(h20_temp,6,9) * h20_exclusive
gen h20b_grd_shr = inrange(h20_temp,6,9) * (h20_exclusive == 0)
gen h20b_other = h20b_pip_exl != 1 & h20b_pip_shr != 1 & h20b_grd_exl != 1 & h20b_grd_shr != 1

tab h20_temp h20_exclusive

*Generate H20 Improved Water 
*Codes: 
* bottled water - 01												NOT IMPROVED bottled water (bottled water is considered improved only when the household use another improved source for cooking and personal hygiene)
* piped water into dwelling - 02									IMPROVED 
* piped water to yard/plot - 03										IMPROVED 
* piped water from neighbour - 04									IMPROVED 
* public tap/standpipe - 05											IMPROVED 
* tube well - 06													IMRPOVED 
* hand pump - 07,													IMPROVED 
* well: protected - 08,												IMPROVED 
* well: unprotected - 09;											NOT IMPROVED 
* tanker-truck: public - 10											NOT IMPROVED 
* tanker, private - 11; 											NOT IMPROVED 
*spring: protected - 12												IMPROVED 
* unprotected - 13;													NOT IMPROVED 
*rainwater collection -14,											IMPROVED
* surface water: tank/pond - 15, 									NOT IMRPROEVED 
* other surface water (river, dam, stream,*canal, lake, etc.) - 16; NOT IMPROVED 
*others (cart with small tank or drum, etc) - 19)					NOT IMPROVED 
* 

gen h20_improved = 100 * (h20_temp == 2 | h20_temp == 3 | h20_temp == 4 | h20_temp == 5 | h20_temp == 6 | h20_temp == 7 | h20_temp == 8 |  ///
						   h20_temp == 12 |h20_temp == 14)
*Check HH who use bottle water to drink, if the household uses an improved source for cooking / cleaning
capture confirm h20_cooking
if _rc == 0 {
    tab h20_cooking if h20_temp == 1
    replace h20_improved = 100 if h20_temp == 1 & (h20_cooking == 2 | h20_cooking == 3 | h20_cooking == 4 | h20_cooking == 5 | h20_cooking == 6 | h20_cooking == 7 | h20_cooking == 8 |  ///
											h20_cooking == 12 |h20_cooking == 14)
											
    table h20_cooking h20_improved if h20_temp == 1
}
//please add a note on the different definition on nss49 here.
label var h20_improved "Water: Improved Source (%)"
						   				   
gen h20_piped_in = 100* (h20_temp == 2 | h20_temp == 1 |h20_temp == 10 | h20_temp == 11)
label var h20_piped_in "Water: Piped into Dwelling (%)"

gen h20_yard = 100* (h20_temp == 3 | h20_temp ==4 )
label var h20_yar "Water: Piped into Yard (%)"

gen h20_pump_in = 100* inrange(h20_temp,5,8)*(h20_distance <= 2) // include a protected well
label var h20_pump_in "Water: Pump/Tubewell in Premises (%)"

gen h20_pump_out = 100* inrange(h20_temp,5,8)*(h20_distance > 2) // include a protected well
label var h20_pump_out "Water: Pump/Tubewell Outside Premises (%)"

gen h20_other = 100* (h20_piped_in!=100 & h20_pump_in!=100 & h20_pump_out!=100 & h20_yard!=100)
label var h20_other "Water: Other (%)"


************************ SANITATION **************************
* Generate Sanitation Improved 
*flush/pour-flush to: piped sewer system - 01, 					IMPROVED
*septic tank - 02, 												IMPROVED
*twin leach pit - 03, 											IMPROVED
*single pit - 04,												IMPROVED
* elsewhere (open drain, open pit, open field, etc) - 05; 		NOT IMPROVED
*ventilated improved pit latrine - 06, 							IMPROVED
* pit latrine with slab - 07, 									IMPROVED
* pit latrine without slab/open pit - 08, 						NOT IMRPOVED
*composting latrine - 10, 										IMPROVED
* not used - 11 )												NOT IMRPOVED
*others - 19; 													NOT IMRPOVED


gen san_improved = 100 * inlist(san_source,1,2,3,4,6,7,10) * inrange(san_distance,1,2)
tab san_source san_improved 
label var san_improved "Sanitation: Improved Source (%)"

sum san_improved [aw=hh_weight]

gen san_flush_private = 100 * inlist(san_source,1,2) * inrange(san_distance,1,2)
label var san_flush_private "Sanitation: Exclusive Flush (%)"

gen san_flush_shared = 100 * inlist(san_source,1,2) * inrange(san_distance,3,9)
label var san_flush_shared "Sanitation: Shared Flush (%)"

gen san_imp_lat_private = 100 * inlist(san_source,3,4,6,7,10) * inrange(san_distance,1,2)
label var san_imp_lat_private "Sanitation: Exclusive Imp Latrine (%)"
*Include shared flush into improved private latrine 
replace san_imp_lat_private = 100 if san_flush_shared == 100

gen san_not_imp_lat_shared = 100 * inlist(san_source,3,4,6,7,8,10) * inrange(san_distance,3,9)
label var san_not_imp_lat_shared "Sanitation: Shared Latrine (%)"

*include shared latrine into other 
gen san_other = 100 * (san_flush_private == 0 & san_imp_lat_private == 0)
label var san_other "Sanitation: Other (%)"

sum san_flush_private  san_imp_lat_private  san_other [aw=hh_weight]

*save the file 
save "${r_output}/`survey'_housing_condition.dta", replace  
}