****************************************************************************
* Description: Generate a summary table of NSS 76 
* Date: October 6, 2020
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 76\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housin\survey_all\Housing_git\nss\"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
* Load the data
****************************************************************************
use "${root}\Data Output Files\NSS76_All.dta"

****************************************************************************
* Get the Variable List to Make a Summary Table 
****************************************************************************
label var hh_size "Size of Household"

**** MATERIALS ****
gen in_wall_permanent = 100*(b7_15== 6 | b7_15== 8 | b7_15== 9) // exclude timber and metal sheet
label var in_wall_permanent "Wall: Cement or Stone (%)"

gen in_roof_permanent = 100*(b7_16== 6 | b7_16== 8 | b7_16== 9) // exclude metal and asbestos sheets
label var in_roof_permanent "Roof: Cement or Stone (%)"

gen in_floor_permanent = 100*(inrange(b7_14,3,6)) // exclude mud, bamboo and log
label var in_floor_permanent "Floor: Cement or Stone (%)"

sum *permanent

gen in_all_permanent = (in_wall_permanent*in_roof_permanent*in_floor_permanent) / 1e4
label var in_all_permanent "All Materials: Cement or Stone (%)"

gen in_sep_kitch = 100*inrange(b7_12,1,2) 
label var in_sep_kitch "Separate Kitchen (%)" 

gen in_flat = 100 * (b7_1 == 2)
label var in_flat "Flat (%)"

gen in_size = b7_8 
label var in_size "Dwelling Size (sq ft)"

egen in_room = rowtotal(b7_2  b7_3)
label var in_room "Number of Rooms"
replace in_room =1 if in_room == 0

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

gen h20_temp = b5_1
label values h20_temp water
*From neighbor=piped dwelling, protected spring = protected well
recode h20_temp (4 = 2) (12=8) (11 15 16 13 10 14 = 19)

gen h20_exclusive = b5_4 == 1 

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

gen h20_improved = 100 * (b5_1 == 2 | b5_1 == 3 | b5_1 == 4 | b5_1 == 5 | b5_1 == 6 | b5_1 == 7 | b5_1 == 8 |  ///
						   b5_1 == 12 |b5_1 == 14)
*Check HH who use bottle water to drink, if the household uses an improved source for cooking / cleaning
tab b5_17 if b5_1 == 1
replace h20_improved = 100 if b5_1 == 1 & (b5_17 == 2 | b5_17 == 3 | b5_17 == 4 | b5_17 == 5 | b5_17 == 6 | b5_17 == 7 | b5_17 == 8 |  ///
											b5_17 == 12 |b5_17 == 14)
											
table b5_17 h20_improved if b5_1 == 1
label var h20_improved "Water: Improved Source (%)"
						   
						   
gen h20_piped_in = 100* (b5_1 == 2 | b5_1 == 1 |b5_1 == 10 | b5_1 == 11)
label var h20_piped_in "Water: Piped into Dwelling (%)"

gen h20_yard = 100* (b5_1 == 3 | b5_1 ==4 )
label var h20_yar "Water: Piped into Yard (%)"

gen h20_pump_in = 100* inrange(b5_1,5,8)*(b5_5 <= 2) // include a protected well
label var h20_pump_in "Water: Pump/Tubewell in Premises (%)"

gen h20_pump_out = 100* inrange(b5_1,5,8)*(b5_5 > 2) // include a protected well
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


gen san_improved = 100 * inlist(b5_26,1,2,3,4,6,7,10) * inrange(b5_25,1,2)
tab b5_26 san_improved 
label var san_improved "Sanitation: Improved Source (%)"

sum san_improved [aw=hh_weight]

gen san_flush_private = 100 * inlist(b5_26,1,2) * inrange(b5_25,1,2)
label var san_flush_private "Sanitation: Exclusive Flush (%)"

gen san_flush_shared = 100 * inlist(b5_26,1,2) * inrange(b5_25,3,9)
label var san_flush_shared "Sanitation: Shared Flush (%)"


gen san_imp_lat_private = 100 * inlist(b5_26,3,4,6,7,10) * inrange(b5_25,1,2)
label var san_imp_lat_private "Sanitation: Exclusive Imp Latrine (%)"
*Include shared flush into improved private latrine 
replace san_imp_lat_private = 100 if san_flush_shared == 100

gen san_not_imp_lat_shared = 100 * inlist(b5_26,3,4,6,7,8,10) * inrange(b5_25,3,9)
label var san_not_imp_lat_shared "Sanitation: Shared Latrine (%)"

*include shared latrine into other 
gen san_other = 100 * (san_flush_private == 0 & san_imp_lat_private == 0)
label var san_other "Sanitation: Other (%)"

sum san_flush_private  san_imp_lat_private  san_other [aw=hh_weight]


gen san_flush = 100*inrange(b5_26,1,2)
label var san_flush "Sanitation: Flush (%)"

gen san_imp_pit = 100*inrange(b5_26,6,7)
label var san_imp_pit "Sanitation: Improved Pit (%)"

gen san_single_twin_pit = 100*inrange(b5_26,3,4)
label var san_single_twin_pit "Sanitation: Single/Twin Pit (%)"

gen san_other = 100*(san_flush!=100&san_imp_pit!= 100 & san_single_twin_pit!=100)
label var san_other "Sanitation: Other (%)"



****** Check Weights for Large Cities ****** 
gen hh_district = substr(b1_id,19,2)
destring hh_district, replace

gen n = 1 
egen district_pop_num = sum(n*hh_weight) ,by(hh_state hh_dist)
egen district_pop_denom = sum(hh_weight)
gen district_pop = district_pop_num / district_pop_denom

gsort -district_pop
order hh_state hh_dist *pop
gen state_dist = hh_state + "-" + string(hh_dist)
table state_dist if district_pop > 0.005, c(count hh_urban mean hh_urban mean district_pop) row 

gen big_city  = district_pop > 0.005 & hh_urban ==1 
 
/*
*Mumbai - district == 23
table hh_district if hh_state == "27", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*Chennai
table hh_district if hh_state == "33", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*HYderabad
table hh_district if hh_state == "36", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*delhi
table hh_district if hh_state == "07", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*Banglore
table hh_district if hh_state == "29", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*/


local var_summary hh_size in_* h20* san*


****************************************************************************
* Code to Produce the Table 
****************************************************************************

eststo all: quietly estpost summarize `var_summary'  [aw=hh_weight]
eststo urban: quietly estpost summarize `var_summary' if hh_urban == 1 [aw=hh_weight]
eststo rural: quietly estpost summarize `var_summary' if hh_urban == 0 [aw=hh_weight]
*eststo diff: quietly estpost ttest `var_summary' , by(hh_urban) 

unab vars : `var_summary'
*di `: word count `vars''
local num : word count `vars'
*di `num'
matrix b_prime = J(1,`num',0)
matrix se_prime = J(1,`num',0)
matrix t_prime = J(1,`num',0)

local rownames = "" 
local i = 1
foreach v of var `var_summary' {
	reg `v' hh_urban [aw=hh_weight]
	matrix b_temp = e(b)
	matrix b_prime[1,`i'] = b_temp[1,1]
	matrix se_temp = e(V)
	local se = sqrt(se_temp[1,1])
	matrix se_prime[1,`i'] = `se'
	matrix t_prime[1,`i'] = b_prime[1,`i']/se_prime[1,`i']
	local i = `i' + 1
	di "`v'"
	local rownames =  "`rownames'" + " " +  "`v'"
	local N = `e(N)'
	}
di `N'
matrix b = b_prime 
matrix colnames b = `rownames'
matrix se = se_prime 
matrix colnames se = `rownames'
ereturn post b 
quietly estadd matrix se
quietly estadd scalar N = `N'
eststo diff2


esttab all urban rural diff2,  cells("mean(pattern(1 1 1 0) fmt(1)) b(star pattern(0 0 0 1) fmt(1))" ///
									  "sd(pattern(1 1 1 0) par fmt(1)) se(pattern(0 0 0 1) par fmt(1))") ///
			mtitles("All" "Urban" "Rural" "Delta U-R") nonumbers wide varwidth(41) label collabels(none) stats(N, label("Observations") fmt(%9.0gc)) ///
		addnote("Notes: Households weighted by survey weights." "       Standard deviations and standard errors shown in parentheses." "       * p<0.05, ** p<0.01, *** p<0.001") ///
		title("Summary Statistics of Housing Features")
		
		
		
***** Hedonic Regressions ****** 
estimates clear 

gen log_c = log(b4_9)
label var log_c "Cons"
gen log_r = log(b7_17)
label var log_r "Rent"

*drop other for h20 and sanit
drop *other hh_size in_ppl_area in_ppl_room 

*Gen location 
gen location = hh_urban
replace location = 2 if big_city == 1 

clear matrix
local var_summary  in_* h20* san*
unab vars : `var_summary'
*di `: word count `vars''
local num : word count `vars'
*All - Rural - Urban - Big City :: bilateral, together, rent

local if1 "< 3"
local if2 "==0"
local if3 "==1 | location == 2"
local if4 "==2"

local mkt1 "All"
local mkt2 "Rural"
local mkt3 "Urban"
local mkt4 "Mega Cities"

foreach lhs in c r {
forvalues i=1(1)4 {
	local rownames = "" 
	local j = 1 
	local r2 = 0 
	matrix C`i' = J(`num',1,0)
	matrix SE`i' = J(`num',1,0)
	matrix r2`i' = J(`num',1,0)
	matrix n`i'  = J(`num',1,0)
foreach v of var `var_summary' {
	qui recode `v' (100=1)
	*di `j'
	*di "`if`i''"
	**** CHECK THE CONSTANT ***** 
	
	qui reg log_`lhs' `v' [aw=hh_weight] if location `if`i''
	*di `j'
	matrix c`j' = e(b)
	matrix se`j' = e(V)
	matrix C`i'[`j',1] = c`j'[1,1]
	matrix SE`i'[`j',1] = sqrt(se`j'[1,1])
	local r2 = `r2' + e(r2)
	local n =e(N)
	local rownames =  "`rownames'" + " " +  "`v'"

	
	local j = `j' + 1
	
		}
	matrix rownames C`i' = `rownames'
	matrix rownames SE`i' = `rownames'
	matrix b = C`i''
	matrix se = SE`i''
	
	
	ereturn post b
	qui estadd matrix se
	qui estadd scalar obs1 = `n'
	qui estadd scalar avg_r2 = `r2' / `j'
	qui estadd local mkt  `mkt`i''
	eststo c`i'_`lhs'
	
}
}
	esttab c1_c c1_r c2_c c2_r c3_c c3_r c4_c c4_r , not label b("%9.2f") /// 
	stats(obs1 avg_r2 mkt, label(Observations "Average R2" "Region") fmt(%9.0gc %9.2f)) ///
	mtitles(Cons Rent Cons Rent Cons Rent Cons Rent Cons Rent) ///
	addnotes("Regressions are weighted by survey weights and dependent variables is log of spending measure.") ///
		title("Bivariate Regressions of Log Consumption and Rent on Housing Features")
	
****************** WATER ***********************************


estimates clear 
local var_summary  h20* 
local if1 "< 3"
local if2 "==0"
local if3 "==1 | location == 2"
local if4 "==2"

local mkt1 "All"
local mkt2 "Rural"
local mkt3 "Urban"
local mkt4 "Mega Cities"

foreach lhs in c r {
forvalues i=1(1)4 {

	qui reg log_`lhs' `var_summary' [aw=hh_weight] if location `if`i''
	qui estadd local mkt  `mkt`i''
	eststo d`i'_`lhs'
	
	}
	}
	
	esttab d1_c d1_r d2_c d2_r d3_c d3_r d4_c d4_r , nose not label b("%9.2f")	r2 ///
	stats(mkt N r2 , label(Region Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
	title("Combined Hedonic Regression of Log Consumption and Rent on Water Features") ///
	addnotes("Regressions are weighted by survey weights and dependent variables is log of spending measure.")	
	

****************** Sanitation ***********************************


estimates clear 
local var_summary  san* 
local if1 "< 3"
local if2 "==0"
local if3 "==1 | location == 2"
local if4 "==2"

local mkt1 "All"
local mkt2 "Rural"
local mkt3 "Urban"
local mkt4 "Mega Cities"

foreach lhs in c r {
forvalues i=1(1)4 {

	qui reg log_`lhs' `var_summary' [aw=hh_weight] if location `if`i''
	qui estadd local mkt  `mkt`i''
	eststo d`i'_`lhs'
	
	}
	}
	
	esttab d1_c d1_r d2_c d2_r d3_c d3_r d4_c d4_r , nose not label b("%9.2f")	r2 ///
	stats(mkt N r2 , label(Region Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
	title("Combined Hedonic Regression of Log Consumption and Rent on Sanitation Features") ///
	addnotes("Regressions are weighted by survey weights and dependent variables is log of spending measure.")		
	
	
	
	
****************** NUMBER OF ROOMS ***********************************


gen in_rm_2 = in_room == 2
gen in_rm_3 = in_room == 3
gen in_rm_4 = in_room == 4
gen in_rm_5 = in_room == 5
gen in_rm_6p = in_room >= 6 

local var_summary  in_rm_* 
local if1 "< 3"
local if2 "==0"
local if3 "==1 | location == 2"
local if4 "==2"

local mkt1 "All"
local mkt2 "Rural"
local mkt3 "Urban"
local mkt4 "Mega Cities"

foreach lhs in c r {
forvalues i=1(1)4 {

	qui reg log_`lhs' `var_summary' [aw=hh_weight] if location `if`i''
	qui estadd local mkt  `mkt`i''
	eststo d`i'_`lhs'
	
	}
	}
	
	esttab d1_c d1_r d2_c d2_r d3_c d3_r d4_c d4_r , nose not label b("%9.2f")	r2 ///
	stats(mkt N r2 , label(Region Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
	title("Combined Hedonic Regression of Log Consumption and Rent on Number of Rooms") ///
	addnotes("Regressions are weighted by survey weights and dependent variables is log of spending measure. Omitted is one room dwelling.")		
	
	
	
	
	
*************** SINGLE REGRESSION **********************

*All - Rural - Urban - Big City :: bilateral, together, rent



local var_summary  in_wall* in_floor* in_roof* in_rm_* in_sep_kitch in_flat h20_piped_in h20_yard   san_flush san_imp_pit
local if1 "< 3"
local if2 "==0"
local if3 "==1 | location == 2"
local if4 "==2"

local mkt1 "All"
local mkt2 "Rural"
local mkt3 "Urban"
local mkt4 "Mega Cities"

foreach lhs in c r {
forvalues i=1(1)4 {

	areg log_`lhs' `var_summary' [aw=hh_weight] if location `if`i'', absorb(hh_district)
	qui estadd local mkt  `mkt`i''
	eststo d`i'_`lhs'
	
	}
	}
	
	esttab d1_c d1_r d2_c d2_r d3_c d3_r d4_c d4_r , nose not label b("%9.2f")	r2 ///
	stats(mkt N r2 , label(Region Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
	title("Combined Hedonic Regression of Log Consumption and Rent on Housing Features") ///
	addnotes("Regressions are weighted by survey weights and dependent variables is log of spending measure. Regressions include district fixed effects.")

