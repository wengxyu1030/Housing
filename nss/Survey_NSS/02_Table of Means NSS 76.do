****************************************************************************
* Description: Generate a summary table of NSS 76 
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

gen in_room = b7_2 + b7_3 
label var in_room "Number of Rooms"

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
local if3 "==1"
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
	qui reg log_`lhs' `v' [aw=hh_weight] if location `if`i'', nocons
	*di `j'
	matrix c`j' = e(b)
	matrix se`j' = e(V)
	matrix C`i'[`j',1] = c`j'
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
	
	
	
	
*************** SINGLE REGRESSION **********************

*All - Rural - Urban - Big City :: bilateral, together, rent

drop in_all_permanent

local var_summary  in_* h20* san*
local if1 "< 3"
local if2 "==0"
local if3 "==1"
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
	title("Combined Hedonic Regression of Log Consumption and Rent on Housing Features") ///
	addnotes("Regressions are weighted by survey weights and dependent variables is log of spending measure.")

