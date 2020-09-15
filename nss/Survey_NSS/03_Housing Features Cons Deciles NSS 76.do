****************************************************************************
* Description: Check Regressions of housing features on income 
* Date: September 15, 2020
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

gen san_flush = 100*inrange(b5_26,1,2)
label var san_flush "Sanitation: Flush (%)"

gen san_imp_pit = 100*inrange(b5_26,6,7)
label var san_imp_pit "Sanitation: Improved Pit (%)"

gen san_single_twin_pit = 100*inrange(b5_26,3,4)
label var san_single_twin_pit "Sanitation: Single/Twin Pit (%)"

gen san_other = 100*(san_flush!=100&san_imp_pit!= 100 & san_single_twin_pit!=100)
label var san_other "Sanitation: Other (%)"


****************************************************************************
* Get Consumption Quintiles 
****************************************************************************
gen log_c = log(b4_9)
label var log_c "Cons"
gen log_r = log(b7_17)
label var log_r "Rent"
xtile c_quin = b4_9 [aw=hh_weight] if hh_urban == 1, nq(10)

xtile c_quin_rural = b4_9 [aw=hh_weight] if hh_urban == 0, nq(10)

xi i.c_quin , noomit pre(Q_)
local i = 1
foreach var of  var Q_* {
label var `var' "Q`i'"
local i = `i' + 1
}
* in_ppl_room 
local var in_wall_permanent in_roof_permanent in_floor_permanent in_all_permanent h20_piped_in san_flush in_sep_kitch in_size in_room in_ppl_room in_ppl_area hh_size

* URBAN 
estimates clear
foreach v of var `var' { 
	qui sum `v'
	*if `r(max)' == 100 recode `v' (100=1)

	qui reg `v' Q_* [aw=hh_weight] if hh_urban == 1, nocons
	eststo 
}

esttab, label b("%9.2f") nose not  ///
mtitles (Wall Roof Floor WRF H20 San Kitchen Sq Rooms P/R P/A "HH Size") varwidth(3) ///
title(How Housing Features Change as Income and Rent Increase)

*RURAL 


xi i.c_quin_rural , noomit pre(R_)
estimates clear
foreach v of var `var' { 
	qui sum `v'
	*if `r(max)' == 100 recode `v' (100=1)

	qui reg `v' R_* [aw=hh_weight] if hh_urban == 0, nocons
	eststo 
}

esttab, label b("%9.2f") nose not  ///
mtitles (Wall Roof Floor WRF H20 San Kitchen Sq Rooms P/R P/A "HH Size") varwidth(3) ///
title(How Housing Features Change as Income and Rent Increase - Rural)
